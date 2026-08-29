import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/chat_provider.dart';
import '../../models/user_model.dart';
import '../../models/message_model.dart';
import '../../services/firestore_service.dart';
import '../../services/zego_call_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/chat_utils.dart';
import '../../widgets/media/voice_message_player.dart';
import '../../widgets/media/voice_recorder_widget.dart';
import '../../widgets/media/full_screen_image_viewer.dart';
import '../../widgets/media/video_message_player.dart';

class ChatRoomScreen extends StatefulWidget {
  final UserModel peerUser;

  const ChatRoomScreen({super.key, required this.peerUser});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _firestoreService = FirestoreService();
  final _imagePicker = ImagePicker();

  late final String _chatId;
  late final String _myUid;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _chatId = ChatUtils.getChatId(_myUid, widget.peerUser.uid);

    _textController.addListener(() {
      final hasTextNow = _textController.text.trim().isNotEmpty;
      if (hasTextNow != _hasText) {
        setState(() => _hasText = hasTextNow);
      }
    });

    // 1. Load local SQLite messages first (instant offline render)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.loadLocalMessages(_chatId);
      chatProvider.markChatAsRead(_chatId, _myUid);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    Provider.of<ChatProvider>(context, listen: false).sendTextMessage(
      chatId: _chatId,
      senderId: _myUid,
      receiverId: widget.peerUser.uid,
      text: text,
    );

    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _sendVoiceNote(File audioFile, int durationSeconds) {
    Provider.of<ChatProvider>(context, listen: false).sendMediaMessage(
      chatId: _chatId,
      senderId: _myUid,
      receiverId: widget.peerUser.uid,
      file: audioFile,
      mediaType: AppConstants.typeAudio,
      duration: durationSeconds,
    );

    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (picked != null && mounted) {
        Provider.of<ChatProvider>(context, listen: false).sendMediaMessage(
          chatId: _chatId,
          senderId: _myUid,
          receiverId: widget.peerUser.uid,
          file: File(picked.path),
          mediaType: AppConstants.typeImage,
        );

        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _pickAndSendVideo(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );

      if (picked != null && mounted) {
        Provider.of<ChatProvider>(context, listen: false).sendMediaMessage(
          chatId: _chatId,
          senderId: _myUid,
          receiverId: widget.peerUser.uid,
          file: File(picked.path),
          mediaType: AppConstants.typeVideo,
        );

        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick video: $e')),
        );
      }
    }
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Wrap(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF128C7E),
                  child: Icon(Icons.camera_alt, color: Colors.white),
                ),
                title: const Text('Camera Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF25D366),
                  child: Icon(Icons.photo_library, color: Colors.white),
                ),
                title: const Text('Gallery Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.deepOrange,
                  child: Icon(Icons.videocam, color: Colors.white),
                ),
                title: const Text('Record Video'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendVideo(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.purple,
                  child: Icon(Icons.video_library, color: Colors.white),
                ),
                title: const Text('Gallery Video'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendVideo(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startCall(bool isVideo) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    ZegoCallService.instance.startCall(
      context: context,
      currentUserId: currentUser.uid,
      currentUserName: currentUser.displayName ?? currentUser.email?.split('@').first ?? 'User',
      peerUserId: widget.peerUser.uid,
      peerUserName: widget.peerUser.name,
      peerAvatar: widget.peerUser.avatarUrl,
      chatId: _chatId,
      isVideo: isVideo,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD), // WhatsApp wallpaper tone
      appBar: AppBar(
        backgroundColor: const Color(0xFF128C7E),
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: const Color(0xFF25D366),
              backgroundImage: widget.peerUser.avatarUrl.isNotEmpty
                  ? CachedNetworkImageProvider(widget.peerUser.avatarUrl)
                  : null,
              child: widget.peerUser.avatarUrl.isEmpty
                  ? Text(
                      widget.peerUser.name.isNotEmpty ? widget.peerUser.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.peerUser.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.peerUser.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.peerUser.isOnline ? const Color(0xFFD4F8D4) : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            tooltip: 'Audio Call',
            onPressed: () => _startCall(false),
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            tooltip: 'Video Call',
            onPressed: () => _startCall(true),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Real-time Messages Stream + Local SQLite Cache
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _firestoreService.streamMessages(_chatId),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                    for (final msg in snapshot.data!) {
                      chatProvider.syncIncomingMessage(msg);
                      // If message was sent to me and is not marked as read yet, mark it as read in Cloud Firestore!
                      if (msg.receiverId == _myUid && msg.status != AppConstants.statusRead) {
                        chatProvider.markMessageAsReadInCloud(_chatId, msg.id);
                      }
                    }
                  });
                }

                return Consumer<ChatProvider>(
                  builder: (context, chatProvider, _) {
                    final messages = chatProvider.messages;

                    if (messages.isEmpty) {
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white70,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            '🔒 Messages are end-to-end encrypted.\nSay hello to start chatting!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54, fontSize: 13),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId == _myUid;

                        // Date header logic
                        bool showDateHeader = false;
                        if (index == 0) {
                          showDateHeader = true;
                        } else {
                          final prevMessage = messages[index - 1];
                          showDateHeader = !DateFormatter.isSameDay(prevMessage.timestamp, message.timestamp);
                        }

                        return Column(
                          children: [
                            if (showDateHeader) _buildDateHeader(message.timestamp),
                            _buildMessageBubble(message, isMe),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          // 2. Bottom Chat Input Bar (Text + Voice Recording + Attachments)
          _buildInputBar(),
        ],
      ),
    );
  }

  // --- Date Header Pill (Today, Yesterday, DD/MM/YYYY) ---
  Widget _buildDateHeader(DateTime timestamp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        DateFormatter.formatDateHeader(timestamp),
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // --- Message Bubble (Right for Me, Left for Peer) ---
  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFE7FFDB) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Media or Text Content
            if (message.messageType == AppConstants.typeAudio)
              VoiceMessagePlayer(message: message, isMe: isMe)
            else if (message.messageType == AppConstants.typeImage)
              _buildImageMessage(message)
            else if (message.messageType == AppConstants.typeVideo)
              VideoMessagePlayer(message: message, isMe: isMe)
            else
              Text(
                message.content,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),

            const SizedBox(height: 2),

            // 2. Time + Dynamic Status Ticks
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  DateFormatter.formatMessageTime(message.timestamp),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  ChatUtils.getStatusIcon(message.status, size: 15),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageMessage(MessageModel message) {
    final localPath = message.localPath;
    final hasLocal = localPath != null && File(localPath).existsSync();
    final imageSource = hasLocal ? localPath : message.content;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullScreenImageViewer(
              imageSource: imageSource,
              title: widget.peerUser.name,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 200,
          width: 220,
          color: Colors.grey.shade200,
          child: Hero(
            tag: imageSource,
            child: hasLocal
                ? Image.file(File(localPath), fit: BoxFit.cover)
                : CachedNetworkImage(
                    imageUrl: message.content,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Color(0xFF128C7E)),
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                  ),
          ),
        ),
      ),
    );
  }

  // --- Bottom Chat Input Bar (Text + Voice Recording + Attachments) ---
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.transparent,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file, color: Colors.grey),
                      tooltip: 'Attach Media',
                      onPressed: _showAttachmentSheet,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        cursorColor: const Color(0xFF128C7E),
                        decoration: InputDecoration(
                          hintText: 'Message',
                          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.grey),
                      tooltip: 'Camera',
                      onPressed: () => _pickAndSendImage(ImageSource.camera),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Dynamic Action: Send Button (if text entered) OR Voice Note Recorder (if text empty)
            if (_hasText)
              CircleAvatar(
                radius: 23,
                backgroundColor: const Color(0xFF128C7E),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _sendMessage,
                ),
              )
            else
              VoiceRecorderWidget(
                onRecordingComplete: _sendVoiceNote,
              ),
          ],
        ),
      ),
    );
  }
}
