// import 'dart:typed_data';

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:uuid/uuid.dart';

// class StorageMethods {
//   final FirebaseStorage storage = FirebaseStorage.instance;
//   final FirebaseAuth auth = FirebaseAuth.instance;

//   Future<String> uploadImageToStorage(Uint8List file,) async {
//     Reference ref = Fire.instance.ref().child(auth.currentUser!.uid);

//     if(isPost) {
//       String id = const Uuid().v1();
//       ref.child(id);
//     }

//     UploadTask uploadTask = ref.putData(file);
//     TaskSnapshot snap = await uploadTask;
//     String downloadUrl = await snap.ref.getDownloadURL();
//     return downloadUrl;
//   }

//   // Future<String> uploadPostDesToStorage(String childName, String des) async {
//   //   Reference ref = storage.ref().child(childName).child(auth.currentUser!.uid);
//   //   UploadTask uploadTask = ref.putString(des);
//   //   TaskSnapshot snap = await uploadTask;
//   //   String downloadUrl = await snap.ref.getDownloadURL();
//   //   return downloadUrl;
//   // }

//   // Future<String> uploadPostImageToStorage(String childName, Uint8List file) async {
//   //   Reference ref = storage.ref().child(childName).child(auth.currentUser!.uid);
//   //   UploadTask uploadTask = ref.putData(file);
//   //   TaskSnapshot snap = await uploadTask;
//   //   String downloadUrl = await snap.ref.getDownloadURL();
//   //   return downloadUrl;
//   // }
// }