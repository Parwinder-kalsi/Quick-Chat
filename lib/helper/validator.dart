import 'package:get/get_utils/src/get_utils/get_utils.dart';

class Validator {
  String? name(String? value) {
    if (value == null || value.isEmpty) {
      return "Name is required";
    }
    return null;
  }
  String? number(String? value) {
    if (value == null || value.isEmpty) {
      return "Number is required";
    }
    return null;
  }
   String? email(String? value) {
     if (value == null || value.isEmpty) {
       return "Email is required";
     }
    else if (!GetUtils.isEmail(value)) {
      return "Enter valid email";
    }
    return null;
  }
   String? password(String? value) {
     if (value == null || value.isEmpty) {
       return "Password is required";
     } else if (value.length < 8) {
       return "Password must be at least 8 characters";
     }
     return null;
   }

   String? confirmPassword(String? value, String? password) {
     if (value == null || value.isEmpty) {
       return "Confirm Password is required";
     } else if (value != password) {
       return "Passwords do not match";
     }
     return null;
   }
  String? forgotPassword(String? value) {
      if (value == null || value.isEmpty) {
        return "Email is required";
      } else if (!GetUtils.isEmail(value)) {
        return "Enter valid email";
      }
      return null;
    }
}