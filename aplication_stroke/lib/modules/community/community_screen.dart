// /// ====================================================================
// /// File: community_screen.dart
// /// --------------------------------------------------------------------
// /// Layar Komunitas/Forum
// /// 
// /// Dokumen ini berisi halaman komunitas untuk berinteraksi dengan
// /// pengguna lain. Pengguna dapat melihat dan membuat post.
// /// 
// /// Fitur:
// /// - Daftar post dari komunitas
// /// - Pull-to-refresh untuk memperbarui data
// /// - Tombol buat post baru (FAB)
// /// - Filter/tabs untuk kategori post
// /// - Like dan comment pada post
// /// 
// /// Author: Tim Developer Synexa
// /// ====================================================================

// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../../../../models/post_model.dart';
// import 'create_post_screen.dart';
// import 'post_detail_screen.dart';
// import 'widgets/post_card.dart';
// import '../../../widgets/quick_settings_sheet.dart';

// /// Halaman Komunitas
// ///
// /// Halaman ini memungkinkan pengguna untuk berinteraksi dengan komunitas.
// /// Pengguna dapat membuat postingan, melihat postingan lain, dan berkomentar.
// class CommunityScreen extends StatefulWidget {
//   const CommunityScreen({super.key});

//   @override
//   State<CommunityScreen> createState() => _CommunityScreenState();
// }

// class _CommunityScreenState extends State<CommunityScreen> {
//   final _supabase = Supabase.instance.client;
//   final List<Post> _posts = [];

//   bool _isLoading = true;
//   bool _isRefreshing = false;
//   String? _errorMessage;

//   RealtimeChannel? _postsChannel;
//   Timer? _realtimeDebounce;

//   @override
//   void initState() {
//     super.initState();
//     _loadInitialFeed();
//     _setupRealtimeListener();
//   }

//   /// Memuat feed awal saat halaman dibuka.
//   Future<void> _loadInitialFeed() async {
//     await _refreshPosts(showFullLoader: true);
//   }

//   /// Mengambil daftar postingan dari database Supabase.
//   /// Memanggil RPC 'get_posts_with_details'.
//   Future<List<Post>> _getPosts() async {
//     final user = _supabase.auth.currentUser;
//     final userId = user?.id;

//     // Schema mapping: image_url, users join, and counts
//     final response = await _supabase
//         .from('posts')
//         .select('''
//           *,
//           users!inner(full_name, photo_url),
//           likes(count),
//           comments(count)
//         ''')
//         .order('created_at', ascending: false);

//     final List<Post> posts = [];
//     for (var data in (response as List)) {
//       final postData = Map<String, dynamic>.from(data);
//       final postId = postData['id'];

//       // Fetch if user liked this post
//       bool hasLiked = false;
//       if (userId != null) {
//         final likeCheck = await _supabase
//             .from('likes')
//             .select('id')
//             .eq('post_id', postId)
//             .eq('user_id', userId)
//             .maybeSingle();
//         hasLiked = likeCheck != null;
//       }

//       // Map counts from the select (Note: Supabase count() return structure)
//       final likesCount = postData['likes']?[0]?['count'] ?? 0;
//       final commentsCount = postData['comments']?[0]?['count'] ?? 0;

//       postData['media_url'] = postData['image_url'];
//       postData['like_count'] = likesCount;
//       postData['comment_count'] = commentsCount;
//       postData['user_has_liked'] = hasLiked;

//       posts.add(Post.fromMap(postData));
//     }
//     return posts;
//   }

//   /// Menyiapkan listener real-time untuk pembaruan postingan, like, dan komentar.
//   void _setupRealtimeListener() {
//     _postsChannel = _supabase.channel('community_feed_channel')
//       ..onPostgresChanges(
//         event: PostgresChangeEvent.all,
//         schema: 'public',
//         table: 'posts',
//         callback: (_) => _scheduleRealtimeRefresh(),
//       )
//       ..onPostgresChanges(
//         event: PostgresChangeEvent.all,
//         schema: 'public',
//         table: 'likes',
//         callback: (_) => _scheduleRealtimeRefresh(),
//       )
//       ..onPostgresChanges(
//         event: PostgresChangeEvent.all,
//         schema: 'public',
//         table: 'comments',
//         callback: (_) => _scheduleRealtimeRefresh(),
//       )
//       ..subscribe();
//   }

