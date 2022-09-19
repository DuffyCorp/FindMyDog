import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

import 'package:instagram_clone/providers/location_provider.dart';
import 'package:instagram_clone/responsive/responsive_layout_screen.dart';

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
  void getLocation() async {
    final provider = LocationProvider();
    final locationData = await provider.getLocation();

    if (locationData != null) {
      setState(() {
        currentLocation = locationData;
      });
    }
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
