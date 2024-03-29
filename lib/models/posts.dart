import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';

//User model for database
class Post {
  final String dogStatus;
  final String dogBreed;
  final String dogColor;
  final String description;
  final dogLocation;
  final String address;
  final String uid;
  final String username;
  final String postId;
  final datePublished;
  final String postUrl;
  final String profImage;
  final String what3words;
  final String what3wordsLink;
  final String userEmail;
  final likes;

  const Post({
    required this.dogStatus,
    required this.dogBreed,
    required this.dogColor,
    required this.description,
    required this.dogLocation,
    required this.address,
    required this.uid,
    required this.username,
    required this.postId,
    required this.datePublished,
    required this.postUrl,
    required this.profImage,
    required this.what3words,
    required this.what3wordsLink,
    required this.userEmail,
    required this.likes,
  });

  //Converts user model to Json format
  Map<String, dynamic> toJson() => {
        "dogStatus": dogStatus,
        "dogBreed": dogBreed,
        "dogColor": dogColor,
        "description": description,
        "dogLocation": dogLocation,
        "address": address,
        "uid": uid,
        "username": username,
        "postId": postId,
        "datePublished": datePublished,
        "postUrl": postUrl,
        "profImage": profImage,
        "what3words": what3words,
        "what3wordsLink": what3wordsLink,
        "userEmail": userEmail,
        "likes": likes,
      };

  //gets all user details from a snapshot
  static Post fromSnap(DocumentSnapshot snap) {
    //get snapshot
    var snapshot = snap.data() as Map<String, dynamic>;

    //return all data formatted for use
    return Post(
      dogStatus: snapshot['dogStatus'],
      dogBreed: snapshot['dogBreed'],
      dogColor: snapshot['dogColor'],
      description: snapshot['description'],
      dogLocation: snapshot['dogLocation'],
      address: snapshot['address'],
      uid: snapshot['uid'],
      username: snapshot['username'],
      postId: snapshot['postId'],
      datePublished: snapshot['datePublished'],
      postUrl: snapshot['postUrl'],
      profImage: snapshot['profImage'],
      what3words: snapshot['what3words'],
      what3wordsLink: snapshot['what3wordsLink'],
      userEmail: snapshot['userEmail'],
      likes: snapshot['likes'],
    );
  }
}
