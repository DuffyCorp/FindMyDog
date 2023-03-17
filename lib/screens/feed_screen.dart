// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:find_my_dog/providers/location_provider.dart';
import 'package:find_my_dog/utils/colors.dart';
import 'package:find_my_dog/utils/global_variables.dart';
import 'package:find_my_dog/utils/utils.dart';
import 'package:find_my_dog/widgets/post_card.dart';
import 'package:location/location.dart';

class FeedScreen extends StatefulWidget {
  final PageController controller;
  const FeedScreen({Key? key, required this.controller}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with AutomaticKeepAliveClientMixin {
  bool get wantKeepAlive => true;
  LocationData? _currentLocation;
  @override
  void initState() {
    // TODO: implement initState
    if (globalCurrentLocation == null) {
      getCurrentLocation();
    } else {
      _currentLocation = globalCurrentLocation;
    }
    super.initState();
  }

  void getCurrentLocation() async {
    Location _location = Location();
    _location.getLocation().then(
      (newLocation) {
        setState(() {
          _currentLocation = newLocation;
          globalCurrentLocation = newLocation;
        });
      },
    );
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    var result = 12742 * asin(sqrt(a));
    return double.parse(result.toStringAsFixed(2));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final width = MediaQuery.of(context).size.width;

    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor:
          width > webScreenSize ? webBackgroundColor : mobileBackgroundColor,
      appBar: width > webScreenSize
          ? null
          : AppBar(
              backgroundColor: mobileBackgroundColor,
              centerTitle: false,
              title: const Text('Find My Dog'),
              actions: [
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("users")
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      return GestureDetector(
                        onTap: () {},
                        child: Stack(
                          children: <Widget>[
                            IconButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                widget.controller.animateToPage(
                                  1,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeIn,
                                );
                              },
                              icon: const Icon(
                                Icons.messenger_outline,
                              ),
                            ),
                            snapshot.connectionState == ConnectionState.waiting
                                ? IconButton(
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      widget.controller.animateToPage(
                                        1,
                                        duration:
                                            const Duration(milliseconds: 200),
                                        curve: Curves.easeIn,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.messenger_outline,
                                    ),
                                  )
                                : snapshot.data!['messagesNotification']
                                            .toInt() ==
                                        0
                                    ? Container()
                                    : Positioned(
                                        child: Stack(
                                          children: <Widget>[
                                            const Icon(
                                              Icons.brightness_1,
                                              size: 20.0,
                                              color: accentColor,
                                            ),
                                            Positioned(
                                              top: 3.0,
                                              right: 4.0,
                                              child: Center(
                                                child: Text(
                                                  snapshot.data![
                                                          'messagesNotification']
                                                      .toInt()
                                                      .toString(),
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11.0,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // IconButton(
                //   onPressed: () {
                //     widget.controller.animateToPage(
                //       1,
                //       duration: const Duration(milliseconds: 200),
                //       curve: Curves.easeIn,
                //     );
                //   },
                //   icon: const Icon(
                //     Icons.messenger_outline,
                //   ),
                // ),
              ],
            ),
      body: _currentLocation == null
          ? const Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
          : StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  // .where(
                  //   'uid',
                  //   isNotEqualTo: FirebaseAuth.instance.currentUser!.uid,
                  // )
                  .orderBy(
                    'dogLocation',
                    descending: true,
                  )
                  .snapshots(),
              builder: (context,
                  AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                    ),
                  );
                }
                //display posts
                return ListView.builder(
                  physics: BouncingScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) => Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: width > webScreenSize ? width * 0.3 : 0,
                      vertical: width > webScreenSize ? 15 : 0,
                    ),
                    child: PostCard(
                      snap: snapshot.data!.docs[index].data(),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
