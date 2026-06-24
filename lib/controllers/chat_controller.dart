import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatController extends GetxController {
  RxList<dynamic> selectedMessages = [].obs;

  bool isSelected(String id) {
    return selectedMessages.contains(id);
  }

  bool get isSelectionMode => selectedMessages.isNotEmpty;
  final ImagePicker picker = ImagePicker();
  Rx<File?> selectedFile = Rx<File?>(null);
  RxBool isImage = true.obs;

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  Future<void> chats({
    required String receiverId,
    required String receiverName,
    required String receiverImage,
    required String message,
  }) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) return;
    final currentUserDoc = await firestore
        .collection('users_qc')
        .doc(currentUser.uid)
        .get();
    final currentUserData = currentUserDoc.data();
    List<String> ids = [currentUser.uid, receiverId];
    ids.sort();
    String chatId = ids.join("_");
    final messageRef = await firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      "senderId": currentUser.uid,
      "receiverId": receiverId,
      "message": message,
      "timestamp": FieldValue.serverTimestamp(),
      "isSeen": false,
      "type": "text",
    });
    await firestore.collection('chats').doc(chatId).set({
      "participantIds": [currentUser.uid, receiverId],
      "participants": [
        {
          "id": currentUser.uid,
          "name": currentUser.displayName,
          "imageUrl": currentUserData?['imageUrl'] ?? "",
        },
        {"id": receiverId, "name": receiverName, "imageUrl": receiverImage},
      ],
      "lastMessage": message,
      "lastMessageTime": FieldValue.serverTimestamp(),
      "createdAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await messageRef.update({"messageId": messageRef.id});
  }

  Stream<QuerySnapshot> getMessages(String receiverId) {
    final currentUser = auth.currentUser!;
    List<String> ids = [currentUser.uid, receiverId];
    ids.sort();
    String chatId = ids.join("_");
    return firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot> getChats() {
    final currentUser = auth.currentUser;
    return firestore
        .collection('chats')
        .where('participantIds', arrayContains: currentUser?.uid)
        .snapshots();
  }

  Future<void> pickMedia() async {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text("Pick Image"),
              onTap: () async {
                Get.back();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (image != null) {
                  selectedFile.value = File(image.path);
                  selectedFile.refresh();
                  isImage.value = true;
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_call),
              title: const Text("Pick Video"),
              onTap: () async {
                Get.back();
                final XFile? video = await picker.pickVideo(
                  source: ImageSource.gallery,
                );
                if (video != null) {
                  selectedFile.value = File(video.path);
                  selectedFile.refresh();
                  isImage.value = false;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> sendMediaMessage({
    required String receiverId,
    required String receiverName,
    required String receiverImage,
  }) async {
    print("receiverId: $receiverId");
    print("receiverName: '$receiverName'");
    print("receiverImage: '$receiverImage'");

    final currentUser = auth.currentUser;
    if (currentUser == null || selectedFile.value == null) {
      print("Current user or selected file is null");
      return;
    }

    try {
      final senderDoc = await firestore
          .collection('users_qc')
          .doc(currentUser.uid)
          .get();

      final receiverDoc = await firestore
          .collection('users_qc')
          .doc(receiverId)
          .get();

      final senderData = senderDoc.data();
      final receiverData = receiverDoc.data();

      print("SENDER DATA: $senderData");
      print("RECEIVER DATA: $receiverData");

      List<String> ids = [currentUser.uid, receiverId];
      ids.sort();
      String chatId = ids.join("_");

      String fileName =
          "${DateTime.now().millisecondsSinceEpoch}.jpg";

      Reference ref = storage
          .ref()
          .child("chat_media/$chatId/$fileName");

      await ref.putFile(selectedFile.value!);

      String fileUrl = await ref.getDownloadURL();

      print("FILE URL: $fileUrl");
      print("Receiver NNN ${receiverData?['name']}");

      await firestore.collection('chats').doc(chatId).set({
        "participantIds": [currentUser.uid, receiverId],
        "participants": [
          {
            "id": currentUser.uid,
            "name": senderData?['name'] ?? "",
            "imageUrl": senderData?['imageUrl'] ?? "",
          },
          {
            "id": receiverId,
            "name": receiverData?['name'] ?? receiverName,
            "imageUrl":
            receiverData?['imageUrl'] ?? receiverImage,
          },
        ],
        "lastMessage": "📷 Image",
        "lastMessageTime": FieldValue.serverTimestamp(),
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final messageRef = await firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        "senderId": currentUser.uid,
        "receiverId": receiverId,
        "message": fileUrl,
        "timestamp": FieldValue.serverTimestamp(),
        "isSeen": false,
        "type": "image",
      });

      await messageRef.update({
        "messageId": messageRef.id,
      });

      selectedFile.value = null;

      print("IMAGE MESSAGE SENT SUCCESSFULLY");
    } catch (e, stackTrace) {
      print("SEND MEDIA ERROR: $e");
      print(stackTrace);
    }
  }

  Future<void> markMessagesAsSeen(String receiverId) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) return;
    List<String> ids = [currentUser.uid, receiverId];
    ids.sort();
    String chatId = ids.join("_");
    final messages = await firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUser.uid)
        .where('isSeen', isEqualTo: false)
        .get();
    for (var doc in messages.docs) {
      doc.reference.update({"isSeen": true});
    }
  }

  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
    required bool forEveryone,
  }) async {
    final ref = firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    if (forEveryone) {
      await ref.delete();
    }
  }

  Future<void> pickFromCamera() async {
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      selectedFile.value = File(image.path);
      isImage.value = true;
    }
  }

  Future<List<Object>> getPhoneContacts() async {
    if (await Permission.contacts.request().isGranted) {
      return [];
    }
    final contacts = await FlutterContacts.getAll(
    );
    List<String> phoneNumbers = [];

    for (var contact in contacts) {
      for (var phone in contact.phones) {
        String number = phone.number
            .replaceAll(" ", "")
            .replaceAll("-", "");

        if (number.isNotEmpty) {
          phoneNumbers.add(number);
        }
      }
    }
    return phoneNumbers;
  }
  Future<List<Map<String, dynamic>>> getAppContacts() async {
    List<Object> phoneContacts = await getPhoneContacts();
    QuerySnapshot usersSnap =
    await FirebaseFirestore.instance.collection("users_qc").get();
    List<Map<String, dynamic>> matchedUsers = [];
    for (var doc in usersSnap.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String dbPhone = (data['number'] ?? "").toString().replaceAll(" ", "");
      if (phoneContacts.contains(dbPhone)) {
        matchedUsers.add(data);
      }
    }
    return matchedUsers;
  }


  void showDeleteOptionsDialog({
    required BuildContext context,
    required String messageId,
    required String currentUserId,
    required String senderId,
    required String receiverId,
  })
  {

    final bool isSender = currentUserId == senderId;
    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatId = ids.join("_");
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Message?'),
          content: const Text('Choose how you want to delete this message.'),
          actionsAlignment: MainAxisAlignment.end,
          actions: [

            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),


            TextButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('chats')
                      .doc(chatId)
                      .collection('messages')
                      .doc(messageId)
                      .update({
                    'deletedForUsers': FieldValue.arrayUnion([currentUserId]),
                  });
                  if (context.mounted) Navigator.pop(dialogContext);

                  refreshSelectMessage();
                } catch (e) {
                  _showErrorSnackBar(context, e.toString());
                }
              },
              child: const Text('Delete for me'),
            ),

            if (isSender)
              TextButton(
                onPressed: () async {
                  try {
                    for (String messageId in selectedMessages) {
                      await FirebaseFirestore.instance
                          .collection('chats')
                          .doc(chatId)
                          .collection('messages')
                          .doc(messageId)
                          .delete();
                    }
                    if (context.mounted) Navigator.pop(dialogContext);
                    refreshSelectMessage();
                  } catch (e) {
                    _showErrorSnackBar(context, e.toString());
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete for everyone'),
              ),
          ],
        );
      },
    );
  }
  void _showErrorSnackBar(BuildContext context, String error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }


  void refreshSelectMessage() {
    selectedMessages.clear();

  }
}
