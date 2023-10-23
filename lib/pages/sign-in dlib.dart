import 'dart:async';
import 'package:face_net_authentication/locator.dart';
import 'package:face_net_authentication/pages/models/user.model.dart';
import 'package:face_net_authentication/pages/widgets/auth_button.dart';
import 'package:face_net_authentication/pages/widgets/camera_detection_preview.dart';
import 'package:face_net_authentication/pages/widgets/camera_header.dart';
import 'package:face_net_authentication/pages/widgets/signin_form.dart';
import 'package:face_net_authentication/pages/widgets/single_picture.dart';
import 'package:face_net_authentication/pages/db/databse_helper.dart';
import 'package:face_net_authentication/pages/models/param.model.dart';
import 'package:face_net_authentication/pages/widgets/camera_stack.dart';
import 'package:face_net_authentication/services/camera.service.dart';
import 'package:face_net_authentication/services/ml_service.dart';
import 'package:face_net_authentication/services/face_detector_service.dart';
import 'package:face_net_authentication/services/pub_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:flutter_opencv_dlib/flutter_opencv_dlib.dart';

class SignInDlib extends StatefulWidget {
  const SignInDlib({Key? key}) : super(key: key);

  @override
  SignInDlibState createState() => SignInDlibState();
}

class SignInDlibState extends State<SignInDlib> {
  CameraService _cameraService = locator<CameraService>();
  RecognizerInterface _faceDetectorService = locator<RecognizerInterface>();
  MLService _mlService = locator<MLService>();
  pub_service _pubService = locator<pub_service>();

  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isPictureTaken = false;
  bool _isInitializing = false;
  List<TimeOfDay> _checkinTime = [];
  List<int> _state = []; //是否已播放
  AssetsAudioPlayer audioPlayer = AssetsAudioPlayer();
  late Timer timer;
  bool isElegantNotification = false;
  FacePoints? facepoints;
  double? width;
  List<Param> musicList = [];
  Size? imageSize;

  @override
  void initState() {
    super.initState();
    _initCheckInTime();
    _initMusic();
    _pubService.initialize();
    _mlService.isSignUpSaveImg = false;
    _start_dlib();
    // 設置計時器，每秒檢查一次是否需要播放音樂
    timer = Timer.periodic(Duration(seconds: 1), checkTimeToRing);
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _mlService.dispose();
    timer.cancel();
    audioPlayer.stop();
    super.dispose();
  }

  void checkTimeToRing(Timer timer) {
    // 獲取當前時間
    TimeOfDay now = TimeOfDay.now();
    // 檢查是否有與 checkinTime 中的時間相匹配
    for (var i = 0; i < _checkinTime.length; i++) {
      var time = _checkinTime[i];
      var state = _state[i];
      if (time.hour == now.hour && time.minute == now.minute && state == 0) {
        _state[i] = 1;
        // 播放音樂
        musicList.forEach((element) async {
          if (element.key == Music.ring.description) {
            await playMusic(music: element.val);
          }
        });
      }
    }
  }

  Future<void> playMusic({String? music}) async {
    // 播放音樂的程式碼
    if (music == null) {
      audioPlayer.setVolume(0.8);
      audioPlayer.open(Audio('assets/audios/Short_mistery_003.mp3'));
    }
    audioPlayer.open(Audio.file(music!));
  }

  //Dlib
  _start_dlib() async {
    setState(() => _isInitializing = true);
    await _cameraService.initialize();
    if (!_faceDetectorService.isRecognizerInit) {
      await _faceDetectorService.initRecognizer();
      _faceDetectorService.setInputColorSpace(ColorSpace.SRC_GRAY);
      _faceDetectorService.setRotation(2);
      _faceDetectorService.setFlip(1);
    }
    setState(() => _isInitializing = false);

    _autoframeFacesDlib();
    setState(() {});
  }

  _initCheckInTime() async {
    DatabaseHelper _databaseHelper = DatabaseHelper.instance;
    List<Param> params = await _databaseHelper.queryAllParams();
    params.forEach((pr) {
      if (pr.key == '打卡') {
        List<String> hrmn = pr.val.split(':');
        _checkinTime.add(TimeOfDay(hour: int.parse(hrmn[0]), minute: int.parse(hrmn[1])));
        _state.add(0);
      }
    });
  }

  _initMusic() async {
    DatabaseHelper _databaseHelper = DatabaseHelper.instance;
    List<Param> params = await _databaseHelper.queryAllParams();
    params.forEach((pr) {
      if (pr.key == Music.ring.description) {
        musicList.add(pr);
      } else if (pr.key == Music.success.description) {
        musicList.add(pr);
      } else if (pr.key == Music.fail.description) {
        musicList.add(pr);
      } else if (pr.key == Music.already.description) {
        musicList.add(pr);
      }
    });
  }

  //比較時間差
  _checktimeIsOk(DateTime now, DateTime check) async {
    Duration diff = now.difference(check);
    if (diff.inSeconds > 15) {
      return true;
    }
    return false;
  }

  _autoframeFacesDlib() async {
    imageSize = _cameraService.getImageSize();
    bool processing = false; //相當於全域
    _cameraService.cameraController!.startImageStream((CameraImage image) async {
      if (_pubService.isDebug) return;
      if (processing) return; // prevents unnecessary overprocessing.
      processing = true;
      // await _autoPredictFacesFromImage2(image: image);
      try {
        await _autoPredictFacesFromImageDlib(image: image);
      } catch (e) {
        print('_autoframeFacesFireBase error => $e');
      }
      processing = false;
    });
  }

