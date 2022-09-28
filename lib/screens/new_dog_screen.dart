import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:find_my_dog/models/user.dart';
import 'package:find_my_dog/providers/users_provider.dart';
import 'package:find_my_dog/resources/firestore_methods.dart';
import 'package:find_my_dog/screens/image_recognition.dart';
import 'package:find_my_dog/utils/colors.dart';
import 'package:find_my_dog/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:tflite/tflite.dart';

import '../widgets/text_field_input.dart';

class NewDogScreen extends StatefulWidget {
  const NewDogScreen({Key? key}) : super(key: key);

  @override
  State<NewDogScreen> createState() => _NewDogScreenState();
}

class _NewDogScreenState extends State<NewDogScreen> {
  //controllers
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  Completer<GoogleMapController> _controller = Completer();
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
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadModel();
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

  // void postImage(
  //   String uid,
  //   String username,
  //   String profImage,
  // ) async {
  //   try {
  //     setState(() {
  //       _isLoading = true;
  //     });
  //     String res = await FirestoreMethods().uploadPost(
  //       _descriptionController.text,
  //       _file!,
  //       uid,
  //       username,
  //       profImage,
  //     );

  //     if (res == "success") {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //       showSnackBar('Posted!', context);
  //       clearImage();
  //     } else {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //       showSnackBar(res, context);
  //     }
  //   } catch (err) {
  //     showSnackBar(err.toString(), context);
  //   }
  // }

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

    return _file == null
        ? isLost == ''
            ?
            //if isLost isn't set show buttons to let user choose
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
                          isLost = 'lost';
                        });
                        print(isLost);
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
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
                          isLost = 'found';
                        });
                        print(isLost);
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Container(
                                    child: const Icon(
                                      Icons.search,
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
                  ],
                ),
              )

            //else if isLost is set then
            : details == ''
                //
                //
                // IF DETAILS HAVE NOT BEEN SET SHOW DETAILS SCREEN
                //
                //
                ? scanning == 'scanning'
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
                                children: (imageSelect)
                                    ? _results.map(
                                        (result) {
                                          return InkWell(
                                            onTap: () {
                                              _breedController.text =
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
                            ),
                          ],
                        ),
                      )
                    :
                    //
                    //
                    // IF LOST STATUS SET AND DETAILS ARENT SHOW DETAILS SCREEN
                    //
                    //
                    Scaffold(
                        appBar: AppBar(
                          backgroundColor: mobileBackgroundColor,
                          leading: IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                            ),
                            onPressed: () {
                              setState(() {
                                isLost = '';
                              });
                            },
                          ),
                          title: const Text('Dog details'),
                          centerTitle: false,
                        ),
                        body: Container(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 24,
                                ),
                                //text field for dog breed
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFieldInput(
                                        textEditingController: _breedController,
                                        hintText: 'Enter dog breed',
                                        textInputType: TextInputType.text,
                                      ),
                                    ),
                                    Expanded(
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
                                          const Text('Scan dog')
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(
                                  height: 24,
                                ),

                                //text field for color
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
                                  textEditingController: _descController,
                                  hintText: 'Enter a description',
                                  textInputType: TextInputType.text,
                                ),
                                const SizedBox(
                                  height: 24,
                                ),

                                //button for submit
                                InkWell(
                                  onTap: () {
                                    if (_breedController.text == '' ||
                                        _colorController.text == '' ||
                                        _descController.text == '') {
                                      showSnackBar(
                                          'Please enter all details', context);
                                    } else {
                                      setState(() {
                                        details = 'filled';
                                      });
                                    }
                                  },
                                  child: Container(
                                    child: _isLoading
                                        ? Center(
                                            child: CircularProgressIndicator(
                                              color: primaryColor,
                                            ),
                                          )
                                        : const Text('Enter details'),
                                    width: double.infinity,
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: const ShapeDecoration(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(4),
                                          ),
                                        ),
                                        color: accentColor),
                                  ),
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                Flexible(
                                  child: Container(),
                                  flex: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                :
                //
                //
                // IF LOCATION HASNT BEEN CHOSEN SHOW MAP
                //
                //
                location == ''
                    ? Scaffold(
                        appBar: AppBar(
                          backgroundColor: mobileBackgroundColor,
                          leading: IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                            ),
                            onPressed: () {
                              setState(() {
                                details = '';
                              });
                            },
                          ),
                          title: const Text('Dog Location'),
                          centerTitle: false,
                          actions: [
                            myMarker.isNotEmpty
                                ? TextButton(
                                    onPressed: () {
                                      setState(() {
                                        if (myMarker.isEmpty == false) {
                                          location = 'filled';
                                        } else {
                                          showSnackBar(
                                              'Please select a location',
                                              context);
                                        }
                                      });
                                    },
                                    child: const Text(
                                      'Add Location',
                                      style: TextStyle(
                                        color: Colors.blueAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  )
                                : Center(),
                          ],
                        ),
                        body: GoogleMap(
                          mapType: MapType.normal,
                          markers: Set.from(myMarker),
                          initialCameraPosition: _kGooglePlex,
                          onMapCreated: (GoogleMapController controller) {
                            _controller.complete(controller);
                          },
                          onTap: _handleTap,
                        ),
                      )
                    :
                    //
                    //
                    // IF LOCATION HAS BEEN CHOSEN SHOW SELECT IMAGE SCREEN
                    //
                    //
                    Scaffold(
                        appBar: AppBar(
                          leading: IconButton(
                            onPressed: () {
                              setState(() {
                                location = '';
                              });
                            },
                            icon: Icon(Icons.arrow_back),
                          ),
                          backgroundColor: mobileBackgroundColor,
                          title: const Text('Images'),
                          centerTitle: false,
                        ),
                        body: Center(
                          child: IconButton(
                            icon: const Icon(Icons.upload),
                            onPressed: () => _selectImage(context),
                          ),
                        ),
                      )
        //
        //
        // IF ALL DETAILS HAS BEEN CHOSEN SHOW FINAL REVIEW SCREEN
        //
        //
        : Scaffold(
            appBar: AppBar(
              backgroundColor: mobileBackgroundColor,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: clearImage,
              ),
              title: const Text('Post to'),
              centerTitle: false,
              actions: [
                TextButton(
                    onPressed: () {},
                    //postImage(user.uid, user.username, user.photoUrl),
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
            body: Column(
              children: [
                _isLoading
                    ? LinearProgressIndicator(
                        color: primaryColor,
                      )
                    : const Padding(
                        padding: EdgeInsets.only(top: 0),
                      ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //Account profile picture
                    CircleAvatar(
                      backgroundImage: NetworkImage(user.photoUrl),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.45,
                      child: TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          hintText: 'Write a caption...',
                          border: InputBorder.none,
                        ),
                        maxLines: 8,
                      ),
                    ),
                    SizedBox(
                      height: 45,
                      width: 45,
                      child: AspectRatio(
                        aspectRatio: 487 / 451,
                        child: Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: MemoryImage(_file!),
                              fit: BoxFit.fill,
                              alignment: FractionalOffset.topCenter,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Divider(),
                  ],
                )
              ],
            ),
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
