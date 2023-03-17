import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_my_dog/screens/confirm_dog_post.dart';
import 'package:find_my_dog/screens/dog_details_screen.dart';
import 'package:find_my_dog/screens/dog_location_screen.dart';
import 'package:find_my_dog/screens/dog_status_screen.dart';
import 'package:find_my_dog/screens/phone_number_screen.dart';
import 'package:find_my_dog/screens/pick_dog_accounts.dart';
import 'package:find_my_dog/screens/post_success_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:find_my_dog/utils/colors.dart';
import 'package:find_my_dog/utils/global_variables.dart';
import 'package:find_my_dog/widgets/text_field_input.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:tflite/tflite.dart';

import '../models/user.dart';
import '../providers/location_provider.dart';
import '../providers/users_provider.dart';
import '../resources/firestore_methods.dart';
import '../utils/utils.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({Key? key}) : super(key: key);

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen>
    with AutomaticKeepAliveClientMixin<SwipeScreen> {
  @override
  bool get wantKeepAlive => true;
  //
  // CONTROLLERS
  //
  //Page controller
  late PageController controller;
  //
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _dogBreedController = TextEditingController();
  //
  //Controller for google maps
  final Completer<GoogleMapController> _controller = Completer();
  //text controller to search on map
  final TextEditingController _searchController = TextEditingController();
  //Controller for image picker
  final ImagePicker _picker = ImagePicker();

  //
  //VARIABLES
  //

  bool dogAccountsLength = false;

  String dogStatus = '';
  List<Marker> myMarker = [];
  LatLng dogLocation = LatLng(0, 0);
  String scanning = '';
  bool _isLoading = false;
  bool imageSelect = false;
  File _image = File('');
  List _results = [];
  bool isLost = false;
  Uint8List? _file;
  List<String> labels = [];
  String dogAccountImage = "";
  String createdID = "";

  void reset() {
    dogStatus = '';
    myMarker = [];
    dogLocation = LatLng(0, 0);
    scanning = '';
    _image = File('');
    _results = [];
    isLost = false;
    dogAccountImage = "";
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadLabels();

    loadModel();
    //initWithLocalModel();
    controller = PageController();

    checkDogs();
  }

  void checkDogs() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(fbAuth.FirebaseAuth.instance.currentUser!.uid)
        .collection("dogs")
        .get();
    if (snapshot.docs.length > 0) {
      setState(() {
        dogAccountsLength = true;
      });
    }
  }

  void getLocation() async {
    String location = await FirestoreMethods().getLocation(dogLocation);

    location != ''
        ? showSnackBar(location, context)
        : showSnackBar('empty', context);
  }

  void clearImage() {
    setState(() {
      _file = null;
    });
  }

  _handleTap(LatLng tappedPoint) {
    setState(
      () {
        myMarker = [];
        myMarker.add(
          Marker(
            markerId: MarkerId(
              tappedPoint.toString(),
            ),
            position: tappedPoint,
            draggable: true,
            onDragEnd: (dragEndPosition) {
              print(dragEndPosition);
            },
            icon: dogStatus == 'Found'
                ? BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen)
                : dogStatus == 'Lost'
                    ? BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueOrange)
                    : BitmapDescriptor.defaultMarker,
            infoWindow:
                InfoWindow(title: '${dogStatus} ${_dogBreedController.text}'),
          ),
        );
        dogLocation = tappedPoint;
      },
    );
    //getLocation();
  }

  @override
  void dispose() {
    super.dispose();
    _descriptionController.dispose();
    _dogBreedController.dispose();
    _colorController.dispose();
  }

  Future loadModel() async {
    Tflite.close();
    String res;
    res = (await Tflite.loadModel(
        model: "assets/model.tflite", labels: "assets/labels.txt"))!;
    print("Models Loading status: ${res}");
  }

  Future imageClassification(File image) async {
    var recognitions = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 6,
      threshold: 0.05,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      _results = recognitions!;
      _image = image;
      imageSelect = true;
    });
  }

  void loadLabels() async {
    LineSplitter lineSplitter = const LineSplitter();

    final loadedLabels = await rootBundle.loadString("assets/labels.txt");

    String noNumbers = loadedLabels.replaceAll(RegExp(r"\d+"), "");

    List<String> convertedLabels = lineSplitter.convert(noNumbers);

    convertedLabels.addAll(["Mix", "Undefined"]);

    setState(() {
      labels = convertedLabels;
    });
  }

  SelectImageType() async {
    return showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text('Scan a dog'),
            children: [
              SimpleDialogOption(
                padding: EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Icon(Icons.camera_alt_rounded),
                    Text(' Take a Photo'),
                  ],
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  final XFile? pickedFile = await _picker.pickImage(
                    source: ImageSource.camera,
                  );
                  File image = File(pickedFile!.path);
                  print(image);
                  imageClassification(image);
                  setState(() {
                    scanning = 'scanning';
                  });
                },
              ),
              SimpleDialogOption(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.image_rounded),
                    Text(' Select from gallery'),
                  ],
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  final XFile? pickedFile = await _picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  File image = File(pickedFile!.path);
                  imageClassification(image);
                  setState(() {
                    scanning = 'scanning';
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

  void changeStatus(String value) {
    setState(() {
      dogStatus = value;
    });
  }

  void changeID(String value) {
    setState(() {
      createdID = value;
    });
    print("TESTING " + value);
  }

  void changeDogImage(String value) {
    setState(() {
      dogAccountImage = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView(
          controller: controller,
          physics: NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            setState(() {});
          },
          children: [
            DogStatusScreen(
              dogStatus: dogStatus,
              dogAccountsLength: dogAccountsLength,
              controller: controller,
              colorController: _colorController,
              dogBreedController: _dogBreedController,
              descriptionController: _descriptionController,
              changeStatus: changeStatus,
              onTap: changeDogImage,
            ),
            PickDogAccountsScreen(
              controller: controller,
              dogStatus: dogStatus,
              dogAccountsLength: dogAccountsLength,
              colorController: _colorController,
              dogBreedController: _dogBreedController,
              descriptionController: _descriptionController,
              changeDogImage: changeDogImage,
            ),
            DogDetailsScreen(
              scanning: scanning,
              imageSelect: imageSelect,
              isLoading: _isLoading,
              image: _image,
              results: _results,
              controller: controller,
              dogBreedController: _dogBreedController,
              descriptionController: _descriptionController,
              colorController: _colorController,
              dogStatus: dogStatus,
              dogAccountsLength: dogAccountsLength,
              SelectImageType: SelectImageType,
              labels: labels,
            ),
            DogLocationScreen(
              dogStatus: dogStatus,
              controller: controller,
              dogBreedController: _dogBreedController,
              currentLocation: globalCurrentLocation!,
              dogLocation: dogLocation,
              onTap: _handleTap,
              myMarker: myMarker,
            ),
            ConfirmDogPost(
              file: _file,
              dogStatus: dogStatus,
              isLoading: _isLoading,
              controller: controller,
              dogBreedController: _dogBreedController,
              colorController: _colorController,
              descriptionController: _descriptionController,
              dogLocation: dogLocation,
              dogAccountImage: dogAccountImage,
              labels: labels,
              changeID: changeID,
            ),
            PostSuccessScreen(
              controller: controller,
              dogStatus: dogStatus,
              reset: reset,
            ),
            PhoneNumberScreen(
              controller: controller,
              reset: reset,
              dogBreed: _dogBreedController.text,
              dogLocation: dogLocation,
              postID: createdID,
            ),
          ],
        ),
      ],
    );
  }
}
