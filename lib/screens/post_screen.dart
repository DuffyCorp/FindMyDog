import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:find_my_dog/screens/profile_screen.dart';
import 'package:find_my_dog/utils/colors.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../resources/firestore_methods.dart';
import '../utils/global_variables.dart';
import '../utils/utils.dart';
import '../widgets/like_animation.dart';
import '../widgets/show_image.dart';
import 'comments_screen.dart';

class PostScreen extends StatefulWidget {
  final snap;
  final uid;
  final postUid;

  const PostScreen({
    Key? key,
    this.snap = null,
    required this.uid,
    this.postUid = '',
  }) : super(key: key);

  @override
  State<PostScreen> createState() => _PostScreenState();
}

enum SocialMedia { facebook, twitter, email, whatsapp }

class _PostScreenState extends State<PostScreen> {
  var userData = {};
  Color isLost = Colors.red;
  bool isLoading = false;
  bool isLikeAnimating = false;
  bool showDetails = false;
  double distance = 0;
  LatLng? position;
  final Completer<GoogleMapController> _controller = Completer();
  var snap;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  void initState() {
    snap = widget.snap;
    init();
    super.initState();
  }

  void init() async {
    if (snap != null) {
      setState(() {
        if (snap['dogStatus'] == 'Found') {
          isLost = accentColor;
        }
        if (snap['dogStatus'] == 'Lost') {
          isLost = Colors.amber;
        }
      });
      getData();

      getDistance();
    } else {
      // set widget.snap to data
      // call init again
      print('null snap');
      snap = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postUid)
          .get();
      print(snap);
      init();
    }
  }

  void getDistance() async {
    GeoPoint geoPoint = snap['dogLocation']['geopoint'];

    position = LatLng(geoPoint.latitude, geoPoint.longitude);
    double newDistance = calculateDistance(
      position!.latitude,
      position!.longitude,
      globalCurrentLocation!.latitude,
      globalCurrentLocation!.longitude,
    );
    setState(() {
      distance = newDistance;
      isLoading = false;
    });
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

  //method to get user data
  getData() async {
    setState(() {
      isLoading = true;
    });
    try {
      var userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      userData = userSnap.data()!;

      setState(() {});
    } catch (err) {
      showSnackBar(
        err.toString(),
        context,
      );
    }
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
    return snap['dogLocation'] == null
        ? const Center(
            child: CircularProgressIndicator(
              color: primaryColor,
            ),
          )
        : Scaffold(
            appBar: AppBar(
              backgroundColor: isLost,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: Text('${snap['dogStatus']} ${snap['dogBreed']}'),
              centerTitle: false,
            ),
            body: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where(
                    'postId',
                    isEqualTo: snap['postId'],
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
                  physics: const BouncingScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) => Container(
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ShowImage(
                                      imageUrl: (snapshot.data! as dynamic)
                                          .docs[index]['postUrl'],
                                    ),
                                  ),
                                );
                              },
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.35,
                                    width: double.infinity,
                                    child: Image.network(
                                      (snapshot.data! as dynamic).docs[index]
                                          ['postUrl'],
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
                            Column(
                              children: [
                                Row(
                                  children: [
                                    LikeAnimation(
                                      isAnimating: (snapshot.data! as dynamic)
                                          .docs[index]['likes']
                                          .contains(userData['uid']),
                                      smallLike: true,
                                      child: IconButton(
                                        onPressed: () async {
                                          await FirestoreMethods().likePost(
                                            (snapshot.data! as dynamic)
                                                .docs[index]['postId'],
                                            userData['uid'],
                                            (snapshot.data! as dynamic)
                                                .docs[index]['likes'],
                                          );
                                        },
                                        icon: (snapshot.data! as dynamic)
                                                .docs[index]['likes']
                                                .contains(userData['uid'])
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
                                      onPressed: () =>
                                          Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => CommentsScreen(
                                            snap: snap,
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
                                        child: (snapshot.data! as dynamic)
                                                    .docs[index]['uid'] ==
                                                FirebaseAuth
                                                    .instance.currentUser!.uid
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                (snapshot.data! as dynamic)
                                                    .docs[index]['address'],
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
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 18,
                                                        ),
                                                      )
                                                    : Text(
                                                        "- ${distance} KM away",
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 24,
                                                        ),
                                                      ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4),
                                            child: Text(
                                              DateFormat.yMMMd().format(
                                                (snapshot.data! as dynamic)
                                                    .docs[index]
                                                        ['datePublished']
                                                    .toDate(),
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
                                              '${(snapshot.data! as dynamic).docs[index]['likes'].length} likes',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyText2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
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
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Container(
                                                child: InkWell(
                                                  onTap: widget.uid !=
                                                          (snapshot.data!
                                                                  as dynamic)
                                                              .docs[index]['uid']
                                                      ? () {
                                                          Navigator.of(context)
                                                              .push(
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                  ProfileScreen(
                                                                uid: (snapshot
                                                                            .data!
                                                                        as dynamic)
                                                                    .docs[index]['uid'],
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      : () {},
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 24,
                                                        backgroundImage:
                                                            NetworkImage((snapshot
                                                                            .data!
                                                                        as dynamic)
                                                                    .docs[index]
                                                                ['profImage']),
                                                      ),
                                                      Text(
                                                        (snapshot.data!
                                                                as dynamic)
                                                            .docs[index]
                                                                ['username']
                                                            .toString(),
                                                        style: TextStyle(
                                                            fontSize: 16),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                height: 24,
                                              ),
                                              SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
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
                                                            color:
                                                                primaryColor),
                                                        children: [
                                                          const TextSpan(
                                                            text: 'Dog Breed:',
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                          TextSpan(
                                                            text:
                                                                ' ${(snapshot.data! as dynamic).docs[index]['dogBreed']}',
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
                                                            color:
                                                                primaryColor),
                                                        children: [
                                                          const TextSpan(
                                                            text: 'Dog Color:',
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                          TextSpan(
                                                            text:
                                                                ' ${(snapshot.data! as dynamic).docs[index]['dogColor']}',
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
                                                            color:
                                                                primaryColor),
                                                        children: [
                                                          const TextSpan(
                                                            text:
                                                                'Description:',
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                          TextSpan(
                                                            text:
                                                                ' ${(snapshot.data! as dynamic).docs[index]['description']}',
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
                                                      style: TextStyle(
                                                          color: primaryColor),
                                                      children: [
                                                        TextSpan(
                                                          text: 'Dog Location:',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: 300,
                                                    width: 300,
                                                    child: GoogleMap(
                                                      tiltGesturesEnabled:
                                                          false,
                                                      zoomGesturesEnabled:
                                                          false,
                                                      rotateGesturesEnabled:
                                                          false,
                                                      scrollGesturesEnabled:
                                                          false,
                                                      mapType: MapType.normal,
                                                      zoomControlsEnabled:
                                                          false,
                                                      markers: {
                                                        Marker(
                                                          infoWindow: InfoWindow(
                                                              title:
                                                                  '${(snapshot.data! as dynamic).docs[index]['dogStatus']} ${(snapshot.data! as dynamic).docs[index]['dogBreed']}'),
                                                          markerId:
                                                              const MarkerId(
                                                                  "dogLocation"),
                                                          icon: (snapshot.data! as dynamic)
                                                                          .docs[index][
                                                                      'dogStatus'] ==
                                                                  'Lost'
                                                              ? BitmapDescriptor
                                                                  .defaultMarkerWithHue(
                                                                      BitmapDescriptor
                                                                          .hueOrange)
                                                              : (snapshot.data! as dynamic).docs[index]
                                                                          [
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
                                                      onMapCreated:
                                                          (GoogleMapController
                                                              controller) {
                                                        _controller.complete(
                                                            controller);
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
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
  }
}
