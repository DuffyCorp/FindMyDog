import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone/screens/profile_screen.dart';
import 'package:instagram_clone/utils/colors.dart';
import 'package:instagram_clone/widgets/show_image.dart';
import 'package:intl/intl.dart';

class MessageWidget extends StatefulWidget {
  final DocumentSnapshot message;
  final bool isMe;
  const MessageWidget({
    Key? key,
    required this.message,
    required this.isMe,
  }) : super(key: key);

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget> {
  DocumentSnapshot? snap;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    const radius = Radius.circular(12);
    final borderRadius = BorderRadius.all(radius);

    return widget.message['type'] == "text"
        ? Row(
            mainAxisAlignment:
                widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!widget.isMe)
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(
                          uid: widget.message["uid"].toString(),
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 16,
                    backgroundImage:
                        NetworkImage(widget.message["profImage"].toString()),
                  ),
                ),
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    margin: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                    ),
                    constraints: const BoxConstraints(maxWidth: 140),
                    decoration: BoxDecoration(
                      color: widget.isMe ? Colors.grey[100] : accentColor,
                      borderRadius: widget.isMe
                          ? borderRadius
                              .subtract(BorderRadius.only(bottomRight: radius))
                          : borderRadius
                              .subtract(BorderRadius.only(bottomLeft: radius)),
                    ),
                    child: buildMessage(),
                  ),
                  Text(
                    DateFormat.yMMMd().format(
                      widget.message["createdAt"].toDate(),
                    ),
                  ),
                ],
              ),
            ],
          )
        : Row(
            mainAxisAlignment:
                widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!widget.isMe)
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(
                          uid: widget.message["uid"].toString(),
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 16,
                    backgroundImage:
                        NetworkImage(widget.message["profImage"].toString()),
                  ),
                ),
              if (!widget.isMe)
                Container(
                  width: 12,
                ),
              Column(
                children: [
                  Container(
                    height: 200,
                    width: 200,
                    alignment: widget.isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ShowImage(imageUrl: widget.message['message']),
                          ),
                        );
                      },
                      child: Container(
                        height: 200,
                        width: 200,
                        alignment: Alignment.center,
                        child: widget.message['message'] != ""
                            ? Image.network(widget.message['message'])
                            : const CircularProgressIndicator(
                                color: primaryColor,
                              ),
                      ),
                    ),
                  ),
                  Text(
                    DateFormat.yMMMd().format(
                      widget.message["createdAt"].toDate(),
                    ),
                  ),
                ],
              ),
            ],
          );
  }

  Widget buildMessage() => Column(
        crossAxisAlignment:
            widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            widget.message["message"],
            style: TextStyle(color: widget.isMe ? Colors.black : Colors.white),
            textAlign: TextAlign.start,
          )
        ],
      );
}
