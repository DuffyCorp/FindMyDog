import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:find_my_dog/resources/auth_methods.dart';
import 'package:find_my_dog/screens/login_screen.dart';
import 'package:find_my_dog/utils/colors.dart';
import 'package:find_my_dog/widgets/settings_option.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //App bar
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        title: const Text('Settings'),
        centerTitle: false,
      ),

      //Settings options

      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(12),
          children: [
            //App settings
            const Text('App Settings'),

            InkWell(
              onTap: () async {},
              child: const SettingsOption(
                text: 'Language',
                icon: Icon(Icons.language),
              ),
            ),
            InkWell(
              onTap: () async {},
              child: const SettingsOption(
                text: 'Theme',
                icon: Icon(Icons.dark_mode),
              ),
            ),

            InkWell(
              onTap: () async {},
              child: const SettingsOption(
                text: 'Notifications',
                icon: Icon(Icons.notifications),
              ),
            ),

            const Divider(
              color: Colors.grey,
            ),

            //User settings
            const Text('User Settings'),
            InkWell(
              onTap: () async {
                await AuthMethods().signOut();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              child: const SettingsOption(
                text: 'Sign out',
                icon: Icon(Icons.logout),
              ),
            ),
            InkWell(
              onTap: () async {},
              child: const SettingsOption(
                text: 'Change email',
                icon: Icon(Icons.email),
              ),
            ),
            InkWell(
              onTap: () async {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Delete Account"),
                      content: const Text(
                          "Are you sure you want to delete your account?"),
                      actions: [
                        TextButton(
                          child: const Text("Cancel"),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        TextButton(
                          child: const Text("Continue"),
                          onPressed: () async {
                            await AuthMethods().deleteUser();
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: const SettingsOption(
                text: 'Delete account',
                icon: Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
              ),
            ),

            const Divider(
              color: Colors.grey,
            ),

            //Feedback
            const Text('Feedback'),
            InkWell(
              onTap: () async {},
              child: const SettingsOption(
                text: 'Report a bug',
                icon: Icon(Icons.email),
              ),
            ),
            InkWell(
              onTap: () async {},
              child: const SettingsOption(
                text: 'Send Feedback',
                icon: Icon(
                  Icons.thumb_up,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
