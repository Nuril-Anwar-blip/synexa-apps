import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../models/post_model.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';
import 'widgets/post_card.dart';
import '../settings/settings_screen.dart';

/// Halaman Komunitas
///
/// Halaman ini memungkinkan pengguna untuk berinteraksi dengan komunitas.
/// Pengguna dapat membuat postingan, melihat postingan lain, dan berkomentar.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _supabase = Supabase.instance.client;
  final List<Post> _posts = [];

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  RealtimeChannel? _postsChannel;
  Timer? _realtimeDebounce;

  @override
  void initState() {
    super.initState();
    _loadInitialFeed();
    _setupRealtimeListener();
  }

  /// Memuat feed awal saat halaman dibuka.
  Future<void> _loadInitialFeed() async {
    await _refreshPosts(showFullLoader: true);
  }

  /// Mengambil daftar postingan dari database Supabase.
  /// Memanggil RPC 'get_posts_with_details'.
  Future<List<Post>> _getPosts() async {
    final user = _supabase.auth.currentUser;
    final userId = user?.id;
    
    // Schema mapping: image_url, users join, and counts
    final response = await _supabase
        .from('posts')
        .select('''
          *,
          users!inner(full_name, photo_url),
          likes(count),
          comments(count)
        ''')
        .order('created_at', ascending: false);
    
    final List<Post> posts = [];
    for (var data in (response as List)) {
      final postData = Map<String, dynamic>.from(data);
      final postId = postData['id'];
      
      // Fetch if user liked this post
      bool hasLiked = false;
      if (userId != null) {
        final likeCheck = await _supabase
            .from('likes')
            .select('id')
            .eq('post_id', postId)
            .eq('user_id', userId)
            .maybeSingle();
        hasLiked = likeCheck != null;
      }

      // Map counts from the select (Note: Supabase count() return structure)
      final likesCount = postData['likes']?[0]?['count'] ?? 0;
      final commentsCount = postData['comments']?[0]?['count'] ?? 0;

      postData['media_url'] = postData['image_url'];
      postData['like_count'] = likesCount;
      postData['comment_count'] = commentsCount;
      postData['user_has_liked'] = hasLiked;
      
      posts.add(Post.fromMap(postData));
    }
    return posts;
  }

  /// Menyiapkan listener real-time untuk pembaruan postingan, like, dan komentar.
  void _setupRealtimeListener() {
    _postsChannel = _supabase.channel('community_feed_channel')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'posts',
        callback: (_) => _scheduleRealtimeRefresh(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'likes',
        callback: (_) => _scheduleRealtimeRefresh(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'comments',
        callback: (_) => _scheduleRealtimeRefresh(),
      )
      ..subscribe();
  }

  /// Menjadwalkan refresh feed dengan debounce untuk menghindari reload berlebihan.
  void _scheduleRealtimeRefresh() {
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _refreshPosts();
    });
  }

  /// Menyegarkan daftar postingan di UI.
  /// [showFullLoader] menentukan apakah menampilkan loading screen penuh atau tidak.
  Future<void> _refreshPosts({bool showFullLoader = false}) async {
    if (showFullLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() => _isRefreshing = true);
    }

    try {
      final posts = await _getPosts();
      if (!mounted) return;
      setState(() {
        _posts
          ..clear()
          ..addAll(posts);
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Tidak dapat memuat postingan. Tarik ke bawah untuk refresh.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat postingan: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  /// Mengelola aksi like/unlike pada postingan.
  /// Memperbarui UI secara optimistik sebelum request ke server.
  Future<void> _toggleLike(Post post) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu.')),
      );
      return;
    }

    final isCurrentlyLiked = post.userHasLiked;
    final delta = isCurrentlyLiked ? -1 : 1;

    _updatePost(post.id, (current) {
      final nextCount = (current.likeCount + delta).clamp(0, 1 << 30);
      return current.copyWith(
        userHasLiked: !isCurrentlyLiked,
        likeCount: nextCount,
      );
    });

    try {
      if (isCurrentlyLiked) {
        await _supabase.from('likes').delete().match({
          'post_id': post.id,
          'user_id': user.id,
        });
      } else {
        await _supabase.from('likes').insert({
          'post_id': post.id,
          'user_id': user.id,
        });
      }
    } catch (e) {
      _updatePost(post.id, (_) => post);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memperbarui suka: $e')));
    }
  }

  /// Menghapus postingan beserta file media jika ada.
  Future<void> _deletePost(Post post) async {
    try {
      if (post.media_url != null && post.media_url!.isNotEmpty) {
        final uri = Uri.parse(post.media_url!);
        final segments = uri.pathSegments;
        final publicIndex = segments.indexOf('public');
        if (publicIndex != -1 && publicIndex + 2 <= segments.length) {
          final bucketId = segments[publicIndex + 1];
          final filePath = segments.sublist(publicIndex + 2).join('/');
          await _supabase.storage.from(bucketId).remove([filePath]);
        }
      }

      await _supabase.from('posts').delete().eq('id', post.id);
      if (!mounted) return;
      setState(() {
        _posts.removeWhere((item) => item.id == post.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Postingan berhasil dihapus')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus postingan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _navigateToCreatePost() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
    if (created == true) {
      await _refreshPosts();
    }
  }

  Future<void> _openDetail(Post post) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
    );
    if (mounted) {
      _refreshPosts();
    }
  }

  void _updatePost(String postId, Post Function(Post current) updater) {
    final index = _posts.indexWhere((item) => item.id == postId);
    if (index == -1) return;
    setState(() {
      _posts[index] = updater(_posts[index]);
    });
  }

  @override
  void dispose() {
    _realtimeDebounce?.cancel();
    if (_postsChannel != null) {
      _supabase.removeChannel(_postsChannel!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Komunitas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Pengaturan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            tooltip: 'Segarkan',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isRefreshing ? null : () => _refreshPosts(),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 74,
        ),
        child: FloatingActionButton.extended(
          onPressed: _navigateToCreatePost,
          icon: const Icon(Icons.edit_rounded),
          label: const Text('Bagikan'),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _isLoading
            ? const _FeedLoadingPlaceholder()
            : _buildFeedContent(),
      ),
    );
  }

  Widget _buildFeedContent() {
    return RefreshIndicator(
      onRefresh: () => _refreshPosts(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).padding.bottom + 80,
        ),
        children: [
          _CommunityHeroCard(
            postCount: _posts.length,
            onCreateTap: _navigateToCreatePost,
          ),
          const SizedBox(height: 16),
          _QuickActionRow(
            onCreateTap: _navigateToCreatePost,
            onRefreshTap: _isRefreshing ? null : () => _refreshPosts(),
            onTipsTap: () => showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (_) => const _CommunityTipsSheet(),
            ),
          ),
          const SizedBox(height: 16),
          _CreateComposerCard(onTap: _navigateToCreatePost),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            _FeedErrorBanner(
              message: _errorMessage!,
              onRetry: () => _refreshPosts(),
            ),
          ],
          const SizedBox(height: 12),
          if (_posts.isEmpty)
            _FeedEmptyState(onCreateTap: _navigateToCreatePost)
          else
            ..._posts.map(
              (post) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PostCard(
                  post: post,
                  onLikeToggle: () => _toggleLike(post),
                  onDelete: () => _deletePost(post),
                  onCommentTap: () => _openDetail(post),
                  onTap: () => _openDetail(post),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeedLoadingPlaceholder extends StatelessWidget {
  const _FeedLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: 4,
      itemBuilder: (_, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 12,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 10,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 12,
                width: MediaQuery.of(context).size.width * 0.6,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CommunityHeroCard extends StatelessWidget {
  const _CommunityHeroCard({
    required this.postCount,
    required this.onCreateTap,
  });

  final int postCount;
  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.indigo.shade400],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100,
            offset: const Offset(0, 12),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Komunitas Stroke',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            postCount == 0
                ? 'Belum ada diskusi hari ini. Mulai percakapanmu.'
                : '$postCount diskusi hangat hari ini.',
            style: TextStyle(color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onCreateTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            icon: const Icon(Icons.edit_rounded),
            label: const Text(
              'Bagikan Pengalaman',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({
    required this.onCreateTap,
    required this.onRefreshTap,
    required this.onTipsTap,
  });

  final VoidCallback onCreateTap;
  final VoidCallback? onRefreshTap;
  final VoidCallback onTipsTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 20) / 3;
        final actions = [
          _QuickActionButton(
            label: 'Posting cepat',
            icon: Icons.add_comment_outlined,
            color: Colors.blue.shade600,
            onTap: onCreateTap,
          ),
          _QuickActionButton(
            label: 'Segarkan',
            icon: Icons.autorenew_rounded,
            color: Colors.teal.shade600,
            onTap: onRefreshTap,
          ),
          _QuickActionButton(
            label: 'Tips',
            icon: Icons.lightbulb_outline,
            color: Colors.orange.shade700,
            onTap: onTipsTap,
          ),
        ];

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: actions
              .map((action) => SizedBox(width: itemWidth, child: action))
              .toList(),
        );
      },
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.18)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateComposerCard extends StatelessWidget {
  const _CreateComposerCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                foregroundColor: Colors.blue.shade700,
                child: const Icon(Icons.person_outline),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Bagikan kabar, pertanyaan, atau tips pemulihan...',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.photo_library_outlined, color: Colors.green.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedErrorBanner extends StatelessWidget {
  const _FeedErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.red)),
          ),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}

class _FeedEmptyState extends StatelessWidget {
  const _FeedEmptyState({required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.forum_outlined, size: 48, color: Colors.blueGrey.shade300),
          const SizedBox(height: 12),
          const Text(
            'Belum ada postingan hari ini',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bagikan pengalamanmu dan mulai diskusi positif dengan penyintas lain.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onCreateTap,
            child: const Text('Tulis Postingan'),
          ),
        ],
      ),
    );
  }
}

class _CommunityTipsSheet extends StatelessWidget {
  const _CommunityTipsSheet();

  @override
  Widget build(BuildContext context) {
    final tips = [
      'Gunakan nada positif dan sopan agar diskusi nyaman.',
      'Bagikan pengalaman nyata untuk membantu penyintas lain.',
      'Gunakan tag #tips, #pertanyaan, atau #motivation agar mudah ditemukan.',
      'Laporkan konten yang tidak pantas kepada moderator.',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const Text(
            'Etika Komunitas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...tips.map(
            (tip) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.check_circle_outline,
                color: Colors.blue.shade600,
              ),
              title: Text(tip),
            ),
          ),
        ],
      ),
    );
  }
}

