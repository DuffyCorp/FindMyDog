import 'package:flutter/material.dart';

import '../utils/colors.dart';

class ShowImage extends StatelessWidget {
  final String imageUrl;

  const ShowImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Container(
        height: size.height,
        width: size.width,
        color: Colors.black,
        child: InteractiveViewer(
          clipBehavior: Clip.none,
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}
