import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:quick_chat/common/app_bar.dart';
import 'package:quick_chat/controllers/chat_controller.dart';
import 'package:quick_chat/notificationservice/notification_service.dart';
import 'package:quick_chat/screens/Chats_page.dart';
import 'package:quick_chat/screens/Profile_page.dart';
import 'package:quick_chat/screens/contacts_page.dart';
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
   PageController pageController = PageController();
  final ChatController chatController = Get.put(ChatController());
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    NotificationService notificationService = NotificationService();
    notificationService.requestNotificationPermission();
    notificationService.getFcmToken();
    notificationService.localNotification();

    // FirebaseMessaging.instance.getInitialMessage().then((message) {
    //   notificationService.showNotification(message!);
    // });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      notificationService.showNotification(message);
    });
    super.initState();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  final List<Widget> pages = const [ChatsPage(), ContactsPage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Obx(
          () => CommonAppBar(
            title: chatController.selectedChats.isNotEmpty && currentIndex == 0
                ? "${chatController.selectedChats.length} Selected"
                : "Quick Chat",
            actions: [
              if (chatController.selectedChats.isNotEmpty && currentIndex == 0)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    chatController.deleteChatDialog(context:context, currentUserId:currentUser!.uid );
                  },
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          height: 75,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF128C7E),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    currentIndex = 0;
                    pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: currentIndex == 0
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_rounded,
                        size: 24,
                        color: currentIndex == 0
                            ? const Color(0xFF128C7E)
                            : Colors.black87,
                      ),
                      Text(
                        "Chats",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: currentIndex == 0
                              ? const Color(0xFF128C7E)
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    currentIndex = 1;
                    pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: currentIndex == 1
                        ? Colors.white
                        : Colors.transparent,

                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.contacts_outlined,
                        size: 24,
                        color: currentIndex == 1
                            ? const Color(0xFF128C7E)
                            : Colors.black87,
                      ),
                      Text(
                        "Contacts",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: currentIndex == 1
                              ? const Color(0xFF128C7E)
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    currentIndex = 2;
                    pageController.animateToPage(
                      2,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),

                  decoration: BoxDecoration(
                    color: currentIndex == 2
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10 ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person,
                        size: 24,
                        color: currentIndex == 2
                            ? const Color(0xFF128C7E)
                            : Colors.black87,
                      ),
                      Text(
                        "Profile",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: currentIndex == 2
                              ? const Color(0xFF128C7E)
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: PageView(
        controller: pageController,
        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        children: pages,
      ),
    );
  }
}
