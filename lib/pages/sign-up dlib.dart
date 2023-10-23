import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:face_net_authentication/locator.dart';
import 'package:face_net_authentication/pages/widgets/camera_header.dart';
import 'package:face_net_authentication/services/camera.service.dart';
import 'package:face_net_authentication/services/ml_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/material.dart';
//加載圖片 1.新增camera head2 2.新增圖片轉換Function 3.新增註冊版本sheet元件 4.導入DB、model
import 'package:face_net_authentication/pages/widgets/camera_header2.dart';
import 'package:image_picker/image_picker.dart';
import 'package:face_net_authentication/services/image_converter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'widgets/app_text_field.dart';
import 'widgets/app_button.dart';
import 'package:face_net_authentication/pages/db/databse_helper.dart';
import 'package:face_net_authentication/pages/models/user.model.dart';
//1.回Home 2.通知功能
import './home.dart';
import 'package:elegant_notification/elegant_notification.dart';
//dlib
import 'package:flutter_opencv_dlib/flutter_opencv_dlib.dart';
import 'package:face_net_authentication/pages/widgets/camera_stack.dart';
import 'package:face_net_authentication/pages/widgets/FacePainter.dart';
import 'package:face_net_authentication/pages/database_user.dart';
//防止黑屏
import 'package:face_net_authentication/services/pub_service.dart';

class SignUpDlib extends StatefulWidget {
  final User? user;
  const SignUpDlib({Key? key, this.user}) : super(key: key);

  @override
  SignUpDlibState createState() => SignUpDlibState();
}

class SignUpDlibState extends State<SignUpDlib> {
  String? imagePath;
  Face? faceDetected;
  Size? imageSize;

  bool _detectingFaces = false;
  bool pictureTaken = false;
  bool pictureTakenFromFile = false;

  bool _initializing = false;

  bool _saving = false;
  bool _bottomSheetVisible = false;
  //dlib
  late double fpsDlib;
  late bool isComputingFrame;
  CameraImage? _cameraImage;
  bool isRunninOnEmulator = false;
  FacePoints? facepoints;
  bool detectmode = true; // true = rectangle false = landmark
  bool flipX = true; // |
  bool flipY = false; // -
  RecognizedFace? regFace;
  Uint8List? adjustImg;

  // service injection
  DetectorInterface _faceDetectorService = locator<DetectorInterface>(); //dlib
  RecognizerInterface _faceReCognizerService = locator<RecognizerInterface>(); //dlib
  CameraService _cameraService = locator<CameraService>();
  MLService _mlService = locator<MLService>();
  pub_service _pubService = locator<pub_service>();

  PermissionStatus? _storagePermissionStatus;
  PermissionStatus? _photosPermissionStatus;
  final TextEditingController _userTextEditingController = TextEditingController(text: '');
  final TextEditingController _passwordTextEditingController = TextEditingController(text: '');

