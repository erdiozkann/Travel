import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ui/design_tokens.dart';

/// Create Post View - Screen 08
/// Per SCREEN_SPECS/08_CREATE_POST.md
///
/// Content creation flow for sharing travel experiences:
/// - Photo/video/carousel upload
/// - Place tagging (city, place, experience, stay)
/// - Caption with hashtag support
/// - Check-in with event-based location
/// - Content safety pre-check before publish
class CreatePostView extends StatefulWidget {
  final String? prefilledTag; // Format: type:id (e.g., "experience:uuid")

  const CreatePostView({super.key, this.prefilledTag});

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView> {
  // State per 5.1 Local State (UI)
  final List<XFile> _selectedMedia = [];
  final TextEditingController _captionController = TextEditingController();

  Map<String, dynamic>? _selectedLocation;
  Map<String, dynamic>? _taggedEntity;
  String? _taggedType; // place, experience, stay

  bool _includeCheckin = false;
  bool _isPublic = true;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _error;

  final ImagePicker _picker = ImagePicker();
  final int _maxMediaItems = 10;
  final int _maxCaptionLength = 2000;

  @override
  void initState() {
    super.initState();
    _captionController.addListener(() => setState(() {}));
    _parsePrefilledTag();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _parsePrefilledTag() {
    if (widget.prefilledTag != null && widget.prefilledTag!.contains(':')) {
      final parts = widget.prefilledTag!.split(':');
      if (parts.length == 2) {
        _taggedType = parts[0];
        _loadPrefilledEntity(parts[0], parts[1]);
      }
    }
  }

  Future<void> _loadPrefilledEntity(String type, String id) async {
    try {
      String table;
      switch (type) {
        case 'experience':
          table = 'experiences';
          break;
        case 'stay':
          table = 'stays';
          break;
        default:
          table = 'places';
      }

      final response = await Supabase.instance.client
          .from(table)
          .select('id, title, name')
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _taggedEntity = response;
          _taggedType = type;
        });
      }
    } catch (e) {
      debugPrint('Failed to load prefilled entity: $e');
    }
  }

  bool get _hasUnsavedChanges =>
      _selectedMedia.isNotEmpty ||
      _captionController.text.isNotEmpty ||
      _selectedLocation != null ||
      _taggedEntity != null;

  bool get _canSubmit => _selectedMedia.isNotEmpty && !_isUploading;

  Future<void> _pickFromCamera() async {
    if (_selectedMedia.length >= _maxMediaItems) {
      _showMaxMediaError();
      return;
    }

    try {
      final image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selectedMedia.add(image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Camera error: $e')));
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final remainingSlots = _maxMediaItems - _selectedMedia.length;
    if (remainingSlots <= 0) {
      _showMaxMediaError();
      return;
    }

    try {
      final images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        final toAdd = images.take(remainingSlots).toList();
        setState(() {
          _selectedMedia.addAll(toAdd);
        });

        if (images.length > remainingSlots && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Only added $remainingSlots of ${images.length} images (max $_maxMediaItems)',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gallery error: $e')));
      }
    }
  }

  void _showMaxMediaError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Maximum $_maxMediaItems items allowed')),
    );
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
    });
  }

  void _reorderMedia(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _selectedMedia.removeAt(oldIndex);
      _selectedMedia.insert(newIndex, item);
    });
  }

  Future<void> _selectLocation() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _LocationSearchSheet(
        onLocationSelected: (location) {
          setState(() {
            _selectedLocation = location;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _selectTag() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _TagSearchSheet(
        onTagSelected: (entity, type) {
          setState(() {
            _taggedEntity = entity;
            _taggedType = type;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _submitPost() async {
    if (!_canSubmit) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      context.push('/auth/login?redirect=/feed/create');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _error = null;
    });

    try {
      // Step 1: Upload media
      final mediaUrls = <String>[];
      for (var i = 0; i < _selectedMedia.length; i++) {
        final file = _selectedMedia[i];
        final url = await _uploadMedia(file, user.id);
        mediaUrls.add(url);

        setState(() {
          _uploadProgress =
              (i + 1) / _selectedMedia.length * 0.7; // 70% for uploads
        });
      }

      setState(() {
        _uploadProgress = 0.8; // Safety check
      });

      // Step 2: Content safety check (simplified - would call edge function)
      final safetyResult = await _checkContentSafety(
        mediaUrls,
        _captionController.text,
      );

      if (safetyResult['recommended_action'] == 'remove') {
        throw Exception('Content does not meet community guidelines');
      }

      setState(() {
        _uploadProgress = 0.9; // Creating post
      });

      // Step 3: Create post record
      final postData = {
        'user_id': user.id,
        'caption': _captionController.text,
        'media_urls': mediaUrls,
        'is_public': _isPublic,
        'city_id': _selectedLocation?['id'],
        'tagged_type': _taggedType,
        'tagged_id': _taggedEntity?['id'],
        'status': safetyResult['recommended_action'] == 'review'
            ? 'pending_review'
            : 'published',
      };

      await Supabase.instance.client.from('posts').insert(postData);

      // Step 4: Create checkin if enabled
      if (_includeCheckin && _selectedLocation != null) {
        await Supabase.instance.client.from('checkins').insert({
          'user_id': user.id,
          'city_id': _selectedLocation!['id'],
          'place_name': _selectedLocation!['name'],
        });
      }

      setState(() {
        _uploadProgress = 1.0; // Complete
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post shared! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> _uploadMedia(XFile file, String userId) async {
    final bytes = await file.readAsBytes();
    final fileName =
        '$userId/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

    await Supabase.instance.client.storage
        .from('posts')
        .uploadBinary(fileName, bytes);

    final publicUrl = Supabase.instance.client.storage
        .from('posts')
        .getPublicUrl(fileName);

    return publicUrl;
  }

  Future<Map<String, dynamic>> _checkContentSafety(
    List<String> mediaUrls,
    String caption,
  ) async {
    // Simplified safety check - in production this would call ContentSafetyAgent
    // For MVP, allow all content (fail-open)
    return {
      'safe': true,
      'flags': [],
      'recommended_action': 'allow',
      'confidence_level': 'high',
    };
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard post?'),
        content: const Text('Your changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscard();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final shouldPop = await _confirmDiscard();
              if (shouldPop && context.mounted) {
                context.pop();
              }
            },
          ),
          title: const Text('New Post'),
          actions: [
            TextButton(
              onPressed: _canSubmit ? _submitPost : null,
              child: Text(
                'Share',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _canSubmit ? AppColors.primary : Colors.grey,
                ),
              ),
            ),
          ],
        ),
        body: _isUploading ? _buildUploadingState() : _buildForm(),
      ),
    );
  }

  Widget _buildUploadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(value: _uploadProgress),
            const SizedBox(height: 24),
            Text(
              _uploadProgress < 0.7
                  ? 'Uploading media...'
                  : _uploadProgress < 0.9
                  ? 'Checking content...'
                  : 'Creating post...',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_uploadProgress * 100).toInt()}%',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3.2 Media Section
          _buildMediaSection(),
          const SizedBox(height: 24),

          // 3.3 Caption Section
          _buildCaptionSection(),
          const SizedBox(height: 24),

          // 3.4 Location Section
          _buildLocationSection(),
          const SizedBox(height: 16),

          // 3.5 Tag Section
          _buildTagSection(),
          const SizedBox(height: 16),

          // 3.6 Check-in Toggle
          _buildCheckinToggle(),
          const SizedBox(height: 16),

          // 3.7 Privacy Toggle
          _buildPrivacyToggle(),
          const SizedBox(height: 24),

          // Error display
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // Submit button (also in app bar)
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSubmit ? _submitPost : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, AppButton.height),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              child: const Text(
                'Share',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 3.2 Media Section
  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Add Photos/Videos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_selectedMedia.length}/$_maxMediaItems',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Media picker buttons
        if (_selectedMedia.isEmpty)
          Row(
            children: [
              Expanded(
                child: _buildMediaPickerButton(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: _pickFromCamera,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMediaPickerButton(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: _pickFromGallery,
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              // Selected media grid
              SizedBox(
                height: 120,
                child: ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedMedia.length + 1,
                  onReorder: (oldIndex, newIndex) {
                    if (oldIndex < _selectedMedia.length &&
                        newIndex <= _selectedMedia.length) {
                      _reorderMedia(oldIndex, newIndex);
                    }
                  },
                  itemBuilder: (context, index) {
                    if (index == _selectedMedia.length) {
                      // Add more button
                      return Container(
                        key: const ValueKey('add_more'),
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: _pickFromGallery,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(
                                AppRadius.card,
                              ),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final file = _selectedMedia[index];
                    return Container(
                      key: ValueKey(file.path),
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            child: Image.file(
                              File(file.path),
                              width: 100,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (index == 0)
                            Positioned(
                              bottom: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Cover',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeMedia(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildMediaPickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  /// 3.3 Caption Section
  Widget _buildCaptionSection() {
    final charCount = _captionController.text.length;
    final isNearLimit = charCount > _maxCaptionLength * 0.9;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Caption',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '$charCount/$_maxCaptionLength',
              style: TextStyle(
                color: isNearLimit ? Colors.red : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _captionController,
          maxLines: 5,
          maxLength: _maxCaptionLength,
          decoration: InputDecoration(
            hintText: 'Tell your story...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            counterText: '',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Hashtags are auto-detected (e.g., #barcelona #travel)',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ],
    );
  }

  /// 3.4 Location Section
  Widget _buildLocationSection() {
    return GestureDetector(
      onTap: _selectLocation,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: _selectedLocation != null
                  ? AppColors.primary
                  : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedLocation != null
                    ? _selectedLocation!['name'] ?? 'Selected location'
                    : 'Add location',
                style: TextStyle(
                  color: _selectedLocation != null
                      ? Colors.black
                      : Colors.grey[600],
                ),
              ),
            ),
            if (_selectedLocation != null)
              GestureDetector(
                onTap: () => setState(() => _selectedLocation = null),
                child: const Icon(Icons.close, size: 18, color: Colors.grey),
              )
            else
              const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  /// 3.5 Tag Section
  Widget _buildTagSection() {
    final entityName =
        _taggedEntity?['title'] ?? _taggedEntity?['name'] ?? 'Tagged item';

    return GestureDetector(
      onTap: _selectTag,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            Icon(
              _taggedType == 'experience'
                  ? Icons.local_activity
                  : _taggedType == 'stay'
                  ? Icons.hotel
                  : Icons.sell,
              color: _taggedEntity != null ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _taggedEntity != null
                    ? entityName
                    : 'Tag a place or experience',
                style: TextStyle(
                  color: _taggedEntity != null
                      ? Colors.black
                      : Colors.grey[600],
                ),
              ),
            ),
            if (_taggedEntity != null)
              GestureDetector(
                onTap: () => setState(() {
                  _taggedEntity = null;
                  _taggedType = null;
                }),
                child: const Icon(Icons.close, size: 18, color: Colors.grey),
              )
            else
              const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  /// 3.6 Check-in Toggle
  Widget _buildCheckinToggle() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          const Icon(Icons.pin_drop, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Include check-in'),
                Text(
                  'Your location will be shared with this post',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: _includeCheckin,
            onChanged: (value) => setState(() => _includeCheckin = value),
          ),
        ],
      ),
    );
  }

  /// 3.7 Privacy Toggle
  Widget _buildPrivacyToggle() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Private Post'),
                Text(
                  'Only visible to followers',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: !_isPublic,
            onChanged: (value) => setState(() => _isPublic = !value),
          ),
        ],
      ),
    );
  }
}

/// Location search modal
class _LocationSearchSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onLocationSelected;

  const _LocationSearchSheet({required this.onLocationSelected});

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  List<Map<String, dynamic>> _cities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      List<dynamic> response;
      try {
        response = await Supabase.instance.client
            .from('cities')
            .select()
            .eq('is_active', true)
            .order('name')
            .limit(50);
      } catch (e) {
        // Fallback if is_active column doesn't exist
        response = await Supabase.instance.client
            .from('cities')
            .select()
            .order('name')
            .limit(50);
      }

      setState(() {
        _cities = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: Text(
              'Select Location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: scrollController,
                    itemCount: _cities.length,
                    itemBuilder: (context, index) {
                      final city = _cities[index];
                      return ListTile(
                        leading: const Icon(Icons.location_city),
                        title: Text(city['name'] ?? 'Unknown'),
                        subtitle: Text(city['country_code'] ?? ''),
                        onTap: () => widget.onLocationSelected(city),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Tag search modal
class _TagSearchSheet extends StatefulWidget {
  final Function(Map<String, dynamic>, String) onTagSelected;

  const _TagSearchSheet({required this.onTagSelected});

  @override
  State<_TagSearchSheet> createState() => _TagSearchSheetState();
}

class _TagSearchSheetState extends State<_TagSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Search experiences
      final experiences = await Supabase.instance.client
          .from('experiences')
          .select('id, title')
          .ilike('title', '%$query%')
          .limit(5);

      // Search stays
      final stays = await Supabase.instance.client
          .from('stays')
          .select('id, title')
          .ilike('title', '%$query%')
          .limit(5);

      // Search places
      final places = await Supabase.instance.client
          .from('places')
          .select('id, name')
          .ilike('name', '%$query%')
          .limit(5);

      setState(() {
        _results = [
          ...List<Map<String, dynamic>>.from(
            experiences,
          ).map((e) => {...e, 'type': 'experience'}),
          ...List<Map<String, dynamic>>.from(
            stays,
          ).map((s) => {...s, 'type': 'stay'}),
          ...List<Map<String, dynamic>>.from(
            places,
          ).map((p) => {...p, 'type': 'place'}),
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: Text(
              'Tag a Place',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search places, experiences...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              onChanged: _search,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: scrollController,
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      final type = item['type'] as String;
                      final name = item['title'] ?? item['name'] ?? 'Unknown';

                      IconData icon;
                      switch (type) {
                        case 'experience':
                          icon = Icons.local_activity;
                          break;
                        case 'stay':
                          icon = Icons.hotel;
                          break;
                        default:
                          icon = Icons.place;
                      }

                      return ListTile(
                        leading: Icon(icon, color: AppColors.primary),
                        title: Text(name),
                        subtitle: Text(type.toUpperCase()),
                        onTap: () => widget.onTagSelected(item, type),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
