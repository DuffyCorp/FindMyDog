import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:find_my_dog/models/user.dart';
import 'package:find_my_dog/resources/auth_methods.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  final AuthMethods _authMethods = AuthMethods();

  User get getUser => _user!;

  Future<void> refreshUser() async {
    //use method inside users model to get user details
    User user = await _authMethods.getUserDetails();

    //set private variable to user details
    _user = user;

    //notify all listeners that variable has changed
    notifyListeners();
  }
}
