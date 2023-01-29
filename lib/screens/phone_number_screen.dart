import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_my_dog/utils/colors.dart';
import 'package:find_my_dog/utils/utils.dart';
import 'package:find_my_dog/widgets/text_field_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:what3words/what3words.dart' as w3w;
import 'package:twilio_flutter/twilio_flutter.dart';

class PhoneNumberScreen extends StatefulWidget {
  final PageController controller;
  final reset;
  final String dogBreed;
  final LatLng dogLocation;
  final String postID;

  const PhoneNumberScreen({
    super.key,
    required this.controller,
    required this.reset,
    required this.dogBreed,
    required this.dogLocation,
    required this.postID,
  });

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  String scanning = '';
  bool isLoading = false;
  bool textScanning = false;
  String textFromPic = "";
  List<String> results = [];

  late TwilioFlutter twilioFlutter;

  bool showSMS = true;

  bool showEmail = true;

  String? w3wApi = dotenv.env['WHAT3WORDSKEY'];

  bool isEmail = false;

  final textDetector = GoogleMlKit.vision.textDetector();

  String scannedText = '';

  late File image = File("");

  late TextEditingController phoneController = TextEditingController();

  late TextEditingController emailController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  final mailPattern =
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';

  @override
  void initState() {
    // TODO: implement initState

    String? accountSid = dotenv.env['TWILIO_SID'];
    String? authToken = dotenv.env['TWILIO_TOKEN'];
    String? number = dotenv.env['TWILIO_NUM'];

    twilioFlutter = TwilioFlutter(
      accountSid: accountSid!,
      authToken: authToken!,
      twilioNumber: number!,
    );
    super.initState();
  }

  bool validateMobile(String value) {
    String pattern = r'(^(?:[+0]9)?[0-9]{10,12}$)';
    RegExp regExp = new RegExp(pattern);
    if (value.length == 0) {
      return false;
    } else if (!regExp.hasMatch(value)) {
      return false;
    }
    print("valid");
    return true;
  }

  bool emailValid(String email) {
    return RegExp(mailPattern, multiLine: true).hasMatch(email);
  }

  void _handleFinish() {
    setState(() {
      FocusScope.of(context);
      emailController.text = "";
      phoneController.text = "";
      image = File("");
      scannedText = "";
      results = [];
      widget.reset();
      widget.controller.animateToPage(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.ease,
      );
    });
  }

