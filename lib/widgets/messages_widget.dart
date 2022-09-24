import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone/models/message.dart';
import 'package:intl/intl.dart';

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
  var date = null;
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

  bool hideProfImage(
      DocumentSnapshot message, DocumentSnapshot previousMessage) {
    final Timestamp messageTimestamp = message['createdAt'] as Timestamp;
    final Timestamp preMessageTimestamp =
        previousMessage['createdAt'] as Timestamp;

    final DateTime messageDateTime = messageTimestamp.toDate();
    final DateTime preMessageDateTime = preMessageTimestamp.toDate();

    final difference = preMessageDateTime.difference(messageDateTime).inSeconds;
    //print("The time difference is $difference");
    //Change difference number
    return (message['uid'] == previousMessage['uid'] &&
        int.parse(difference.toString()) <= 150);
  }

  void readMessage() async {
    int num = 0;
    var user = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    var userData = user.data();

    final query = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatroomId(FirebaseAuth.instance.currentUser!.uid, widget.uid))
        .collection('messages')
        .where('uid', isEqualTo: widget.uid)
        .where('read', isEqualTo: false)
        .get();

    query.docs.forEach((doc) {
      doc.reference.update({'read': true});
    });

    num = query.docs.length;

    if (userData!['messagesNotification'] >= num) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update(
        {
          "messagesNotification": FieldValue.increment(-num),
        },
      );
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update(
        {
          "messagesNotification": 0,
        },
      );
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            );
          }

          if (!snapshot.data!.docs.isEmpty) {
            if ((snapshot.data! as dynamic).docs[0]['read'] == false) {
              readMessage();
            }
          }

          //display posts
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            reverse: true,
            itemCount: (snapshot.data! as dynamic).docs.length,
            itemBuilder: (context, index) {
              var nextDate;

              int range = (snapshot.data! as dynamic).docs.length;

              var indexDate = DateFormat.yMMMd().format(
                (snapshot.data! as dynamic).docs[index]['createdAt'].toDate(),
              );

              if (index == range - 1) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 20, bottom: 10),
                      child: Text(
                        DateFormat.yMMMd().format(
                          (snapshot.data! as dynamic)
                              .docs[index]["createdAt"]
                              .toDate(),
                        ),
                      ),
                    ),
                    MessageWidget(
                      message: (snapshot.data! as dynamic).docs[index],
                      isMe: (snapshot.data! as dynamic).docs[index]['uid'] ==
                          FirebaseAuth.instance.currentUser!.uid,
                      index: index,
                      hideProf: index == 0
                          ? false
                          : hideProfImage(
                              (snapshot.data! as dynamic).docs[index],
                              (snapshot.data! as dynamic).docs[index],
                            ),
                    ),
                  ],
                );
              } else {
                nextDate = DateFormat.yMMMd().format(
                  (snapshot.data! as dynamic)
                      .docs[index + 1]['createdAt']
                      .toDate(),
                );
              }

              if (indexDate == nextDate) {
                //custom code
                return MessageWidget(
                  message: (snapshot.data! as dynamic).docs[index],
                  isMe: (snapshot.data! as dynamic).docs[index]['uid'] ==
                      FirebaseAuth.instance.currentUser!.uid,
                  index: index,
                  hideProf: index == 0
                      ? false
                      : hideProfImage((snapshot.data! as dynamic).docs[index],
                          (snapshot.data! as dynamic).docs[index - 1]),
                );
              } else {
                date = (snapshot.data! as dynamic).docs[index]['createdAt'];
                // custom code
                return Column(
                  children: [
                    const Divider(
                      color: Colors.grey,
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 10),
                      child: Text(
                        DateFormat.yMMMd().format(
                          (snapshot.data! as dynamic)
                              .docs[index]["createdAt"]
                              .toDate(),
                        ),
                      ),
                    ),
                    MessageWidget(
                      message: (snapshot.data! as dynamic).docs[index],
                      isMe: (snapshot.data! as dynamic).docs[index]['uid'] ==
                          FirebaseAuth.instance.currentUser!.uid,
                      index: index,
                      hideProf: index == 0
                          ? false
                          : hideProfImage(
                              (snapshot.data! as dynamic).docs[index],
                              (snapshot.data! as dynamic).docs[index - 1]),
                    ),
                  ],
                );
              }
            },
          );
        },
      ),
    );
  }
}
