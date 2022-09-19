import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class StorageMethods {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //adding image to firebase storage
  Future<String> uploadImageToStorage(
      String childName, Uint8List file, bool isPost) async {
    //get user ID to reference it to the image
    Reference ref =
        _storage.ref().child(childName).child(_auth.currentUser!.uid);

    //if it is a post change UID
    if (isPost) {
      String id = const Uuid().v1();
      ref = ref.child(id);
    }

    //upload file
    UploadTask uploadTask = ref.putData(file);

    //get info on uploaded image
    TaskSnapshot snap = await uploadTask;

    //set string to the downloadable URL of image
    String downloadUrl = await snap.ref.getDownloadURL();

    //return downloadable URL
    return downloadUrl;
  }
}
