// ignore_for_file: unnecessary_brace_in_string_interps

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone/screens/chat_screen.dart';
import 'package:instagram_clone/widgets/message_subtitle.dart';

import '../utils/colors.dart';

class MessagesScreen extends StatefulWidget {
  final PageController controller;
  const MessagesScreen({Key? key, required this.controller}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  var userData = {};
  String subtitle = "";
  String message = "";

  @override
  void initState() {
    super.initState();
  }

  String chatroomId(String user1, String user2) {
    if (user1[0].toLowerCase().codeUnits[0] >
        user2.toLowerCase()[0].codeUnits[0]) {
      return "$user1$user2";
    } else {
      return "$user2$user1";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
          ),
          onPressed: () {
            widget.controller.animateToPage(
              0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.ease,
            );
          },
        ),
        title: const Text('Messages'),
        centerTitle: false,
      ),
      body: Center(
        child: FutureBuilder(
          future: FirebaseFirestore.instance
              .collection('users')
              .where(
                'uid',
                isNotEqualTo: FirebaseAuth.instance.currentUser!.uid,
              )
              .orderBy('uid', descending: true)
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  color: primaryColor,
                ),
              );
            }

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: (snapshot.data! as dynamic).docs.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () async {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          uid: (snapshot.data! as dynamic).docs[index]['uid'],
                        ),
                      ),
                    );
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .update(
                      {
                        "currentlyMessaging":
                            (snapshot.data! as dynamic).docs[index]['uid'],
                      },
                    );
                  },
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                        (snapshot.data! as dynamic).docs[index]['photoUrl'],
                      ),
                    ),
                    title: Text(
                      (snapshot.data! as dynamic).docs[index]['username'],
                    ),
                    subtitle: MessageSubtitle(
                      uid: (snapshot.data! as dynamic).docs[index]['uid'],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
