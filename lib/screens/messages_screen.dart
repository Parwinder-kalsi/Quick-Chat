import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quick_chat/common/message_bubble.dart';
import 'package:quick_chat/models/user_model.dart';
import '../controllers/chat_controller.dart';
import '../themes/colors.dart';
import 'package:get/get.dart';

class MessagesScreen extends StatefulWidget {
  final UserModel user;
  final String chatId;

  const MessagesScreen({super.key, required this.user,required this.chatId});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final ChatController chatController = Get.put(ChatController());
  final TextEditingController messageController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;
  bool isSend = true;
  String selectedMessageId = "";
  String senderMessageId = "";
  String receiverMessageId = "";

  @override
  void initState() {
    super.initState();
    chatController.selectedMessages.clear();
    chatController.markMessagesAsSeen(widget.user.uid!);
  }

  void select(String id, String senderId, String receiverId) {
    selectedMessageId = id;
    senderMessageId = senderId;
    receiverMessageId = receiverId;
    chatController.selectedMessages.add(id);
  }

  void unselect(String id) {
    chatController.selectedMessages.remove(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: AppColors.darkGreenColor,
        elevation: 1,
        automaticallyImplyLeading: false,
        leadingWidth: 100,

        leading: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.black,
                size: 20,
              ),
            ),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users_qc')
                  .doc(widget.user.uid!)
                  .snapshots(),
              builder: (context, snapshot) {
                String imageUrl = "";

                if (snapshot.hasData && snapshot.data!.data() != null) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  imageUrl = data['imageUrl'] ?? "";
                }

                return CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: imageUrl.trim().isNotEmpty
                      ? NetworkImage(imageUrl)
                      : null,
                  child: imageUrl.trim().isEmpty
                      ? const Icon(Icons.person, size: 26)
                      : null,
                );
              },
            ),
          ],
        ),

        title: Obx(() {
          final isSelectionMode = chatController.selectedMessages.isNotEmpty;
          return Text(
            isSelectionMode
                ? "${chatController.selectedMessages.length} selected"
                : (widget.user.name ?? ""),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          );
        }),

        actions: [
          Obx(() {
            final isSelectionMode = chatController.selectedMessages.isNotEmpty;
            if (isSelectionMode) {
              return Row(
                children: [
                  IconButton(
                    onPressed: () {
                      chatController.selectedMessages.clear();
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: () {
                      chatController.showDeleteOptionsDialog(
                        context: context,
                        messageId: selectedMessageId,
                        currentUserId: currentUser!.uid,
                        senderId: senderMessageId,
                        receiverId: receiverMessageId,
                        chatId:widget.chatId,
                      );
                    },
                  ),
                ],
              );
            }
            return Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.phone, color: Colors.white, size: 24),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.videocam,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: chatController.getMessages(widget.user.uid!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Start chatting 👋",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }
                final messages = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final deletedForUsers =
                  List<String>.from(data['deletedForUsers'] ?? []);

                  return !deletedForUsers.contains(currentUser!.uid);
                }).toList();

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final reversedIndex = messages.length - 1 - index;
                    final messageSnapshot = messages[reversedIndex];
                    final data = messageSnapshot.data() as Map<String, dynamic>;
                    final bool isMe = data['senderId'] == currentUser!.uid;

                    Timestamp? timeStamp = data['timestamp'];
                    DateTime? time = timeStamp?.toDate();
                    if (time != null) {}

                    return MessageBubble(
                      data: data,
                      isMe: isMe,
                      selectedMessages: chatController.selectedMessages,
                      onSelect: select,
                      onUnselect: unselect,
                    );
                  },
                );
              },
            ),
          ),
          Obx(() {
            final file = chatController.selectedFile.value;
            if (file == null) {
              return const SizedBox.shrink();
            }
            return SizedBox(
              height: 200,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  children: [
                    if (chatController.isImage.value)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          file,
                          height: 170,
                          width: 120,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.video_library, size: 50),
                        ),
                      ),

                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          chatController.selectedFile.value = null;
                        },
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.teal,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      chatController.pickFromCamera();
                    },
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.black,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: messageController,
                        decoration: const InputDecoration(
                          hintText: "Type a message",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: chatController.pickMedia,
                    icon: const Icon(Icons.attach_file, color: Colors.black),
                  ),
                  const SizedBox(width: 4),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: IconButton(
                      onPressed: () async {
                        if (messageController.text.trim().isNotEmpty) {
                          if (isSend == false) {
                            return;
                          }
                          isSend = false;
                        String  message = messageController.text.trim();
                          messageController.clear();

                        await chatController.chats(
                            receiverId: widget.user.uid!,
                            receiverName: widget.user.name ?? "",
                            receiverImage: widget.user.imageUrl ?? "",
                            message: message,
                          );
                        }
                        if (chatController.selectedFile.value != null) {
                          await chatController.sendMediaMessage(
                            receiverId: widget.user.uid!,
                            receiverName: widget.user.name ?? "",
                            receiverImage: widget.user.imageUrl ?? "",
                          );
                        }
                          isSend = true;
                      },
                      icon: const Icon(Icons.send, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
