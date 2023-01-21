import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';

//User model for database
class DogAccount {
  final String ownerID;
  final String dogBreed;
  final String dogColor;
  final String description;
  final String file;
  final String uid;

  const DogAccount({
    required this.ownerID,
    required this.dogBreed,
    required this.dogColor,
    required this.description,
    required this.file,
    required this.uid,
  });

  //Converts user model to Json format
  Map<String, dynamic> toJson() => {
        "ownerID": ownerID,
        "dogBreed": dogBreed,
        "dogColor": dogColor,
        "description": description,
        "file": file,
        "uid": uid,
      };

  //gets all user details from a snapshot
  static DogAccount fromSnap(DocumentSnapshot snap) {
    //get snapshot
    var snapshot = snap.data() as Map<String, dynamic>;

    //return all data formatted for use
    return DogAccount(
        ownerID: snapshot['ownerID'],
        dogBreed: snapshot['dogBreed'],
        dogColor: snapshot['dogColor'],
        description: snapshot['description'],
        file: snapshot['file'],
        uid: snapshot['uid']);
  }
}
