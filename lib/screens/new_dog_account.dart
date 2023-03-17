import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:find_my_dog/models/user.dart';
import 'package:find_my_dog/providers/users_provider.dart';
import 'package:find_my_dog/resources/firestore_methods.dart';
import 'package:find_my_dog/utils/colors.dart';
import 'package:find_my_dog/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:tflite/tflite.dart';

import '../widgets/text_field_input.dart';

class NewDogAccountScreen extends StatefulWidget {
  const NewDogAccountScreen({Key? key}) : super(key: key);

  @override
  State<NewDogAccountScreen> createState() => _NewDogAccountScreenState();
}

class _NewDogAccountScreenState extends State<NewDogAccountScreen> {
  //controllers
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();

  //Page controller
  late PageController controller;

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  TextEditingController _searchController = TextEditingController();
  List<Marker> myMarker = [];

  //variables
  String isLost = '';
  String details = '';
  String photos = '';
  String scanning = '';
  String location = '';
  Uint8List? _file;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;
  late File _image;
  late List _results;
  bool imageSelect = false;
  List<String> labels = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadLabels();
    loadModel();
    //initWithLocalModel();
    controller = PageController();
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

  //allow user to select where to get dog photo to scan for breed
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
      },
    );
  }

  final ImagePicker _picker = ImagePicker();

  void showChoiceBox() {}

  void postImage() async {
    try {
      setState(() {
        _isLoading = true;
      });
      String res = await FirestoreMethods().uploadDogAccount(
        _breedController.text,
        _colorController.text,
        _descriptionController.text,
        _file!,
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

  void clearImage() {
    setState(() {
      _file = null;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _descController.dispose();
    _breedController.dispose();
    _colorController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final User user = Provider.of<UserProvider>(context).getUser;

    void handleTap(value) {
      setState(() {
        _breedController.text = value;
      });
    }

    return Stack(
      children: [
        PageView(
          controller: controller,
          physics: NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            setState(() {});
          },
          children: [
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
                                          String text = result['label']
                                              .toString()
                                              .replaceAll(RegExp(r"\d+"), "");
                                          return InkWell(
                                            onTap: () {
                                              _breedController.text = text;
                                              setState(() {
                                                scanning = '';
                                              });
                                            },
                                            child: Card(
                                              child: Container(
                                                margin: EdgeInsets.all(10),
                                                child: Text(
                                                  "${text} - ${result['confidence'].toStringAsFixed(2)} %",
                                                  style: const TextStyle(
                                                    color: Colors.white,
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
                                      _breedController.text = "Mix";
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
                                            color: Colors.white,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      _breedController.text = "Undefined";
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
                                            color: Colors.white,
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
                          Navigator.of(context).pop();
                        },
                      ),
                      title: Text("Create a dog account"),
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
                                // Expanded(
                                //   child: TextFieldInput(
                                //     textEditingController: _breedController,
                                //     hintText: 'Enter dog breed',
                                //     textInputType: TextInputType.text,
                                //   ),
                                // ),
                                Expanded(
                                  child: DropdownSearch<String>(
                                    popupProps: const PopupProps.menu(
                                      showSelectedItems: true,
                                      showSearchBox: true,
                                    ),
                                    items: labels,
                                    dropdownDecoratorProps:
                                        const DropDownDecoratorProps(
                                      dropdownSearchDecoration: InputDecoration(
                                        labelText: "Dog breed",
                                        hintText: "Select a dog breed",
                                      ),
                                    ),
                                    onChanged: handleTap,
                                    selectedItem: _breedController.text,
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
                                if (_breedController.text == '' ||
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
                            0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.ease,
                          );
                        },
                      ),
                      title: Text("Image for the Dog"),
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
                      title: Text("Create Dog Account"),
                      centerTitle: false,
                      actions: [
                        TextButton(
                            onPressed: () => {
                                  postImage(),
                                },
                            child: const Text(
                              'Create',
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
                                controller: _breedController,
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
    showSnackBar(tappedPoint.toString(), context);
    print(tappedPoint);
    setState(() {
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
            }),
      );
    });
  }
}
