import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/firebase_status.dart' as fb_status;

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({super.key});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool get _useFirestore => fb_status.isFirebaseReady &&
      FirebaseAuth.instance.currentUser != null &&
      !FirebaseAuth.instance.currentUser!.isAnonymous;
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'guest';
  String get _userName => FirebaseAuth.instance.currentUser?.displayName ?? 'Urban Explorer';

  // Local simulated database
  static final Map<String, List<Map<String, dynamic>>> _simulatedChats = {};

  List<Map<String, dynamic>> get _localMessages {
    final routeArgs = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final id = routeArgs['id'] as String;
    
    if (!_simulatedChats.containsKey(id)) {
      _simulatedChats[id] = [
        {
          'senderId': 'system',
          'senderName': 'System',
          'text': 'Selamat datang di grup obrolan!',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 10)),
        },
        {
          'senderId': 'u1',
          'senderName': 'Rian',
          'text': 'Halo semuanya! Ada yang lagi nongkrong di cafe hari ini?',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 8)),
        },
        {
          'senderId': 'u2',
          'senderName': 'Siti',
          'text': 'Halo Rian! Aku lagi di The Espresso Lab nih, Wi-Fi kencang banget.',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
        },
      ];
    }
    return _simulatedChats[id]!;
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final routeArgs = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final id = routeArgs['id'] as String;

    if (_useFirestore) {
      try {
        await FirebaseFirestore.instance
            .collection('group_chats')
            .doc(id)
            .collection('messages')
            .add({
          'senderId': _uid,
          'senderName': _userName,
          'text': text,
          'timestamp': FieldValue.serverTimestamp(),
        });
        Timer(const Duration(milliseconds: 200), _scrollToBottom);
        return; // Success
      } catch (e) {
        // Fail over to simulated local chat on error
        debugPrint('Firestore Chat Error, falling back: $e');
      }
    }

    // Local simulated flow
    setState(() {
      _localMessages.add({
        'senderId': _uid,
        'senderName': _userName,
        'text': text,
        'timestamp': DateTime.now(),
      });
    });
    Timer(const Duration(milliseconds: 100), _scrollToBottom);

    // Mock automatic response for engagement after 2 seconds
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _localMessages.add({
            'senderId': 'coffee_bot',
            'senderName': 'BrewBot ☕',
            'text': 'Kopi pilihan hari ini: Cappuccino hangat dengan latte art cantik!',
            'timestamp': DateTime.now(),
          });
        });
        Timer(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final routeArgs = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final id = routeArgs['id'] as String;
    final title = routeArgs['title'] as String;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
            const SizedBox(height: 2),
            const Text(
              'Grup Obrolan Aktif',
              style: TextStyle(fontSize: 11, color: AppTheme.textLight),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppTheme.primary),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Messages area
          Expanded(
            child: _useFirestore
                ? StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('group_chats')
                        .doc(id)
                        .collection('messages')
                        .orderBy('timestamp', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError || !snapshot.hasData) {
                        // Fallback to local messages if firebase fails
                        return _buildMessagesList(_localMessages);
                      }
                      
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        // If collection is empty, show pre-loaded local messages
                        return _buildMessagesList(_localMessages);
                      }

                      final dbMessages = docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        DateTime time = DateTime.now();
                        if (data['timestamp'] is Timestamp) {
                          time = (data['timestamp'] as Timestamp).toDate();
                        }
                        return {
                          'senderId': data['senderId'] ?? '',
                          'senderName': data['senderName'] ?? 'Pengguna',
                          'text': data['text'] ?? '',
                          'timestamp': time,
                        };
                      }).toList();

                      return _buildMessagesList(dbMessages);
                    },
                  )
                : _buildMessagesList(_localMessages),
          ),

          // Send message bar
          Container(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFD4C3BA).withValues(alpha: 0.5)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: AppTheme.text, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Ketik pesan...',
                        hintStyle: TextStyle(color: AppTheme.textLight),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<Map<String, dynamic>> messages) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final senderId = msg['senderId'] as String;
        final senderName = msg['senderName'] as String;
        final text = msg['text'] as String;
        final time = msg['timestamp'] as DateTime;

        final isMe = senderId == _uid;
        final isSystem = senderId == 'system';

        if (isSystem) {
          return Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                text,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              ),
            ),
          );
        }

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMe) ...[
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(
                      'https://images.unsplash.com/photo-${1500000000000 + (senderName.hashCode % 1000000)}?w=100&auto=format&fit=crop&q=80',
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isMe) ...[
                      Text(
                        senderName,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textLight, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                      decoration: BoxDecoration(
                        color: isMe ? AppTheme.primary : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 16 : 0),
                          bottomRight: Radius.circular(isMe ? 0 : 16),
                        ),
                        border: isMe ? null : Border.all(color: const Color(0xFFD4C3BA).withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        text,
                        style: TextStyle(
                          color: isMe ? Colors.white : AppTheme.text,
                          fontSize: 13.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
