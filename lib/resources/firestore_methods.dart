import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_my_dog/models/dogAccount.dart';
import 'package:find_my_dog/utils/global_variables.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:find_my_dog/models/comment.dart';
import 'package:find_my_dog/models/message.dart';
import 'package:find_my_dog/models/posts.dart';
import 'package:find_my_dog/resources/storage_methods.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:what3words/what3words.dart' as w3w;

class FirestoreMethods {
  final geo = Geoflutterfire();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? notifApi = dotenv.env['FCM_API_KEY'];

  String? w3wApi = dotenv.env['WHAT3WORDSKEY'];

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

  Future<List<DocumentSnapshot<Object?>>> getNearbyUsers(
    LatLng centerPoint,
  ) async {
    // GeoFirePoint center = geo.point(
    //     latitude: centerPoint.latitude, longitude: centerPoint.longitude);

    // var collectionReference = _firestore.collection('users');

    // // 5 miles in km a.k.a 8km
    // double radius = 8;
    // String field = 'position';

    // Stream<List<DocumentSnapshot<Object?>>> users = geo
    //     .collection(collectionRef: collectionReference)
    //     .within(center: center, radius: radius, field: field, strictMode: true);

    // return users;
    List<DocumentSnapshot<Object?>> ret = [];

    GeoFirePoint center = geo.point(
        latitude: centerPoint.latitude, longitude: centerPoint.longitude);
    await geo
        .collection(collectionRef: _firestore.collection("users"))
        .within(center: center, radius: 8, field: 'position')
        .first
        .then((docs) {
      Future.forEach(docs, (DocumentSnapshot doc) {
        // parse place
        ret.add(doc);
      }).whenComplete(() {
        return;
      });
    });
    return ret;
  }

  Future<String> uploadDogAccount(
    String dogBreed,
    String dogColor,
    String description,
    Uint8List file,
  ) async {
    String res = "some error occurred";
    try {
      //create dogAccount id
      String dogID = const Uuid().v1();

      String photoUrl =
          await StorageMethods().uploadImageToStorage('posts', file, true);

      //create post
      DogAccount dogAccount = DogAccount(
        ownerID: _auth.currentUser!.uid,
        dogBreed: dogBreed,
        dogColor: dogColor,
        description: description,
        file: photoUrl,
        uid: dogID,
      );

      //Add post to database
      _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection("dogs")
          .doc(dogID)
          .set(
            dogAccount.toJson(),
          );

      res = "success";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  //upload posts to firestore
  Future<String> uploadPost(
      String dogStatus,
      String dogBreed,
      String dogColor,
      LatLng dogLocation,
      String description,
      Uint8List? file,
      String uid,
      String username,
      String profImage,
      String postId,
      [String dogAccountImage = ""]) async {
    //set default error message
    String res = "some error occurred";
    try {
      String photoUrl = "";
      if (dogAccountImage != "") {
        photoUrl = dogAccountImage;
      } else {
        //store photo in firebase storage and get downloadable url link
        photoUrl =
            await StorageMethods().uploadImageToStorage('posts', file!, true);
      }

      var api = w3w.What3WordsV3(w3wApi.toString());

      var words = await api
          .convertTo3wa(
              w3w.Coordinates(dogLocation.latitude, dogLocation.longitude))
          .language('en')
          .execute();

      print('Words: ${words.data()?.toJson()["words"]}');

      List<Placemark> placemarks = await placemarkFromCoordinates(
          dogLocation.latitude, dogLocation.longitude);
      Placemark place = placemarks[0];
      String address = "${place.locality}";

      if (address == '') {
        address = "${place.postalCode}";
      }

      GeoFirePoint postLocation = geo.point(
          latitude: dogLocation.latitude, longitude: dogLocation.longitude);

      //create post
      Post post = Post(
        dogStatus: dogStatus,
        dogBreed: dogBreed,
        dogColor: dogColor,
        description: description,
        dogLocation: postLocation.data,
        address: address,
        uid: uid,
        username: username,
        postId: postId,
        datePublished: DateTime.now(),
        postUrl: photoUrl,
        profImage: profImage,
        what3words: words.data()?.toJson()["words"],
        what3wordsLink: words.data()?.toJson()["map"],
        likes: [],
      );

      //Add post to database
      _firestore.collection('posts').doc(postId).set(
            post.toJson(),
          );

      res = "success";

      sendNotifNearByAll(dogLocation, postId);
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  void sendNotifNearByAll(LatLng centerPoint, String ID) async {
    try {
      List<DocumentSnapshot<Object?>> users = await getNearbyUsers(centerPoint);

      users.forEach((DocumentSnapshot document) {
        final data = document.data() as Map<String, dynamic>;

        if (data["uid"] != _auth.currentUser!.uid) {
          if (data["deviceToken"].toString() != "unavailable") {
            final String name = data["username"];

            var notifData = {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'id': '1',
              'status': 'done',
              'screen': 'post',
              'uid': ID,
            };
            sendPushMessage(data["deviceToken"], "Lost Dog Near by",
                'Find My Dog', notifData);
          } else {
            //SEND TEXT
          }
        }
      });
    } catch (err) {
      print(err.toString());
    }
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

        print("Testing doc");

        final refMessages = _firestore.collection('chats/$chatRoom/messages');

        await refMessages.add(
          newMessage.toJson(),
        );

        await FirebaseFirestore.instance.collection('chats').doc(chatRoom).set(
          {
            "lastMessaged": newMessage.createdAt,
            "users": [
              userData["uid"],
              myData["uid"],
            ]
          },
          SetOptions(merge: true),
        );

        if (userData['messagesNotification'] < 0) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(targetUid)
              .update(
            {
              "messagesNotification": 0,
            },
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
          'Authorization': 'key=$notifApi',
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
      print("ERROR $e");
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

        await FirebaseFirestore.instance.collection('chats').doc(chatRoom).set(
          {
            "lastMessaged": newMessage.createdAt,
            "users": [
              userData["uid"],
              myData["uid"],
            ]
          },
          SetOptions(merge: true),
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
