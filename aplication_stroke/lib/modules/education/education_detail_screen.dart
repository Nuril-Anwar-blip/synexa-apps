import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../models/education_model.dart';

class EducationDetailScreen extends StatefulWidget {
  const EducationDetailScreen({super.key, required this.content});

  final EducationContent content;

  @override
  State<EducationDetailScreen> createState() => _EducationDetailScreenState();
}

class _EducationDetailScreenState extends State<EducationDetailScreen> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _incrementView();
    if (widget.content.isVideo && widget.content.videoUrl != null) {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.content.videoUrl!),
      )..initialize().then((_) {
          if (mounted) setState(() {});
        });
    }
  }

  Future<void> _incrementView() async {
    try {
      await Supabase.instance.client
          .from('education_contents')
          .update({'view_count': widget.content.viewCount + 1})
          .eq('id', widget.content.id);
    } catch (_) {}
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.content;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(c.title, maxLines: 1)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (c.thumbnailUrl != null && c.thumbnailUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  c.thumbnailUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            if (c.isVideo && _videoController != null) ...[
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: _videoController!.value.isInitialized
                    ? _videoController!.value.aspectRatio
                    : 16 / 9,
                child: _videoController!.value.isInitialized
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          VideoPlayer(_videoController!),
                          IconButton(
                            icon: Icon(
                              _videoController!.value.isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              size: 56,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _videoController!.value.isPlaying
                                    ? _videoController!.pause()
                                    : _videoController!.play();
                              });
                            },
                          ),
                        ],
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            ],
            const SizedBox(height: 16),
            if (c.category != null)
              Chip(
                label: Text(c.category!),
                backgroundColor: Colors.red.withOpacity(0.1),
              ),
            const SizedBox(height: 8),
            Text(
              c.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            if (c.summary != null && c.summary!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                c.summary!,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              c.content,
              style: TextStyle(
                fontSize: 15,
                height: 1.7,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            if (c.source != null && c.source!.isNotEmpty) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.tryParse(c.source!);
                  if (uri != null) await launchUrl(uri);
                },
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Sumber'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
