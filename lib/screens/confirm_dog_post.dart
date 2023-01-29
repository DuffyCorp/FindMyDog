import 'dart:async';
import 'dart:typed_data';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:find_my_dog/models/user.dart';
import 'package:find_my_dog/providers/users_provider.dart';
import 'package:find_my_dog/resources/firestore_methods.dart';
import 'package:find_my_dog/utils/colors.dart';
import 'package:find_my_dog/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class ConfirmDogPost extends StatefulWidget {
  Uint8List? file;
  String dogStatus;
  bool isLoading;
  PageController controller;
  TextEditingController dogBreedController;
  TextEditingController colorController;
  TextEditingController descriptionController;
  LatLng dogLocation;
  String dogAccountImage;
  List<String> labels;
  final changeID;

  ConfirmDogPost({
    super.key,
    required this.file,
    required this.dogStatus,
    required this.isLoading,
    required this.controller,
    required this.dogBreedController,
    required this.colorController,
    required this.descriptionController,
    required this.dogLocation,
    required this.dogAccountImage,
    required this.labels,
    required this.changeID,
  });

  @override
  State<ConfirmDogPost> createState() => _ConfirmDogPostState();
}

class _ConfirmDogPostState extends State<ConfirmDogPost> {
  final Completer<GoogleMapController> _controller = Completer();
  //create post id
  String postId = const Uuid().v1();
  void postImage(
    String uid,
    String username,
    String profImage,
  ) async {
    try {
      setState(() {
        widget.isLoading = true;
      });

      String res = "";

      if (widget.dogAccountImage != "") {
        widget.file = Uint8List(0);
        res = await FirestoreMethods().uploadPost(
          widget.dogStatus,
          widget.dogBreedController.text,
          widget.colorController.text,
          widget.dogLocation,
          widget.descriptionController.text,
          widget.file!,
          uid,
          username,
          profImage,
          postId,
          widget.dogAccountImage,
        );
      } else {
        res = await FirestoreMethods().uploadPost(
          widget.dogStatus,
          widget.dogBreedController.text,
          widget.colorController.text,
          widget.dogLocation,
          widget.descriptionController.text,
          widget.file!,
          uid,
          username,
          profImage,
          postId,
        );
      }
      widget.changeID(postId);
      if (res == "success") {
        setState(() {
          widget.isLoading = false;
        });

        showSnackBar('Posted!', context);
        clearImage();
      } else {
        setState(() {
          widget.isLoading = false;
        });
        showSnackBar(res, context);
      }
    } catch (err) {
      showSnackBar(err.toString(), context);
    }
  }

  void clearImage() {
    if (widget.dogAccountImage != "") {
      widget.controller.animateToPage(
        3,
        duration: const Duration(milliseconds: 200),
        curve: Curves.ease,
      );
    } else {
      setState(() {
        widget.file = null;
      });
    }
  }

  void handleTap(value) {
    setState(() {
      widget.dogBreedController.text = value;
    });
  }

