import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

import 'package:find_my_dog/providers/location_provider.dart';
import 'package:find_my_dog/responsive/responsive_layout_screen.dart';
import 'package:geoflutterfire/geoflutterfire.dart';

import 'package:location/location.dart';
import 'package:provider/provider.dart';
import '../providers/users_provider.dart';

import '../screens/login_screen.dart';
import '../utils/colors.dart';
import '../utils/global_variables.dart';
import 'mobile_screen_layout.dart';
import 'web_screen_layout.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  LocationData? currentLocation;
  final geo = Geoflutterfire();

  //CHANGE FOR FINAL MODE, WILL ENABLE FIREBASE TO TRACK LIVE DATA
  bool testing = true;

  void getLocation() async {
    final provider = LocationProvider();
    final locationData = await provider.getLocation();

    if (locationData != null) {
      setState(() {
        currentLocation = locationData;
      });
    }

    Location location = new Location();

    location.onLocationChanged.listen((LocationData cLoc) {
      currentLocation = cLoc;
      GeoFirePoint myLocation = geo.point(
          latitude: currentLocation!.latitude!,
          longitude: currentLocation!.longitude!);

//FOR PUBLIC MODE DONT ENABLE IN TESTING will spam firebase
      if (testing == false) {
        FirebaseFirestore.instance
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({"position": myLocation.data});
      }
    });
  }

  @override
  void initState() {
    getLocation();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserProvider(),
        )
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Find my Dog',
        theme: ThemeData.dark()
            .copyWith(scaffoldBackgroundColor: mobileBackgroundColor),
        home: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            //if the snapshot is connection is active
            if (snapshot.connectionState == ConnectionState.active) {
              //if the snapshot has data aka the user is logged in, display the appropriate layout
              if (snapshot.hasData) {
                return const ResponsiveLayout(
                  mobileScreenLayout: MobileScreenLayout(),
                  webScreenLayout: WebScreenLayout(),
                );
              } else if (snapshot.hasError) {
                //if snapshot has an error display error
                return Center(
                  child: Text('${snapshot.error}'),
                );
              }
            }
            //if the connection is waiting show loading indicator
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: primaryColor,
                ),
              );
            }

            //otherwise display login screen
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
