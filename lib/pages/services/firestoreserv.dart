import 'package:cloud_firestore/cloud_firestore.dart';

class Firestoreserv {
  final CollectionReference _inwardCollection =
      FirebaseFirestore.instance.collection('inward');

  final CollectionReference usercoll =
      FirebaseFirestore.instance.collection('users');

  final CollectionReference gradcoll =
      FirebaseFirestore.instance.collection('grading');

  Stream<QuerySnapshot?> getGradStream() {
    return gradcoll.snapshots();
  }
}