//   /// Menjadwalkan refresh feed dengan debounce untuk menghindari reload berlebihan.
//   void _scheduleRealtimeRefresh() {
//     _realtimeDebounce?.cancel();
//     _realtimeDebounce = Timer(const Duration(milliseconds: 350), () {
//       if (!mounted) return;
//       _refreshPosts();
//     });
//   }

//   /// Menyegarkan daftar postingan di UI.
//   /// [showFullLoader] menentukan apakah menampilkan loading screen penuh atau tidak.
//   Future<void> _refreshPosts({bool showFullLoader = false}) async {
//     if (showFullLoader) {
//       setState(() {
//         _isLoading = true;
//         _errorMessage = null;
//       });
//     } else {
//       setState(() => _isRefreshing = true);
//     }

//     try {
//       final posts = await _getPosts();
//       if (!mounted) return;
//       setState(() {
//         _posts
//           ..clear()
//           ..addAll(posts);
//         _errorMessage = null;
//       });
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _errorMessage =
//             'Tidak dapat memuat postingan. Tarik ke bawah untuk refresh.';
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Gagal memuat postingan: $e'),
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     } finally {
//       if (!mounted) return;
//       setState(() {
//         _isLoading = false;
//         _isRefreshing = false;
//       });
//     }
//   }

//   /// Mengelola aksi like/unlike pada postingan.
//   /// Memperbarui UI secara optimistik sebelum request ke server.
//   Future<void> _toggleLike(Post post) async {
//     final user = _supabase.auth.currentUser;
//     if (user == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Silakan login terlebih dahulu.')),
//       );
//       return;
//     }

//     final isCurrentlyLiked = post.userHasLiked;
//     final delta = isCurrentlyLiked ? -1 : 1;

//     _updatePost(post.id, (current) {
//       final nextCount = (current.likeCount + delta).clamp(0, 1 << 30);
//       return current.copyWith(
//         userHasLiked: !isCurrentlyLiked,
//         likeCount: nextCount,
//       );
//     });

//     try {
//       if (isCurrentlyLiked) {
//         await _supabase.from('likes').delete().match({
//           'post_id': post.id,
//           'user_id': user.id,
//         });
//       } else {
//         await _supabase.from('likes').insert({
//           'post_id': post.id,
//           'user_id': user.id,
//         });
//       }
//     } catch (e) {
//       _updatePost(post.id, (_) => post);
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Gagal memperbarui suka: $e')));
//     }
//   }

//   /// Menghapus postingan beserta file media jika ada.
//   Future<void> _deletePost(Post post) async {
//     try {
//       if (post.media_url != null && post.media_url!.isNotEmpty) {
//         final uri = Uri.parse(post.media_url!);
//         final segments = uri.pathSegments;
//         final publicIndex = segments.indexOf('public');
//         if (publicIndex != -1 && publicIndex + 2 <= segments.length) {
//           final bucketId = segments[publicIndex + 1];
//           final filePath = segments.sublist(publicIndex + 2).join('/');
//           await _supabase.storage.from(bucketId).remove([filePath]);
//         }
//       }

//       await _supabase.from('posts').delete().eq('id', post.id);
//       if (!mounted) return;
//       setState(() {
//         _posts.removeWhere((item) => item.id == post.id);
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Postingan berhasil dihapus')),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Gagal menghapus postingan: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   Future<void> _navigateToCreatePost() async {
//     final created = await Navigator.push<bool>(
//       context,
//       MaterialPageRoute(builder: (_) => const CreatePostScreen()),
//     );
//     if (created == true) {
//       await _refreshPosts();
//     }
//   }

//   Future<void> _openDetail(Post post) async {
//     await Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
//     );
//     if (mounted) {
//       _refreshPosts();
//     }
//   }

//   void _updatePost(String postId, Post Function(Post current) updater) {
//     final index = _posts.indexWhere((item) => item.id == postId);
//     if (index == -1) return;
//     setState(() {
//       _posts[index] = updater(_posts[index]);
//     });
//   }

//   @override
//   void dispose() {
//     _realtimeDebounce?.cancel();
//     if (_postsChannel != null) {
//       _supabase.removeChannel(_postsChannel!);
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Komunitas'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.tune_rounded),
//             tooltip: 'Quick Settings',
//             onPressed: () => QuickSettingsSheet.show(context),
//           ),
//           if (_isRefreshing)
//             const Padding(
//               padding: EdgeInsets.only(right: 12),
//               child: SizedBox(
//                 width: 18,
//                 height: 18,
//                 child: CircularProgressIndicator(strokeWidth: 2),
//               ),
//             ),
//           IconButton(
//             tooltip: 'Segarkan',
//             icon: const Icon(Icons.refresh_rounded),
//             onPressed: _isRefreshing ? null : () => _refreshPosts(),
//           ),
//         ],
//       ),
//       floatingActionButton: Padding(
//         padding: EdgeInsets.only(
//           bottom: MediaQuery.of(context).padding.bottom + 74,
//         ),
//         child: FloatingActionButton.extended(
//           onPressed: _navigateToCreatePost,
//           icon: const Icon(Icons.edit_rounded),
//           label: const Text('Bagikan'),
//         ),
//       ),
//       body: AnimatedSwitcher(
//         duration: const Duration(milliseconds: 250),
//         child: _isLoading
//             ? const _FeedLoadingPlaceholder()
//             : _buildFeedContent(),
//       ),
//     );
//   }

//   Widget _buildFeedContent() {
//     return RefreshIndicator(
//       onRefresh: () => _refreshPosts(),
//       child: ListView(
//         physics: const AlwaysScrollableScrollPhysics(),
//         padding: EdgeInsets.fromLTRB(
//           16,
//           12,
//           16,
//           MediaQuery.of(context).padding.bottom + 80,
//         ),
//         children: [
//           _CommunityHeroCard(
//             postCount: _posts.length,
//             onCreateTap: _navigateToCreatePost,
//           ),
//           const SizedBox(height: 16),
//           _QuickActionRow(
//             onCreateTap: _navigateToCreatePost,
//             onRefreshTap: _isRefreshing ? null : () => _refreshPosts(),
//             onTipsTap: () => showModalBottomSheet(
//               context: context,
//               shape: const RoundedRectangleBorder(
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//               ),
//               builder: (_) => const _CommunityTipsSheet(),
//             ),
//           ),
//           const SizedBox(height: 16),
//           _CreateComposerCard(onTap: _navigateToCreatePost),
//           if (_errorMessage != null) ...[
//             const SizedBox(height: 12),
//             _FeedErrorBanner(
//               message: _errorMessage!,
//               onRetry: () => _refreshPosts(),
//             ),
//           ],
//           const SizedBox(height: 12),
//           if (_posts.isEmpty)
//             _FeedEmptyState(onCreateTap: _navigateToCreatePost)
//           else
//             ..._posts.map(
//               (post) => Padding(
//                 padding: const EdgeInsets.only(bottom: 12),
//                 child: PostCard(
//                   post: post,
//                   onLikeToggle: () => _toggleLike(post),
//                   onDelete: () => _deletePost(post),
//                   onCommentTap: () => _openDetail(post),
//                   onTap: () => _openDetail(post),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// class _FeedLoadingPlaceholder extends StatelessWidget {
//   const _FeedLoadingPlaceholder();

//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       physics: const NeverScrollableScrollPhysics(),
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
//       itemCount: 4,
//       itemBuilder: (_, index) {
//         return Container(
//           margin: const EdgeInsets.only(bottom: 16),
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Container(
//                     width: 42,
//                     height: 42,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[300],
//                       shape: BoxShape.circle,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Container(
//                           height: 12,
//                           width: 120,
//                           decoration: BoxDecoration(
//                             color: Colors.grey[300],
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Container(
//                           height: 10,
//                           width: 80,
//                           decoration: BoxDecoration(
//                             color: Colors.grey[300],
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               Container(
//                 height: 12,
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   color: Colors.grey[300],
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Container(
//                 height: 12,
//                 width: MediaQuery.of(context).size.width * 0.6,
//                 decoration: BoxDecoration(
//                   color: Colors.grey[300],
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Container(
//                 height: 150,
//                 decoration: BoxDecoration(
//                   color: Colors.grey[200],
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// class _CommunityHeroCard extends StatelessWidget {
//   const _CommunityHeroCard({
//     required this.postCount,
//     required this.onCreateTap,
//   });

//   final int postCount;
//   final VoidCallback onCreateTap;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(24),
//         gradient: LinearGradient(
//           colors: [Colors.blue.shade600, Colors.indigo.shade400],
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.blue.shade100,
//             offset: const Offset(0, 12),
//             blurRadius: 24,
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Komunitas Stroke',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             postCount == 0
//                 ? 'Belum ada diskusi hari ini. Mulai percakapanmu.'
//                 : '$postCount diskusi hangat hari ini.',
//             style: TextStyle(color: Colors.white.withOpacity(0.9)),
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton.icon(
//             onPressed: onCreateTap,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.white,
//               foregroundColor: Colors.blue.shade700,
//               padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(26),
//               ),
//             ),
//             icon: const Icon(Icons.edit_rounded),
//             label: const Text(
//               'Bagikan Pengalaman',
//               style: TextStyle(fontWeight: FontWeight.w700),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _QuickActionRow extends StatelessWidget {
//   const _QuickActionRow({
//     required this.onCreateTap,
//     required this.onRefreshTap,
//     required this.onTipsTap,
//   });

//   final VoidCallback onCreateTap;
//   final VoidCallback? onRefreshTap;
//   final VoidCallback onTipsTap;

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final itemWidth = (constraints.maxWidth - 20) / 3;
//         final actions = [
//           _QuickActionButton(
//             label: 'Posting cepat',
//             icon: Icons.add_comment_outlined,
//             color: Colors.blue.shade600,
//             onTap: onCreateTap,
//           ),
//           _QuickActionButton(
//             label: 'Segarkan',
//             icon: Icons.autorenew_rounded,
//             color: Colors.teal.shade600,
//             onTap: onRefreshTap,
//           ),
//           _QuickActionButton(
//             label: 'Tips',
//             icon: Icons.lightbulb_outline,
//             color: Colors.orange.shade700,
//             onTap: onTipsTap,
//           ),
//         ];

//         return Wrap(
//           spacing: 10,
//           runSpacing: 10,
//           children: actions
//               .map((action) => SizedBox(width: itemWidth, child: action))
//               .toList(),
//         );
//       },
//     );
//   }
// }

// class _QuickActionButton extends StatelessWidget {
//   const _QuickActionButton({
//     required this.label,
//     required this.icon,
//     required this.color,
//     this.onTap,
//   });

//   final String label;
//   final IconData icon;
//   final Color color;
//   final VoidCallback? onTap;

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(14),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(14),
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(14),
//             border: Border.all(color: color.withOpacity(0.18)),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(icon, color: color),
//               const SizedBox(width: 8),
//               Flexible(
//                 child: Text(
//                   label,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(color: color, fontWeight: FontWeight.w700),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _CreateComposerCard extends StatelessWidget {
//   const _CreateComposerCard({required this.onTap});

//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 0,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(18),
//         onTap: onTap,
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Row(
//             children: [
//               CircleAvatar(
//                 backgroundColor: Colors.blue.shade100,
//                 foregroundColor: Colors.blue.shade700,
//                 child: const Icon(Icons.person_outline),
//               ),
//               const SizedBox(width: 12),
//               const Expanded(
//                 child: Text(
//                   'Bagikan kabar, pertanyaan, atau tips pemulihan...',
//                   style: TextStyle(color: Colors.black54),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Icon(Icons.photo_library_outlined, color: Colors.green.shade400),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _FeedErrorBanner extends StatelessWidget {
//   const _FeedErrorBanner({required this.message, required this.onRetry});

//   final String message;
//   final VoidCallback onRetry;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.red.shade50,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.error_outline, color: Colors.red),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(message, style: const TextStyle(color: Colors.red)),
//           ),
//           TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
//         ],
//       ),
//     );
//   }
// }

// class _FeedEmptyState extends StatelessWidget {
//   const _FeedEmptyState({required this.onCreateTap});

//   final VoidCallback onCreateTap;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Column(
//         children: [
//           Icon(Icons.forum_outlined, size: 48, color: Colors.blueGrey.shade300),
//           const SizedBox(height: 12),
//           const Text(
//             'Belum ada postingan hari ini',
//             style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
//           ),
//           const SizedBox(height: 6),
//           const Text(
//             'Bagikan pengalamanmu dan mulai diskusi positif dengan penyintas lain.',
//             textAlign: TextAlign.center,
//             style: TextStyle(color: Colors.black54),
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: onCreateTap,
//             child: const Text('Tulis Postingan'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _CommunityTipsSheet extends StatelessWidget {
//   const _CommunityTipsSheet();

//   @override
//   Widget build(BuildContext context) {
//     final tips = [
//       'Gunakan nada positif dan sopan agar diskusi nyaman.',
//       'Bagikan pengalaman nyata untuk membantu penyintas lain.',
//       'Gunakan tag #tips, #pertanyaan, atau #motivation agar mudah ditemukan.',
//       'Laporkan konten yang tidak pantas kepada moderator.',
//     ];

//     return Padding(
//       padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 40,
//             height: 4,
//             margin: const EdgeInsets.only(bottom: 16),
//             decoration: BoxDecoration(
//               color: Colors.grey[300],
//               borderRadius: BorderRadius.circular(100),
//             ),
//           ),
//           const Text(
//             'Etika Komunitas',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
//           ),
//           const SizedBox(height: 12),
//           ...tips.map(
//             (tip) => ListTile(
//               contentPadding: EdgeInsets.zero,
//               leading: Icon(
//                 Icons.check_circle_outline,
//                 color: Colors.blue.shade600,
//               ),
//               title: Text(tip),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// ====================================================================
// File: community_screen.dart — Full Redesign v3
// ✅ ThemeProvider + LanguageProvider di semua widget
// ✅ Modern card design dengan gradient & animations
// ✅ Story-like quick post row, trending topics
// ====================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../models/post_model.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../widgets/quick_settings_sheet.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';
import 'widgets/post_card.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final List<Post> _posts = [];

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  RealtimeChannel? _postsChannel;
  Timer? _realtimeDebounce;

  late AnimationController _headerAnim;
  late Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _headerFade = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _loadInitialFeed();
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    _realtimeDebounce?.cancel();
    if (_postsChannel != null) _supabase.removeChannel(_postsChannel!);
    super.dispose();
  }

  Future<void> _loadInitialFeed() async => await _refreshPosts(showFullLoader: true);

  Future<List<Post>> _getPosts() async {
    final user = _supabase.auth.currentUser;
    final userId = user?.id;
    final response = await _supabase.from('posts').select('''
      *, users!inner(full_name, photo_url), likes(count), comments(count)
    ''').order('created_at', ascending: false);

    final List<Post> posts = [];
    for (var data in (response as List)) {
      final postData = Map<String, dynamic>.from(data);
      final postId = postData['id'];
      bool hasLiked = false;
      if (userId != null) {
        final likeCheck = await _supabase.from('likes').select('id').eq('post_id', postId).eq('user_id', userId).maybeSingle();
        hasLiked = likeCheck != null;
      }
      postData['media_url'] = postData['image_url'];
      postData['like_count'] = postData['likes']?[0]?['count'] ?? 0;
      postData['comment_count'] = postData['comments']?[0]?['count'] ?? 0;
      postData['user_has_liked'] = hasLiked;
      posts.add(Post.fromMap(postData));
    }
    return posts;
  }

  void _setupRealtimeListener() {
    _postsChannel = _supabase.channel('community_feed_channel')
      ..onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'posts', callback: (_) => _scheduleRealtimeRefresh())
      ..onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'likes', callback: (_) => _scheduleRealtimeRefresh())
      ..onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'comments', callback: (_) => _scheduleRealtimeRefresh())
      ..subscribe();
  }

  void _scheduleRealtimeRefresh() {
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(const Duration(milliseconds: 350), () { if (!mounted) return; _refreshPosts(); });
  }

  Future<void> _refreshPosts({bool showFullLoader = false}) async {
    if (showFullLoader) setState(() { _isLoading = true; _errorMessage = null; });
    else setState(() => _isRefreshing = true);
    try {
      final posts = await _getPosts();
      if (!mounted) return;
      setState(() { _posts..clear()..addAll(posts); _errorMessage = null; });
      _headerAnim.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() { _errorMessage = 'Tidak dapat memuat postingan.'; });
    } finally {
      if (!mounted) return;
      setState(() { _isLoading = false; _isRefreshing = false; });
    }
  }

  Future<void> _toggleLike(Post post) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    final isLiked = post.userHasLiked;
    _updatePost(post.id, (cur) => cur.copyWith(userHasLiked: !isLiked, likeCount: (cur.likeCount + (isLiked ? -1 : 1)).clamp(0, 1 << 30)));
    try {
      if (isLiked) await _supabase.from('likes').delete().match({'post_id': post.id, 'user_id': user.id});
      else await _supabase.from('likes').insert({'post_id': post.id, 'user_id': user.id});
    } catch (e) {
      _updatePost(post.id, (_) => post);
    }
  }

  Future<void> _deletePost(Post post) async {
    try {
      if (post.media_url != null && post.media_url!.isNotEmpty) {
        final uri = Uri.parse(post.media_url!);
        final segments = uri.pathSegments;
        final publicIndex = segments.indexOf('public');
        if (publicIndex != -1 && publicIndex + 2 <= segments.length) {
          await _supabase.storage.from(segments[publicIndex + 1]).remove([segments.sublist(publicIndex + 2).join('/')]);
        }
      }
      await _supabase.from('posts').delete().eq('id', post.id);
      if (!mounted) return;
      setState(() { _posts.removeWhere((item) => item.id == post.id); });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red));
    }
  }

  void _updatePost(String postId, Post Function(Post) updater) {
    final index = _posts.indexWhere((item) => item.id == postId);
    if (index == -1) return;
    setState(() { _posts[index] = updater(_posts[index]); });
  }

  Future<void> _navigateToCreatePost() async {
    final created = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const CreatePostScreen()));
    if (created == true) await _refreshPosts();
  }

  Future<void> _openDetail(Post post) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)));
    if (mounted) _refreshPosts();
  }

  @override
  Widget build(BuildContext context) {
    final themeP = context.watch<ThemeProvider>();
    final lang = context.watch<LanguageProvider>();
    final isDark = themeP.isDarkMode;
    final fs = themeP.fontSize;
    String t(Map<String, String> m) => lang.translate(m);

    final bg = isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF4F7FF);

    return Scaffold(
      backgroundColor: bg,
      body: Column(children: [
        // ── Header ──────────────────────────────────────────────────────
        _CommunityHeader(
          isDark: isDark, fs: fs, t: t,
          postCount: _posts.length,
          isRefreshing: _isRefreshing,
          onSettings: () => QuickSettingsSheet.show(context),
          onRefresh: () => _refreshPosts(),
          onCreatePost: _navigateToCreatePost,
        ),

        // ── Feed ────────────────────────────────────────────────────────
        Expanded(child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isLoading
            ? _FeedSkeleton(isDark: isDark)
            : RefreshIndicator(
                onRefresh: () => _refreshPosts(),
                color: Colors.blue.shade600,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 80),
                  children: [
                    // Compose bar
                    _ComposeBar(isDark: isDark, fs: fs, t: t, onTap: _navigateToCreatePost),
                    const SizedBox(height: 16),

                    // Quick topics
                    _TopicChips(isDark: isDark, fs: fs, t: t, onTap: _navigateToCreatePost),
                    const SizedBox(height: 16),

                    if (_errorMessage != null) _ErrorCard(message: _errorMessage!, onRetry: () => _refreshPosts(), isDark: isDark, fs: fs),
                    if (_posts.isEmpty)
                      _EmptyFeed(isDark: isDark, fs: fs, t: t, onTap: _navigateToCreatePost)
                    else ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(children: [
                          Container(width: 4, height: 14, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue.shade600, Colors.purple.shade400]), borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 8),
                          Text(t({'id': 'Diskusi Terbaru', 'en': 'Recent Discussions', 'ms': 'Perbincangan Terkini'}),
                            style: TextStyle(fontSize: 15 * fs, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
                          const Spacer(),
                          Text('${_posts.length} ${t({'id': 'postingan', 'en': 'posts', 'ms': 'catatan'})}',
                            style: TextStyle(fontSize: 12 * fs, color: Colors.grey.shade500)),
                        ]),
                      ),
                      ..._posts.map((post) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PostCard(
                          post: post,
                          onLikeToggle: () => _toggleLike(post),
                          onDelete: () => _deletePost(post),
                          onCommentTap: () => _openDetail(post),
                          onTap: () => _openDetail(post),
                        ),
                      )),
                    ],
                  ],
                ),
              ),
        )),
      ]),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 74),
        child: _ComposeFAB(isDark: isDark, fs: fs, t: t, onTap: _navigateToCreatePost),
      ),
    );
  }
}

