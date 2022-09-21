import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MessageSubtitle extends StatefulWidget {
  final String uid;
  const MessageSubtitle({super.key, required this.uid});

  @override
  State<MessageSubtitle> createState() => _MessageSubtitleState();
}

class _MessageSubtitleState extends State<MessageSubtitle> {
  String subtitle = "";

  String message = "";

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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("chats")
          .doc(chatroomId(widget.uid, FirebaseAuth.instance.currentUser!.uid))
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading...");
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Text("Start messaging");
        }
        if (snapshot.hasData) {
          (snapshot.data! as dynamic).docs[0]['uid'] !=
                  FirebaseAuth.instance.currentUser!.uid
              ? subtitle = (snapshot.data! as dynamic).docs[0]['username']
              : subtitle = "You";
          (snapshot.data! as dynamic).docs[0]['type'] != "img"
              ? message = (snapshot.data! as dynamic).docs[0]['message']
              : message = "Sent a Photo";
          return Text(
            "${subtitle}: ${message}",
            style: (snapshot.data! as dynamic).docs[0]['uid'] !=
                    FirebaseAuth.instance.currentUser!.uid
                ? (snapshot.data! as dynamic).docs[0]['read'] == false
                    ? const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      )
                    : const TextStyle()
                : const TextStyle(),
          );
        } else {
          return const Text("Start messaging");
        }
      },
    );
  }
}
