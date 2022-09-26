import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

import '../utils/colors.dart';
import '../utils/global_variables.dart';
import 'chat_screen.dart';

class NewChat extends StatefulWidget {
  const NewChat({super.key});

  @override
  State<NewChat> createState() => _NewChatState();
}

class _NewChatState extends State<NewChat> {
  final TextEditingController searchController = TextEditingController();
  bool isShowUsers = false;
  bool isLoading = false;
  List<DocumentSnapshot> followList = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getData();
  }

  @override
  void dispose() {
    super.dispose();
    searchController.dispose();
  }

  getData() async {
    List<DocumentSnapshot> followers = [];

    final currentUserSnapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    List<String> followUids =
        List.from(currentUserSnapshot.data()!["following"]);

    //Loop through list
    for (int i = 0; i < followUids.length; i++) {
      var followId = followUids[i];

      var userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(followId)
          .get();

      //store user data
      var data = userSnap;

      followers.add(data);
    }

    // List<String> followerUids =
    //     List.from(currentUserSnapshot.data()!["followers"]);

    // //Loop through list
    // for (int i = 0; i < followerUids.length; i++) {
    //   var followerId = followerUids[i];

    //   var userSnap = await FirebaseFirestore.instance
    //       .collection('users')
    //       .doc(followerId)
    //       .get();

    //   //store user data
    //   var data = userSnap;

    //   followers.add(data);
    // }

    setState(
      () {
        followList = followers;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        title: TextFormField(
          controller: searchController,
          decoration: const InputDecoration(
            labelText: 'Search for a user',
          ),
          onFieldSubmitted: (String _) {
            setState(
              () {
                isLoading = true;
                isShowUsers = true;
                isLoading = false;
              },
            );
          },
        ),
      ),
      body: isShowUsers
          ? FutureBuilder(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .where('username',
                      isGreaterThanOrEqualTo: searchController.text)
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
                  shrinkWrap: true,
                  itemCount: (snapshot.data! as dynamic).docs.length,
                  itemBuilder: (context, index) {
                    if ((snapshot.data! as dynamic).docs[index]['uid'] !=
                        FirebaseAuth.instance.currentUser!.uid) {
                      return InkWell(
                        onTap: () async {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                uid: (snapshot.data! as dynamic).docs[index]
                                    ['uid'],
                              ),
                            ),
                          );
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .update(
                            {
                              "currentlyMessaging": (snapshot.data! as dynamic)
                                  .docs[index]['uid'],
                            },
                          );
                        },
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(
                              (snapshot.data! as dynamic).docs[index]
                                  ['photoUrl'],
                            ),
                          ),
                          title: Text(
                            (snapshot.data! as dynamic).docs[index]['username'],
                          ),
                        ),
                      );
                    } else {
                      return Column();
                    }
                  },
                );
              },
            )
          : followList == []
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Column(
                  children: [
                    const Text("Following"),
                    ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: followList.length,
                      itemBuilder: (context, index) {
                        var followersItem =
                            followList[index].data()! as Map<String, dynamic>;

                        return followersTile(followersItem["photoUrl"],
                            followersItem["uid"], followersItem["username"]);
                      },
                    ),
                  ],
                ),
    );
  }

  Widget followersTile(String photoUrl, String uid, String username) {
    return InkWell(
      onTap: () async {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              uid: uid,
            ),
          ),
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update(
          {
            "currentlyMessaging": uid,
          },
        );
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(
            photoUrl,
          ),
        ),
        title: Text(
          username,
        ),
      ),
    );
  }
}
