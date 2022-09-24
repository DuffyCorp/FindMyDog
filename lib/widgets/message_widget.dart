import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone/screens/profile_screen.dart';
import 'package:instagram_clone/utils/colors.dart';
import 'package:instagram_clone/widgets/show_image.dart';
import 'package:intl/intl.dart';

class MessageWidget extends StatefulWidget {
  final DocumentSnapshot message;
  final bool isMe;
  final int index;
  final bool hideProf;
  const MessageWidget({
    Key? key,
    required this.message,
    required this.isMe,
    required this.index,
    this.hideProf = false,
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
                widget.hideProf
                    ? Container(
                        width: 32,
                      )
                    : InkWell(
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
                          backgroundImage: NetworkImage(
                              widget.message["profImage"].toString()),
                        ),
                      ),
              Container(
                margin: widget.hideProf
                    ? const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        //top: 5,
                        bottom: 3,
                      )
                    : const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        //top: 16,
                      ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          constraints: const BoxConstraints(maxWidth: 140),
                          decoration: BoxDecoration(
                            color: widget.isMe ? Colors.grey[100] : accentColor,
                            borderRadius: widget.isMe
                                ? borderRadius.subtract(
                                    widget.hideProf
                                        ? const BorderRadius.only()
                                        : const BorderRadius.only(
                                            bottomRight: radius),
                                  )
                                : borderRadius.subtract(
                                    widget.hideProf
                                        ? const BorderRadius.only()
                                        : const BorderRadius.only(
                                            bottomLeft: radius),
                                  ),
                          ),
                          child: buildMessage(),
                        ),
                      ],
                    ),
                    widget.hideProf
                        ? Container()
                        : Row(
                            children: [
                              widget.index == 0
                                  ? widget.isMe
                                      ? Positioned(
                                          bottom: -3,
                                          left: -3,
                                          child: Icon(
                                            widget.message["read"] == false
                                                ? Icons.check
                                                : Icons.remove_red_eye,
                                            size: 15,
                                          ),
                                        )
                                      : Container()
                                  : Container(),
                              Text(
                                DateFormat('HH:mm').format(
                                  widget.message["createdAt"].toDate(),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
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
              Container(
                margin: widget.hideProf
                    ? const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        //top: 5,
                        bottom: 3,
                      )
                    : const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        //top: 16,
                      ),
                child: Column(
                  children: [
                    Container(
                      width: 200,
                      alignment: widget.isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ShowImage(
                                  imageUrl: widget.message['message']),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
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
                    Row(
                      children: [
                        widget.index == 0
                            ? widget.isMe
                                ? Positioned(
                                    bottom: -3,
                                    left: -3,
                                    child: Icon(
                                      widget.message["read"] == false
                                          ? Icons.check
                                          : Icons.remove_red_eye,
                                      size: 15,
                                    ),
                                  )
                                : Container()
                            : Container(),
                        Text(
                          DateFormat('HH:mm').format(
                            widget.message["createdAt"].toDate(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
