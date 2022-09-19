import 'package:flutter/material.dart';
import 'package:instagram_clone/providers/users_provider.dart';
import 'package:instagram_clone/utils/global_variables.dart';
import 'package:provider/provider.dart';

class ResponsiveLayout extends StatefulWidget {
  final Widget webScreenLayout;
  final Widget mobileScreenLayout;

  const ResponsiveLayout(
      {Key? key,
      required this.webScreenLayout,
      required this.mobileScreenLayout})
      : super(key: key);

  @override
  State<ResponsiveLayout> createState() => _ResponsiveLayoutState();
}

class _ResponsiveLayoutState extends State<ResponsiveLayout> {
  //override init state to get the user data on launch
  @override
  void initState() {
    super.initState();
    addData();
  }

  //method to get user data
  addData() async {
    UserProvider _userProvider = Provider.of(context, listen: false);
    await _userProvider.refreshUser();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        //If width is greater than web screen size defined in dimensions.dart set to web layout
        if (constraints.maxWidth > webScreenSize) {
          return widget.webScreenLayout;
        }
        //else set to mobile layout
        return widget.mobileScreenLayout;
      },
    );
  }
}
