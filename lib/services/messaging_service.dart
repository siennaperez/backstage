import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  factory Message.fromJson(Map<String, dynamic> json, String id) {
    return Message(
      id: id,
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      text: json['text'] ?? '',
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }
}

class Conversation {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserDisplayName;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserDisplayName,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });
}

class MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Send a message
  Future<void> sendMessage({
    required String receiverId,
    required String text,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final now = DateTime.now();
    final conversationId = _getConversationId(currentUserId!, receiverId);

    // Create message document
    final messageRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();

    final message = Message(
      id: messageRef.id,
      senderId: currentUserId!,
      receiverId: receiverId,
      text: text,
      timestamp: now,
      isRead: false,
    );

    // Save message
    await messageRef.set(message.toJson());

    // Update conversation metadata
    await _firestore.collection('conversations').doc(conversationId).set({
      'participants': [currentUserId, receiverId],
      'lastMessage': text,
      'lastMessageTime': Timestamp.fromDate(now),
      'lastMessageSenderId': currentUserId,
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));
  }

  // Get messages stream for a conversation
  Stream<List<Message>> getMessages(String otherUserId) {
    if (currentUserId == null) return Stream.value([]);

    final conversationId = _getConversationId(currentUserId!, otherUserId);

    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Message.fromJson(doc.data(), doc.id))
              .toList();
        })
        .handleError((error) {
          print('Error loading messages: $error');
        });
  }

  // Get list of conversations
  Stream<List<Conversation>> getConversations() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .handleError((error) {
          print('Error loading conversations: $error');
        })
        .asyncMap((snapshot) async {
          final conversations = <Conversation>[];

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final participants = List<String>.from(data['participants'] ?? []);
            final otherUserId = participants.firstWhere(
              (id) => id != currentUserId,
              orElse: () => '',
            );

            if (otherUserId.isEmpty) continue;

            // Get other user's info
            final userDoc = await _firestore
                .collection('users')
                .doc(otherUserId)
                .get();
            final userData = userDoc.data() ?? {};

            // Count unread messages
            final unreadQuery = await _firestore
                .collection('conversations')
                .doc(doc.id)
                .collection('messages')
                .where('receiverId', isEqualTo: currentUserId)
                .where('isRead', isEqualTo: false)
                .get();

            conversations.add(
              Conversation(
                id: doc.id,
                otherUserId: otherUserId,
                otherUserName: userData['username'] ?? 'Unknown',
                otherUserDisplayName:
                    userData['displayName'] ?? userData['username'],
                lastMessage: data['lastMessage'],
                lastMessageTime: (data['lastMessageTime'] as Timestamp?)
                    ?.toDate(),
                unreadCount: unreadQuery.docs.length,
              ),
            );
          }

          return conversations;
        });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String otherUserId) async {
    if (currentUserId == null) return;

    final conversationId = _getConversationId(currentUserId!, otherUserId);

    final unreadMessages = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // Helper to generate consistent conversation ID
  String _getConversationId(String userId1, String userId2) {
    final sorted = [userId1, userId2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}
