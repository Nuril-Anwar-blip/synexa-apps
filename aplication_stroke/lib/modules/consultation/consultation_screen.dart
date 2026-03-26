import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/remote/socket_service.dart';
import '../../services/remote/backend_api_service.dart';

bool _isImageUrl(String url) {
  final lower = url.toLowerCase();
  return lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.webp') ||
      lower.contains('image');
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.createdAt,
    this.metadata,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    // Schema doesn't have metadata, so we handle it optionally
    final dynamic rawMetadata = map['metadata'];
    return ChatMessage(
      id: map['id'].toString(),
      content: map['content'] ?? '',
      senderId: map['sender_id']?.toString() ?? '',
      createdAt: DateTime.parse(map['created_at']),
      metadata: rawMetadata is Map
          ? Map<String, dynamic>.from(rawMetadata)
          : null,
    );
  }

  final String id;
  final String content;
  final String senderId;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;
}

/// Halaman Konsultasi
///
/// Halaman ini memungkinkan pengguna untuk berkonsultasi dengan profesional kesehatan.
/// Pengguna dapat mengirim pesan dan mendapatkan jawaban dari dokter.
class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({
    super.key,
    required this.roomId,
    required this.recipientId,
    required this.recipientName,
  });

  final String roomId;
  final String recipientId;
  final String recipientName;

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final ValueNotifier<bool> _isSending = ValueNotifier<bool>(false);

  late final SupabaseClient _supabase;
  final BackendApiService _apiService = BackendApiService.instance;
  final SocketService _socketService = SocketService.instance;

  List<ChatMessage> _messages = [];
  String? _currentUserId;
  String? _recipientPhone;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _currentUserId = _supabase.auth.currentUser?.id;
    _loadMessages();
    _setupSocketListener();
    // Ambil nomor telepon penerima untuk fitur panggilan
    _loadRecipientPhone();

    // Join Socket.io room untuk real-time chat
    _socketService.joinChatRoom(widget.roomId);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _isSending.dispose();
    _socketService.offReceiveMessage();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final data = await _apiService.getMessages(widget.roomId);
      setState(() {
        _messages = data.map((row) => ChatMessage.fromMap(row)).toList();
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat pesan: $e')));
      }
    }
  }

  void _setupSocketListener() {
    _socketService.onReceiveMessage((data) {
      final newMessage = ChatMessage.fromMap(data);
      setState(() {
        _messages.add(newMessage);
      });
      _scrollToBottom();
    });
  }

  Future<void> _sendMessage() async {
    final content = _textController.text.trim();
    if (content.isEmpty || _currentUserId == null) return;

    _isSending.value = true;
    try {
      await _apiService.sendMessage(roomId: widget.roomId, content: content);
      _textController.clear();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim pesan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _isSending.value = false;
    }
  }

  // Ambil nomor telepon penerima dari tabel users
  Future<void> _loadRecipientPhone() async {
    try {
      final row = await _supabase
          .from('users')
          .select('phone_number')
          .eq('id', widget.recipientId)
          .maybeSingle();
      if (row != null) {
        setState(() => _recipientPhone = row['phone_number']?.toString());
      }
    } catch (_) {}
  }

  // Kirim lampiran gambar: unggah ke Storage dan simpan URL pada metadata pesan
  Future<void> _pickAndSendPhoto() async {
    if (_currentUserId == null) return;
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;

      _isSending.value = true;
      final file = File(picked.path);
      // Gunakan bucket khusus chat: 'chat_attachments'
      final bucket = 'chat_attachments';
      final objectPath =
          '${_currentUserId}/${DateTime.now().millisecondsSinceEpoch}_${picked.name}';

      await _supabase.storage.from(bucket).upload(objectPath, file);
      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(objectPath);

      try {
        await _apiService.sendMessage(roomId: widget.roomId, content: '');
        // Note: Backend doesn't support metadata yet, so we'll send URL as content
        await _apiService.sendMessage(
          roomId: widget.roomId,
          content: publicUrl,
        );
      } catch (_) {
        // Fallback: send URL as content
        await _apiService.sendMessage(
          roomId: widget.roomId,
          content: publicUrl,
        );
      }
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim foto: $e')));
    } finally {
      _isSending.value = false;
    }
  }

  // Kirim lampiran dokumen umum
  Future<void> _pickAndSendFile() async {
    if (_currentUserId == null) return;
    try {
      final result = await FilePicker.platform.pickFiles(withReadStream: false);
      if (result == null || result.files.isEmpty) return;
      final f = result.files.first;
      if (f.path == null) return;

      _isSending.value = true;
      final file = File(f.path!);
      final ext = (f.extension ?? 'bin').toLowerCase();
      // Gunakan bucket khusus chat: 'chat_attachments'
      final bucket = 'chat_attachments';
      final objectPath =
          '${_currentUserId}/${DateTime.now().millisecondsSinceEpoch}_${f.name}';

      await _supabase.storage.from(bucket).upload(objectPath, file);
      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(objectPath);

      try {
        // Note: Backend doesn't support metadata yet, so we'll send URL as content
        await _apiService.sendMessage(
          roomId: widget.roomId,
          content: '${f.name} | ${publicUrl}',
        );
      } catch (_) {
        // Fallback: send name + URL as content
        await _apiService.sendMessage(
          roomId: widget.roomId,
          content: '${f.name} | ${publicUrl}',
        );
      }
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim dokumen: $e')));
    } finally {
      _isSending.value = false;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipientName),
        backgroundColor: isDark ? const Color(0xFF1E2A3A) : Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          if (_recipientPhone != null && _recipientPhone!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.phone),
              onPressed: () async {
                final url = 'tel:$_recipientPhone';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada pesan',
                          style: TextStyle(
                            fontSize: 18,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mulai percakapan dengan ${widget.recipientName}',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message.senderId == _currentUserId;
                      return _MessageBubble(
                        message: message,
                        isMe: isMe,
                        isDark: isDark,
                      );
                    },
                  ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _pickAndSendPhoto,
                  color: Colors.teal,
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _pickAndSendFile,
                  color: Colors.teal,
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Ketik pesan...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<bool>(
                  valueListenable: _isSending,
                  builder: (context, isSending, _) {
                    return IconButton(
                      icon: isSending
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      onPressed: isSending ? null : _sendMessage,
                      color: Colors.teal,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool isDark;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.teal
              : (isDark ? const Color(0xFF2A3A4A) : Colors.grey[200]),
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.metadata != null &&
                message.metadata!['type'] == 'image')
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message.metadata!['url'],
                  width: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 200,
                      height: 150,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image),
                    );
                  },
                ),
              )
            else if (message.metadata != null &&
                message.metadata!['type'] == 'file')
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isMe ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.insert_drive_file, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        message.metadata!['name'] ?? 'File',
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                message.content,
                style: TextStyle(color: isMe ? Colors.white : Colors.black87),
              ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