  //dlib
  Future<void> _autoPredictFacesFromImageDlib({@required CameraImage? image}) async {
    assert(image != null, 'Image is null');
    if (image == null) {
      print('Image is null');
      return;
    }
    await _faceDetectorService.compareFace(
      image.width,
      image.height,
      image.planes[0].bytesPerPixel ?? 1,
      image.planes[0].bytes,
    );
    if (_faceDetectorService.RegFaces != null) {
      List<int> points = [];
      List<RecognizedFace>? faces = _faceDetectorService.RegFaces;
      if (faces == null) return;
      String nm = faces[0].name;
      for (var element in faces) {
        points.addAll(element.rectPoints);
      }
      facepoints = FacePoints(
        faces.length,
        2,
        points,
        List.generate(faces.length, (index) => faces[index].name),
      );
      DatabaseHelper _databaseHelper = DatabaseHelper.instance;
      User? us = await _databaseHelper.getUserByName(nm);
      if (us != null) print('找到使用者: ${us.user}');
      // User us = User(user: nm, userid: '9527', modelData: [
      //   [123]
      // ]);
      try {
        await checkInDialog(user: us);
      } catch (e) {
        print('checkInDialog error => $e');
      }
    } else {
      facepoints = null;
    }
    if (mounted) setState(() {});
  }

  _onBackPressed() async {
    if (!_pubService.intervalClick(2)) return;
    await _cameraService.stopStream();
    await Future.delayed(Duration(seconds: 1)).then((value) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  _reload() {
    if (mounted) setState(() => _isPictureTaken = false);
    _start_dlib();
  }

  Widget getBodyWidget() {
    if (_isInitializing) return Center(child: CircularProgressIndicator());
    if (_isPictureTaken) return SinglePicture(imagePath: _cameraService.imagePath!);
    return CameraStack(
        cameraDescription: _cameraService.description!,
        controller: _cameraService.cameraController!,
        isRunninOnEmulator: false,
        width: width,
        points: facepoints);
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    Widget header = CameraHeader("打卡", onBackPressed: _onBackPressed);
    Widget body = getBodyWidget();

    return Scaffold(
      key: scaffoldKey,
      body: Stack(
        children: [body, header],
      ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // floatingActionButton: fab,
    );
  }

  signInSheet({@required User? user}) {
    return user == null
        ? Container(width: MediaQuery.of(context).size.width, padding: EdgeInsets.all(20), child: Text('未找到使用者 😞', style: TextStyle(fontSize: 20)))
        : SignInSheet(user: user, reload: _reload);
  }

  showGnDialog(IconData ic, Color cl, String msg) {
    //去背
    return showGeneralDialog(
        context: context,
        pageBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation) {
          return AlertDialog(
              surfaceTintColor: Colors.transparent,
              alignment: Alignment(0.0, -0.7),
              content: Container(
                height: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(ic, color: cl),
                    SizedBox(width: 10),
                    Text(msg),
                  ],
                ),
              ));
        },
        barrierDismissible: true,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 150));
  }

  Future<void> useElegantNotification() async {
    isElegantNotification = true;
    await Future.delayed(Duration(milliseconds: 1500));
    isElegantNotification = false;
  }

  checkInDialog({required User? user}) async {
    // useElegantNotification();
    if (user == null) {
      //未找到使用者
      showGnDialog(Icons.cancel, Colors.red, '未找到使用者 😞');
      // ElegantNotification.error(title: Text('Fail'), description: Text('未找到使用者 😞')).show(context);
      musicList.forEach((element) async {
        if (element.key == Music.fail.description) {
          await playMusic(music: element.val);
        }
      });
    } else {
      //有找到使用者
      //是否打卡過
      //判斷是否15s冷卻
      DateTime now = DateTime.now();
      if (user.checktime == '') {
        //沒打卡過
        DatabaseHelper _databaseHelper = DatabaseHelper.instance;
        // await _databaseHelper.updateCheckin(user.id!, 1);
        _databaseHelper.updateChecktime(user.id!, now.toString().substring(0, 19)); // 输出形如 2023-04-22 09:32:14 的字符串
        showGnDialog(Icons.check_circle_outline, Colors.green, '${user.user} 打卡成功!');
        // ElegantNotification.success(title: Text('Success'), description: Text('${user.user} 打卡成功!')).show(context);
        musicList.forEach((element) async {
          if (element.key == Music.success.description) {
            await playMusic(music: element.val);
          }
        });
      } else {
        DateTime checktime = DateTime.parse('${user.checktime}');
        //打卡過 看有沒有冷卻
        if (await _checktimeIsOk(now, checktime)) {
          DatabaseHelper _databaseHelper = DatabaseHelper.instance;
          _databaseHelper.updateChecktime(user.id!, now.toString().substring(0, 19)); // 输出形如 2023-04-22 09:32:14 的字符串
          showGnDialog(Icons.check_circle_outline, Colors.green, '${user.user} 打卡成功!');
          // ElegantNotification.success(title: Text('Success'), description: Text('${user.user} 打卡成功!')).show(context);
          musicList.forEach((element) async {
            if (element.key == Music.success.description) {
              playMusic(music: element.val);
            }
          });
        } else {
          showGnDialog(Icons.hourglass_empty, Colors.orange, '${user.user} 已打卡，請在稍等!');
          musicList.forEach((element) async {
            if (element.key == Music.already.description) {
              playMusic(music: element.val);
            }
          });
          // ElegantNotification(
          //         icon: Icon(Icons.access_alarm, color: Colors.orange),
          //         progressIndicatorColor: Colors.orange,
          //         title: Text('Wait'),
          //         description: Text('${user.user} 已打卡 請在稍等15秒!'))
          //     .show(context);
        }
      }
    }
    // 延遲1秒後自動關閉AlertDialog
    await Future.delayed(Duration(seconds: 1)).then((value) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }
}
