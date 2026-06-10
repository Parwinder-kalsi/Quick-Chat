import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quick_chat/common/app_bar.dart';
import 'package:quick_chat/themes/colors.dart';


class EditProfile extends StatefulWidget {
  const EditProfile({super.key});
  @override
  State<EditProfile> createState() => _EditProfileState();
}
class _EditProfileState extends State<EditProfile> {
  final TextEditingController nameController = TextEditingController();
  File? _image;
  final ImagePicker _picker = ImagePicker();
  String oldImageUrl = "";
  @override
  void initState() {
    super.initState();
    loadOldData();
  }
  Future<void> loadOldData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users_qc')
        .doc(user.uid)
        .get();
    setState(() {
      nameController.text = doc.data()?['name'] ?? "";
      oldImageUrl = doc.data()?['imageUrl'] ?? "";
    });
  }
  Future<void> pickImage() async {
    final XFile? pickedFile =
    await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }
  Future<void> saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String name = nameController.text.trim();

    try {
      String imageUrl = oldImageUrl;
      if (_image != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${user.uid}.jpg');
        await ref.putFile(_image!);
        imageUrl = await ref.getDownloadURL();
      }
      await FirebaseFirestore.instance
          .collection('users_qc')
          .doc(user.uid)
          .set({
        "name": name,
        "email": user.email,
        "imageUrl": imageUrl,
      }, SetOptions(merge: true));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile Updated")),
      );
      Navigator.pop(context);
    } catch (e) {
      print("Error: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.cyan[50],
      appBar:CommonAppBar(title: "Edit Profile"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _image != null
                    ? FileImage(_image!)
                    : (oldImageUrl.isNotEmpty
                    ? NetworkImage(oldImageUrl)
                    : null) as ImageProvider?,
                child: (_image == null && oldImageUrl.isEmpty)
                    ? const Icon(Icons.person, size: 50,color: AppColors.darkGreenColor,)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            const Text("Tap to change photo"),
            const SizedBox(height: 30),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Name",
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkGreenColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: saveProfile,
                child: const Text(
                  "Save Changes",
                  style: TextStyle(fontSize: 16,color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
