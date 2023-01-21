import 'dart:async';

import 'package:find_my_dog/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class DogLocationScreen extends StatefulWidget {
  String dogStatus;
  PageController controller;
  TextEditingController dogBreedController;
  LatLng dogLocation;
  List<Marker> myMarker;
  final onTap;

  LocationData currentLocation;

  DogLocationScreen({
    super.key,
    required this.dogStatus,
    required this.controller,
    required this.dogBreedController,
    required this.currentLocation,
    required this.dogLocation,
    required this.onTap,
    required this.myMarker,
  });

  @override
  State<DogLocationScreen> createState() => _DogLocationScreenState();
}

class _DogLocationScreenState extends State<DogLocationScreen> {
  @override
  Widget build(BuildContext context) {
    final Completer<GoogleMapController> _controller = Completer();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
          ),
          onPressed: () {
            widget.controller.animateToPage(
              2,
              duration: const Duration(milliseconds: 200),
              curve: Curves.ease,
            );
          },
        ),
        title: Text("${widget.dogStatus} Dog Location"),
        centerTitle: false,
        actions: [
          widget.dogLocation != LatLng(0, 0)
              ? TextButton(
                  onPressed: () {
                    widget.controller.animateToPage(
                      4,
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
      body: widget.currentLocation == null
          ? const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : GoogleMap(
              zoomControlsEnabled: false,
              mapType: MapType.normal,
              markers: Set.from(widget.myMarker),
              myLocationEnabled: true,
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.currentLocation.latitude!,
                    widget.currentLocation.longitude!),
                zoom: 15,
              ),
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              onTap: widget.onTap,
            ),
    );
  }
}
