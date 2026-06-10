import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quick_chat/themes/colors.dart';

import '../common/app_bar.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {

  final TextEditingController oldPassController = TextEditingController();
  final TextEditingController newPassController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();

  bool isLoading = false;


  Future<void> changePassword() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    String oldPass = oldPassController.text.trim();
    String newPass = newPassController.text.trim();
    String confirmPass = confirmPassController.text.trim();


    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      showMsg("All fields are required");
      return;
    }

    if (newPass.length < 6) {
      showMsg("Password must be at least 6 characters");
      return;
    }

    if (newPass != confirmPass) {
      showMsg("Passwords do not match");
      return;
    }

    setState(() => isLoading = true);

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPass,
      );

      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPass);

      showMsg("Password updated successfully");

      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        showMsg("Old password is incorrect");
      } else {
        showMsg(e.message ?? "Error occurred");
      }
    } catch (e) {
      showMsg("Something went wrong");
    }

    setState(() => isLoading = false);
  }
  void showMsg(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,

      appBar: CommonAppBar(title: "Forgot Password"),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            const SizedBox(height: 20),
            TextField(
              controller: oldPassController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Old Password",
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),
            TextField(
              controller: newPassController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "New Password",
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),
            TextField(
              controller: confirmPassController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Confirm Password",
                prefixIcon: const Icon(Icons.lock_reset),
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
                onPressed: isLoading ? null : changePassword,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Update Password",
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
