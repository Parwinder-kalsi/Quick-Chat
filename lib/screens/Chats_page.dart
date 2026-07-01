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
  final ChatController chatController = Get.find();
  final currentUser = FirebaseAuth.instance.currentUser;
  bool isSelected(String participantId) => chatController.selectedChats.contains(participantId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: chatController.getChats(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();

          final chats = snapshot.data!.where((item) {
            final chat = item["chat"] as DocumentSnapshot;
            final data = chat.data() as Map<String, dynamic>;

            final deletedForUsers =
            List<String>.from(data['deletedForUsers'] ?? []);

            return !deletedForUsers.contains(currentUser!.uid);
          }).toList();
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat =
              chats[index]['chat'] as QueryDocumentSnapshot;

              final user =
              chats[index]['user'] as DocumentSnapshot;

              final chatData =
              chat.data() as Map<String, dynamic>;
              // print("chatData $chatData");
              final userData =
              user.data() as Map<String, dynamic>;

              final receiverId = user.id;
              final receiverName = userData['name'];
              final receiverImage = userData['imageUrl'];

              final chatId = chat.id;
              final lastMessage = chatData['lastMessage'];
                 Timestamp? timestamp = chatData['lastMessageTime'];
                 String time = "";
                 if (timestamp != null) {
                   DateTime date = timestamp.toDate();
                   int hour = date.hour;
                   String period = hour >= 12 ? 'PM' : 'AM';
                   hour = hour % 12;
                   if (hour == 0) hour = 12;
                   time =
                   "$hour:${date.minute.toString().padLeft(2, '0')} $period";
                 }
                 return GestureDetector(
                   onLongPress: () {
                     if (chatController.selectedChats.contains(chatId)) {
                       chatController.selectedChats.remove(chatId);
                     } else {
                       chatController.selectedChats.add(chatId);
                     }
                     chatController.update([chatId]);
                     chatController. update(['appbar']);
                   },
                   onTap: () {
                     if (chatController.selectedChats.isNotEmpty) {
                       if (chatController.selectedChats.contains(chatId)) {
                         chatController.selectedChats.remove(chatId);
                       } else {
                         chatController.selectedChats.add(chatId);

                       }
                       chatController.update([chatId]);
                     chatController. update(['appbar']);
                       return;
                     }
                     Get.to(
                           () => MessagesScreen(
                         user: UserModel(
                           uid: receiverId,
                           name: receiverName,
                           imageUrl: receiverImage,
                         ),
                        chatId: chatId,
                       ),
                     );
                   },
                   child:GetBuilder<ChatController>(
                     id: chatId,
                     builder: (controller) {
                     final bool selection=chatController.selectedChats.contains(chatId);
                     return Container(
                       margin:  EdgeInsets.symmetric(
                         horizontal: 12,
                         vertical: 6,
                       ),
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(
                         color: selection
                             ? Colors.blue.withValues(alpha: 0.25)
                             :  Colors.white,
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
                               if (snapshot.connectionState ==
                                   ConnectionState.waiting) {
                                 return const Center(
                                   child: CircularProgressIndicator(),
                                 );
                               }
                               if (!snapshot.hasData) {
                                 return const Center(child: Text("No chats yet 👋"));
                               }
                               String imageUrl = "";
                               String name = "";
                               if (snapshot.hasData &&
                                   snapshot.data!.data() != null) {
                                 final data =
                                 snapshot.data!.data() as Map<String, dynamic>;
                                 imageUrl = data['imageUrl'] ?? "";
                                 name = data['name'] ?? "";
                               }
                               return CircleAvatar(
                                 radius: 28,
                                 backgroundColor: Colors.green.shade300,
                                 backgroundImage: imageUrl.trim().isNotEmpty
                                     ? NetworkImage(imageUrl)
                                     : null,
                                 child: imageUrl.trim().isEmpty
                                     ? Text(
                                   name[0].toUpperCase(),
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
                                   lastMessage  ?? "",
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
                     );
                   },),
                 );
               },
             );
        },
      ),
    );
  }
}
