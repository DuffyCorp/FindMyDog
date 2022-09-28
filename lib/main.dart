import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:find_my_dog/providers/users_provider.dart';
import 'package:find_my_dog/responsive/main_screen.dart';
import 'package:find_my_dog/responsive/mobile_screen_layout.dart';
import 'package:find_my_dog/responsive/responsive_layout_screen.dart';
import 'package:find_my_dog/responsive/web_screen_layout.dart';
import 'package:find_my_dog/screens/login_screen.dart';
import 'package:find_my_dog/screens/signup_screen.dart';
import 'package:find_my_dog/utils/colors.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyB7OnOy6_FTjlnwpFqCBQfzYHls2TIUBws',
        appId: '1:266502127881:web:941168d702452155f193d8',
        messagingSenderId: '266502127881',
        projectId: 'instagram-clone-5b92a',
        storageBucket: 'instagram-clone-5b92a.appspot.com',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MainScreen();
  }
}
