import 'dart:convert';

class Payload {
  final String screen;
  final String uid;

  Payload({required this.screen, required this.uid});

  //Add these methods below

  factory Payload.fromJsonString(String str) =>
      Payload._fromJson(jsonDecode(str));

  String toJsonString() => jsonEncode(_toJson());

  factory Payload._fromJson(Map<String, dynamic> json) => Payload(
        screen: json['screen'],
        uid: json['uid'],
      );

  Map<String, dynamic> _toJson() => {
        'screen': screen,
        'uid': uid,
      };
}
