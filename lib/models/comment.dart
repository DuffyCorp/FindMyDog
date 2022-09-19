import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';

//User model for database
class Comment {
  final String profilePic;
  final String name;
  final String uid;
  final String text;
  final String commentId;
  final datePublished;

  const Comment({
    required this.profilePic,
    required this.name,
    required this.uid,
    required this.text,
    required this.commentId,
    required this.datePublished,
  });

  //Converts user model to Json format
  Map<String, dynamic> toJson() => {
        "profilePic": profilePic,
        "name": name,
        "uid": uid,
        "text": text,
        "commentId": commentId,
        "datePublished": datePublished,
      };

  //gets all user details from a snapshot
  static Comment fromSnap(DocumentSnapshot snap) {
    //get snapshot
    var snapshot = snap.data() as Map<String, dynamic>;

    //return all data formatted for use
    return Comment(
      profilePic: snapshot['profilePic'],
      name: snapshot['name'],
      uid: snapshot['uId'],
      text: snapshot['text'],
      commentId: snapshot['commentId'],
      datePublished: snapshot['datePublished'],
    );
  }
}
