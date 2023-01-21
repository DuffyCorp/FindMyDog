import 'package:find_my_dog/utils/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

class PostSuccessScreen extends StatefulWidget {
  final PageController controller;
  final String dogStatus;
  final reset;
  const PostSuccessScreen(
      {super.key,
      required this.controller,
      required this.dogStatus,
      required this.reset});

  @override
  State<PostSuccessScreen> createState() => _PostSuccessScreenState();
}

class _PostSuccessScreenState extends State<PostSuccessScreen> {
  @override
  Widget build(BuildContext context) {
    PageController controller = widget.controller;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        title: const Text('Report a Dog'),
        centerTitle: false,
      ),
      //Show 2 buttons for setting lost status
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          widget.dogStatus == "Found"
              ? InkWell(
                  onTap: () {
                    controller.animateToPage(
                      7,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.ease,
                    );
                  },
                  child: Column(
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(90.0),
                        ),
                        color: Colors.amber,
                        child: Container(
                          width: 150,
                          height: 150,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: const [
                              Icon(
                                Icons.numbers,
                                size: 50,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          'Is there contact details?',
                          style: TextStyle(
                            fontSize: 18,
                            color: primaryColor,
                          ),
                        ),
                      )
                    ],
                  ),
                )
              : SizedBox(),
          InkWell(
            onTap: () {
              widget.reset();
              controller.animateToPage(
                0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.ease,
              );
            },
            child: Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(90.0),
                  ),
                  color: accentColor,
                  child: Container(
                    width: 150,
                    height: 150,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          child: const Icon(
                            Icons.check,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 18,
                      color: primaryColor,
                    ),
                  ),
                )
              ],
            ),
          ),
          Container(
            height: 32,
          ),
        ],
      ),
    );
  }
}