// ── Community Header ──────────────────────────────────────────────────────────
class _CommunityHeader extends StatelessWidget {
  const _CommunityHeader({required this.isDark, required this.fs, required this.t, required this.postCount, required this.isRefreshing, required this.onSettings, required this.onRefresh, required this.onCreatePost});
  final bool isDark, isRefreshing;
  final double fs;
  final String Function(Map<String, String>) t;
  final int postCount;
  final VoidCallback onSettings, onRefresh, onCreatePost;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [const Color(0xFF1A237E).withOpacity(0.8), const Color(0xFF0A0F1E)] : [Colors.blue.shade700, Colors.indigo.shade500],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 16, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t({'id': 'Komunitas', 'en': 'Community', 'ms': 'Komuniti'}),
                style: TextStyle(color: Colors.white, fontSize: 24 * fs, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              Text(t({'id': 'Berbagi & saling mendukung', 'en': 'Share & support each other', 'ms': 'Berkongsi & sokong sesama'}),
                style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13 * fs)),
            ])),
            Row(children: [
              if (isRefreshing) Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white.withOpacity(0.7), strokeWidth: 2)),
              ),
              _HBtn(icon: Icons.refresh_rounded, onTap: onRefresh),
              const SizedBox(width: 8),
              _HBtn(icon: Icons.tune_rounded, onTap: onSettings),
            ]),
          ]),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.2))),
            child: Row(children: [
              Expanded(child: Row(children: [
                Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.people_rounded, color: Colors.white, size: 16)),
                const SizedBox(width: 8),
                Text(postCount == 0 ? t({'id': 'Jadilah yang pertama berbagi!', 'en': 'Be the first to share!', 'ms': 'Jadilah yang pertama!'})
                    : t({'id': '$postCount diskusi hari ini', 'en': '$postCount discussions today', 'ms': '$postCount perbincangan hari ini'}),
                  style: TextStyle(color: Colors.white, fontSize: 13 * fs, fontWeight: FontWeight.w600)),
              ])),
              GestureDetector(
                onTap: onCreatePost,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.edit_rounded, size: 14, color: Colors.blue.shade700),
                    const SizedBox(width: 5),
                    Text(t({'id': 'Bagikan', 'en': 'Share', 'ms': 'Kongsi'}), style: TextStyle(fontSize: 12 * fs, fontWeight: FontWeight.w800, color: Colors.blue.shade700)),
                  ]),
                ),
              ),
            ]),
          ),
        ]),
      )),
    );
  }
}

