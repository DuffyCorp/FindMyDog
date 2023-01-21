import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_my_dog/screens/new_dog_account.dart';
import 'package:find_my_dog/screens/view_dog_account.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:find_my_dog/resources/auth_methods.dart';
import 'package:find_my_dog/resources/firestore_methods.dart';
import 'package:find_my_dog/screens/chat_screen.dart';
import 'package:find_my_dog/screens/login_screen.dart';
import 'package:find_my_dog/screens/post_screen.dart';
import 'package:find_my_dog/screens/settings_screen.dart';
import 'package:find_my_dog/utils/colors.dart';
import 'package:find_my_dog/utils/utils.dart';
import 'package:find_my_dog/widgets/follow_button.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  const ProfileScreen({Key? key, this.uid = ''}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  var userData = {};
  int postLen = 0;
  int followers = 0;
  int following = 0;
  String uid = '';
  bool isFollowing = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.uid == '') {
      setState(() {
        uid = FirebaseAuth.instance.currentUser!.uid;
      });
    } else {
      setState(() {
        uid = widget.uid;
      });
    }

    getData();
  }

  //method to get user data
  getData() async {
    setState(() {
      isLoading = true;
    });
    try {
      //get user data from firebase
      var userSnap =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      //get post length
      var postSnap = await FirebaseFirestore.instance
          .collection('posts')
          .where(
            'uid',
            isEqualTo: uid,
          )
          .get();

      //store user data
      userData = userSnap.data()!;

      //store how many posts
      postLen = postSnap.docs.length;

      //store followers
      followers = userSnap.data()!['followers'].length;

      //store following
      following = userSnap.data()!['following'].length;

      //check if user is following
      isFollowing = userSnap.data()!['followers'].contains(
            FirebaseAuth.instance.currentUser!.uid,
          );

      setState(() {});
    } catch (err) {
      showSnackBar(
        err.toString(),
        context,
      );
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(
            child: CircularProgressIndicator(
              color: primaryColor,
            ),
          )
        : Scaffold(
            appBar: AppBar(
              backgroundColor: mobileBackgroundColor,
              title: Text(userData['username']),
              centerTitle: false,
              actions: [
                FirebaseAuth.instance.currentUser!.uid == uid
                    ? IconButton(
                        icon: const Icon(
                          Icons.settings,
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SettingScreen(),
                          ),
                        ),
                      )
                    : Container()
              ],
            ),
            //body
            body: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.grey,
                            backgroundImage: NetworkImage(
                              userData['photoUrl'],
                            ),
                            radius: 40,
                          ),

                          //stats
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    buildStatColumn(postLen, "posts"),
                                    buildStatColumn(followers, "followers"),
                                    buildStatColumn(following, "following"),
                                  ],
                                ),
                                //Buttons
                                Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        FirebaseAuth.instance.currentUser!
                                                    .uid ==
                                                uid
                                            ? Container()
                                            : FollowButton(
                                                backgroundColor:
                                                    mobileBackgroundColor,
                                                borderColor: Colors.grey,
                                                text: 'Message',
                                                textColor: primaryColor,
                                                function: () async {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            ChatScreen(
                                                                uid: uid)),
                                                  );
                                                },
                                              ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        FirebaseAuth.instance.currentUser!
                                                    .uid ==
                                                uid
                                            ? FollowButton(
                                                backgroundColor:
                                                    mobileBackgroundColor,
                                                borderColor: Colors.grey,
                                                text: 'Edit Profile',
                                                textColor: primaryColor,
                                                function: () async {
                                                  showSnackBar(
                                                      'edit profile', context);
                                                },
                                              )
                                            : isFollowing
                                                ? FollowButton(
                                                    backgroundColor:
                                                        Colors.white,
                                                    borderColor: Colors.grey,
                                                    text: 'Unfollow',
                                                    textColor: Colors.black,
                                                    function: () async {
                                                      await FirestoreMethods()
                                                          .followUser(
                                                        FirebaseAuth.instance
                                                            .currentUser!.uid,
                                                        userData['uid'],
                                                      );
                                                      setState(() {
                                                        isFollowing = false;
                                                        followers--;
                                                      });
                                                    },
                                                  )
                                                : FollowButton(
                                                    backgroundColor:
                                                        Colors.blue,
                                                    borderColor: Colors.blue,
                                                    text: 'Follow',
                                                    textColor: Colors.white,
                                                    function: () async {
                                                      await FirestoreMethods()
                                                          .followUser(
                                                        FirebaseAuth.instance
                                                            .currentUser!.uid,
                                                        userData['uid'],
                                                      );
                                                      setState(() {
                                                        isFollowing = true;
                                                        followers++;
                                                      });
                                                    },
                                                  )
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(top: 15),
                        child: Text(
                          userData['username'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(userData['bio']),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  color: Colors.grey,
                ),
                FirebaseAuth.instance.currentUser!.uid == uid
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("Dogs"),
                          Container(
                            height: 120,
                            width: double.infinity,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(uid)
                                    .collection("dogs")
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                          color: Colors.white),
                                    );
                                  }
                                  if (!snapshot.hasData) {
                                    return Container();
                                  }
                                  return ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: (snapshot.data! as dynamic)
                                            .docs
                                            .length +
                                        1,
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    itemBuilder: (context, index) {
                                      if (index == 0) {
                                        return addDogAccount(context);
                                      } else {
                                        DocumentSnapshot snap =
                                            (snapshot.data! as dynamic)
                                                .docs[index - 1];
                                        return Row(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: accentColor
                                                      .withOpacity(0.80),
                                                  width: 3,
                                                ),
                                              ),
                                              child: SizedBox(
                                                width: 70,
                                                height: 70,
                                                child: FittedBox(
                                                  fit: BoxFit.contain,
                                                  child: InkWell(
                                                    onTap: () {
                                                      Navigator.of(context)
                                                          .push(
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              ViewDogAccount(
                                                                  snap: snap),
                                                        ),
                                                      );
                                                    },
                                                    child: CircleAvatar(
                                                      radius: 35,
                                                      backgroundImage:
                                                          NetworkImage(
                                                        snap['file'],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 12,
                                            ),
                                          ],
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                          const Divider(
                            color: Colors.grey,
                          ),
                        ],
                      )
                    : SizedBox(),
                FutureBuilder(
                    future: FirebaseFirestore.instance
                        .collection('posts')
                        .where('uid', isEqualTo: uid)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: primaryColor,
                          ),
                        );
                      }

                      return GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: (snapshot.data! as dynamic).docs.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 5,
                          mainAxisSpacing: 1.5,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          DocumentSnapshot snap =
                              (snapshot.data! as dynamic).docs[index];

                          return InkWell(
                            onTap: () {
                              //showSnackBar(snap['postId'], context);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => PostScreen(
                                    snap: snap,
                                    uid: FirebaseAuth.instance.currentUser!.uid,
                                    //postUid: snap['postId'],
                                  ),
                                ),
                              );
                            },
                            child: Image(
                              image: NetworkImage(
                                snap['postUrl'],
                              ),
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      );
                    })
              ],
            ),
          );
  }

  Column buildStatColumn(
    int num,
    String label,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          num.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: const EdgeInsets.only(
            top: 4,
          ),
          child: Text(
            label.toString(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}

Widget addDogAccount(context) {
  return Row(
    children: [
      InkWell(
        onTap: () => {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NewDogAccountScreen(),
            ),
          ),
        },
        child: Container(
          height: 70,
          width: 70,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
      ),
      SizedBox(
        width: 12,
      ),
    ],
  );
}
