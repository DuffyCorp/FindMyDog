import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:find_my_dog/utils/colors.dart';
import 'package:find_my_dog/widgets/text_field_input.dart';
import 'package:uuid/uuid.dart';

import '../resources/firestore_methods.dart';
import '../utils/utils.dart';

class NewMessageWidget extends StatefulWidget {
  final userId;
  final groupId;
  const NewMessageWidget({
    Key? key,
    required this.userId,
    required this.groupId,
  }) : super(key: key);

  @override
  State<NewMessageWidget> createState() => _NewMessageWidgetState();
}

class _NewMessageWidgetState extends State<NewMessageWidget> {
  //controllers
  final TextEditingController _newMessageController = TextEditingController();
  bool _isLoading = false;
  var userData = {};
  var myData = {};
  Uint8List? imageFile;

  final ImagePicker _picker = ImagePicker();

  void postImage(Uint8List _file) async {
    try {
      setState(() {
        _isLoading = true;
      });
      String res = await FirestoreMethods().postImage(
        FirebaseAuth.instance.currentUser!.uid,
        widget.userId,
        myData['username'],
        myData['photoUrl'],
        _file,
        userData['deviceToken'],
      );

      if (res == "success") {
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        showSnackBar(res, context);
      }
    } catch (err) {
      showSnackBar(err.toString(), context);
    }
  }

  SelectImageType() async {
    return showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text('Upload an Image'),
            children: [
              SimpleDialogOption(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Icon(Icons.camera_alt_rounded),
                    Text(' Take a Photo'),
                  ],
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  Uint8List file = await pickImage(
                    ImageSource.camera,
                  );
                  setState(() {
                    imageFile = file;
                  });
                  postImage(file);
                },
              ),
              SimpleDialogOption(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Icon(Icons.image_rounded),
                    Text(' Select from gallery'),
                  ],
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  Uint8List file = await pickImage(
                    ImageSource.gallery,
                  );
                  setState(() {
                    imageFile = file;
                  });
                  postImage(file);
                },
              ),
              SimpleDialogOption(
                padding: EdgeInsets.all(20),
                child: const Text('Cancel'),
                onPressed: () async {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getData();
  }

  @override
  void dispose() {
    super.dispose();
    _newMessageController.dispose();
  }

  getData() async {
    try {
//get user data from firebase
      var userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      //store user data
      userData = userSnap.data()!;

      var mySnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      //store user data
      myData = mySnap.data()!;
    } catch (err) {
      showSnackBar(
        err.toString(),
        context,
      );
    }
  }

  void sendMessage() async {
    if (_newMessageController.text != '') {
      FocusScope.of(context).unfocus();

      await FirestoreMethods().postMessage(
        _newMessageController.text,
        myData['uid'],
        widget.userId,
        myData['username'],
        myData['photoUrl'],
        userData['deviceToken'],
      );
      setState(() {
        _newMessageController.clear();
      });
    } else {
      showSnackBar('Please enter a message', context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              SelectImageType();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(
            width: 20,
          ),
          Expanded(
            child: TextFieldInput(
              textEditingController: _newMessageController,
              hintText: 'New Message...',
              textInputType: TextInputType.text,
            ),
          ),
          SizedBox(
            width: 20,
          ),
          GestureDetector(
            onTap: () {
              sendMessage();
            },
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor,
              ),
              child: Icon(
                Icons.send,
                color: Colors.white,
              ),
            ),
          )
        ],
      ),
    );
  }
}
