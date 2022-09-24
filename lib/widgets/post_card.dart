import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:instagram_clone/models/user.dart' as data;
import 'package:instagram_clone/providers/users_provider.dart';
import 'package:instagram_clone/resources/firestore_methods.dart';
import 'package:instagram_clone/screens/comments_screen.dart';
import 'package:instagram_clone/utils/colors.dart';
import 'package:instagram_clone/utils/global_variables.dart';
import 'package:instagram_clone/utils/utils.dart';
import 'package:instagram_clone/widgets/like_animation.dart';
import 'package:instagram_clone/widgets/show_image.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../providers/location_provider.dart';
import '../screens/profile_screen.dart';

class PostCard extends StatefulWidget {
  final snap;
  const PostCard({
    Key? key,
    required this.snap,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool isLikeAnimating = false;
  int commentLen = 0;
  bool isLoading = true;
  double distance = 0;
  bool showDetails = false;
  LatLng? position;
  LocationData? _currentLocation;

  Color headerColor = Colors.red;

  final Completer<GoogleMapController> _controller = Completer();

  @override
  void initState() {
    if (currentLocation == null) {
      getCurrentLocation();
    } else {
      _currentLocation = currentLocation;
    }
    getComments();
    setState(() {
      GeoPoint geoPoint = widget.snap['dogLocation'];
      position = LatLng(geoPoint.latitude, geoPoint.longitude);
    });
    getDistance();
    setState(() {
      isLoading = false;
      if (widget.snap['dogStatus'] == 'Found') {
        headerColor = accentColor;
      }
    });
    super.initState();
  }

  void getCurrentLocation() async {
    Location location = Location();

    location.getLocation().then(
      (newLocation) {
        setState(() {
          _currentLocation = newLocation;
          currentLocation = newLocation;
        });
      },
    );
  }

  void getDistance() async {
    double newDistance = calculateDistance(
      position!.latitude,
      position!.longitude,
      _currentLocation!.latitude,
      _currentLocation!.longitude,
    );
    setState(() {
      distance = newDistance;
    });
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    var result = 12742 * asin(sqrt(a));
    setState(() {
      isLoading = false;
    });
    return double.parse(result.toStringAsFixed(2));
  }

  void getComments() async {
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.snap['postId'])
          .collection('comments')
          .get();

      setState(() {
        commentLen = snap.docs.length;
      });
    } catch (err) {
      showSnackBar(err.toString(), context);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final data.User user = Provider.of<UserProvider>(context).getUser;
    final width = MediaQuery.of(context).size.width;

    return isLoading == true
        ? const Center(
            child: CircularProgressIndicator(
              color: primaryColor,
            ),
          )
        : Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              //borderRadius: const BorderRadius.all(Radius.circular(25)),
              border: Border.all(
                color: width > webScreenSize
                    ? secondaryColor
                    : mobileBackgroundColor,
              ),
              color: mobileBackgroundColor,
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 10,
            ),
            child: Column(
              children: [
                //Header section
                Container(
                  color: headerColor,
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 16,
                  ).copyWith(right: 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.snap['dogStatus'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 8,
                              ),
                              child: Text(
                                widget.snap['dogBreed'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      widget.snap['uid'] ==
                              FirebaseAuth.instance.currentUser!.uid
                          ? IconButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return SimpleDialog(
                                      title: const Text('Post Options'),
                                      children: [
                                        SimpleDialogOption(
                                          padding: const EdgeInsets.all(20),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: const [
                                              Icon(Icons.delete),
                                              Text(' Delete post'),
                                            ],
                                          ),
                                          onPressed: () async {
                                            FirestoreMethods().deletePost(
                                              widget.snap['postId'],
                                            );
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        SimpleDialogOption(
                                          padding: const EdgeInsets.all(20),
                                          child: const Text('Cancel'),
                                          onPressed: () async {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              icon: const Icon(Icons.more_vert),
                            )
                          : const SizedBox(
                              width: 24,
                              height: 24,
                            ),
                    ],
                  ),
                ),

                //Image section
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ShowImage(imageUrl: widget.snap['postUrl']),
                      ),
                    );
                  },
                  onDoubleTap: () async {
                    await FirestoreMethods().likePost(
                      widget.snap['postId'],
                      user.uid,
                      widget.snap['likes'],
                    );
                    setState(() {
                      isLikeAnimating = true;
                    });
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.35,
                        width: double.infinity,
                        child: Image.network(
                          widget.snap['postUrl'],
                          fit: BoxFit.cover,
                        ),
                      ),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isLikeAnimating ? 1 : 0,
                        child: LikeAnimation(
                          isAnimating: isLikeAnimating,
                          duration: const Duration(
                            milliseconds: 400,
                          ),
                          onEnd: () {
                            setState(
                              () {
                                isLikeAnimating = false;
                              },
                            );
                          },
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 120,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // LIKE COMMENT SECTION
                Column(
                  children: [
                    Row(
                      children: [
                        LikeAnimation(
                          isAnimating: widget.snap['likes'].contains(user.uid),
                          smallLike: true,
                          child: IconButton(
                            onPressed: () async {
                              await FirestoreMethods().likePost(
                                widget.snap['postId'],
                                user.uid,
                                widget.snap['likes'],
                              );
                            },
                            icon: widget.snap['likes'].contains(user.uid)
                                ? const Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                  )
                                : const Icon(
                                    Icons.favorite_outline,
                                  ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CommentsScreen(
                                snap: widget.snap,
                              ),
                            ),
                          ),
                          icon: const Icon(
                            Icons.comment_outlined,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            showSnackBar('send post', context);
                          },
                          icon: const Icon(
                            Icons.share_outlined,
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: widget.snap['uid'] ==
                                    FirebaseAuth.instance.currentUser!.uid
                                ? IconButton(
                                    onPressed: () {
                                      showSnackBar('print post', context);
                                    },
                                    icon: const Icon(
                                      Icons.print_outlined,
                                    ),
                                  )
                                : Container(),
                          ),
                        )
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 8,
                      ),
                      child: Row(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.snap['address'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 8,
                                    ),
                                    child: distance == 0
                                        ? const Text(
                                            "Measuring...",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          )
                                        : Text(
                                            "- ${distance} KM away",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 24,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  DateFormat.yMMMd().format(
                                    widget.snap['datePublished'].toDate(),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: secondaryColor,
                                  ),
                                ),
                              ),
                              DefaultTextStyle(
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle2!
                                    .copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                child: Text(
                                  '${widget.snap['likes'].length} likes',
                                  style: Theme.of(context).textTheme.bodyText2,
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      showDetails = !showDetails;
                                    });
                                  },
                                  icon: showDetails
                                      ? const Icon(
                                          Icons.arrow_upward,
                                          color: primaryColor,
                                        )
                                      : const Icon(
                                          Icons.arrow_downward,
                                          color: primaryColor,
                                        ),
                                ),
                                const Text('More Details')
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                //DESCRIPTION AND NUMBER OF COMMENTS
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                ),

                showDetails
                    ?
                    //USERNAME AND DESCRIPTION
                    Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(
                            top: 8,
                          ),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    InkWell(
                                      onTap: FirebaseAuth
                                                  .instance.currentUser!.uid !=
                                              widget.snap['uid']
                                          ? () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ProfileScreen(
                                                    uid: widget.snap['uid'],
                                                  ),
                                                ),
                                              );
                                            }
                                          : () {},
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundImage: NetworkImage(
                                                widget.snap['profImage']),
                                          ),
                                          Text(
                                            widget.snap['username'].toString(),
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      height: 24,
                                    ),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.8,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          RichText(
                                            text: TextSpan(
                                              style: const TextStyle(
                                                  color: primaryColor),
                                              children: [
                                                const TextSpan(
                                                  text: 'Dog Breed:',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text:
                                                      ' ${widget.snap['dogBreed']}',
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            height: 12,
                                          ),
                                          RichText(
                                            text: TextSpan(
                                              style: const TextStyle(
                                                  color: primaryColor),
                                              children: [
                                                const TextSpan(
                                                  text: 'Dog Color:',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text:
                                                      ' ${widget.snap['dogColor']}',
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            height: 12,
                                          ),
                                          RichText(
                                            text: TextSpan(
                                              style: const TextStyle(
                                                  color: primaryColor),
                                              children: [
                                                const TextSpan(
                                                  text: 'Description:',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text:
                                                      ' ${widget.snap['description']}',
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      height: 24,
                                    ),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        RichText(
                                          text: const TextSpan(
                                            style:
                                                TextStyle(color: primaryColor),
                                            children: [
                                              TextSpan(
                                                text: 'Dog Location:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          height: 300,
                                          width: 350,
                                          child: GoogleMap(
                                            tiltGesturesEnabled: false,
                                            zoomGesturesEnabled: false,
                                            rotateGesturesEnabled: false,
                                            scrollGesturesEnabled: false,
                                            mapType: MapType.normal,
                                            zoomControlsEnabled: false,
                                            markers: {
                                              Marker(
                                                infoWindow: InfoWindow(
                                                    title:
                                                        '${widget.snap['dogStatus']} ${widget.snap['dogBreed']}'),
                                                markerId: const MarkerId(
                                                    "dogLocation"),
                                                icon: widget.snap[
                                                            'dogStatus'] ==
                                                        'Found'
                                                    ? BitmapDescriptor
                                                        .defaultMarkerWithHue(
                                                            BitmapDescriptor
                                                                .hueGreen)
                                                    : BitmapDescriptor
                                                        .defaultMarker,
                                                position: LatLng(
                                                  position!.latitude,
                                                  position!.longitude,
                                                ),
                                              )
                                            },
                                            initialCameraPosition:
                                                CameraPosition(
                                              target: LatLng(
                                                position!.latitude,
                                                position!.longitude,
                                              ),
                                              zoom: 13,
                                            ),
                                            onMapCreated: (GoogleMapController
                                                controller) {
                                              _controller.complete(controller);
                                            },
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Container(),
              ],
            ),
          );
  }
}
