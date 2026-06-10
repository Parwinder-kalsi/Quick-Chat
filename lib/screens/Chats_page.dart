import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quick_chat/controllers/chat_controller.dart';
import 'package:quick_chat/models/user_model.dart';
import 'package:quick_chat/screens/messages_screen.dart';
import 'package:quick_chat/themes/colors.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});
  @override
  State<ChatsPage> createState() => _ChatsPageState();
}
class _ChatsPageState extends State<ChatsPage> {
  final ChatController chatController = Get.put(ChatController());
  final currentUser = FirebaseAuth.instance.currentUser;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: chatController.getChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No chats yet 👋"));
          }
          final chats = snapshot.data!.docs;
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final data = chats[index].data() as Map<String, dynamic>;
              List participants = data['participants'] ?? [];
              Map<String, dynamic>? otherUser;
              try {
                otherUser = participants.firstWhere(
                      (user) => user['id'] != currentUser!.uid,
                  orElse: () => null,
                );
              } catch (e) {
                otherUser = null;
              }
              if (otherUser == null) {
                return const SizedBox();
              }
              String receiverId = otherUser['id'] ?? "";
              String receiverName = otherUser['name'] ?? "User";
              String receiverImage = otherUser['imageUrl'] ?? "";
              Timestamp? timestamp = data['lastMessageTime'];
              String time = "";
              if (timestamp != null) {
                DateTime date = timestamp.toDate();
                time = "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
              }
              return InkWell(
                onTap: () {
                  Get.to(
                    () => MessagesScreen(
                      user: UserModel(
                        uid: receiverId,
                        name: receiverName,
                        imageUrl: receiverImage,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users_qc')
                            .doc(receiverId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          String imageUrl = "";
                          if (snapshot.hasData && snapshot.data!.data() != null) {
                            final data = snapshot.data!.data() as Map<String, dynamic>;
                            imageUrl = data['imageUrl'] ?? "";
                          }
                          return CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.green.shade300,
                            backgroundImage: imageUrl.trim().isNotEmpty
                                ? NetworkImage(imageUrl)
                                : null,
                            child: imageUrl.trim().isEmpty
                                ? Text(
                              receiverName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            )
                                : null,
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              receiverName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['lastMessage'] ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
