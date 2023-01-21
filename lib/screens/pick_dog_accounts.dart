import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_my_dog/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

class PickDogAccountsScreen extends StatefulWidget {
  PageController controller;
  String dogStatus;
  bool dogAccountsLength;
  TextEditingController colorController;
  TextEditingController dogBreedController;
  TextEditingController descriptionController;
  final changeDogImage;

  PickDogAccountsScreen({
    super.key,
    required this.controller,
    required this.dogStatus,
    required this.dogAccountsLength,
    required this.colorController,
    required this.dogBreedController,
    required this.descriptionController,
    required this.changeDogImage,
  });

  @override
  State<PickDogAccountsScreen> createState() => _PickDogAccountsScreenState();
}

class _PickDogAccountsScreenState extends State<PickDogAccountsScreen> {
  @override
  Widget build(BuildContext context) {
    if (widget.dogAccountsLength == true) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
            ),
            onPressed: () {
              widget.controller.animateToPage(
                0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.ease,
              );
            },
          ),
          backgroundColor: mobileBackgroundColor,
          title: const Text('Your dogs'),
          centerTitle: false,
        ),
        //Show 2 buttons for setting lost status
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            //First button for setting status to Lost
            Container(
              height: 200,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection("dogs")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }
                    if (!snapshot.hasData) {
                      return Container();
                    }
                    return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: (snapshot.data! as dynamic).docs.length,
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          DocumentSnapshot snap =
                              (snapshot.data! as dynamic).docs[index];
                          return Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: accentColor.withOpacity(0.80),
                                    width: 3,
                                  ),
                                ),
                                child: SizedBox(
                                  width: 150,
                                  height: 150,
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: InkWell(
                                      onTap: () {
                                        widget.colorController.text =
                                            snap["dogColor"];
                                        widget.dogBreedController.text =
                                            snap["dogBreed"];
                                        widget.descriptionController.text =
                                            snap["description"];
                                        widget.changeDogImage(snap["file"]);
                                        widget.controller.animateToPage(
                                          3,
                                          duration:
                                              const Duration(milliseconds: 200),
                                          curve: Curves.ease,
                                        );
                                      },
                                      child: CircleAvatar(
                                        radius: 75,
                                        backgroundImage: NetworkImage(
                                          snap['file'],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 30,
                              ),
                            ],
                          );
                        });
                  },
                ),
              ),
            ),
            //Second button for setting status to found
            InkWell(
              onTap: () {
                widget.controller.animateToPage(
                  2,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.ease,
                );
                widget.colorController.text = "";
                widget.dogBreedController.text = "";
                widget.descriptionController.text = "";
                widget.changeDogImage("");
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
                      'New dog',
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
    } else {
      return SizedBox();
    }
  }
}
