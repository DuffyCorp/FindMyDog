import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:find_my_dog/models/user.dart' as data;
import 'package:find_my_dog/providers/users_provider.dart';
import 'package:find_my_dog/resources/firestore_methods.dart';
import 'package:find_my_dog/screens/comments_screen.dart';
import 'package:find_my_dog/utils/colors.dart';
import 'package:find_my_dog/utils/global_variables.dart';
import 'package:find_my_dog/utils/utils.dart';
import 'package:find_my_dog/widgets/like_animation.dart';
import 'package:find_my_dog/widgets/show_image.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'dart:math';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

enum SocialMedia { facebook, twitter, email, whatsapp }

class _PostCardState extends State<PostCard> {
  bool isLikeAnimating = false;
  int commentLen = 0;
  bool isLoading = true;
  double distance = 0;
  bool showDetails = false;
  LatLng? position;
  LocationData? _currentLocation;

  Color? headerColor;

  final Completer<GoogleMapController> _controller = Completer();

  @override
  void initState() {
    setState(() {
      if (widget.snap['dogStatus'] == 'Found') {
        headerColor = accentColor;
      }
      if (widget.snap['dogStatus'] == 'Stolen') {
        headerColor = Colors.amber;
      }
      if (widget.snap['dogStatus'] == 'Lost') {
        headerColor = Colors.red;
      }
    });
    if (globalCurrentLocation == null) {
      getCurrentLocation();
    } else {
      _currentLocation = globalCurrentLocation;
    }
    getComments();
    setState(() {
      GeoPoint geoPoint = widget.snap['dogLocation']['geopoint'];
      position = LatLng(geoPoint.latitude, geoPoint.longitude);
    });
    getDistance();
    setState(() {
      isLoading = false;
    });
    super.initState();
  }

  void getCurrentLocation() async {
    Location location = Location();

    location.getLocation().then(
      (newLocation) {
        setState(() {
          _currentLocation = newLocation;
          globalCurrentLocation = newLocation;
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

  Future share(SocialMedia socialPlatform) async {
    final subject = "${widget.snap['dogStatus']} ${widget.snap['dogBreed']}";
    final text =
        'Help watch out for this ${widget.snap['dogStatus']} ${widget.snap['dogBreed']}\n\n It was lost on ${DateFormat.yMMMd().format(widget.snap['datePublished'].toDate())}.\n';

    final urlShare = Uri.encodeComponent("${widget.snap['what3wordsLink']}");

    final urls = {
      SocialMedia.facebook:
          'https://www.facebook.com/sharer/sharer.php?u=$urlShare&t=$text',
      SocialMedia.twitter:
          'https://twitter.com/intent/tweet?url=$urlShare&text=$text',
      SocialMedia.email: 'mailto:?subject=$subject&body=$text\n\n$urlShare',
      SocialMedia.whatsapp:
          'https://api.whatsapp.com/send?text=$text\n\n$urlShare',
    };

    final url = urls[socialPlatform]!;

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print("cant launch");
      await launch(url);
    }
  }

  void showSocials() async {
    return showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Share post'),
          children: [
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Icon(Icons.facebook),
                  Text(' Facebook'),
                ],
              ),
              onPressed: () async {
                share(SocialMedia.facebook);
                Navigator.of(context).pop();
              },
            ),
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  FaIcon(FontAwesomeIcons.twitter),
                  Text(' Twitter'),
                ],
              ),
              onPressed: () async {
                share(SocialMedia.twitter);
                Navigator.of(context).pop();
              },
            ),
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Icon(Icons.email),
                  Text(' Email'),
                ],
              ),
              onPressed: () async {
                share(SocialMedia.email);
                Navigator.of(context).pop();
              },
            ),
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Icon(Icons.whatsapp),
                  Text(' Whatsapp'),
                ],
              ),
              onPressed: () async {
                share(SocialMedia.whatsapp);
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
  }

  void printPost() async {
    final doc = pw.Document();

    final provider =
        await flutterImageProvider(NetworkImage(widget.snap['postUrl']));
    print(provider);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Center(
                child: pw.SizedBox(
                  width: double.infinity,
                  child: pw.Center(
                    child: pw.Text(
                      "${widget.snap['dogStatus']} Dog",
                      style: const pw.TextStyle(fontSize: 50),
                    ),
                  ),
                ),
              ),
              pw.Center(
                child: pw.SizedBox(
                  height: 400,
                  width: double.infinity,
                  child: pw.Image(
                    provider,
                    height: 400,
                    width: 400,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      "Lost ${widget.snap['dogBreed']}",
                      style: const pw.TextStyle(fontSize: 40),
                    ),
                    pw.Text(
                      "Date: ${DateFormat.yMMMd().format(widget.snap['datePublished'].toDate())}",
                      style: const pw.TextStyle(fontSize: 30),
                    ),
                    pw.Text(
                      "Color: ${widget.snap['dogColor']}",
                      style: const pw.TextStyle(fontSize: 30),
                    ),
                    pw.Text(
                      "Description: ${widget.snap['description']}",
                      style: const pw.TextStyle(fontSize: 30),
                    ),
                    pw.Text(
                      "W3W: ${widget.snap['what3words']}",
                      style: const pw.TextStyle(fontSize: 30),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    final data.User user = Provider.of<UserProvider>(context).getUser;
    final width = MediaQuery.of(context).size.width;

    if (user == null || isLoading == true) {
      return const Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      );
    } else {
      if (headerColor != null) {
        return Container(
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
                color: widget.snap['dogStatus'] == 'Found'
                    ? accentColor
                    : widget.snap['dogStatus'] == 'Lost'
                        ? Colors.amber
                        : Colors.red,
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
                    widget.snap['uid'] == FirebaseAuth.instance.currentUser!.uid
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
                        : Opacity(
                            opacity: 0,
                            child: IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.more_vert),
                            ),
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
                          //showSnackBar('send post', context);
                          showSocials();
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
                                    printPost();
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
                                          style: const TextStyle(
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 24,
                                  ),
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.8,
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      RichText(
                                        text: const TextSpan(
                                          style: TextStyle(color: primaryColor),
                                          children: [
                                            TextSpan(
                                              text: 'Dog Location:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 12,
                                      ),
                                      RichText(
                                        text: const TextSpan(
                                          style: TextStyle(color: primaryColor),
                                          children: [
                                            TextSpan(
                                              text: 'What 3 words:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        child: RichText(
                                          text: TextSpan(
                                            style:
                                                TextStyle(color: primaryColor),
                                            children: [
                                              TextSpan(
                                                text:
                                                    '${widget.snap["what3words"]}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        onTap: () async {
                                          showSnackBar(
                                              "tapped link ${widget.snap["what3wordsLink"]}",
                                              context);
                                          await launchUrlString(
                                              widget.snap["what3wordsLink"]);
                                        },
                                      ),
                                      const SizedBox(
                                        height: 12,
                                      ),
                                      Center(
                                        child: Container(
                                          height: 300,
                                          width: width - 34,
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
                                                        'Lost'
                                                    ? BitmapDescriptor
                                                        .defaultMarkerWithHue(
                                                            BitmapDescriptor
                                                                .hueOrange)
                                                    : widget.snap[
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
      } else {
        return const Center(
          child: CircularProgressIndicator(
            color: primaryColor,
          ),
        );
      }
    }
  }
}
