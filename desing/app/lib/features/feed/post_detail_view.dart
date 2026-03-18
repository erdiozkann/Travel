import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ui/design_tokens.dart';

/// Post Detail View
class PostDetailView extends StatefulWidget {
  final String postId;

  const PostDetailView({super.key, required this.postId});

  @override
  State<PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<PostDetailView> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _post;
  List<Map<String, dynamic>> _comments = [];
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPostDetails();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPostDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Fetch Post details (simplified for MVP)
      final postResponse = await Supabase.instance.client
          .from('posts')
          .select('*, profiles(id, display_name, avatar_url)')
          .eq('id', widget.postId)
          .maybeSingle();

      if (postResponse == null) {
        setState(() {
          _error = 'Post not found';
          _isLoading = false;
        });
        return;
      }

      // 2. Fetch Comments (dummy logic for now, using an empty array since the table might not exist yet)
      // final commentsResponse = await Supabase.instance.client
      //    .from('comments')
      //    ...

      setState(() {
        _post = postResponse;
        _comments = []; // Real comments will be fetched here later
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please log in to comment')));
      return;
    }

    // Dummy add comment for MVP (UI optimistic update)
    setState(() {
      _comments.insert(0, {
        'id': DateTime.now().toIso8601String(),
        'content': text,
        'created_at': DateTime.now().toIso8601String(),
        'profiles': {'display_name': 'You', 'avatar_url': null},
      });
      _commentController.clear();
    });

    // In production, insert to Supabase 'comments' table here.
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Unknown error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final post = _post!;
    final profile = post['profiles'] ?? {};
    final caption = post['caption'] ?? '';
    final mediaUrls = post['media_urls'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                // User Header
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: profile['avatar_url'] != null
                        ? NetworkImage(profile['avatar_url'])
                        : null,
                    child: profile['avatar_url'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(profile['display_name'] ?? 'Unknown User'),
                  subtitle: Text(
                    _formatDate(post['created_at']),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),

                // Caption
                if (caption.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(caption),
                  ),

                // Media
                if (mediaUrls.isNotEmpty)
                  SizedBox(
                    height: 300,
                    child: PageView.builder(
                      itemCount: mediaUrls.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          mediaUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        );
                      },
                    ),
                  ),

                const Divider(),

                // Comments Section Header
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Comments',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                // Comments List
                if (_comments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('No comments yet. Be the first to comment!'),
                    ),
                  )
                else
                  ..._comments.map((comment) => _buildCommentItem(comment)),
              ],
            ),
          ),

          // Comment Input
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final profile = comment['profiles'] ?? {};
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: profile['avatar_url'] != null
                ? NetworkImage(profile['avatar_url'])
                : null,
            child: profile['avatar_url'] == null
                ? const Icon(Icons.person, size: 16)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      profile['display_name'] ?? 'User',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(comment['created_at']),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment['content'] ?? ''),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -1),
            blurRadius: 4,
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _postComment(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            color: AppColors.primary,
            onPressed: () {
              FocusScope.of(context).unfocus();
              _postComment();
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final date = DateTime.parse(isoString);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 0) return '${diff.inDays}d';
      if (diff.inHours > 0) return '${diff.inHours}h';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m';
      return 'just now';
    } catch (e) {
      return '';
    }
  }
}
