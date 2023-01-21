import 'package:find_my_dog/utils/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

class DogStatusScreen extends StatefulWidget {
  String dogStatus;
  bool dogAccountsLength;
  PageController controller;
  TextEditingController colorController;
  TextEditingController dogBreedController;
  TextEditingController descriptionController;
  final changeStatus;
  final onTap;

  DogStatusScreen({
    super.key,
    required this.dogStatus,
    required this.dogAccountsLength,
    required this.controller,
    required this.colorController,
    required this.dogBreedController,
    required this.descriptionController,
    required this.changeStatus,
    required this.onTap,
  });

  @override
  State<DogStatusScreen> createState() => _DogStatusScreenState();
}

class _DogStatusScreenState extends State<DogStatusScreen>
    with AutomaticKeepAliveClientMixin<DogStatusScreen> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
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
          //First button for setting status to Lost
          InkWell(
            onTap: () async {
              widget.changeStatus('Stolen');
              if (widget.dogAccountsLength == true) {
                widget.controller.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.ease,
                );
              } else {
                widget.controller.animateToPage(
                  2,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.ease,
                );
              }
            },
            child: Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(90.0),
                  ),
                  color: Colors.red,
                  child: Container(
                    width: 150,
                    height: 150,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          child: const Icon(
                            Icons.report_rounded,
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
                    'Stolen',
                    style: TextStyle(
                      fontSize: 18,
                      color: primaryColor,
                    ),
                  ),
                )
              ],
            ),
          ),
          InkWell(
            onTap: () async {
              widget.changeStatus('Lost');
              if (widget.dogAccountsLength == true) {
                widget.controller.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.ease,
                );
              } else {
                widget.controller.animateToPage(
                  2,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.ease,
                );
              }
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
                      children: [
                        Container(
                          child: const Icon(
                            Icons.question_mark,
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
                    'Lost',
                    style: TextStyle(
                      fontSize: 18,
                      color: primaryColor,
                    ),
                  ),
                )
              ],
            ),
          ),
          //Second button for setting status to found
          InkWell(
            onTap: () {
              widget.changeStatus('Found');

              widget.controller.animateToPage(
                2,
                duration: const Duration(milliseconds: 200),
                curve: Curves.ease,
              );

              widget.colorController.text = "";
              widget.dogBreedController.text = "";
              widget.descriptionController.text = "";
              widget.onTap("");
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
                      children: const [
                        Icon(
                          Icons.search,
                          size: 50,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    'Found',
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
            height: 64,
          ),
        ],
      ),
    );
  }
}
