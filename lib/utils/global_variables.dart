import 'package:flutter/material.dart';
import 'package:instagram_clone/screens/home_screen.dart';
import 'package:instagram_clone/screens/image_recognition.dart';
import 'package:instagram_clone/screens/maps_screen.dart';
import 'package:instagram_clone/screens/profile_screen.dart';
import 'package:instagram_clone/screens/search_screen.dart';
import 'package:instagram_clone/screens/swipeScreen.dart';
import 'package:location/location.dart';

//change breakpoint for web application globally
const webScreenSize = 600;

LocationData? currentLocation;

List<Widget> homeScreenItems = [
  const HomeScreen(),
  const SearchScreen(),
  //const NewDogScreen(),
  //const DogStatusScreen(),
  const SwipeScreen(),
  const MapsScreen(),
  const ProfileScreen(),
  const imageRecognition(),
];