  @override
  void initState() {
    super.initState();

    _checkAndRequestPermissions();
    _pubService.initialize();
    _checkIsSignUpOrAdd();
    // _start();
    _mlService.isSignUpSaveImg = true;
    variableinit();
    _start2();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  //Dlib
  variableinit() {
    isComputingFrame = false;
    fpsDlib = 0;
  }

  //Dlib
  _start2() async {
    setState(() => _initializing = true);
    await _cameraService.initialize();
    if (!_faceDetectorService.isDetectorInit) {
      await _faceDetectorService.initDetector();
      _faceDetectorService.setInputColorSpace(ColorSpace.SRC_GRAY);
      _faceDetectorService.setRotation(2);
      _faceDetectorService.setFlip(1);
    }
    if (!_faceReCognizerService.isRecognizerInit) {
      await _faceReCognizerService.initRecognizer();
      _faceReCognizerService.setInputColorSpace(ColorSpace.SRC_GRAY);
      _faceReCognizerService.setRotation(2);
      _faceReCognizerService.setFlip(1);
    }
    setState(() => _initializing = false);

    // _frameFacesdlib();
    _frameFacesdlib();
    setState(() {});
  }

  //影片註冊
  _frameFacesdlib() async {
    imageSize = _cameraService.getImageSize();
    _cameraService.cameraController?.startImageStream((image) async {
      if (_pubService.isDebug) return;
      if (isComputingFrame) return;
      isComputingFrame = true;
      // * send only Y plane of YUV frame
      _cameraImage = image;

      try {
        if (_cameraImage?.planes[0] != null) {
          // fpsDlib++;
          DateTime before = DateTime.now(); // 获取调用函数之前的时间
          await _faceDetectorService.getFacePosePoints(
            image.width,
            image.height,
            _cameraImage!.planes[0].bytesPerPixel,
            _cameraImage!.planes[0].bytes,
          );

          DateTime after = DateTime.now(); // 获取调用函数之后的时间
          Duration duration = after.difference(before); // 计算函数调用所花费的时间
          print('函数调用所花费的时间：${duration.inMilliseconds} 毫秒');

          if (_faceDetectorService.facepoints != null) {
            setState(() {
              facepoints = _faceDetectorService.facepoints;
              print('檢測到人臉');
            });
            if (_saving) {
              adjustImg = await _faceReCognizerService.getAdjustedSource(
                  image.width, image.height, _cameraImage!.planes[0].bytesPerPixel!, _cameraImage!.planes[0].bytes);
              print('bytesPerPixel => ${_cameraImage!.planes[0].bytesPerPixel}');
              setState(() {
                _saving = false;
              });
            }
          } else {
            setState(() {
              // print('face is null');
              facepoints = null;
            });
          }

          isComputingFrame = false;
        }
      } catch (e) {
        print('Error _faceDetectorService face => $e');
        isComputingFrame = false;
      }
    });
  }

  //Dlib
  _onDetectMode() {
    detectmode = !detectmode;
    _faceDetectorService.setGetOnlyRectangle(detectmode);
  }

  //權限
  Future<void> _checkAndRequestPermissions() async {
    final storagePermissionStatus = await Permission.storage.status;
    final photosPermissionStatus = await Permission.photos.status;
    setState(() {
      _storagePermissionStatus = storagePermissionStatus;
      _photosPermissionStatus = photosPermissionStatus;
    });

    if (_storagePermissionStatus != PermissionStatus.granted) {
      final status = await Permission.storage.request();
      setState(() {
        _storagePermissionStatus = status;
      });
    }

    if (_photosPermissionStatus != PermissionStatus.granted) {
      final status = await Permission.photos.request();
      setState(() {
        _photosPermissionStatus = status;
      });
    }
  }

  //註冊or補單張
  _checkIsSignUpOrAdd() {
    if (widget.user == null)
      _mlService.openSignUp(); //用user判斷是否為註冊使用者還是新增人臉
    else
      _mlService.closeSignUp();
  }

  //第三版 無卡頓 使用dlib(需使用手動按鈕)
  Future<bool> onShotDlib() async {
    if (facepoints == null) {
      ElegantNotification.error(title: Text('失敗'), description: Text('沒有檢測到人臉!')).show(context);

      return false;
    } else {
      _saving = true;
      ElegantNotification.success(title: Text('成功'), description: Text('已取得照片')).show(context);
      _cameraService.stopStream();
      setState(() {
        _bottomSheetVisible = true;
        pictureTaken = true; //拍照body
      });
      return true;
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
    final currentRoute = ModalRoute.of(context);
    final isCurrentRoute = currentRoute?.settings.name == '/signupDlib';
    if (isCurrentRoute) {
      print('backPress Reload success');
      _mlService.userListface = [];
      _reload();
    }
  }

  //圖庫 dlib
  Future<void> _pickImageDlib() async {
    final imagePicker = ImagePicker();
    final XFile? file = await imagePicker.pickImage(source: ImageSource.gallery);
    imagePath = file?.path;
    await _cameraService.stopStream();
    //處理
    if (imagePath == null) return;
    final imageBytes = await loadImage(imagePath!);
    final resizedImageBytes = resizeImage(imageBytes, imageSize?.width.toInt() ?? 1, imageSize?.height.toInt() ?? 1);

    await _faceDetectorService.getFacePosePoints(imageSize?.width.toInt() ?? 1, imageSize?.height.toInt() ?? 1, 1, resizedImageBytes);
    adjustImg = await _faceReCognizerService.getAdjustedSource(imageSize?.width.toInt() ?? 1, imageSize?.height.toInt() ?? 1, 1, resizedImageBytes);

    if (_faceDetectorService.facepoints != null) {
      facepoints = _faceDetectorService.facepoints;

      setState(() {
        _bottomSheetVisible = true;
        pictureTakenFromFile = true;
      });
    } else {
      ElegantNotification.error(title: Text('失敗'), description: Text('沒有檢測到人臉!')).show(context);
      print('face is null');
      setState(() {
        faceDetected = null;
      });
    }
  }

  //圖庫、dlib
  Widget _signUpSheet({isPickImg = false}) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(
            height: 20,
          ),
          Padding(
              padding: EdgeInsets.only(left: 20, right: 20),
              child: AppTextField(
                controller: _userTextEditingController,
                labelText: "名稱",
              )),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.only(left: 20, right: 20),
            child: AppTextField(
              controller: _passwordTextEditingController,
              labelText: "員工編號",
              isPassword: false,
            ),
          ),
          SizedBox(height: 10),
          Divider(),
          SizedBox(height: 10),
          AppButton(
            text: '註冊',
            onPressed: () async {
              _pubService.intervalClick(2);
              isPickImg ? await _signUp(context, isPickImg: true) : await _signUp(context);
            },
            icon: Icon(
              Icons.person_add,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  //圖庫
  Future _signUp(context, {isPickImg = false}) async {
    DatabaseHelper _databaseHelper = DatabaseHelper.instance;
    //新增 註冊
    String name = widget.user == null ? _userTextEditingController.text : widget.user!.user;
    String userid = _passwordTextEditingController.text;
    User? us = await _databaseHelper.getUserByName(name);
    RecognizedFace? res;
    try {
      if (!isPickImg) {
        res = await _faceReCognizerService.addFace(
          _cameraImage!.width,
          _cameraImage!.height,
          _cameraImage!.planes[0].bytesPerPixel!,
          name,
          _cameraImage!.planes[0].bytes,
        );
        print('_signUp bytesPerPixel => ${_cameraImage!.planes[0].bytesPerPixel}');
      } else {
        final img = await decodeImageFromList(adjustImg!);
        res = await _faceReCognizerService.addFace(img.width, img.height, 1, name, adjustImg!);
      }

      if (res != null) {
        _mlService.saveUint8ListToGallery(res.face);

        if (us != null) {
          print('db有此使用者 刪除並覆蓋');
          await _databaseHelper.deleteDataById(us.id!, DatabaseHelper.user_table);
        }
        User userToSave = User(
          user: name,
          userid: userid,
          modelData: [
            [123]
          ],
        );
        await _databaseHelper.insertUser(userToSave);
      }
    } catch (e) {
      print('_signUp error => $e');
    }

    _userTextEditingController.clear();
    _passwordTextEditingController.clear();
    _reload();
  }

  _reload() {
    setState(() {
      _bottomSheetVisible = false;
      pictureTaken = false;
      pictureTakenFromFile = false;
    });
    // this._start();
    this._start2();
  }

  showGnDialog(String msg) {
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
                    Icon(Icons.check_circle_outline, color: Colors.green),
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

  Widget btn(void fn(), String tx, IconData id) {
    return InkWell(
      onTap: fn,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.blue[200],
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
        width: MediaQuery.of(context).size.width * 0.3,
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              tx,
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(
              width: 10,
            ),
            Icon(id, color: Colors.white)
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double mirror = math.pi;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    late Widget body;
    if (_initializing) {
      body = Center(
        child: CircularProgressIndicator(),
      );
    }
    //取圖庫
    if (!_initializing && pictureTakenFromFile) {
      body = Stack(
        children: [
          Container(
            width: width,
            height: height,
            child: Transform(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.cover,
                  // child: Image.file(File(imagePath!)),
                  child: Image.memory(adjustImg!),
                ),
                transform: Matrix4.identity()),
            // transform: Matrix4.rotationY(mirror)),
            // transform: Matrix4.identity()),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _signUpSheet(isPickImg: true),
          ),
        ],
      );
    }
    //拍照
    if (!_initializing && pictureTaken) {
      body = Stack(
        children: [
          Container(
            width: width,
            height: height,
            child: Transform(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: Image.memory(adjustImg!),
                ),
                transform: Matrix4.identity()),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _signUpSheet(),
          ),
        ],
      );
    }
    //連續取像
    if (!_initializing && !pictureTaken && !pictureTakenFromFile) {
      body = Transform.scale(
        scale: 1.0,
        child: AspectRatio(
          aspectRatio: MediaQuery.of(context).size.aspectRatio,
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.fitHeight,
              child: Container(
                width: width,
                height: width * _cameraService.cameraController!.value.aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    CameraStack(
                        cameraDescription: _cameraService.description!,
                        controller: _cameraService.cameraController!,
                        isRunninOnEmulator: isRunninOnEmulator,
                        width: width,
                        points: facepoints),
                    // CameraPreview(_cameraService.cameraController!),
                    // CustomPaint(painter: FacePainter(face: faceDetected, imageSize: imageSize!)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
        body: Stack(
          children: [
            body,
            CameraHeader2(
              "註冊",
              onBackPressed: _onBackPressed,
              onDetectMode: _onDetectMode,
              isDlib: true,
            )
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: !_bottomSheetVisible
            ? AuthActionButtondlib(
                onPressed: onShotDlib,
                user: widget.user,
              )
            : Container());
  }
}

class AuthActionButtondlib extends StatefulWidget {
  AuthActionButtondlib({Key? key, this.user, required this.onPressed}) : super(key: key);
  final Function onPressed;
  final User? user;
  @override
  _AuthActionButtondlibState createState() => _AuthActionButtondlibState();
}

class _AuthActionButtondlibState extends State<AuthActionButtondlib> {
  pub_service _pubService = locator<pub_service>();
  Future onTap() async {
    try {
      _pubService.intervalClick(2);
      await widget.onPressed(); //這邊觸發 父類執行onPressed 那邊進行重繪後 這邊接續執行
    } catch (e) {
      print('AuthActionButton onTap() => error:$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.blue[200],
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
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '拍照',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(
              width: 10,
            ),
            Icon(Icons.camera_alt, color: Colors.white)
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
