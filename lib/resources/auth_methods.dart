import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:find_my_dog/models/user.dart' as model;
import 'package:find_my_dog/resources/storage_methods.dart';
import 'package:geoflutterfire/geoflutterfire.dart';

import '../models/push_notification.dart';

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final geo = Geoflutterfire();

  //Method for getting user details from Firebase
  Future<model.User> getUserDetails() async {
    //get current user from Firebase auth
    User currentUser = _auth.currentUser!;

    //Grab all details of user from Firebase
    DocumentSnapshot snap =
        await _firestore.collection('users').doc(currentUser.uid).get();

    //Return user details
    return model.User.fromSnap(snap);
  }

  //Sign up user to firebase
  Future<String> signUpUser({
    required String email,
    required String password,
    required String username,
    required String bio,
    required Uint8List file,
  }) async {
    //set default error
    String res = "some error occurred while signing up user";
    try {
      //if all inputs aren't empty
      if (email.isNotEmpty ||
          password.isNotEmpty ||
          username.isNotEmpty ||
          bio.isNotEmpty) {
        //Register user with email and password
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
            email: email, password: password);

        //get downloadable photo url from upload image to storage method from storage_methods.dart
        String photoUrl = await StorageMethods()
            .uploadImageToStorage('profilePics', file, false);

        //Create user
        model.User user = model.User(
          username: username,
          uid: cred.user!.uid,
          email: email,
          bio: bio,
          photoUrl: photoUrl,
          following: [],
          followers: [],
          messagesNotification: 0,
        );

        //add user to database
        await _firestore.collection('users').doc(cred.user!.uid).set(
              user.toJson(),
            );

        //set success response
        res = "success";
      }
    } on FirebaseAuthException catch (err) {
      //EXPAND
      if (err.code == 'invalid-email') {
        res = 'The email is badly formatted';
      } else if (err.code == 'weak-password') {
        res = 'Your password should be at least 6 characters long';
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  //Logging in user
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    //set default error message
    String res = "Some error occurred";

    GeoFirePoint myLocation =
        geo.point(latitude: 12.960632, longitude: 77.641603);

    try {
      //if inputs are not empty
      if (email.isNotEmpty || password.isNotEmpty) {
        //use firebase auth method to sign in with email and password
        await _auth.signInWithEmailAndPassword(
            email: email, password: password);

        FirebaseMessaging.instance.getToken().then((token) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .update({'deviceToken': token, 'position': myLocation.data});
        });

        //set success response
        res = "success";
      } else {
        //let user know fields are empty
        res = "Please enter all the fields";
      }
    } on FirebaseAuthException catch (err) {
      //FINISH ALL ERROR CODES
      if (err.code == 'user-not-found') {
        res = 'User doesnt exist';
      } else if (err.code == 'wrong-password') {
        res = 'Password is incorrect';
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  //sign out user
  Future<void> signOut() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({
      "status": "Offline",
      'deviceToken': 'unavailable',
      "currentlyMessaging": "",
    });
    await _auth.signOut();
  }

  //delete User
  Future<void> deleteUser() async {
    await FirebaseAuth.instance.currentUser!.delete();

    _firestore
        .collection('posts')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .delete();
  }
}
