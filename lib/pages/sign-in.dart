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
import 'package:dio/dio.dart';

class SignIn extends StatefulWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  SignInState createState() => SignInState();
}

class SignInState extends State<SignIn> {
  CameraService _cameraService = locator<CameraService>();
  DetectorInterface _faceDetectorService2 = locator<DetectorInterface>(); //dlib
  FaceDetectorService _faceDetectorService = locator<FaceDetectorService>();
  MLService _mlService = locator<MLService>();
  pub_service _pubService = locator<pub_service>();
  Dio dio = Dio();

  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isPictureTaken = false;
  bool _isInitializing = false;
  bool serviceMode = true; //True firebase False dlib
  List<TimeOfDay> _checkinTime = [];
  List<int> _state = []; //是否已播放
  AssetsAudioPlayer audioPlayer = AssetsAudioPlayer();
  late Timer timer;
  bool isElegantNotification = false;
  FacePoints? facepoints;
  double? width;
  List<Param> musicList = [];
  Size? imageSize;
  List<Param> ParamList = [];
  int coldtime = 15; //seconds
  int showtime = 1000; //milliseconds

  @override
  void initState() {
    super.initState();
    try {
      _initCheckInTime(); //打卡時間
      _initMusic(); //設定音樂
      _initParam();
      _pubService.initialize();
      _mlService.isSignUpSaveImg = false;
      serviceMode ? _start_firebase() : _start_dlib();
      // 設置計時器，每秒檢查一次是否需要播放音樂
      timer = Timer.periodic(Duration(seconds: 1), checkTimeToRing);
    } catch (e) {
      print('initState error => $e');
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _mlService.dispose();
    _faceDetectorService.dispose();
    timer.cancel();
    audioPlayer.stop();
    super.dispose();
  }

  //模式切換
  _changeServiceMode() async {
    await _cameraService.stopStream();
    serviceMode = !serviceMode;
    _reload();
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

  _start_firebase() async {
    setState(() => _isInitializing = true);
    await _cameraService.initialize();
    setState(() => _isInitializing = false);
    _autoframeFacesFireBase();
  }

  //Dlib
  _start_dlib() async {
    setState(() => _isInitializing = true);
    await _cameraService.initialize();
    if (!_faceDetectorService2.isDetectorInit) {
      await _faceDetectorService2.initDetector();
      _faceDetectorService2.setInputColorSpace(ColorSpace.SRC_GRAY);
      _faceDetectorService2.setRotation(2);
      _faceDetectorService2.setFlip(1);
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

  _initParam() async {
    DatabaseHelper _databaseHelper = DatabaseHelper.instance;
    //url
    ParamList = await _databaseHelper.queryByColumnLike(DatabaseHelper.param_table, DatabaseHelper.columnKey, Param_enum.url.description);
    if (ParamList.isNotEmpty) {
      print(ParamList[0].val);
      dio.options.baseUrl = ParamList[0].val;
    }
    //coldtime
    ParamList = await _databaseHelper.queryByColumnLike(DatabaseHelper.param_table, DatabaseHelper.columnKey, Param_enum.coldtime.description);
    if (ParamList.isNotEmpty) {
      print(ParamList[0].val);
      coldtime = int.parse(ParamList[0].val);
    }
    //coldtime
    ParamList = await _databaseHelper.queryByColumnLike(DatabaseHelper.param_table, DatabaseHelper.columnKey, Param_enum.showtime.description);
    if (ParamList.isNotEmpty) {
      print(ParamList[0].val);
      showtime = int.parse(ParamList[0].val);
    }
  }

  //比較時間差
  _checktimeIsOk(DateTime now, DateTime check) async {
    Duration diff = now.difference(check);
    if (diff.inSeconds > coldtime) {
      return true;
    }
    return false;
  }

  _frameFaces() async {
    bool processing = false;
    _cameraService.cameraController!.startImageStream((CameraImage image) async {
      if (processing) return; // prevents unnecessary overprocessing.
      processing = true;
      await _predictFacesFromImage(image: image);
      processing = false;
    });
  }

  _autoframeFacesFireBase() async {
    bool processing = false;
    _cameraService.cameraController!.startImageStream((CameraImage image) async {
      if (processing) return; // prevents unnecessary overprocessing.
      processing = true;
      try {
        await _autoPredictFacesFromImageFireBase(image: image);
      } catch (e) {
        print('_autoframeFacesFireBase error => $e');
      }
      processing = false;
    });
  }

  _autoframeFacesDlib() async {
    imageSize = _cameraService.getImageSize();
    bool processing = false; //相當於全域
    _faceDetectorService2.setGetOnlyRectangle(true);
    _cameraService.cameraController!.startImageStream((CameraImage image) async {
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

  //firebase
  Future<void> _autoPredictFacesFromImageFireBase({@required CameraImage? image}) async {
    assert(image != null, 'Image is null');
    await _faceDetectorService.detectFacesFromImage(image!);
    //送一張照片進去 加開關控制
    if (_faceDetectorService.faceDetected) {
      _pubService.isOverlay = _pubService.checkRectOverlap(
          _pubService.scaleRect(
              rect: _faceDetectorService.faces[0].boundingBox, imageSize: _cameraService.getImageSize(), widgetSize: _pubService.widgetSize!),
          _pubService.WindowRect!,
          0.75);
      if (_pubService.isOverlay) {
        _mlService.setCurrentPrediction(image, _faceDetectorService.faces[0]);
        User? user = await _mlService.predict();
        await checkInDialog(user: user);
      } else {
        showGnDialog(Icons.cancel, Colors.red, '請對準框框位置');
        await Future.delayed(Duration(milliseconds: 300)).then((value) {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } else {
      _pubService.isOverlay = false;
    }
    if (mounted) setState(() {});
  }

  //dlib
  Future<void> _autoPredictFacesFromImageDlib({@required CameraImage? image}) async {
    assert(image != null, 'Image is null');
    if (_pubService.isDebug) return;
    await _faceDetectorService2.getFacePosePoints(
      image!.width,
      image.height,
      image.planes[0].bytesPerPixel,
      image.planes[0].bytes,
    );
    //送一張照片進去 加開關控制
    if (_faceDetectorService2.facepoints != null) {
      facepoints = _faceDetectorService2.facepoints;
      _mlService.setCurrentPredictionDlib(image, _faceDetectorService2.facepoints);
      User? user = await _mlService.predict();
      await checkInDialog(user: user);
    }
    if (mounted) setState(() {});
  }

  //卡頓版
  Future<void> _autoPredictFacesFromImage({@required CameraImage? image}) async {
    assert(image != null, 'Image is null');
    await _faceDetectorService.detectFacesFromImage(image!);
    if (_faceDetectorService.faceDetected) {
      _mlService.setCurrentPrediction(image, _faceDetectorService.faces[0]);
      await onTap();
    }
    if (mounted) setState(() {});
  }

  Future<void> _predictFacesFromImage({@required CameraImage? image}) async {
    assert(image != null, 'Image is null');
    await _faceDetectorService.detectFacesFromImage(image!);
    if (_faceDetectorService.faceDetected) {
      _mlService.setCurrentPrediction(image, _faceDetectorService.faces[0]);
    }
    if (mounted) setState(() {});
  }

  Future<void> takePicture() async {
    if (_faceDetectorService.faceDetected) {
      await _cameraService.trytakePicture();
      setState(() => _isPictureTaken = true);
    } else {
      showDialog(context: context, builder: (context) => AlertDialog(content: Text('No face detected!')));
    }
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
    serviceMode ? _start_firebase() : _start_dlib();
  }

  Future<void> onTap() async {
    await takePicture();
    if (_faceDetectorService.faceDetected) {
      User? user = await _mlService.predict();
      // var bottomSheetController = scaffoldKey.currentState!
      //     .showBottomSheet((context) => checkInDialog(user: user));
      // bottomSheetController.closed.whenComplete(_reload);
      await checkInDialog(user: user);
      _reload();
    }
  }

  Widget getBodyWidget() {
    List<Widget> view = [];
    if (_isInitializing) return Center(child: CircularProgressIndicator());
    if (_isPictureTaken) return SinglePicture(imagePath: _cameraService.imagePath!);

    return serviceMode
        ? CameraDetectionPreview()
        : CameraStack(
            cameraDescription: _cameraService.description!,
            controller: _cameraService.cameraController!,
            isRunninOnEmulator: false,
            width: width,
            points: facepoints);
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    Widget header = CameraHeader("打卡", onBackPressed: _onBackPressed, onServiceMode: _changeServiceMode, serviceMode: serviceMode);
    Widget body = getBodyWidget();
    Widget? fab;
    if (!_isPictureTaken) fab = AuthButton(onTap: onTap);

    return Scaffold(
      key: scaffoldKey,
      body: Stack(
        children: [header, body],
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
              content: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(ic, color: cl),
                  SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      msg,
                      style: TextStyle(fontSize: 20),
                    ),
                  )
                ],
              ));
        },
        barrierDismissible: true,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 200));
  }

  Future<void> useElegantNotification() async {
    isElegantNotification = true;
    await Future.delayed(Duration(milliseconds: 1500));
    isElegantNotification = false;
  }

  checkInDialog({required User? user}) async {
    // useElegantNotification();
    Response? response;
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
        if (ParamList.isNotEmpty) response = await dio.get('', queryParameters: {'who': user.userid});
        showGnDialog(Icons.check_circle_outline, Colors.green, '${user.user}打卡成功!\r\n傳遞API顯示結果:${response!.data}');
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
          if (ParamList.isNotEmpty) response = await dio.get('', queryParameters: {'who': user.userid});
          showGnDialog(Icons.check_circle_outline, Colors.green, '${user.user}打卡成功!\r\n傳遞API顯示結果:${response!.data}');
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
    await Future.delayed(Duration(milliseconds: showtime)).then((value) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }
}
