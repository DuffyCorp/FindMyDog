import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_my_dog/utils/global_variables.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:find_my_dog/screens/feed_screen.dart';
import 'package:find_my_dog/screens/messages_screen.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:location/location.dart' as LocationPlugin;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late PageController controller;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final geo = Geoflutterfire();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  LocationPlugin.LocationData? _currentLocation;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = PageController();
    if (globalCurrentLocation == null) {
      getCurrentLocation();
    } else {
      _currentLocation = globalCurrentLocation;
      updateLocation();
    }
    setStatus("Online");

    setMessageStatus();
  }

  void getCurrentLocation() async {
    LocationPlugin.Location _location = LocationPlugin.Location();

    _location.getLocation().then(
      (newLocation) {
        setState(() {
          _currentLocation = newLocation;
          globalCurrentLocation = newLocation;
        });
        updateLocation();
      },
    );
  }

  void setMessageStatus() async {
    await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
      "currentlyMessaging": "",
    });
  }

  void setStatus(String status) async {
    await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
      "status": status,
    });
  }

  void updateLocation() async {
    GeoFirePoint myLocation = geo.point(
        latitude: globalCurrentLocation!.latitude!,
        longitude: globalCurrentLocation!.longitude!);

    if (globalCurrentLocation != null) {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update({"position": myLocation.data});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      //online
      setStatus("Online");
      updateLocation();
    } else {
      //offline
      setStatus("Offline");
      updateLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: controller,
      physics: const BouncingScrollPhysics(),
      children: [
        FeedScreen(
          controller: controller,
        ),
        MessagesScreen(
          controller: controller,
        ),
      ],
    );
  }
}
