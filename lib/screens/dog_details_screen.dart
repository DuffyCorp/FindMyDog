import 'package:dropdown_search/dropdown_search.dart';
import 'package:find_my_dog/utils/colors.dart';
import 'package:find_my_dog/utils/utils.dart';
import 'package:find_my_dog/widgets/text_field_input.dart';
import 'package:flutter/material.dart';

class DogDetailsScreen extends StatefulWidget {
  String scanning;
  bool imageSelect;
  bool isLoading;
  var image;
  List results;
  PageController controller;
  TextEditingController dogBreedController;
  TextEditingController colorController;
  TextEditingController descriptionController;
  String dogStatus;
  bool dogAccountsLength;
  final SelectImageType;
  List<String> labels;

  DogDetailsScreen({
    super.key,
    required this.scanning,
    required this.imageSelect,
    required this.isLoading,
    required this.image,
    required this.results,
    required this.controller,
    required this.dogBreedController,
    required this.colorController,
    required this.descriptionController,
    required this.dogStatus,
    required this.dogAccountsLength,
    required this.SelectImageType,
    required this.labels,
  });

  @override
  State<DogDetailsScreen> createState() => _DogDetailsScreenState();
}

class _DogDetailsScreenState extends State<DogDetailsScreen> {
  void handleTap(value) {
    setState(() {
      widget.dogBreedController.text = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.scanning == 'scanning'
        //
        //
        // IF ML SET TO SCANNING SHOW ML SCREEN
        //
        //
        ? Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              backgroundColor: mobileBackgroundColor,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                ),
                onPressed: () {
                  setState(() {
                    widget.scanning = '';
                  });
                },
              ),
              title: const Text('Scanning dog breed'),
              centerTitle: false,
            ),
            //Show image
            body: ListView(
              children: [
                (widget.imageSelect)
                    ?
                    //if imageSelect has data show image
                    Container(
                        margin: const EdgeInsets.all(10),
                        child: Image.file(widget.image!),
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
                        children: (widget.imageSelect)
                            ? widget.results.map(
                                (result) {
                                  String text = result['label']
                                      .toString()
                                      .replaceAll(RegExp(r"\d+"), "");
                                  return InkWell(
                                    onTap: () {
                                      widget.dogBreedController.text = text;
                                      setState(() {
                                        widget.scanning = '';
                                      });
                                    },
                                    child: Card(
                                      child: Container(
                                        margin: EdgeInsets.all(10),
                                        child: Text(
                                          "${text} - ${result['confidence'].toStringAsFixed(2)} %",
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
                              widget.dogBreedController.text = "Mix";
                              setState(() {
                                widget.scanning = '';
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
                              widget.dogBreedController.text = "Undefined";
                              setState(() {
                                widget.scanning = '';
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
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              backgroundColor: mobileBackgroundColor,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                ),
                onPressed: () {
                  if (widget.dogAccountsLength == true &&
                      widget.dogStatus == "Lost") {
                    widget.controller.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.ease,
                    );
                  } else {
                    widget.controller.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.ease,
                    );
                  }
                },
              ),
              title: Text("${widget.dogStatus} Dog details"),
              centerTitle: false,
            ),
            body: Container(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        height: 24,
                      ),
                      Row(
                        children: [
                          // Expanded(
                          //   child: TextFieldInput(
                          //     textEditingController: widget.dogBreedController,
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
                              items: widget.labels,
                              dropdownDecoratorProps:
                                  const DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  labelText: "Dog breed",
                                  hintText: "Select a dog breed",
                                ),
                              ),
                              onChanged: handleTap,
                              selectedItem: widget.dogBreedController.text,
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
                                      widget.SelectImageType();
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
                        textEditingController: widget.colorController,
                        hintText: 'What color is the dog',
                        textInputType: TextInputType.emailAddress,
                      ),
                      const SizedBox(
                        height: 24,
                      ),

                      //text field for bio
                      TextFieldInput(
                        textEditingController: widget.descriptionController,
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
                          if (widget.dogBreedController.text == '' ||
                              widget.colorController.text == '' ||
                              widget.descriptionController.text == '') {
                            showSnackBar('Please enter all details', context);
                          } else {
                            setState(() {
                              FocusScope.of(context)
                                  .requestFocus(new FocusNode());
                              widget.controller.animateToPage(
                                3,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.ease,
                              );
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: const ShapeDecoration(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(4),
                                ),
                              ),
                              color: accentColor),
                          child: widget.isLoading
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
          );
  }
}
