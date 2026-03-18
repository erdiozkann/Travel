import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ui/design_tokens.dart';
import '../../core/ui/widgets/cards.dart';

/// Community Feed View - Screen 07
/// Per SCREEN_SPECS/07_COMMUNITY_FEED.md
///
/// Social discovery hub with:
/// - Instagram-style vertical scrolling feed
/// - Organic user posts + sponsored posts
/// - Social actions: like, comment, save
/// - Real experiences from real travelers
class FeedView extends StatefulWidget {
  const FeedView({super.key});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  // State per 5.1 Local State (UI)
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _posts = [];
  final Set<String> _likedPosts = {};
  final Set<String> _savedPosts = {};
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMorePosts();
    }
  }

  Future<void> _loadFeed() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch posts with user profiles (per 7.1 Read Operations)
      final response = await Supabase.instance.client
          .from('posts')
          .select('''
            id,
            caption,
            media_urls,
            city_id,
            tagged_type,
            tagged_id,
            is_public,
            created_at,
            is_sponsored,
            sponsor_name,
            sponsor_cta,
            profiles:user_id (
              id,
              display_name,
              avatar_url
            ),
            cities:city_id (
              name
            )
          ''')
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .limit(20);

      // Also fetch like/save status for current user
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final likes = await Supabase.instance.client
            .from('likes')
            .select('post_id')
            .eq('user_id', user.id);

        final saves = await Supabase.instance.client
            .from('saved_items')
            .select('target_id')
            .eq('user_id', user.id)
            .eq('target_type', 'post');

        for (final like in likes) {
          _likedPosts.add(like['post_id'] as String);
        }
        for (final save in saves) {
          _savedPosts.add(save['target_id'] as String);
        }
      }

      setState(() {
        _posts = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (!_hasMore || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final lastPost = _posts.isNotEmpty ? _posts.last : null;
      final lastCreatedAt = lastPost?['created_at'];

      final response = await Supabase.instance.client
          .from('posts')
          .select('''
            id, caption, media_urls, city_id, tagged_type, tagged_id,
            is_public, created_at, is_sponsored, sponsor_name, sponsor_cta,
            profiles:user_id ( id, display_name, avatar_url ),
            cities:city_id ( name )
          ''')
          .eq('is_public', true)
          .lt('created_at', lastCreatedAt ?? DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(20);

      final newPosts = List<Map<String, dynamic>>.from(response);

      setState(() {
        _posts.addAll(newPosts);
        _hasMore = newPosts.length == 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshFeed() async {
    await _loadFeed();
  }

  Future<void> _toggleLike(String postId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showAuthPrompt();
      return;
    }

    final isLiked = _likedPosts.contains(postId);

    // Optimistic update
    setState(() {
      if (isLiked) {
        _likedPosts.remove(postId);
      } else {
        _likedPosts.add(postId);
      }
    });

    try {
      if (isLiked) {
        await Supabase.instance.client
            .from('likes')
            .delete()
            .eq('user_id', user.id)
            .eq('post_id', postId);
      } else {
        await Supabase.instance.client.from('likes').insert({
          'user_id': user.id,
          'post_id': postId,
        });
      }
    } catch (e) {
      // Revert on error
      setState(() {
        if (isLiked) {
          _likedPosts.add(postId);
        } else {
          _likedPosts.remove(postId);
        }
      });
    }
  }

  Future<void> _toggleSave(String postId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showAuthPrompt();
      return;
    }

    final isSaved = _savedPosts.contains(postId);

    setState(() {
      if (isSaved) {
        _savedPosts.remove(postId);
      } else {
        _savedPosts.add(postId);
      }
    });

    try {
      if (isSaved) {
        await Supabase.instance.client
            .from('saved_items')
            .delete()
            .eq('user_id', user.id)
            .eq('target_id', postId)
            .eq('target_type', 'post');
      } else {
        await Supabase.instance.client.from('saved_items').insert({
          'user_id': user.id,
          'target_id': postId,
          'target_type': 'post',
        });
      }
    } catch (e) {
      setState(() {
        if (isSaved) {
          _savedPosts.add(postId);
        } else {
          _savedPosts.remove(postId);
        }
      });
    }
  }

  void _showAuthPrompt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Sign in to interact with posts'),
        action: SnackBarAction(
          label: 'Sign In',
          onPressed: () => context.push('/auth/login'),
        ),
      ),
    );
  }

  String _formatTimestamp(String? isoDate) {
    if (isoDate == null) return '';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text(
          'Community',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () => context.push('/feed/create'),
            tooltip: 'Create Post',
          ),
        ],
      ),
      body: _buildBody(),
      // FAB for create post (per 3.5)
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/feed/create'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _posts.isEmpty) {
      return _buildLoadingState();
    }

    if (_error != null && _posts.isEmpty) {
      return _buildErrorState();
    }

    if (_posts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshFeed,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.sm),
        itemCount: _posts.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final post = _posts[index];
          return _buildPostCard(post);
        },
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final postId = post['id'] as String;
    final profile = post['profiles'] as Map<String, dynamic>?;
    final city = post['cities'] as Map<String, dynamic>?;
    final mediaUrls =
        (post['media_urls'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return PostCard(
      id: postId,
      username: profile?['display_name'] ?? 'Anonymous',
      avatarUrl: profile?['avatar_url'],
      caption: post['caption'],
      mediaUrls: mediaUrls,
      locationCity: city?['name'],
      taggedEntityName: null, // TODO: Fetch from tagged_id
      taggedEntityType: post['tagged_type'],
      likeCount: 0, // TODO: Aggregate from likes table
      commentCount: 0, // TODO: Aggregate from comments table
      isLiked: _likedPosts.contains(postId),
      isSaved: _savedPosts.contains(postId),
      isSponsored: post['is_sponsored'] == true,
      sponsorName: post['sponsor_name'],
      sponsorCta: post['sponsor_cta'],
      timestamp: _formatTimestamp(post['created_at']),
      onLike: () => _toggleLike(postId),
      onSave: () => _toggleSave(postId),
      onComment: () {
        context.push('/feed/post/$postId');
      },
      onShare: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share: ${post['caption'] ?? 'post'}')),
        );
      },
      onAvatarTap: () {
        if (profile?['id'] != null) {
          context.push('/u/${profile!['id']}');
        }
      },
      onLocationTap: () {
        if (post['city_id'] != null) {
          context.go('/map');
        }
      },
      onTaggedEntityTap: () {
        final type = post['tagged_type'];
        final id = post['tagged_id'];
        if (type == 'experience' && id != null) {
          context.pushNamed('experience-detail', pathParameters: {'id': id});
        } else if (type == 'stay' && id != null) {
          context.pushNamed('stay-detail', pathParameters: {'id': id});
        }
      },
      onCtaTap: () {
        // Sponsored CTA - internal navigation only per GUARDRAILS
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Learn more')));
      },
    );
  }

  /// Loading skeleton (per 11.2)
  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          height: 400,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(width: 120, height: 16, color: Colors.grey[300]),
                  ],
                ),
              ),
              Expanded(child: Container(color: Colors.grey[300])),
            ],
          ),
        );
      },
    );
  }

  /// Error state (per 11.3)
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Failed to load feed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: _loadFeed,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, AppButton.height),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty state (per 3.6 and 11.1)
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Your feed is empty',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Follow travelers or explore the community',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => context.go('/explore'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, AppButton.height),
                  ),
                  child: const Text('Explore'),
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () {
                    context.go('/explore');
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(120, AppButton.height),
                  ),
                  child: const Text('Find People'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
