import 'package:flutter/material.dart';

class SettingsOption extends StatelessWidget {
  final String text;
  final Icon icon;
  const SettingsOption({
    Key? key,
    required this.text,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon,
      title: Text(
        text,
      ),
    );
  }
}
