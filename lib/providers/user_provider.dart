import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class UserProvider extends ChangeNotifier {
  User? _user;

  User? get user => _user;

  void updateUser(User? user) {
    _user = user;
    notifyListeners();
  }

 Future<String?> fetchUserName() async {
  if (user != null) {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    
    Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

    
    if (userData != null && userData.containsKey('name')) {
      String? userName = userData['name'] as String?;
      return userName;
    }
  }
  return "You";
}

  

}


