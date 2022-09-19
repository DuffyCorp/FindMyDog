import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';

//User model for database
class Message {
  final String uid;
  final String username;
  final createdAt;
  final String profImage;
  final String message;
  final String type;

  const Message({
    required this.uid,
    required this.username,
    required this.createdAt,
    required this.profImage,
    required this.message,
    required this.type,
  });

  //Converts user model to Json format
  Map<String, dynamic> toJson() => {
        "uid": uid,
        "username": username,
        "createdAt": createdAt,
        "profImage": profImage,
        "message": message,
        "type": type,
      };

  //gets all user details from a snapshot
  static Message fromSnap(DocumentSnapshot snap) {
    //get snapshot
    var snapshot = snap.data() as Map<String, dynamic>;

    //return all data formatted for use
    return Message(
      uid: snapshot['uid'],
      username: snapshot['username'],
      createdAt: snapshot['createdAt'],
      profImage: snapshot['profImage'],
      message: snapshot['message'],
      type: snapshot['type'],
    );
  }
}
