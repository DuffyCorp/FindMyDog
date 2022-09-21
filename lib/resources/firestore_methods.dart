import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:instagram_clone/models/comment.dart';
import 'package:instagram_clone/models/message.dart';
import 'package:instagram_clone/models/posts.dart';
import 'package:instagram_clone/resources/storage_methods.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirestoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? api = dotenv.env['FCM_API_KEY'];

  Future<String> getLocation(LatLng dogLocation) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
        dogLocation.latitude, dogLocation.longitude);
    Placemark place = placemarks[0];
    String address = "${place.locality}";

    if (address == '') {
      address = "${place.postalCode}";
    }

    return address;
  }

  //upload posts to firestore
  Future<String> uploadPost(
      String dogStatus,
      String dogBreed,
      String dogColor,
      LatLng dogLocation,
      String description,
      Uint8List file,
      String uid,
      String username,
      String profImage) async {
    //set default error message
    String res = "some error occurred";
    try {
      //store photo in firebase storage and get downloadable url link
      String photoUrl =
          await StorageMethods().uploadImageToStorage('posts', file, true);

      //create post id
      String postId = const Uuid().v1();

      List<Placemark> placemarks = await placemarkFromCoordinates(
          dogLocation.latitude, dogLocation.longitude);
      Placemark place = placemarks[0];
      String address = "${place.locality}";

      if (address == '') {
        address = "${place.postalCode}";
      }

      //create post
      Post post = Post(
        dogStatus: dogStatus,
        dogBreed: dogBreed,
        dogColor: dogColor,
        description: description,
        dogLocation: GeoPoint(dogLocation.latitude, dogLocation.longitude),
        address: address,
        uid: uid,
        username: username,
        postId: postId,
        datePublished: DateTime.now(),
        postUrl: photoUrl,
        profImage: profImage,
        likes: [],
      );

      //Add post to database
      _firestore.collection('posts').doc(postId).set(
            post.toJson(),
          );
      res = "success";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<void> likePost(String postId, String uid, List likes) async {
    try {
      if (likes.contains(uid)) {
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayRemove([uid]),
        });
      } else {
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayUnion([uid]),
        });
      }
    } catch (err) {
      print(
        err.toString(),
      );
    }

    try {
      DocumentSnapshot snap =
          await _firestore.collection('users').doc(uid).get();

      List likes = (snap.data() as dynamic)['likes'];

      if (likes.contains(postId)) {
        //if the user already likes

        //remove target user from list of following
        await _firestore.collection('users').doc(uid).update({
          'likes': FieldValue.arrayRemove([postId])
        });
      } else {
        //if they havent liked

        //add the target user to list of following
        await _firestore.collection('users').doc(uid).update({
          'likes': FieldValue.arrayUnion([postId])
        });
      }
    } catch (err) {
      print(
        err.toString(),
      );
    }
  }

  Future<void> postComment(String postId, String text, String uid, String name,
      String profilePic) async {
    try {
      if (text.isNotEmpty) {
        //Create comment ID
        String commentId = const Uuid().v1();

        //create Comment
        Comment comment = Comment(
          profilePic: profilePic,
          name: name,
          uid: uid,
          text: text,
          commentId: commentId,
          datePublished: DateTime.now(),
        );

        await _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .set(
              comment.toJson(),
            );
      } else {
        print('Text is empty');
      }
    } catch (err) {
      print(err.toString());
    }
  }

  //Deleting post
  Future<void> deletePost(String postId) async {
    try {
      _firestore.collection('posts').doc(postId).delete();
    } catch (err) {
      print(err.toString());
    }
  }

  //method to follow users
  Future<void> followUser(
    String uid,
    String followId,
  ) async {
    try {
      DocumentSnapshot snap =
          await _firestore.collection('users').doc(uid).get();

      List following = (snap.data() as dynamic)['following'];

      if (following.contains(followId)) {
        //if the user already is following

        //remove current user from target list of followers
        await _firestore.collection('users').doc(followId).update({
          'followers': FieldValue.arrayRemove([uid])
        });

        //remove target user from list of following
        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayRemove([followId])
        });
      } else {
        //if they arent followimg

        //add the current user to target list of followers
        await _firestore.collection('users').doc(followId).update({
          'followers': FieldValue.arrayUnion([uid])
        });

        //add the target user to list of following
        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayUnion([followId])
        });
      }
    } catch (err) {
      print(
        err.toString(),
      );
    }
  }

  String chatroomId(String user1, String user2) {
    if (user1[0].toLowerCase().codeUnits[0] >
        user2.toLowerCase()[0].codeUnits[0]) {
      return "$user1$user2";
    } else {
      return "$user2$user1";
    }
  }

  Future<void> postMessage(
    String message,
    String myUid,
    String targetUid,
    String myName,
    String myProfilePic,
    String token,
  ) async {
    try {
      if (message.isNotEmpty) {
        //Create comment ID
        String commentId = const Uuid().v1();

        String chatRoom = chatroomId(myUid, targetUid);

        //get user data from firebase
        var userSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUid)
            .get();

        //store user data
        var userData = userSnap.data()!;

        //get user data from firebase
        var mySnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get();

        //store user data
        var myData = mySnap.data()!;

        //create Comment
        Message newMessage = Message(
          profImage: myProfilePic,
          username: myName,
          uid: myUid,
          message: message,
          createdAt: DateTime.now(),
          type: "text",
          read: false,
        );

        final refMessages = _firestore.collection('chats/$chatRoom/messages');

        await refMessages.add(
          newMessage.toJson(),
        );

        if (myData['messagesNotification'] < 0) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(targetUid)
              .update(
            {"messagesNotification": 0},
          );
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUid)
            .update(
          {"messagesNotification": FieldValue.increment(1)},
        );

        print('testing notifications');
        print('target token is $token');
        if (token != 'unavailable') {
          if (userData['status'] == "Offline") {
            var data = {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'id': '1',
              'status': 'done',
              'screen': 'chat',
              'uid': myUid,
            };
            sendPushMessage(token, message, 'Find My Dog - $myName', data);
            print('Success');
          } else {
            if (userData['currentlyMessaging'] != myUid) {
              var data = {
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                'id': '1',
                'status': 'done',
                'screen': 'chat',
                'uid': myUid,
              };
              sendPushMessage(token, message, 'Find My Dog - $myName', data);
              print('Success');
            }
          }
        } else {
          print('Token is unavailable');
        }
      } else {
        print('Text is empty');
      }
    } catch (err) {
      print(err.toString());
    }
  }

  void sendPushMessage(String token, String body, String title, data) async {
    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=${api}',
        },
        body: jsonEncode(
          <String, dynamic>{
            'notification': <String, dynamic>{'body': body, 'title': title},
            'priority': 'high',
            'data': data,
            "to": token,
          },
        ),
      );
    } catch (e) {
      print("error push notification");
    }
  }

  Future<String> postImage(
    String myUid,
    String targetUid,
    String myName,
    String myProfilePic,
    Uint8List file,
    String token,
  ) async {
    String res = "An error occured";
    try {
      if (file.isNotEmpty) {
        //Create comment ID
        String commentId = const Uuid().v1();

        String chatRoom = chatroomId(myUid, targetUid);

        //get user data from firebase
        var userSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUid)
            .get();

        //store user data
        var userData = userSnap.data()!;

        //get current data from firebase
        var mySnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get();

        //store user data
        var myData = mySnap.data()!;

        String photoUrl =
            await StorageMethods().uploadImageToStorage('posts', file, true);

        //create Comment
        Message newMessage = Message(
            profImage: myProfilePic,
            username: myName,
            uid: myUid,
            message: photoUrl,
            createdAt: DateTime.now(),
            type: "img",
            read: false);

        final refMessages = _firestore.collection('chats/$chatRoom/messages');

        await refMessages.add(
          newMessage.toJson(),
        );

        if (myData['messagesNotification'] < 0) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(targetUid)
              .update(
            {"messagesNotification": 0},
          );
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUid)
            .update(
          {"messagesNotification": FieldValue.increment(1)},
        );

        if (token != 'unavailable') {
          if (userData['status'] == "offline") {
            var data = {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'id': '1',
              'status': 'done',
              'screen': 'chat',
              'uid': myUid,
            };
            sendPushMessage(
                token, 'Sent an image', 'Find My Dog - $myName', data);
            print('Success');
          } else {
            if (userData['currentlyMessaging'] != myUid) {
              var data = {
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                'id': '1',
                'status': 'done',
                'screen': 'chat',
                'uid': myUid,
              };
              sendPushMessage(
                  token, 'Sent an image', 'Find My Dog - $myName', data);
              print('Success');
            }
          }
        } else {
          print('Token is unavailable');
        }
        res = "success";
        return res;
      } else {
        return res = 'Text is empty';
      }
    } catch (err) {
      res = err.toString();
      return res;
    }
  }
}
