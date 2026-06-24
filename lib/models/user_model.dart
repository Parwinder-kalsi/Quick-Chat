
class UserModel {
  String? name;
  String? email;
  String? uid;
  String? imageUrl;

  UserModel({this.name, this.email, this.uid, this.imageUrl});

  UserModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    email = json["email"];
    uid = json["uid"];
    imageUrl = json['image'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['name'] = name!;
    data['email'] = email;
    data['uid'] = uid;
    data['image'] = imageUrl;
    return data;
  }
}
