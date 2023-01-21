import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';

//User model for database
class User {
  final String email;
  final String uid;
  final String photoUrl;
  final String username;
  final String bio;
  final List followers;
  final List following;
  final int messagesNotification;

  const User({
    required this.email,
    required this.uid,
    required this.photoUrl,
    required this.username,
    required this.bio,
    required this.followers,
    required this.following,
    required this.messagesNotification,
  });

  //Converts user model to Json format
  Map<String, dynamic> toJson() => {
        "username": username,
        "uid": uid,
        "email": email,
        "photoUrl": photoUrl,
        "bio": bio,
        "followers": followers,
        "following": following,
        "messageNotification": messagesNotification,
      };

  //gets all user details from a snapshot
  static User fromSnap(DocumentSnapshot snap) {
    //get snapshot
    var snapshot = snap.data() as Map<String, dynamic>;

    //return all data formatted for use
    return User(
        username: snapshot['username'],
        uid: snapshot['uid'],
        email: snapshot['email'],
        photoUrl: snapshot['photoUrl'],
        bio: snapshot['bio'],
        followers: snapshot['followers'],
        following: snapshot['following'],
        messagesNotification: snapshot['messagesNotification'].toInt());
  }
}
