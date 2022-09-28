// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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
    var markerIdVal = specifyId;
    final MarkerId markerId = MarkerId(markerIdVal);
    final Marker marker = Marker(
      markerId: markerId,
      position: LatLng(
          specify['dogLocation'].latitude, specify['dogLocation'].longitude),
      icon: specify['dogStatus'] == 'Found'
          ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
          : BitmapDescriptor.defaultMarker,
      infoWindow:
          InfoWindow(title: '${specify['dogStatus']} ${specify['dogBreed']}'),
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
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_currentLocation!.latitude!,
                        _currentLocation!.longitude!),
                    zoom: 14,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
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
