import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:instagram_clone/models/payload.dart';
import 'package:instagram_clone/screens/chat_screen.dart';
import 'package:instagram_clone/screens/post_screen.dart';
import 'package:instagram_clone/utils/colors.dart';
import 'package:instagram_clone/utils/global_variables.dart';
import 'package:instagram_clone/utils/utils.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../providers/location_provider.dart';
import '../screens/search_screen.dart';

class MobileScreenLayout extends StatefulWidget {
  final currentLocation;
  const MobileScreenLayout({
    Key? key,
    this.currentLocation = null,
  }) : super(key: key);

  @override
  State<MobileScreenLayout> createState() => _MobileScreenLayout();
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  AndroidNotificationChannel channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    importance: Importance.high,
    enableVibration: true,
  );

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;
  if (notification != null && android != null && !kIsWeb) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          icon: 'launch_background',
        ),
      ),
    );
  }
}

class _MobileScreenLayout extends State<MobileScreenLayout> {
  int _page = 0;
  late PageController pageController;
  late AndroidNotificationChannel channel;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    requestPermission();

    loadFCM();

    listenFCM();
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }

  void onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    // display a dialog with the notification details, tap ok to go to another page
    showDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(title!),
        content: Text(body!),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Ok'),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  void requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  void selectNotification(String? payload) async {
    print(payload);
    Payload newPayload = Payload.fromJsonString(payload!);
    print('Selected notification');
    print(newPayload.screen);
    if (newPayload.screen == 'post') {
      print('post selected');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PostScreen(
            uid: '',
            postUid: newPayload.uid,
          ),
        ),
      );
    } else if (newPayload.screen == 'chat') {
      print('chat selected');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(uid: newPayload.uid),
        ),
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        "currentlyMessaging": newPayload.uid,
      });
    }
  }

  void loadFCM() async {
    if (!kIsWeb) {
      channel = const AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        importance: Importance.high,
        enableVibration: true,
      );

      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('launch_background');
      final IOSInitializationSettings initializationSettingsIOS =
          IOSInitializationSettings(
              onDidReceiveLocalNotification: onDidReceiveLocalNotification);
      final MacOSInitializationSettings initializationSettingsMacOS =
          MacOSInitializationSettings();
      final InitializationSettings initializationSettings =
          InitializationSettings(
              android: initializationSettingsAndroid,
              iOS: initializationSettingsIOS,
              macOS: initializationSettingsMacOS);
      await flutterLocalNotificationsPlugin.initialize(initializationSettings,
          onSelectNotification: selectNotification);

      /// Create an Android Notification Channel.
      ///
      /// We use this channel in the `AndroidManifest.xml` file to override the
      /// default FCM channel to enable heads up notifications.
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      /// Update the iOS foreground notification presentation options to allow
      /// heads up notifications.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  void listenFCM() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      //_handleMessage(initialMessage);
      RemoteNotification? notification = initialMessage.notification;
      AndroidNotification? android = initialMessage.notification?.android;
      String payload = '';

      if (initialMessage.data['screen'] || initialMessage.data['uid']) {
        Payload newPayload = Payload(
          screen: initialMessage.data['screen'],
          uid: initialMessage.data['uid'],
        );
        payload = newPayload.toJsonString();
      }

      if (notification != null && android != null && !kIsWeb) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              icon: 'launch_background',
            ),
          ),
          payload: payload,
        );
      }
    }

    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;
        String payload = '';

        if (message.data['screen'] || message.data['uid']) {
          Payload newPayload = Payload(
            screen: message.data['screen'],
            uid: message.data['uid'],
          );
          payload = newPayload.toJsonString();
        }

        if (notification != null && android != null && !kIsWeb) {
          flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                icon: 'launch_background',
              ),
            ),
            payload: payload,
          );
        }
      },
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;
        String payload = '';

        if (message.data['uid'] != null) {
          Payload newPayload = Payload(
            screen: message.data['screen'],
            uid: message.data['uid'],
          );
          payload = newPayload.toJsonString();
        } else {
          Payload newPayload = Payload(
            screen: message.data['screen'],
            uid: '',
          );
          payload = newPayload.toJsonString();
        }
        if (notification != null && android != null && !kIsWeb) {
          flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                icon: 'launch_background',
              ),
            ),
            payload: payload,
          );
        }
      },
    );
  }

  void navigationTapped(int page) {
    pageController.jumpToPage(page);
  }

  void onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      floatingActionButton: FloatingActionButton(
        splashColor: Colors.blue,
        onPressed: () {
          navigationTapped(2);
        },
        child: const Icon(
          Icons.report_rounded,
          color: primaryColor,
        ),
        backgroundColor: accentColor,
      ),
      //

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: PageView(
        children: homeScreenItems,
        physics: NeverScrollableScrollPhysics(),
        controller: pageController,
        onPageChanged: onPageChanged,
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 5,
        color: mobileBackgroundColor,
        shape: CircularNotchedRectangle(), //shape of notch
        notchMargin: 10,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: () {
                navigationTapped(0);
              },
              icon: Icon(
                Icons.home,
                color: _page == 0 ? accentColor : Colors.grey,
              ),
            ),
            IconButton(
              onPressed: () {
                navigationTapped(1);
              },
              icon: Icon(
                Icons.search,
                color: _page == 1 ? accentColor : Colors.grey,
              ),
            ),
            Container(
              height: 24,
              width: 24,
            ),
            IconButton(
              onPressed: () {
                navigationTapped(3);
              },
              icon: Icon(
                Icons.map,
                color: _page == 3 ? accentColor : Colors.grey,
              ),
            ),
            IconButton(
              onPressed: () {
                navigationTapped(4);
              },
              icon: Icon(
                Icons.person,
                color: _page == 4 ? accentColor : Colors.grey,
              ),
            ),
            //IconButton(
            //  onPressed: () {
            //    navigationTapped(5);
            //  },
            //  icon: Icon(
            //    Icons.scanner,
            //    color: _page == 5 ? accentColor : Colors.grey,
            //  ),
            //),
          ],
        ),
      ),
    );
  }
}