class _HBtn extends StatelessWidget {
  const _HBtn({required this.icon, required this.onTap});
  final IconData icon; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Colors.white, size: 20)));
}

// ── Compose Bar ───────────────────────────────────────────────────────────────
class _ComposeBar extends StatelessWidget {
  const _ComposeBar({required this.isDark, required this.fs, required this.t, required this.onTap});
  final bool isDark; final double fs;
  final String Function(Map<String, String>) t; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        CircleAvatar(radius: 18, backgroundColor: Colors.blue.shade100, child: Icon(Icons.person_rounded, color: Colors.blue.shade600, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade50, borderRadius: BorderRadius.circular(24)),
          child: Text(t({'id': 'Bagikan cerita, tips, atau pertanyaan...', 'en': 'Share a story, tips, or question...', 'ms': 'Kongsi cerita, tip, atau soalan...'}),
            style: TextStyle(fontSize: 13 * fs, color: Colors.grey.shade400)),
        )),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue.shade600, Colors.indigo.shade500]), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 18),
        ),
      ]),
    ),
  );
}

// ── Topic Chips ───────────────────────────────────────────────────────────────
class _TopicChips extends StatelessWidget {
  const _TopicChips({required this.isDark, required this.fs, required this.t, required this.onTap});
  final bool isDark; final double fs;
  final String Function(Map<String, String>) t; final VoidCallback onTap;

