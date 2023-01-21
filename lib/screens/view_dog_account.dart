import 'package:find_my_dog/utils/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

class ViewDogAccount extends StatefulWidget {
  final snap;
  const ViewDogAccount({super.key, required this.snap});

  @override
  State<ViewDogAccount> createState() => _ViewDogAccountState();
}

class _ViewDogAccountState extends State<ViewDogAccount> {
  //controllers
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    _colorController.text = widget.snap["dogColor"];
    _descriptionController.text = widget.snap["description"];
    _breedController.text = widget.snap["dogBreed"];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text("View Dog Account"),
        centerTitle: false,
        // actions: [
        //   TextButton(
        //       onPressed: () => {
        //             postImage(),
        //           },
        //       child: const Text(
        //         'Create',
        //         style: TextStyle(
        //           color: Colors.blueAccent,
        //           fontWeight: FontWeight.bold,
        //           fontSize: 16,
        //         ),
        //       ))
        // ],
      ),

      //Body section
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 0),
              ),
              const Divider(
                color: Colors.grey,
              ),
              Container(
                margin: const EdgeInsets.all(10),
                child: Image.network(widget.snap["file"]),
              ),
              const Divider(
                color: Colors.grey,
              ),
              Text('Dog Breed:'),
              SizedBox(
                child: TextField(
                  readOnly: true,
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
                  readOnly: true,
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
                  readOnly: true,
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
    );
  }
}
