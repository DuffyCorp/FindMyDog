import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
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

class _SwipeScreenState extends State<SwipeScreen> {
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
  String dogStatus = '';
  List<Marker> myMarker = [];
  LatLng dogLocation = const LatLng(0, 0);
  String scanning = '';
  bool _isLoading = false;
  bool imageSelect = false;
  late File _image;
  late List _results;
  bool isLost = false;
  Uint8List? _file;
  LocationData? _currentLocation;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadModel();
    controller = PageController();
    if (currentLocation == null) {
      getCurrentLocation();
    } else {
      _currentLocation = currentLocation;
    }
  }

  void getLocation() async {
    String location = await FirestoreMethods().getLocation(dogLocation);

    location != ''
        ? showSnackBar(location, context)
        : showSnackBar('empty', context);
  }

  void postImage(
    String uid,
    String username,
    String profImage,
  ) async {
    try {
      setState(() {
        _isLoading = true;
      });
      String res = await FirestoreMethods().uploadPost(
        dogStatus,
        _dogBreedController.text,
        _colorController.text,
        dogLocation,
        _descriptionController.text,
        _file!,
        uid,
        username,
        profImage,
      );

      if (res == "success") {
        setState(() {
          _isLoading = false;
        });
        showSnackBar('Posted!', context);
        clearImage();
      } else {
        setState(() {
          _isLoading = false;
        });
        showSnackBar(res, context);
      }
    } catch (err) {
      showSnackBar(err.toString(), context);
    }
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
                    _file = file;
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
                    _file = file;
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

  void getCurrentLocation() async {
    final service = LocationProvider();
    final locationData = await service.getLocation();
    setState(() {
      _currentLocation = locationData;
      currentLocation = locationData;
    });
  }

  void clearImage() {
    setState(() {
      _file = null;
    });
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
    print(recognitions);
    setState(() {
      _results = recognitions!;
      _image = image;
      imageSelect = true;
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
                  children: [
                    Icon(Icons.camera_alt_rounded),
                    const Text(' Take a Photo'),
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

  @override
  Widget build(BuildContext context) {
    final User user = Provider.of<UserProvider>(context).getUser;
    return Stack(
      children: [
        PageView(
          controller: controller,
          physics: NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            setState(() {});
          },
          children: [
            Scaffold(
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
                    onTap: () {
                      setState(() {
                        dogStatus = 'Lost';
                      });
                      controller.animateToPage(
                        1,
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
                      setState(() {
                        dogStatus = 'Found';
                      });
                      controller.animateToPage(
                        1,
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
                    height: 32,
                  ),
                ],
              ),
            ),
            scanning == 'scanning'
                //
                //
                // IF ML SET TO SCANNING SHOW ML SCREEN
                //
                //
                ? Scaffold(
                    appBar: AppBar(
                      backgroundColor: mobileBackgroundColor,
                      leading: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                        ),
                        onPressed: () {
                          setState(() {
                            scanning = '';
                          });
                        },
                      ),
                      title: const Text('Scanning dog breed'),
                      centerTitle: false,
                    ),
                    //Show image
                    body: ListView(
                      children: [
                        (imageSelect)
                            ?
                            //if imageSelect has data show image
                            Container(
                                margin: const EdgeInsets.all(10),
                                child: Image.file(_image),
                              )
                            :
                            //else if imageSelect doesnt have data show No image selected message
                            Container(
                                margin: const EdgeInsets.all(10),
                                child: const Opacity(
                                  opacity: 0.8,
                                  child: Center(
                                    child: Text('No image selected'),
                                  ),
                                ),
                              ),
                        //Show ML model results that are clickable
                        SingleChildScrollView(
                          child: Column(
                            children: [
                              Column(
                                children: (imageSelect)
                                    ? _results.map(
                                        (result) {
                                          return InkWell(
                                            onTap: () {
                                              _dogBreedController.text =
                                                  "${result['label']}";
                                              setState(() {
                                                scanning = '';
                                              });
                                            },
                                            child: Card(
                                              child: Container(
                                                margin: EdgeInsets.all(10),
                                                child: Text(
                                                  "${result['label']} - ${result['confidence'].toStringAsFixed(2)} %",
                                                  style: const TextStyle(
                                                    color: accentColor,
                                                    fontSize: 20,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ).toList()
                                    : [],
                              ),
                              Column(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      _dogBreedController.text = "Mix";
                                      setState(() {
                                        scanning = '';
                                      });
                                    },
                                    child: Card(
                                      child: Container(
                                        margin: EdgeInsets.all(10),
                                        child: const Text(
                                          "Mix",
                                          style: TextStyle(
                                            color: accentColor,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      _dogBreedController.text = "Undefined";
                                      setState(() {
                                        scanning = '';
                                      });
                                    },
                                    child: Card(
                                      child: Container(
                                        margin: EdgeInsets.all(10),
                                        child: const Text(
                                          "Undefined",
                                          style: TextStyle(
                                            color: accentColor,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                height: 60,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : Scaffold(
                    appBar: AppBar(
                      backgroundColor: mobileBackgroundColor,
                      leading: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                        ),
                        onPressed: () {
                          controller.animateToPage(
                            0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.ease,
                          );
                        },
                      ),
                      title: Text("$dogStatus Dog details"),
                      centerTitle: false,
                    ),
                    body: Container(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 24,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFieldInput(
                                    textEditingController: _dogBreedController,
                                    hintText: 'Enter dog breed',
                                    textInputType: TextInputType.text,
                                  ),
                                ),
                                SizedBox(
                                  width: 100,
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: accentColor,
                                        child: IconButton(
                                          onPressed: () {
                                            SelectImageType();
                                          },
                                          icon: const Icon(
                                            Icons.camera_alt_rounded,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const Text('Scan a dog')
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            //text field for dog breed

                            const SizedBox(
                              height: 24,
                            ),

                            //text field for email
                            TextFieldInput(
                              textEditingController: _colorController,
                              hintText: 'What color is the dog',
                              textInputType: TextInputType.emailAddress,
                            ),
                            const SizedBox(
                              height: 24,
                            ),

                            //text field for bio
                            TextFieldInput(
                              textEditingController: _descriptionController,
                              hintText: 'Enter a description',
                              textInputType: TextInputType.text,
                              maxLines: 8,
                            ),
                            const SizedBox(
                              height: 24,
                            ),

                            //buttom for login
                            InkWell(
                              onTap: () {
                                if (_dogBreedController.text == '' ||
                                    _colorController.text == '' ||
                                    _descriptionController.text == '') {
                                  showSnackBar(
                                      'Please enter all details', context);
                                } else {
                                  setState(() {
                                    FocusScope.of(context)
                                        .requestFocus(new FocusNode());
                                    controller.animateToPage(
                                      2,
                                      duration:
                                          const Duration(milliseconds: 200),
                                      curve: Curves.ease,
                                    );
                                  });
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                alignment: Alignment.center,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: const ShapeDecoration(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(4),
                                      ),
                                    ),
                                    color: accentColor),
                                child: _isLoading
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          color: primaryColor,
                                        ),
                                      )
                                    : const Text('Enter details'),
                              ),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            Flexible(
                              flex: 2,
                              child: Container(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            Scaffold(
              appBar: AppBar(
                backgroundColor: mobileBackgroundColor,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                  ),
                  onPressed: () {
                    controller.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.ease,
                    );
                  },
                ),
                title: Text("${dogStatus} Dog Location"),
                centerTitle: false,
                actions: [
                  dogLocation != LatLng(0, 0)
                      ? TextButton(
                          onPressed: () {
                            controller.animateToPage(
                              3,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.ease,
                            );
                          },
                          child: const Text(
                            'Add Location',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ))
                      : Container()
                ],
              ),
              body: _currentLocation == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: primaryColor,
                      ),
                    )
                  : GoogleMap(
                      zoomControlsEnabled: false,
                      mapType: MapType.normal,
                      markers: Set.from(myMarker),
                      myLocationEnabled: true,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(_currentLocation!.latitude!,
                            _currentLocation!.longitude!),
                        zoom: 15,
                      ),
                      onMapCreated: (GoogleMapController controller) {
                        _controller.complete(controller);
                      },
                      onTap: _handleTap,
                    ),
            ),
            _file == null
                ? Scaffold(
                    appBar: AppBar(
                      backgroundColor: mobileBackgroundColor,
                      leading: IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                        ),
                        onPressed: () {
                          controller.animateToPage(
                            2,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.ease,
                          );
                        },
                      ),
                      title: Text("Image for the ${dogStatus} Dog"),
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
                      title: Text("Post ${dogStatus} Dog"),
                      centerTitle: false,
                      actions: [
                        TextButton(
                            onPressed: () => postImage(
                                user.uid, user.username, user.photoUrl),
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
                            _isLoading
                                ? const LinearProgressIndicator(
                                    color: primaryColor,
                                  )
                                : const Padding(
                                    padding: EdgeInsets.only(top: 0),
                                  ),
                            const Divider(
                              color: Colors.grey,
                            ),
                            Container(
                              margin: const EdgeInsets.all(10),
                              child: Image.memory(_file!),
                            ),
                            const Divider(
                              color: Colors.grey,
                            ),
                            Text('Dog Breed:'),
                            SizedBox(
                              child: TextField(
                                controller: _dogBreedController,
                                decoration: const InputDecoration(
                                  hintText: 'Dog Breed ...',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            const Divider(
                              color: Colors.grey,
                            ),
                            Text('Dog Color:'),
                            SizedBox(
                              child: TextField(
                                controller: _colorController,
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
                                controller: _descriptionController,
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
                                    infoWindow:
                                        InfoWindow(title: 'Dog Postion'),
                                    markerId: MarkerId("dogLocation"),
                                    position: LatLng(dogLocation.latitude,
                                        dogLocation.longitude),
                                  )
                                },
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(dogLocation.latitude,
                                      dogLocation.longitude),
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
                  ),
          ],
        ),
      ],
    );
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
}
