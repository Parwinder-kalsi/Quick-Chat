import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:quick_chat/screens/home_screen.dart';
import 'package:quick_chat/screens/login_page.dart';

class AuthController extends GetxController {

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  Future<void> register(
      String name,
      String number,
      String email,
      String password,
      String image,
      ) async {
    try {
      UserCredential userCredential =
      await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String uid = userCredential.user!.uid;
      await firestore.collection("users_qc").doc(uid).set({
        "uid": uid,
        "name": name,
        "number":number,
        "email": email,
        "image":image,
        "createdAt": DateTime.now(),
      });
      Get.snackbar(
        "Success",
        "Account created successfully",
      );
      Get.to(HomeScreen());
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        "Error",
        e.message ?? "Something went wrong",
      );
    } catch (e) {
      Get.snackbar(
        "Firestore Error",
        e.toString(),
      );
    }
  }
  Future<void> login(String email, String password,) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
      Get.snackbar(
        "Success",
        "Login successful",
      );
      Get.to(HomeScreen());
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        "Error",
        e.message ?? "Login failed",
      );
    }
  }
  Future<void> forgot(String email,) async {
    try {
      await auth.sendPasswordResetEmail(email: email,);
      Get.snackbar(
        "Success",
        "Password reset email sent",
      );
      Get.to(LoginPage());
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        "Error",
        e.message ?? "Something went wrong",
      );
    }
  }

}