  _selectImage(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text('Create a Post'),
            children: [
              SimpleDialogOption(
                padding: EdgeInsets.all(20),
                child: const Text('Take a Photo'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  Uint8List file = await pickImage(
                    ImageSource.camera,
                  );
                  setState(() {
                    widget.file = file;
                  });
                },
              ),
              SimpleDialogOption(
                padding: EdgeInsets.all(20),
                child: const Text('Select from gallery'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  Uint8List file = await pickImage(
                    ImageSource.gallery,
                  );
                  setState(() {
                    widget.file = file;
                  });
                },
              ),
              SimpleDialogOption(
                padding: EdgeInsets.all(20),
                child: const Text('Cancel'),
                onPressed: () async {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final User user = Provider.of<UserProvider>(context).getUser;
    return (widget.file == null && widget.dogAccountImage == "")
        ? Scaffold(
            appBar: AppBar(
              backgroundColor: mobileBackgroundColor,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                ),
                onPressed: () {
                  widget.controller.animateToPage(
                    3,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.ease,
                  );
                },
              ),
              title: Text("Image for the ${widget.dogStatus} Dog"),
              centerTitle: false,
            ),
            body: Center(
              child: IconButton(
                icon: const Icon(Icons.upload),
                onPressed: () => _selectImage(context),
              ),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              backgroundColor: mobileBackgroundColor,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: clearImage,
              ),
              title: Text("Post ${widget.dogStatus} Dog"),
              centerTitle: false,
              actions: [
                TextButton(
                    onPressed: () async {
                      try {
                        postImage(user.uid, user.username, user.photoUrl);
                        widget.controller.animateToPage(
                          5,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.ease,
                        );
                      } catch (err) {
                        widget.controller.animateToPage(
                          6,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.ease,
                        );
                      }
                    },
                    child: const Text(
                      'Post',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ))
              ],
            ),

            //Body section
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    widget.isLoading
                        ? const LinearProgressIndicator(
                            color: primaryColor,
                          )
                        : const Padding(
                            padding: EdgeInsets.only(top: 0),
                          ),
                    const Divider(
                      color: Colors.grey,
                    ),
                    widget.dogAccountImage != ""
                        ? Container(
                            margin: const EdgeInsets.all(10),
                            child: Image.network(widget.dogAccountImage),
                          )
                        : Container(
                            margin: const EdgeInsets.all(10),
                            child: Image.memory(widget.file!),
                          ),
                    const Divider(
                      color: Colors.grey,
                    ),
                    Text('Dog Breed:'),
                    SizedBox(
                      child: DropdownSearch<String>(
                        popupProps: const PopupProps.menu(
                          showSelectedItems: true,
                          showSearchBox: true,
                        ),
                        items: widget.labels,
                        dropdownDecoratorProps: const DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            labelText: "Dog breed",
                            hintText: "Select a dog breed",
                          ),
                        ),
                        onChanged: handleTap,
                        selectedItem: widget.dogBreedController.text,
                      ),
                    ),
                    const Divider(
                      color: Colors.grey,
                    ),
                    Text('Dog Color:'),
                    SizedBox(
                      child: TextField(
                        controller: widget.colorController,
                        decoration: const InputDecoration(
                          hintText: 'Dog Color ...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const Divider(
                      color: Colors.grey,
                    ),
                    Text('Dog Description:'),
                    SizedBox(
                      child: TextField(
                        controller: widget.descriptionController,
                        decoration: const InputDecoration(
                          hintText: 'Dog Description ...',
                          border: InputBorder.none,
                        ),
                        maxLines: 5,
                      ),
                    ),
                    const Divider(
                      color: Colors.grey,
                    ),
                    Text('Dog Location:'),
                    SizedBox(
                      height: 300,
                      width: 300,
                      child: GoogleMap(
                        mapType: MapType.normal,
                        zoomControlsEnabled: false,
                        markers: {
                          Marker(
                            infoWindow: InfoWindow(title: 'Dog Postion'),
                            markerId: MarkerId("dogLocation"),
                            position: LatLng(widget.dogLocation.latitude,
                                widget.dogLocation.longitude),
                            icon: widget.dogStatus == 'Found'
                                ? BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueGreen)
                                : widget.dogStatus == 'Lost'
                                    ? BitmapDescriptor.defaultMarkerWithHue(
                                        BitmapDescriptor.hueOrange)
                                    : BitmapDescriptor.defaultMarker,
                          )
                        },
                        initialCameraPosition: CameraPosition(
                          target: LatLng(widget.dogLocation.latitude,
                              widget.dogLocation.longitude),
                          zoom: 13,
                        ),
                        onMapCreated: (GoogleMapController controller) {
                          _controller.complete(controller);
                        },
                      ),
                    ),
                    Container(
                      height: 150,
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}
