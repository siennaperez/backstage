import 'package:flutter/material.dart';
import '../services/messaging_service.dart';
import '../services/user_service.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final MessagingService _messagingService = MessagingService();
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();

  int _selectedIndex = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Messages' : 'New Message'),
        backgroundColor: const Color(0xFF7086F8),
        foregroundColor: Colors.white,
        leading: _selectedIndex == 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedIndex = 0;
                  });
                },
              )
            : null,
        actions: _selectedIndex == 0
            ? [
                IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                ),
              ]
            : null,
      ),
      body: _selectedIndex == 0
          ? _buildConversationsList()
          : _buildNewMessageView(),
    );
  }

  Widget _buildConversationsList() {
    return StreamBuilder<List<Conversation>>(
      stream: _messagingService.getConversations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final conversations = snapshot.data ?? [];

        if (conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No conversations yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                  icon: const Icon(Icons.message),
                  label: const Text('Start a conversation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7086F8),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            return _buildConversationTile(conversations[index]);
          },
        );
      },
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    return ListTile(
      leading: FutureBuilder<AppUser?>(
        future: _userService.getUserById(conversation.otherUserId),
        builder: (context, snapshot) {
          final otherUser = snapshot.data;
          return CircleAvatar(
            backgroundColor: const Color(0xFF7086F8),
            backgroundImage: otherUser?.profileImageUrl != null
                ? NetworkImage(otherUser!.profileImageUrl!)
                : null,
            child: otherUser?.profileImageUrl == null
                ? Text(
                    (conversation.otherUserDisplayName ??
                            conversation.otherUserName)
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
          );
        },
      ),
      title: Text(
        conversation.otherUserDisplayName ?? conversation.otherUserName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        conversation.lastMessage ?? 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: conversation.unreadCount > 0
          ? Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF7086F8),
                shape: BoxShape.circle,
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : conversation.lastMessageTime != null
          ? Text(
              _formatTime(conversation.lastMessageTime!),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            )
          : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              otherUserId: conversation.otherUserId,
              otherUserName: conversation.otherUserName,
              otherUserDisplayName: conversation.otherUserDisplayName,
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewMessageView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            onChanged: (query) {
              setState(() {
                _searchQuery = query.toLowerCase();
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<List<AppUser>>(
            stream: _userService.getAllUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var users = snapshot.data ?? [];

              if (_searchQuery.isNotEmpty) {
                users = users.where((user) {
                  final username = user.username?.toLowerCase() ?? '';
                  final displayName = user.displayName?.toLowerCase() ?? '';
                  final email = user.email?.toLowerCase() ?? '';
                  return username.contains(_searchQuery) ||
                      displayName.contains(_searchQuery) ||
                      email.contains(_searchQuery);
                }).toList();
              }

              if (users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'No other users found'
                            : 'No users match your search',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              otherUserId: user.id,
                              otherUserName: user.username ?? 'User',
                              otherUserDisplayName: user.displayName,
                            ),
                          ),
                        ).then((_) {
                          setState(() {
                            _selectedIndex = 0;
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: const Color(0xFF7086F8),
                                  backgroundImage: user.profileImageUrl != null
                                      ? NetworkImage(user.profileImageUrl!)
                                      : null,
                                  child: user.profileImageUrl == null
                                      ? Text(
                                          user.displayNameOrUsername
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.displayNameOrUsername,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (user.email != null)
                                      Text(
                                        user.email!,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // FIXED: USE user.attending, NOT attendingEvents
                            Builder(
                              builder: (_) {
                                final attending = user.attending;

                                if (attending.isEmpty) {
                                  return Text(
                                    "Not attending any events",
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 13,
                                    ),
                                  );
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Attending:",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      children: attending.take(3).map((
                                        eventId,
                                      ) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                            horizontal: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF7086F8,
                                            ).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            eventId,
                                            style: const TextStyle(
                                              color: Color(0xFF7086F8),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${time.month}/${time.day}';
    }
  }
}
