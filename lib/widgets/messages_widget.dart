import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone/models/message.dart';

import 'message_widget.dart';

class MessagesWidget extends StatefulWidget {
  final uid;
  const MessagesWidget({Key? key, required this.uid}) : super(key: key);

  @override
  State<MessagesWidget> createState() => _MessagesWidgetState();
}

class _MessagesWidgetState extends State<MessagesWidget> {
  get primaryColor => null;
  String chatRoom = '';
  @override
  void initState() {
    // TODO: implement initState
    chatRoom = chatroomId(FirebaseAuth.instance.currentUser!.uid, widget.uid);
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
    return Container(
      child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .doc(chatRoom)
              .collection('messages')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context,
              AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
            final messages = snapshot.data;

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: primaryColor,
                ),
              );
            }
            //display posts
            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              reverse: true,
              itemCount: (snapshot.data! as dynamic).docs.length,
              itemBuilder: (context, index) {
                return MessageWidget(
                  message: (snapshot.data! as dynamic).docs[index],
                  isMe: (snapshot.data! as dynamic).docs[index]['uid'] ==
                      FirebaseAuth.instance.currentUser!.uid,
                );
              },
            );
          }),
    );
  }
}
