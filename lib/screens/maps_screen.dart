// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:find_my_dog/screens/post_screen.dart';
import 'package:find_my_dog/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:find_my_dog/utils/colors.dart';
import 'package:find_my_dog/utils/global_variables.dart';
import 'package:location/location.dart' as LocationPlugin;

class MapsScreen extends StatefulWidget {
  const MapsScreen({Key? key}) : super(key: key);

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen>
    with AutomaticKeepAliveClientMixin {
  bool get wantKeepAlive => true;
  Completer<GoogleMapController> _controller = Completer();
  TextEditingController _searchController = TextEditingController();
  LocationPlugin.LocationData? _currentLocation;
  List<Marker> markers = [];

  final userId = FirebaseAuth.instance.currentUser!.uid;

  CollectionReference posts = FirebaseFirestore.instance.collection('posts');

  CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();

  getMarkerData() {
    posts.get().then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        initMarker(doc.data(), doc.id);
      });
    });
    //_retrieveNearbyRestaurants(
    //  LatLng(currentLocation!.latitude!, currentLocation!.longitude!));
  }

  void getCurrentLocation() async {
    LocationPlugin.Location _location = LocationPlugin.Location();

    _location.getLocation().then(
      (newLocation) {
        setState(() {
          _currentLocation = newLocation;
          currentLocation = newLocation;
        });
      },
    );
  }

  @override
  void initState() {
    super.initState();
    if (currentLocation == null) {
      getCurrentLocation();
    } else {
      _currentLocation = currentLocation;
    }
    getMarkerData();
  }

  void initMarker(specify, specifyId) async {
    LatLng markerLocation = LatLng(specify['dogLocation']['geopoint'].latitude,
        specify['dogLocation']['geopoint'].longitude);
    var markerIdVal = specifyId;
    final MarkerId markerId = MarkerId(markerIdVal);
    final Marker marker = Marker(
      markerId: markerId,
      position: LatLng(specify['dogLocation']['geopoint'].latitude,
          specify['dogLocation']['geopoint'].longitude),
      icon: specify['dogStatus'] == 'Found'
          ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
          : BitmapDescriptor.defaultMarker,
      onTap: () {
        _customInfoWindowController.addInfoWindow!(
          GestureDetector(
            onTap: () {
              //showSnackBar("tapped", context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PostScreen(
                    snap: specify,
                    uid: FirebaseAuth.instance.currentUser!.uid,
                    //postUid: snap['postId'],
                  ),
                ),
              );
            },
            child: Container(
              height: 300,
              width: 200,
              decoration: BoxDecoration(
                color:
                    specify['dogStatus'] == 'Found' ? accentColor : Colors.red,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 300,
                    height: 150,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(
                          specify['postUrl'],
                        ),
                        fit: BoxFit.fitWidth,
                        filterQuality: FilterQuality.high,
                      ),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(10.0),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 10, left: 10, right: 10),
                    child: Center(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            specify['dogStatus'],
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          Text(
                            " ${specify['dogBreed']}",
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          markerLocation,
        );
      },
    );
    setState(() {
      markers.add(marker);
      //print(markerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby You'),
        backgroundColor: mobileBackgroundColor,
      ),
      body: _currentLocation == null
          ? const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  mapType: MapType.normal,
                  zoomControlsEnabled: false,
                  myLocationEnabled: true,
                  markers: Set.from(markers),
                  circles: {
                    Circle(
                        circleId: CircleId("CurrentLocation"),
                        center: LatLng(_currentLocation!.latitude!,
                            _currentLocation!.longitude!),
                        radius: 200,
                        strokeWidth: 1,
                        fillColor: Color(0xFF006491).withOpacity(0.2))
                  },
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_currentLocation!.latitude!,
                        _currentLocation!.longitude!),
                    zoom: 14,
                  ),
                  onTap: (position) {
                    _customInfoWindowController.hideInfoWindow!();
                  },
                  onCameraMove: (position) {
                    _customInfoWindowController.onCameraMove!();
                  },
                  onMapCreated: (GoogleMapController controller) {
                    _customInfoWindowController.googleMapController =
                        controller;
                    _controller.complete(controller);
                  },
                ),
                CustomInfoWindow(
                  controller: _customInfoWindowController,
                  height: 200,
                  width: 300,
                  offset: 35,
                ),
                // DraggableScrollableSheet(
                //   expand: true,
                //   initialChildSize: 0.22,
                //   minChildSize: 0.22,
                //   builder: (BuildContext context,
                //       ScrollController scrollController) {
                //     return Container(
                //       height: MediaQuery.of(context).size.height,
                //       child: SingleChildScrollView(
                //         controller: scrollController,
                //         child: Card(
                //           elevation: 12.0,
                //           shape: RoundedRectangleBorder(
                //               borderRadius: BorderRadius.circular(24)),
                //           margin: const EdgeInsets.all(0),
                //           child: Container(
                //             decoration: BoxDecoration(
                //               borderRadius: BorderRadius.circular(24),
                //             ),
                //             child: Column(
                //               children: <Widget>[
                //                 SizedBox(height: 12),
                //                 CustomDraggingHandle(),
                //                 SizedBox(height: 16),
                //                 Row(
                //                   mainAxisAlignment: MainAxisAlignment.center,
                //                   children: const <Widget>[
                //                     Text("Near by",
                //                         style: TextStyle(
                //                             fontSize: 22,
                //                             color: Colors.black45)),
                //                   ],
                //                 ),
                //                 SizedBox(height: 16),
                //                 Column(
                //                   children: <Widget>[
                //                     Padding(
                //                       padding: const EdgeInsets.fromLTRB(
                //                           16,
                //                           16,
                //                           16,
                //                           8), //adjust "40" according to the status bar size
                //                       child: Container(
                //                         height: 50,
                //                         decoration: BoxDecoration(
                //                             color: Colors.white,
                //                             borderRadius:
                //                                 BorderRadius.circular(6)),
                //                         child: Row(
                //                           children: <Widget>[
                //                             Expanded(
                //                               child: TextFormField(
                //                                 maxLines: 1,
                //                                 decoration:
                //                                     const InputDecoration(
                //                                   contentPadding:
                //                                       EdgeInsets.all(16),
                //                                   hintText: "Search here",
                //                                   border: InputBorder.none,
                //                                 ),
                //                               ),
                //                             ),
                //                           ],
                //                         ),
                //                       ),
                //                     ),
                //                     SingleChildScrollView(
                //                       scrollDirection: Axis.horizontal,
                //                       child: Row(
                //                         children: <Widget>[
                //                           SizedBox(width: 16),
                //                           CustomCategoryChip(
                //                               Icons.fastfood, "Lost"),
                //                           SizedBox(width: 12),
                //                           CustomCategoryChip(
                //                               Icons.directions_bike, "Found"),
                //                           SizedBox(width: 12),
                //                           CustomCategoryChip(
                //                               Icons.local_gas_station,
                //                               "Dog Shelters"),
                //                           SizedBox(width: 12),
                //                         ],
                //                       ),
                //                     ),
                //                   ],
                //                 ),
                //                 SizedBox(height: 24),
                //                 // Text("Lost Dogs", style: TextStyle(fontSize: 14)),
                //                 // SizedBox(height: 16),
                //                 // Padding(
                //                 //   padding:
                //                 //       const EdgeInsets.symmetric(horizontal: 16),
                //                 //   child: GridView.count(
                //                 //     //to avoid scrolling conflict with the dragging sheet
                //                 //     physics: NeverScrollableScrollPhysics(),
                //                 //     padding: const EdgeInsets.all(0),
                //                 //     crossAxisCount: 2,
                //                 //     mainAxisSpacing: 12,
                //                 //     crossAxisSpacing: 12,
                //                 //     shrinkWrap: true,
                //                 //     children: <Widget>[
                //                 //       CustomFeaturedItem(),
                //                 //       CustomFeaturedItem(),
                //                 //       CustomFeaturedItem(),
                //                 //       CustomFeaturedItem(),
                //                 //     ],
                //                 //   ),
                //                 // ),
                //                 // SizedBox(height: 24),
                //                 // Text("Found Dogs",
                //                 //     style: TextStyle(fontSize: 14)),
                //                 // SizedBox(height: 16),
                //                 // Padding(
                //                 //   padding:
                //                 //       const EdgeInsets.symmetric(horizontal: 16),
                //                 //   child: GridView.count(
                //                 //     //to avoid scrolling conflict with the dragging sheet
                //                 //     physics: NeverScrollableScrollPhysics(),
                //                 //     padding: const EdgeInsets.all(0),
                //                 //     crossAxisCount: 2,
                //                 //     mainAxisSpacing: 12,
                //                 //     crossAxisSpacing: 12,
                //                 //     shrinkWrap: true,
                //                 //     children: <Widget>[
                //                 //       CustomFeaturedItem(),
                //                 //       CustomFeaturedItem(),
                //                 //       CustomFeaturedItem(),
                //                 //       CustomFeaturedItem(),
                //                 //     ],
                //                 //   ),
                //                 // ),
                //                 // SizedBox(height: 16),
                //               ],
                //             ),
                //           ),
                //         ),
                //       ),
                //     );
                //   },
                // ),
              ],
            ),
    );
  }
}

class CustomCategoryChip extends StatelessWidget {
  final IconData iconData;
  final String title;

  CustomCategoryChip(this.iconData, this.title);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Row(
        children: <Widget>[
          Icon(
            iconData,
            size: 16,
            color: Colors.black,
          ),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.black,
            ),
          )
        ],
      ),
      backgroundColor: Colors.grey[50],
    );
  }
}

class CustomDraggingHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 5,
      width: 30,
      decoration: BoxDecoration(
          color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
    );
  }
}

class CustomFeaturedItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[500],
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
