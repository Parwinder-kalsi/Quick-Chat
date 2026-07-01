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
  RxList<String> selectedChats = <String>[].obs;

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
    // final currentUserDoc = await firestore
    //     .collection('users_qc')
    //     .doc(currentUser.uid)
    //     .get();
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
      "lastMessage": message,
      "lastMessageId": messageRef.id,
      "lastMessageTime": FieldValue.serverTimestamp(),
      "createdAt": FieldValue.serverTimestamp(),
      "deletedForUsers": FieldValue.arrayRemove([currentUser.uid, receiverId]),
    }, SetOptions(merge: true));
    await messageRef.update({"messageId": messageRef.id});
    await firestore.collection('chats').doc(chatId).update({
      "deletedForUsers": FieldValue.arrayRemove([currentUser.uid, receiverId]),
    });
  }

  Future<String?> getChatId(String currentUserId, String otherUserId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('participantIds', arrayContains: currentUserId)
          .get();

      for (final doc in snapshot.docs) {
        final participantIds = List<String>.from(doc['participantIds']);

        if (participantIds.contains(otherUserId)) {
          return doc.id;
        }
      }

      return null;
    } catch (e) {
      print('Error fetching chatId: $e');
      return null;
    }
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

  Stream<List<Map<String, dynamic>>> getChats() {
    final currentUser = auth.currentUser!;

    return firestore
        .collection('chats')
        .where('participantIds', arrayContains: currentUser.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          return Future.wait(
            snapshot.docs.map((chat) async {
              final participants = List<String>.from(chat['participantIds']);

              final receiverId = participants.firstWhere(
                (id) => id != currentUser.uid,
              );

              final user = await firestore
                  .collection('users_qc')
                  .doc(receiverId)
                  .get();

              return {"chat": chat, "user": user};
            }),
          );
        });
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
    final currentUser = auth.currentUser;
    if (currentUser == null || selectedFile.value == null) {
      print("Current user or selected file is null");
      return;
    }

    try {
      // final senderDoc = await firestore
      //     .collection('users_qc')
      //     .doc(currentUser.uid)
      //     .get();
      //
      // final receiverDoc = await firestore
      //     .collection('users_qc')
      //     .doc(receiverId)
      //     .get();

      List<String> ids = [currentUser.uid, receiverId];
      ids.sort();
      String chatId = ids.join("_");

      String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";

      Reference ref = storage.ref().child("chat_media/$chatId/$fileName");

      await ref.putFile(selectedFile.value!);

      String fileUrl = await ref.getDownloadURL();

      await firestore.collection('chats').doc(chatId).set({
        "participantIds": [currentUser.uid, receiverId],
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

      await messageRef.update({"messageId": messageRef.id});

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

  void deleteChatDialog({
    required BuildContext context,
    required String currentUserId,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Chat?'),
          content: const Text('This chat will be removed only for you'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  for (final chatId in selectedChats) {
                    await FirebaseFirestore.instance
                        .collection('chats')
                        .doc(chatId)
                        .update({
                          'deletedForUsers': FieldValue.arrayUnion([
                            currentUserId,
                          ]),
                        });
                    final messages = await FirebaseFirestore.instance
                        .collection('chats')
                        .doc(chatId)
                        .collection('messages')
                        .get();
                    final batch = FirebaseFirestore.instance.batch();
                    for (final doc in messages.docs) {
                      batch.update(doc.reference, {
                        'deletedForUsers': FieldValue.arrayUnion([
                          currentUserId,
                        ]),
                      });
                    }
                    await batch.commit();
                  }
                  if (context.mounted) Navigator.pop(dialogContext);
                  selectedChats.clear();
                  refresh();
                  update();
                  update(['appbar']);
                } catch (e) {
                  debugPrint("Delete Chat Error: $e");
                }
              },
              child: const Text("Delete for me"),
            ),
          ],
        );
      },
    );
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
    final contacts = await FlutterContacts.getAll();
    List<String> phoneNumbers = [];

    for (var contact in contacts) {
      for (var phone in contact.phones) {
        String number = phone.number.replaceAll(" ", "").replaceAll("-", "");

        if (number.isNotEmpty) {
          phoneNumbers.add(number);
        }
      }
    }
    return phoneNumbers;
  }

  Future<List<Map<String, dynamic>>> getAppContacts() async {
    List<Object> phoneContacts = await getPhoneContacts();
    QuerySnapshot usersSnap = await FirebaseFirestore.instance
        .collection("users_qc")
        .get();
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

  Future<bool> currentUserMessages(
    String chatId,
    RxList<dynamic> messageIds,
    String currentUserId,
  ) async {
    for (final messageId in messageIds) {
      final doc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (!doc.exists) {
        return false;
      }

      if (doc.data()?['senderId'] != currentUserId) {
        return false;
      }
    }

    return true;
  }

  Future<void> showDeleteOptionsDialog({
    required BuildContext context,
    required String messageId,
    required String chatId,
    required String currentUserId,
    required String senderId,
    required String receiverId,
  }) async {
    final bool isSenderMe = currentUserId == senderId;
    final bool userMessages = await currentUserMessages(
      chatId,
      selectedMessages,
      currentUserId,
    );
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Message?'),
          content: const Text(
            'Are you sure you want to delete the selected messages?',
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final chatRef = FirebaseFirestore.instance
                      .collection('chats')
                      .doc(chatId);

                  for (String messageId in selectedMessages) {
                    await chatRef
                        .collection('messages')
                        .doc(messageId)
                        .update({
                          'deletedForUsers': FieldValue.arrayUnion([
                            currentUserId,
                          ]),
                        });
                  }

                  final chatDoc = await chatRef.get();
                  final lastMsgId = chatDoc.data()?['lastMessageId'];

                  if (selectedMessages.contains(lastMsgId)) {
                    final messages = await chatRef
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .get();

                    Map<String, dynamic>? newLastMessage;
                    String? newLastMessageId;

                    for (final doc in messages.docs) {
                      final data = doc.data();
                      final deletedFor = List<String>.from(data['deletedForUsers'] ?? []);

                      if (!deletedFor.contains(currentUserId)) {
                        newLastMessage = data;
                        newLastMessageId = doc.id;
                        break;
                      }
                    }

                    await chatRef.update({
                      'lastMessage': newLastMessage?['message'] ?? '',
                      'lastMessageId': newLastMessageId ?? '',
                      'lastMessageTime': newLastMessage?['timestamp'],
                      'lastSenderId': newLastMessage?['senderId'] ?? '',
                    });
                  }

                  if (context.mounted) Navigator.pop(dialogContext);
                  selectedMessages.clear();
                  refreshSelectMessage();
                  update(['appbar']);
                  } catch (e) {
                  // _showErrorSnackBar(context, e.toString());
                  debugPrint("Error: $e");
                }
              },
              child: const Text('Delete for me'),
            ),
            if (isSenderMe && userMessages)
              TextButton(
                onPressed: () async {
                  try {
                    final chatRef = FirebaseFirestore.instance
                        .collection('chats')
                        .doc(chatId);

                    for (String messageId in selectedMessages) {
                      await chatRef
                          .collection('messages')
                          .doc(messageId)
                          .delete();
                          // .update({
                          //   'deletedForUsers': FieldValue.arrayUnion([
                          //     currentUserId,receiverId
                          //   ]),
                          // });
                    }

                    final messages = await chatRef
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .get();

                    Map<String, dynamic>? lastVisibleMessage;
                    String? lastVisibleMessageId;

                    for (final doc in messages.docs) {
                      final data = doc.data();

                      final deletedForUsers = List<String>.from(
                        data['deletedForUsers'] ?? [],
                      );

                      final deletedForEveryone =
                          deletedForUsers.contains(currentUserId) &&
                              deletedForUsers.contains(receiverId);

                      if (!deletedForEveryone) {
                        lastVisibleMessage = data;
                        lastVisibleMessageId = doc.id;
                        break;
                      }
                    }

                    if (lastVisibleMessage != null) {
                      await chatRef.update({
                        'lastMessage': lastVisibleMessage['message'],
                        'lastMessageId': lastVisibleMessageId,
                        'lastMessageTime': lastVisibleMessage['timestamp'],
                        'lastSenderId': lastVisibleMessage['senderId'],
                      });
                    } else {
                      await chatRef.update({
                        'lastMessage': '',
                        'lastMessageId': '',
                        'lastMessageTime': null,
                        'lastSenderId': '',
                      });
                    }

                    if (context.mounted) Navigator.pop(dialogContext);
                    selectedMessages.clear();
                    refreshSelectMessage();
                    update(['appbar']);
                  } catch (e) {
                    // _showErrorSnackBar(context, e.toString());
                    debugPrint("Error: $e");
                  }
                },
                child: const Text('Delete for everyone'),
              ),
          ],
        );
      },
    );
  }

  // void _showErrorSnackBar(BuildContext context, String error) {
  //   if (context.mounted) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('Error: $error')));
  //   }
  // }

  void refreshSelectMessage() {
    selectedMessages.clear();
  }
}