  Future sendEmail({
    required String email,
    required String subject,
    required String message,
  }) async {
    final serviceId = 'service_s1p6k35';
    final templateId = 'template_46w7jkc';
    final userId = 'uxtrAGfSJHsVEvQyx';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'user_email': email,
          'user_subject': subject,
          'user_message': message,
        }
      }),
    );
  }

  void sendSMS() async {
    var api = w3w.What3WordsV3(w3wApi.toString());

    var words = await api
        .convertTo3wa(w3w.Coordinates(
            widget.dogLocation.latitude, widget.dogLocation.longitude))
        .language('en')
        .execute();

    twilioFlutter.sendSMS(
        toNumber: phoneController.text,
        messageBody:
            "We've had a report of a lost ${widget.dogBreed}.\n\nYou can download the FindMyDog app to view the post, If you do not have the app here are the what 3 words of the location it was found.\n\n${words.data()?.toJson()["words"]}\nhttps://find-my-dog-web.vercel.app/${widget.postID}\n\nIf you do not own a dog of this breed, please ignore this message.");

    setState(() {
      showSMS = false;
    });
  }

  selectImageType() async {
    return showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text('Scan a dog'),
            children: [
              SimpleDialogOption(
                padding: EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Icon(Icons.camera_alt_rounded),
                    Text(' Take a Photo'),
                  ],
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  final XFile? pickedFile = await _picker.pickImage(
                    source: ImageSource.camera,
                  );
                  File imageSelected = File(pickedFile!.path);
                  recogniseText(imageSelected);
                  print(imageSelected);
                  setState(() {
                    scanning = 'scanning';
                    image = imageSelected;
                  });
                },
              ),
              SimpleDialogOption(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.image_rounded),
                    Text(' Select from gallery'),
                  ],
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  final XFile? pickedFile = await _picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  File imageSelected = File(pickedFile!.path);
                  recogniseText(imageSelected);
                  setState(() {
                    scanning = 'scanning';
                    image = imageSelected;
                  });
                },
              ),
              SimpleDialogOption(
                padding: EdgeInsets.all(20),
                child: const Text('Cancel'),
                onPressed: () async {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  void recogniseText(File image) async {
    LineSplitter lineSplitter = const LineSplitter();
    setState(() {
      textScanning = true;
      scannedText = "";
      results = [];
    });

    final inputImage = InputImage.fromFile(image);

    final RecognisedText recognisedText =
        await textDetector.processImage(inputImage);

    String text = recognisedText.text;
    for (TextBlock block in recognisedText.blocks) {
      final Rect rect = block.rect;
      final List<Offset> cornerPoints = block.cornerPoints;
      final String text = block.text;
      final List<String> languages = block.recognizedLanguages;

      for (TextLine line in block.lines) {
        // Same getters as TextBlock
        String? temp = "";
        for (TextElement element in line.elements) {
          if (isEmail) {
            print(element.text);
            final regEx =
                RegExp(mailPattern, multiLine: true, caseSensitive: false);
            var matches = regEx.firstMatch(element.text);

            temp = matches?.group(0);
          } else {
            temp = element.text.replaceAll(RegExp(r'[^0-9]'), '');
          }
          if (temp != null) {
            if (temp.length > 1) {
              if (isEmail) {
                results.add(temp);

                textFromPic = textFromPic + temp + '\n';
              } else {
                if (validateMobile(temp)) {
                  temp = "$temp";

                  results.add(temp);

                  textFromPic = textFromPic + temp + '\n';
                }
              }
            }
          }
        }
      }
    }
    textFromPic.replaceAll(RegExp(r'[^0-9]'), '');

    scannedText = "$textFromPic";

    textScanning = false;
    setState(() {});
  }

  void _sendSMS(String message) async {
    try {
      // List<String> recipients = [phoneController.text];
      // String _result = await sendSMS(message: message, recipients: recipients)
      //     .catchError((onError) {
      //   print(onError);
      // });
      // print(_result);

    } catch (err) {
      showSnackBar("Unable to send text", context);
    }
  }

  void _sendEmail() async {
    // final Email email = Email(
    //   body: "test",
    //   subject: "test",
    //   recipients: [emailController.text],
    //   isHTML: false,
    // );

    // await FlutterEmailSender.send(email);

    // String message =
    //     "We've had a report of a lost ${widget.dogBreed}.\nYou can download the FindMyDog app to view the post, If you do not have the app here are the what 3 words of the location it was found.\n<a href='${words.data()?.toJson()["map"]}'>${words.data()?.toJson()["words"]}</a>\nIf you do not own a dog of this breed, please ignore this email.";
    var api = w3w.What3WordsV3(w3wApi.toString());

    var words = await api
        .convertTo3wa(w3w.Coordinates(
            widget.dogLocation.latitude, widget.dogLocation.longitude))
        .language('en')
        .execute();
    String message = """<!doctype html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <title>Simple Transactional Email</title>
    <style>
@media only screen and (max-width: 620px) {
  table.body h1 {
    font-size: 28px !important;
    margin-bottom: 10px !important;
  }

  table.body p,
table.body ul,
table.body ol,
table.body td,
table.body span,
table.body a {
    font-size: 16px !important;
  }

  table.body .wrapper,
table.body .article {
    padding: 10px !important;
  }

  table.body .content {
    padding: 0 !important;
  }

  table.body .container {
    padding: 0 !important;
    width: 100% !important;
  }

  table.body .main {
    border-left-width: 0 !important;
    border-radius: 0 !important;
    border-right-width: 0 !important;
  }

  table.body .btn table {
    width: 100% !important;
  }

  table.body .btn a {
    width: 100% !important;
  }

  table.body .img-responsive {
    height: auto !important;
    max-width: 100% !important;
    width: auto !important;
  }
}
@media all {
  .ExternalClass {
    width: 100%;
  }

  .ExternalClass,
.ExternalClass p,
.ExternalClass span,
.ExternalClass font,
.ExternalClass td,
.ExternalClass div {
    line-height: 100%;
  }

  .apple-link a {
    color: inherit !important;
    font-family: inherit !important;
    font-size: inherit !important;
    font-weight: inherit !important;
    line-height: inherit !important;
    text-decoration: none !important;
  }

  #MessageViewBody a {
    color: inherit;
    text-decoration: none;
    font-size: inherit;
    font-family: inherit;
    font-weight: inherit;
    line-height: inherit;
  }

  .btn-primary table td:hover {
    background-color: #34495e !important;
  }

  .btn-primary a:hover {
    background-color: #34495e !important;
    border-color: #34495e !important;
  }
}
</style>
  </head>
  <body style="background-color: #f6f6f6; font-family: sans-serif; -webkit-font-smoothing: antialiased; font-size: 14px; line-height: 1.4; margin: 0; padding: 0; -ms-text-size-adjust: 100%; -webkit-text-size-adjust: 100%;">
    <span class="preheader" style="color: transparent; display: none; height: 0; max-height: 0; max-width: 0; opacity: 0; overflow: hidden; mso-hide: all; visibility: hidden; width: 0;">A lost dog has been reported!</span>
    <table role="presentation" border="0" cellpadding="0" cellspacing="0" class="body" style="border-collapse: separate; mso-table-lspace: 0pt; mso-table-rspace: 0pt; background-color: #f6f6f6; width: 100%;" width="100%" bgcolor="#f6f6f6">
      <tr>
        <td style="font-family: sans-serif; font-size: 14px; vertical-align: top;" valign="top">&nbsp;</td>
        <td class="container" style="font-family: sans-serif; font-size: 14px; vertical-align: top; display: block; max-width: 580px; padding: 10px; width: 580px; margin: 0 auto;" width="580" valign="top">
          <div class="content" style="box-sizing: border-box; display: block; margin: 0 auto; max-width: 580px; padding: 10px;">

            <!-- START CENTERED WHITE CONTAINER -->
            <table role="presentation" class="main" style="border-collapse: separate; mso-table-lspace: 0pt; mso-table-rspace: 0pt; background: #ffffff; border-radius: 3px; width: 100%;" width="100%">

              <!-- START MAIN CONTENT AREA -->
              <tr>
                <td class="wrapper" style="font-family: sans-serif; font-size: 14px; vertical-align: top; box-sizing: border-box; padding: 20px;" valign="top">
                  <table role="presentation" border="0" cellpadding="0" cellspacing="0" style="border-collapse: separate; mso-table-lspace: 0pt; mso-table-rspace: 0pt; width: 100%;" width="100%">
                    <tr>
                      <td style="font-family: sans-serif; font-size: 14px; vertical-align: top;" valign="top">
                        <p style="font-family: sans-serif; font-size: 14px; font-weight: normal; margin: 0; margin-bottom: 15px;">We've had a report!</p>
                        <p style="font-family: sans-serif; font-size: 14px; font-weight: normal; margin: 0; margin-bottom: 15px;">We've had a report of a lost ${widget.dogBreed}.</p>
                        <p style="font-family: sans-serif; font-size: 14px; font-weight: normal; margin: 0; margin-bottom: 15px;">You can download the FindMyDog app to view the post, If you do not have the app is a link to view the post.</p>
                        <table role="presentation" border="0" cellpadding="0" cellspacing="0" class="btn btn-primary" style="border-collapse: separate; mso-table-lspace: 0pt; mso-table-rspace: 0pt; box-sizing: border-box; width: 100%;" width="100%">
                          <tbody>
                            <tr>
                              <td align="left" style="font-family: sans-serif; font-size: 14px; vertical-align: top; padding-bottom: 15px;" valign="top">
                                <table role="presentation" border="0" cellpadding="0" cellspacing="0" style="border-collapse: separate; mso-table-lspace: 0pt; mso-table-rspace: 0pt; width: auto;">
                                  <tbody>
                                    <tr>
                                      <td style="font-family: sans-serif; font-size: 14px; vertical-align: top; border-radius: 5px; text-align: center; text-transform: capitalize; background-color: #05AD05;" valign="top" align="center" bgcolor="#05AD05"> <a href="https://find-my-dog-web.vercel.app/${widget.postID}" target="_blank" style="border: solid 1px #3498db; border-radius: 5px; box-sizing: border-box; cursor: pointer; display: inline-block; font-size: 14px; font-weight: bold; margin: 0; padding: 12px 25px; text-decoration: none; background-color: #05AD05; border-color: #05AD05; color: #ffffff;">View</a> </td>
                                    </tr>
                                  </tbody>
                                </table>
                              </td>
                            </tr>
                          </tbody>
                        </table>
                        <p style="font-family: sans-serif; font-size: 14px; font-weight: normal; margin: 0; margin-bottom: 15px;">If you do not own a dog of this breed, please ignore this email.</p>
                        <p style="font-family: sans-serif; font-size: 14px; font-weight: normal; margin: 0; margin-bottom: 15px;">Best wishes! Find My Dog Team.</p>
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>

            <!-- END MAIN CONTENT AREA -->
            </table>
            <!-- END CENTERED WHITE CONTAINER -->

          </div>
        </td>
        <td style="font-family: sans-serif; font-size: 14px; vertical-align: top;" valign="top">&nbsp;</td>
      </tr>
    </table>
  </body>
</html>""";
    sendEmail(
      email: emailController.text,
      subject: "Lost a dog?",
      message: message,
    );
    setState(() {
      showEmail = false;
    });
  }

  void submitPhone() {
    if (phoneController.text == '') {
      showSnackBar("Please enter a phone number", context);
    } else {
      if (validateMobile(phoneController.text)) {
        // _sendSMS("message");
        sendSMS();
      } else {
        showSnackBar("Please enter a valid phone number", context);
      }
    }
  }

  void submitEmail() async {
    if (emailController.text == '') {
      showSnackBar("Please enter an email address", context);
    } else {
      if (emailValid(emailController.text)) {
        _sendEmail();
      } else {
        showSnackBar("Please enter a valid email address", context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    PageController controller = widget.controller;
    return scanning == 'scanning'
        //
        //
        // IF ML SET TO SCANNING SHOW ML SCREEN
        //
        //
        ? Scaffold(
            appBar: AppBar(
              backgroundColor: mobileBackgroundColor,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                ),
                onPressed: () {
                  setState(() {
                    scanning = '';
                    scannedText = '';
                  });
                },
              ),
              title: const Text('Scanning phone number'),
              centerTitle: false,
            ),
            //Show image
            body: ListView(
              children: [
                (image != null)
                    ?
                    //if imageSelect has data show image
                    Container(
                        margin: const EdgeInsets.all(10),
                        child: Image.file(image),
                      )
                    :
                    //else if imageSelect doesnt have data show No image selected message
                    Container(
                        margin: const EdgeInsets.all(10),
                        child: const Opacity(
                          opacity: 0.8,
                          child: Center(
                            child: Text('No image selected'),
                          ),
                        ),
                      ),
                //Show ML model results that are clickable
                // SingleChildScrollView(
                //   child: Container(
                //     child: textScanning
                //         ? const CircularProgressIndicator(
                //             color: primaryColor,
                //           )
                //         : Text(scannedText),
                //   ),
                // ),
                SingleChildScrollView(
                  child: Column(
                    children: results.length > 0
                        ? results.map(
                            (result) {
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isEmail) {
                                      emailController.text = result;
                                    } else {
                                      phoneController.text = result;
                                    }
                                    scanning = "";
                                  });
                                },
                                child: Card(
                                  child: Container(
                                    margin: EdgeInsets.all(10),
                                    child: Text(
                                      result,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ).toList()
                        : [],
                  ),
                ),
                SizedBox(
                  height: 100,
                )
              ],
            ),
          )
        : Scaffold(
            appBar: AppBar(
              backgroundColor: mobileBackgroundColor,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                ),
                onPressed: () {
                  widget.controller.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.ease,
                  );
                },
              ),
              title: Text("Contact"),
              centerTitle: false,
            ),
            body: Container(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 24,
                    ),
                    showSMS
                        ? Row(
                            children: [
                              Expanded(
                                child: TextFieldInput(
                                  textEditingController: phoneController,
                                  hintText: 'Enter phone number',
                                  textInputType: TextInputType.number,
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: accentColor,
                                      child: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            isEmail = false;
                                          });
                                          selectImageType();
                                        },
                                        icon: const Icon(
                                          Icons.camera_alt_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const Text('Scan a phone number')
                                  ],
                                ),
                              ),
                            ],
                          )
                        : const Text("Text message sent"),
                    //text field for dog breed
                    const SizedBox(
                      height: 24,
                    ),
                    showSMS
                        ? InkWell(
                            onTap: () {
                              submitPhone();
                            },
                            child: Container(
                              width: double.infinity,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: const ShapeDecoration(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(4),
                                    ),
                                  ),
                                  color: accentColor),
                              child: isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        color: primaryColor,
                                      ),
                                    )
                                  : const Text('Send text'),
                            ),
                          )
                        : SizedBox(),
                    const SizedBox(
                      height: 12,
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    showEmail
                        ? Row(
                            children: [
                              Expanded(
                                child: TextFieldInput(
                                  textEditingController: emailController,
                                  hintText: 'Enter email address',
                                  textInputType: TextInputType.text,
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: accentColor,
                                      child: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            isEmail = true;
                                          });
                                          selectImageType();
                                        },
                                        icon: const Icon(
                                          Icons.camera_alt_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const Text('Scan an email address')
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Text("Email sent"),

                    const SizedBox(
                      height: 24,
                    ),

                    showEmail
                        ?
                        //buttom for login
                        InkWell(
                            onTap: () {
                              submitEmail();
                            },
                            child: Container(
                              width: double.infinity,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: const ShapeDecoration(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(4),
                                    ),
                                  ),
                                  color: accentColor),
                              child: isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        color: primaryColor,
                                      ),
                                    )
                                  : const Text('Send email'),
                            ),
                          )
                        : SizedBox(),
                    const SizedBox(
                      height: 12,
                    ),
                    const SizedBox(
                      height: 36,
                    ),

                    //buttom for login
                    InkWell(
                      onTap: () {
                        _handleFinish();
                      },
                      child: Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: const ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(4),
                              ),
                            ),
                            color: accentColor),
                        child: isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: primaryColor,
                                ),
                              )
                            : const Text('Finish'),
                      ),
                    ),
                    Flexible(
                      flex: 2,
                      child: Container(),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}
