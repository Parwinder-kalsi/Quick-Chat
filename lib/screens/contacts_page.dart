import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quick_chat/controllers/chat_controller.dart';
import 'package:quick_chat/models/user_model.dart';
import 'package:quick_chat/screens/messages_screen.dart';
import 'package:get/get.dart';
import 'package:quick_chat/themes/colors.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});
  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  ChatController chatController=ChatController();
  late Future<List<Map<String, dynamic>>> contactsFuture;

  @override
  void initState() {
    super.initState();
    contactsFuture = chatController.getAppContacts();
  }

  Stream<QuerySnapshot> getUsersStream() {
    return FirebaseFirestore.instance
        .collection("users_qc")
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: contactsFuture,
        builder: (context, contactsSnap) {
          if (contactsSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final contacts = contactsSnap.data ?? [];

          return StreamBuilder<QuerySnapshot>(
            stream: getUsersStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final firestoreUsers = snapshot.data!.docs
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .where((u) =>
              u["uid"] != null &&
                  u["uid"].toString() != currentUser?.uid
              )
                  .toList();

              return ListView.builder(
                itemCount: firestoreUsers.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final user = firestoreUsers[index];

                  final String name = user['name'] ?? '';
                  final String email = user['email'] ?? '';
                  final String imageUrl = user['imageUrl'] ?? '';
                  final String phone = user['phone'] ?? '';

                  final isInContacts = contacts.any((c) =>
                  (c['phone'] ?? '').toString() == phone);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: imageUrl.isNotEmpty
                            ? NetworkImage(imageUrl)
                            : null,
                        child: imageUrl.isEmpty
                            ? Text(name.isNotEmpty ? name[0] : "?")
                            : null,
                      ),
                      title: Row(
                        children: [
                          Text(name,style: TextStyle(fontWeight: FontWeight.bold),),

                          if (isInContacts)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.green,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(email,style: TextStyle(fontSize: 10),),
                      trailing: const Icon(Icons.chat),
                      onTap: () {
                        Get.to(() => MessagesScreen(
                          user: UserModel(
                            uid: user['uid'] ?? '',
                            name: name,
                            imageUrl: imageUrl,
                          ),
                        ));
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