  static const _topics = [
    (emoji: '💊', label: 'Tips Obat', color: Color(0xFF7B1FA2)),
    (emoji: '🧠', label: 'Stroke', color: Color(0xFFE53935)),
    (emoji: '🏃', label: 'Latihan', color: Color(0xFF2E7D32)),
    (emoji: '❤️', label: 'Motivasi', color: Color(0xFFE91E63)),
    (emoji: '🍎', label: 'Nutrisi', color: Color(0xFFFF6F00)),
    (emoji: '💬', label: 'Tanya', color: Color(0xFF1565C0)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t({'id': 'Topik Populer', 'en': 'Popular Topics', 'ms': 'Topik Popular'}),
        style: TextStyle(fontSize: 13 * fs, fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
      const SizedBox(height: 8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: _topics.map((topic) => GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: topic.color.withOpacity(isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: topic.color.withOpacity(0.25)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(topic.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Text(topic.label, style: TextStyle(fontSize: 12 * fs, color: topic.color, fontWeight: FontWeight.w700)),
            ]),
          ),
        )).toList()),
      ),
    ]);
  }
}

// ── Compose FAB ───────────────────────────────────────────────────────────────
class _ComposeFAB extends StatelessWidget {
  const _ComposeFAB({required this.isDark, required this.fs, required this.t, required this.onTap});
  final bool isDark; final double fs;
  final String Function(Map<String, String>) t; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade600, Colors.indigo.shade500]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text(t({'id': 'Bagikan', 'en': 'Share', 'ms': 'Kongsi'}), style: TextStyle(color: Colors.white, fontSize: 14 * fs, fontWeight: FontWeight.w800)),
      ]),
    ),
  );
}

