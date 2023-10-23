import 'package:face_net_authentication/constants/constants.dart';
import 'package:face_net_authentication/locator.dart';
import 'package:face_net_authentication/pages/db/databse_helper.dart';
import 'package:face_net_authentication/pages/sign-in.dart';
import 'package:face_net_authentication/pages/sign-up.dart';
import 'package:face_net_authentication/pages/sign-up manual.dart';
import 'package:face_net_authentication/pages/sign-up dlib.dart';
import 'package:face_net_authentication/pages/sign-in dlib.dart';
import 'package:face_net_authentication/pages/database_ring.dart';
import 'package:face_net_authentication/pages/database_user.dart';
import 'package:face_net_authentication/pages/database_data.dart';
import 'package:face_net_authentication/services/camera.service.dart';
import 'package:face_net_authentication/services/ml_service.dart';
import 'package:face_net_authentication/services/face_detector_service.dart';
import 'package:face_net_authentication/services/pub_service.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_opencv_dlib/flutter_opencv_dlib.dart';
import 'package:face_net_authentication/pages/database_music.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  MLService _mlService = locator<MLService>();
  FaceDetectorService _mlKitService = locator<FaceDetectorService>();
  CameraService _cameraService = locator<CameraService>();
  DetectorInterface _faceDetectorService = locator<DetectorInterface>(); //dlib
  // RecognizerInterface _faceReCognizerService = locator<RecognizerInterface>(); //dlib
  pub_service _pubService = locator<pub_service>();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  _initializeServices() async {
    setState(() => loading = true);
    // await _cameraService.initialize();
    await _mlService.initialize();
    _mlKitService.initialize();
    await _faceDetectorService.initDetector();
    _faceDetectorService.setInputColorSpace(ColorSpace.SRC_GRAY);
    _faceDetectorService.setRotation(2);
    _faceDetectorService.setFlip(1);
    // await _faceReCognizerService.initRecognizer();
    // _faceReCognizerService.setInputColorSpace(ColorSpace.SRC_GRAY);
    // _faceReCognizerService.setRotation(2);
    // _faceReCognizerService.setFlip(1);
    setState(() => loading = false);
    _showDialog();
  }

  void _launchURL() async =>
      await canLaunch(Constants.githubURL) ? await launch(Constants.githubURL) : throw 'Could not launch ${Constants.githubURL}';

  void _showDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final modelExist = _mlService.checkModelExist();
        return AlertDialog(
          content: modelExist ? Text("模型加載成功!") : Text("模型加載失敗!"),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    _pubService.widgetSize = MediaQuery.of(context).size;
    _pubService.setWindowRect(width / 2, height / 2 - 40); //為了註冊與打卡的設定
    return Scaffold(
      extendBodyBehindAppBar: true, //透明度 穿透
      appBar: AppBar(
        // leading: Container(),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 20, top: 20),
            child: PopupMenuButton<String>(
              child: Icon(
                Icons.more_vert,
                color: Colors.black,
              ),
              onSelected: (value) {
                switch (value) {
                  case '清除資料庫':
                    DatabaseHelper _dataBaseHelper = DatabaseHelper.instance;
                    _dataBaseHelper.deleteAll(DatabaseHelper.user_table);
                    break;
                }
              },
              itemBuilder: (BuildContext context) {
                return {'清除資料庫'}.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                }).toList();
              },
            ),
          ),
        ],
      ),
      body: !loading
          ? SingleChildScrollView(
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Image(image: AssetImage('assets/logo.png')),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: Column(
                          children: [
                            Text(
                              "人臉辨識",
                              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              "打卡系統",
                              style: TextStyle(
                                fontSize: 20,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(
                              height: 10,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (BuildContext context) => SignIn(),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.1),
                                    blurRadius: 1,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              width: MediaQuery.of(context).size.width * 0.8,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '登入',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Icon(Icons.login, color: Colors.black)
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          // InkWell(
                          //   onTap: () {
                          //     Navigator.push(
                          //       context,
                          //       MaterialPageRoute(
                          //         builder: (BuildContext context) => SignUp(),
                          //         settings: RouteSettings(name: '/signup'),
                          //       ),
                          //     );
                          //   },
                          //   child: Container(
                          //     decoration: BoxDecoration(
                          //       borderRadius: BorderRadius.circular(10),
                          //       color: Colors.black12,
                          //       boxShadow: <BoxShadow>[
                          //         BoxShadow(
                          //           color: Colors.blue.withOpacity(0.1),
                          //           blurRadius: 1,
                          //           offset: Offset(0, 2),
                          //         ),
                          //       ],
                          //     ),
                          //     alignment: Alignment.center,
                          //     padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          //     width: MediaQuery.of(context).size.width * 0.8,
                          //     child: Row(
                          //       mainAxisAlignment: MainAxisAlignment.center,
                          //       children: [
                          //         Text(
                          //           '註冊',
                          //           style: TextStyle(color: Colors.white),
                          //         ),
                          //         SizedBox(
                          //           width: 10,
                          //         ),
                          //         Icon(Icons.person_add, color: Colors.white)
                          //       ],
                          //     ),
                          //   ),
                          // ),
                          // SizedBox(
                          //   height: 20,
                          //   width: MediaQuery.of(context).size.width * 0.8,
                          //   child: Divider(
                          //     thickness: 2,
                          //   ),
                          // ),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (BuildContext context) => SignUpManual(),
                                  settings: RouteSettings(name: '/signupManual'),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.black26,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.1),
                                    blurRadius: 1,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              width: MediaQuery.of(context).size.width * 0.8,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '註冊',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Icon(Icons.person_add, color: Colors.white)
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 20,
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: Divider(
                              thickness: 2,
                            ),
                          ),
                          // InkWell(
                          //   onTap: () {
                          //     Navigator.push(
                          //       context,
                          //       MaterialPageRoute(
                          //         builder: (BuildContext context) => SignUpDlib(),
                          //         settings: RouteSettings(name: '/signupDlib'),
                          //       ),
                          //     );
                          //   },
                          //   child: Container(
                          //     decoration: BoxDecoration(
                          //       borderRadius: BorderRadius.circular(10),
                          //       color: Colors.black38,
                          //       boxShadow: <BoxShadow>[
                          //         BoxShadow(
                          //           color: Colors.blue.withOpacity(0.1),
                          //           blurRadius: 1,
                          //           offset: Offset(0, 2),
                          //         ),
                          //       ],
                          //     ),
                          //     alignment: Alignment.center,
                          //     padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          //     width: MediaQuery.of(context).size.width * 0.8,
                          //     child: Row(
                          //       mainAxisAlignment: MainAxisAlignment.center,
                          //       children: [
                          //         Text(
                          //           'Dlib註冊',
                          //           style: TextStyle(color: Colors.white),
                          //         ),
                          //         SizedBox(
                          //           width: 10,
                          //         ),
                          //         Icon(Icons.person_add, color: Colors.white)
                          //       ],
                          //     ),
                          //   ),
                          // ),
                          // SizedBox(
                          //   height: 20,
                          //   width: MediaQuery.of(context).size.width * 0.8,
                          //   child: Divider(
                          //     thickness: 2,
                          //   ),
                          // ),
                          // InkWell(
                          //   onTap: () {
                          //     Navigator.push(
                          //       context,
                          //       MaterialPageRoute(
                          //         builder: (BuildContext context) => SignInDlib(),
                          //         settings: RouteSettings(name: '/signinDlib'),
                          //       ),
                          //     );
                          //   },
                          //   child: Container(
                          //     decoration: BoxDecoration(
                          //       borderRadius: BorderRadius.circular(10),
                          //       color: Colors.black45,
                          //       boxShadow: <BoxShadow>[
                          //         BoxShadow(
                          //           color: Colors.blue.withOpacity(0.1),
                          //           blurRadius: 1,
                          //           offset: Offset(0, 2),
                          //         ),
                          //       ],
                          //     ),
                          //     alignment: Alignment.center,
                          //     padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          //     width: MediaQuery.of(context).size.width * 0.8,
                          //     child: Row(
                          //       mainAxisAlignment: MainAxisAlignment.center,
                          //       children: [
                          //         Text(
                          //           'Dlib登入',
                          //           style: TextStyle(color: Colors.white),
                          //         ),
                          //         SizedBox(
                          //           width: 10,
                          //         ),
                          //         Icon(Icons.account_circle, color: Colors.white)
                          //       ],
                          //     ),
                          //   ),
                          // ),
                          // SizedBox(
                          //   height: 20,
                          //   width: MediaQuery.of(context).size.width * 0.8,
                          //   child: Divider(
                          //     thickness: 2,
                          //   ),
                          // ),
                          // InkWell(
                          //   onTap: () {
                          //     Navigator.push(
                          //       context,
                          //       MaterialPageRoute(
                          //         builder: (BuildContext context) => DlibPage(),
                          //         settings: RouteSettings(name: '/dlib'),
                          //       ),
                          //     );
                          //   },
                          //   child: Container(
                          //     decoration: BoxDecoration(
                          //       borderRadius: BorderRadius.circular(10),
                          //       color: Colors.brown,
                          //       boxShadow: <BoxShadow>[
                          //         BoxShadow(
                          //           color: Colors.blue.withOpacity(0.1),
                          //           blurRadius: 1,
                          //           offset: Offset(0, 2),
                          //         ),
                          //       ],
                          //     ),
                          //     alignment: Alignment.center,
                          //     padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          //     width: MediaQuery.of(context).size.width * 0.8,
                          //     child: Row(
                          //       mainAxisAlignment: MainAxisAlignment.center,
                          //       children: [
                          //         Text(
                          //           '追蹤測試',
                          //           style: TextStyle(color: Colors.white),
                          //         ),
                          //         SizedBox(
                          //           width: 10,
                          //         ),
                          //         Icon(Icons.face_sharp, color: Colors.white)
                          //       ],
                          //     ),
                          //   ),
                          // ),
                          // SizedBox(
                          //   height: 20,
                          //   width: MediaQuery.of(context).size.width * 0.8,
                          //   child: Divider(
                          //     thickness: 2,
                          //   ),
                          // ),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (BuildContext context) => databaseMusicpage(),
                                  settings: RouteSettings(name: '/music'),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.black54,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.1),
                                    blurRadius: 1,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              width: MediaQuery.of(context).size.width * 0.8,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '音樂',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Icon(Icons.music_note, color: Colors.white)
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 20,
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: Divider(
                              thickness: 2,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (BuildContext context) => databaseRingpage(),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.black87,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.1),
                                    blurRadius: 1,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              width: MediaQuery.of(context).size.width * 0.8,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '時間',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  FaIcon(
                                    Icons.notifications_active,
                                    color: Colors.white,
                                  )
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 20,
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: Divider(
                              thickness: 2,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (BuildContext context) => databaseUserpage(),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.black,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.1),
                                    blurRadius: 1,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              width: MediaQuery.of(context).size.width * 0.8,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '用戶',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  FaIcon(
                                    FontAwesomeIcons.user,
                                    color: Colors.white,
                                  )
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 20,
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: Divider(
                              thickness: 2,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (BuildContext context) => databaseDatapage(),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.black,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.1),
                                    blurRadius: 1,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              width: MediaQuery.of(context).size.width * 0.8,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '參數',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  FaIcon(
                                    FontAwesomeIcons.database,
                                    color: Colors.white,
                                  )
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 20,
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: Divider(
                              thickness: 2,
                            ),
                          ),
                          // InkWell(
                          //   onTap: _launchURL,
                          //   child: Container(
                          //     decoration: BoxDecoration(
                          //       borderRadius: BorderRadius.circular(10),
                          //       color: Colors.black,
                          //       boxShadow: <BoxShadow>[
                          //         BoxShadow(
                          //           color: Colors.blue.withOpacity(0.1),
                          //           blurRadius: 1,
                          //           offset: Offset(0, 2),
                          //         ),
                          //       ],
                          //     ),
                          //     alignment: Alignment.center,
                          //     padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          //     width: MediaQuery.of(context).size.width * 0.8,
                          //     child: Row(
                          //       mainAxisAlignment: MainAxisAlignment.center,
                          //       children: [
                          //         Text(
                          //           'CONTRIBUTE',
                          //           style: TextStyle(color: Colors.white),
                          //         ),
                          //         SizedBox(
                          //           width: 10,
                          //         ),
                          //         FaIcon(
                          //           FontAwesomeIcons.github,
                          //           color: Colors.white,
                          //         )
                          //       ],
                          //     ),
                          //   ),
                          // ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
