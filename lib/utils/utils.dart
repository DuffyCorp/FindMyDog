import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

//method that allows user to pick image from gallery
pickImage(ImageSource source) async {
  //create image picker
  final ImagePicker _imagePicker = ImagePicker();

  //set to chosen file
  XFile? _file = await _imagePicker.pickImage(source: source);

  //if the file is not null
  if (_file != null) {
    //return the file as data
    return await _file.readAsBytes();
  }
  //Otherwise alert no image was chosen
  print("No image selected");
}

//method to show snackbar
showSnackBar(String content, BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(content),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