// ── Feed Skeleton ─────────────────────────────────────────────────────────────
class _FeedSkeleton extends StatefulWidget {
  const _FeedSkeleton({required this.isDark});
  final bool isDark;
  @override
  State<_FeedSkeleton> createState() => _FeedSkeletonState();
}

class _FeedSkeletonState extends State<_FeedSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true); _anim = Tween<double>(begin: 0.2, end: 0.5).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Widget _block(double w, double h) => AnimatedBuilder(animation: _anim, builder: (_, __) => Container(
    width: w, height: h, margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: (widget.isDark ? Colors.white : Colors.black).withOpacity(_anim.value * 0.15),
      borderRadius: BorderRadius.circular(8),
    ),
  ));

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: 3,
    itemBuilder: (_, __) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF131D2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AnimatedBuilder(animation: _anim, builder: (_, __) => Container(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle, color: (widget.isDark ? Colors.white : Colors.black).withOpacity(_anim.value * 0.15)))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_block(120, 12), _block(80, 10)]),
        ]),
        const SizedBox(height: 12),
        _block(double.infinity, 12),
        _block(double.infinity, 12),
        _block(200, 12),
      ]),
    ),
  );
}

// ── Empty Feed ────────────────────────────────────────────────────────────────
class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({required this.isDark, required this.fs, required this.t, required this.onTap});
  final bool isDark; final double fs;
  final String Function(Map<String, String>) t; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(color: isDark ? const Color(0xFF131D2E) : Colors.white, borderRadius: BorderRadius.circular(24)),
    child: Column(children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue.shade50, Colors.indigo.shade50]), shape: BoxShape.circle),
        child: Icon(Icons.forum_rounded, size: 48, color: Colors.blue.shade600),
      ),
      const SizedBox(height: 20),
      Text(t({'id': 'Belum ada postingan', 'en': 'No posts yet', 'ms': 'Tiada catatan lagi'}),
        style: TextStyle(fontSize: 18 * fs, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
      const SizedBox(height: 8),
      Text(t({'id': 'Jadilah yang pertama berbagi pengalaman dan inspirasi!', 'en': 'Be the first to share your experience!', 'ms': 'Jadilah yang pertama berkongsi!'}),
        textAlign: TextAlign.center, style: TextStyle(fontSize: 13 * fs, color: Colors.grey.shade500, height: 1.5)),
      const SizedBox(height: 24),
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue.shade600, Colors.indigo.shade500]), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 5))]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(t({'id': 'Tulis Postingan', 'en': 'Write a Post', 'ms': 'Tulis Catatan'}), style: TextStyle(color: Colors.white, fontSize: 14 * fs, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    ]),
  );
}

// ── Error Card ────────────────────────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry, required this.isDark, required this.fs});
  final String message; final VoidCallback onRetry; final bool isDark; final double fs;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16)),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, color: Colors.red),
      const SizedBox(width: 10),
      Expanded(child: Text(message, style: TextStyle(color: Colors.red.shade700, fontSize: 13 * fs))),
      TextButton(onPressed: onRetry, child: const Text('Retry')),
    ]),
  );
}