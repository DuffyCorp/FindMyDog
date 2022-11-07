import 'package:find_my_dog/screens/swipeScreen.dart';
import 'package:flutter/material.dart';
import 'package:find_my_dog/screens/home_screen.dart';
import 'package:find_my_dog/screens/maps_screen.dart';
import 'package:find_my_dog/screens/profile_screen.dart';
import 'package:find_my_dog/screens/search_screen.dart';
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
];
