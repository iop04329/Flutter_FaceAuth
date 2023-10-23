import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:face_net_authentication/locator.dart';
import 'package:face_net_authentication/pages/widgets/auth-action-button.dart';
import 'package:face_net_authentication/pages/widgets/camera_header.dart';
import 'package:face_net_authentication/services/camera.service.dart';
import 'package:face_net_authentication/services/ml_service.dart';
import 'package:face_net_authentication/services/face_detector_service.dart';
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

class SignUp extends StatefulWidget {
  final User? user;
  const SignUp({Key? key, this.user}) : super(key: key);

  @override
  SignUpState createState() => SignUpState();
}

class SignUpState extends State<SignUp> {
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
  bool serviceMode = true; //True firebase False dlib

  // service injection
  DetectorInterface _faceDetectorService2 = locator<DetectorInterface>(); //dlib
  FaceDetectorService _faceDetectorService = locator<FaceDetectorService>(); //firebase
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

    _mlService.isSignUpSaveImg = true;
    variableinit();
    serviceMode ? _start() : _start2();
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
    _faceDetectorService2.setGetOnlyRectangle(true);
    if (!_faceDetectorService2.isDetectorInit) {
      await _faceDetectorService2.initDetector();
      _faceDetectorService2.setInputColorSpace(ColorSpace.SRC_GRAY);
      _faceDetectorService2.setRotation(2);
      _faceDetectorService2.setFlip(1);
    }
    setState(() => _initializing = false);

    // _frameFacesdlib();
    _frameFacesdlib_Auto();
    setState(() {});
  }

  //影片註冊
  _frameFacesdlib_Auto() async {
    imageSize = _cameraService.getImageSize();
    _saving = true; //初始化 設置true 可等待取人臉
    _mlService.userListface = [];
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
          await _faceDetectorService2.getFacePosePoints(
            image.width,
            image.height,
            _cameraImage!.planes[0].bytesPerPixel,
            _cameraImage!.planes[0].bytes,
          );
          DateTime after = DateTime.now(); // 获取调用函数之后的时间
          Duration duration = after.difference(before); // 计算函数调用所花费的时间
          print('函数调用所花费的时间：${duration.inMilliseconds} 毫秒');

          if (_faceDetectorService2.facepoints != null) {
            setState(() {
              facepoints = _faceDetectorService2.facepoints;
              print('檢測到人臉');
            });
            if (_saving) {
              _saving = false; //防止二進 後面會加延遲打開
              _mlService.setCurrentPredictionDlib(image, facepoints);
              if (_mlService.is5SignUp) {
                _mlService.userListface.add(_mlService.predictedData.cast<double>());
                print('predictedData => ${_mlService.predictedData}');
                ElegantNotification.success(title: Text('成功'), description: Text('已取得第${_mlService.userListface.length}張照片')).show(context);
              } else {
                ElegantNotification.success(title: Text('成功'), description: Text('已取得照片')).show(context);
                XFile? file = await _cameraService.takePicture();
                imagePath = file?.path;
                //定格
                setState(() {
                  _bottomSheetVisible = true; //不顯示底下sheet
                  pictureTakenFromFile = true; //拍照body 改用圖庫版本 為了解決傳遞給子widget的開關問題
                });
              }

              if (_mlService.userListface.length == 3) {
                XFile? file = await _cameraService.takePicture();
                imagePath = file?.path;
                print('Face 1 ${_mlService.userListface[0]}');
                print('Face 2 ${_mlService.userListface[1]}');
                print('Face 3 ${_mlService.userListface[2]}');
                //定格
                setState(() {
                  _bottomSheetVisible = true; //不顯示底下sheet
                  pictureTakenFromFile = true; //拍照body 改用圖庫版本 為了解決傳遞給子widget的開關問題
                });
                // return true; //顯示註冊
              }
              //冷卻1.5秒再打開
              Future.delayed(Duration(milliseconds: 1500)).then((_) {
                setState(() {
                  _saving = true;
                });
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

  //Dlib _computeDetectorPoints function
  _frameFacesdlib() async {
    imageSize = _cameraService.getImageSize();

    _cameraService.cameraController?.startImageStream((image) async {
      if (isComputingFrame) return;
      isComputingFrame = true;
      // * send only Y plane of YUV frame
      _cameraImage = image;

      try {
        if (_cameraImage?.planes[0] != null) {
          // fpsDlib++;
          DateTime before = DateTime.now(); // 获取调用函数之前的时间
          await _faceDetectorService2.getFacePosePoints(
            _cameraService.cameraController!.value.previewSize?.width.toInt() ?? 0,
            _cameraService.cameraController!.value.previewSize?.height.toInt() ?? 0,
            _cameraImage!.planes[0].bytesPerPixel,
            _cameraImage!.planes[0].bytes,
          );
          DateTime after = DateTime.now(); // 获取调用函数之后的时间
          Duration duration = after.difference(before); // 计算函数调用所花费的时间
          print('函数调用所花费的时间：${duration.inMilliseconds} 毫秒');

          if (_faceDetectorService2.facepoints != null) {
            setState(() {
              facepoints = _faceDetectorService2.facepoints;
              print(facepoints!.points[0]);
              print(facepoints!.points[1]);
              print(facepoints!.points[2]);
              print(facepoints!.points[3]);
              print('檢測到人臉');
            });
            if (_saving) {
              _mlService.setCurrentPredictionDlib(image, facepoints);
              if (_mlService.is5SignUp) {
                _mlService.userListface.add(_mlService.predictedData.cast<double>());
              }
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
    _faceDetectorService2.setGetOnlyRectangle(detectmode);
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

  _start() async {
    setState(() => _initializing = true);
    await _cameraService.initialize();
    // _cameraService.setOrientation(DeviceOrientation.landscapeRight);
    setState(() => _initializing = false);

    _frameFaces_Auto();
  }

  //第三版 無卡頓 使用dlib(需使用手動按鈕)
  Future<bool> onShot_dlib() async {
    if (_mlService.userListface.length == 3) return false;
    if (facepoints == null) {
      ElegantNotification.error(title: Text('失敗'), description: Text('沒有檢測到人臉!')).show(context);

      return false;
    } else if (!detectmode) {
      ElegantNotification.info(title: Text('模式警告'), description: Text('請將模式切換至矩形框!再進行拍照')).show(context);

      return false;
    } else {
      _saving = true;

      if (_mlService.is5SignUp) {
        while (_saving) {
          //等待處理完
          await Future.delayed(Duration(milliseconds: 100)); // 暫停 100 毫秒
        }
        ElegantNotification.success(title: Text('成功'), description: Text('已取得第${_mlService.userListface.length}張照片')).show(context);
        if (_mlService.userListface.length == 3) {
          XFile? file = await _cameraService.takePicture();
          imagePath = file?.path;
          //定格
          setState(() {
            _bottomSheetVisible = true; //不顯示底下sheet
            pictureTaken = true; //拍照body
          });
          return true; //顯示註冊
        } else {
          return false;
        }
      } else {
        _saving = true;
        XFile? file = await _cameraService.takePicture();
        imagePath = file?.path;
        ElegantNotification.success(title: Text('成功'), description: Text('已取得照片')).show(context);
        setState(() {
          _bottomSheetVisible = true; //不顯示底下sheet
          pictureTaken = true; //拍照body
        });
        return true;
      }
    }
  }

  //第二版 無卡頓
  Future<bool> onShot_origin() async {
    if (_mlService.userListface.length == 3) return false;
    if (faceDetected == null) {
      ElegantNotification.error(title: Text('失敗'), description: Text('沒有檢測到人臉!')).show(context);

      return false;
    } else {
      _saving = true;

      if (_mlService.is5SignUp) {
        while (_saving) {
          await Future.delayed(Duration(milliseconds: 100)); // 暫停 100 毫秒
        }
        ElegantNotification.success(title: Text('成功'), description: Text('已取得第${_mlService.userListface.length}張照片')).show(context);
        if (_mlService.userListface.length == 3) {
          XFile? file = await _cameraService.takePicture();
          imagePath = file?.path;
          //定格
          setState(() {
            _bottomSheetVisible = true; //不顯示底下sheet
            pictureTaken = true; //拍照body
          });
          return true; //顯示註冊
        } else {
          return false;
        }
      } else {
        _saving = true;
        XFile? file = await _cameraService.takePicture();
        imagePath = file?.path;
        ElegantNotification.success(title: Text('成功'), description: Text('已取得照片')).show(context);
        setState(() {
          _bottomSheetVisible = true; //不顯示底下sheet
          pictureTaken = true; //拍照body
        });
        return true;
      }
    }
  }

  //第一版 卡頓
  Future<bool> onShot() async {
    XFile? file = await _cameraService.takePicture();
    imagePath = file?.path;
    _saving = true;
    //處理
    _faceDetectorService.detectFacesFromFile(imagePath!);
    if (_faceDetectorService.faces.isNotEmpty) {
      faceDetected = _faceDetectorService.faces[0];
      var image = await xFileToImage(file!);
      _mlService.setCurrentPrediction2(image, faceDetected);
      _mlService.userListface.add(_mlService.predictedData.cast<double>());
      showGnDialog('已取得第${_mlService.userListface.length}張照片');
      //重繪 是否開啟連拍模式
      if (_mlService.is5SignUp) {
        if (_mlService.userListface.length == 3) {
          setState(() {
            _bottomSheetVisible = true; //不顯示底下sheet
            pictureTaken = true; //拍照body
          });
          return true;
        } else {
          _reload();
          return false;
        }
      } else {
        setState(() {
          _bottomSheetVisible = true; //不顯示底下sheet
          pictureTaken = true; //拍照body
        });
        return true;
      }
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text('沒有檢測到人臉!'),
          );
        },
      );
      print('face is null');
      setState(() {
        faceDetected = null;
      });
      return false;
    }
  }

  _frameFaces_Auto() {
    imageSize = _cameraService.getImageSize();
    _saving = true;
    _mlService.userListface = [];
    _cameraService.cameraController?.startImageStream((image) async {
      if (_cameraService.cameraController != null) {
        if (_detectingFaces) return;

        _detectingFaces = true;

        try {
          await _faceDetectorService.detectFacesFromImage(image);

          if (_faceDetectorService.faces.isNotEmpty) {
            setState(() {
              faceDetected = _faceDetectorService.faces[0];
            });
            if (_saving) {
              _saving = false;
              _mlService.setCurrentPrediction(image, faceDetected);
              if (_mlService.is5SignUp) {
                _mlService.userListface.add(_mlService.predictedData.cast<double>());
                ElegantNotification.success(title: Text('成功'), description: Text('已取得第${_mlService.userListface.length}張照片')).show(context);
              } else {
                ElegantNotification.success(title: Text('成功'), description: Text('已取得照片')).show(context);
                setState(() {
                  _bottomSheetVisible = true; //不顯示底下sheet
                  pictureTakenFromFile = true; //拍照body 改用圖庫版本 為了解決傳遞給子widget的開關問題
                });
              }

              if (_mlService.userListface.length == 3) {
                XFile? file = await _cameraService.takePicture();
                imagePath = file?.path;
                print('Face 1 ${_mlService.userListface[0]}');
                print('Face 2 ${_mlService.userListface[1]}');
                print('Face 3 ${_mlService.userListface[2]}');
                //定格
                setState(() {
                  _bottomSheetVisible = true; //不顯示底下sheet
                  pictureTakenFromFile = true; //拍照body 改用圖庫版本 為了解決傳遞給子widget的開關問題
                });
              }
              // return true; //顯示註冊

              //冷卻1.5秒再打開
              Future.delayed(Duration(milliseconds: 1500)).then((_) {
                setState(() {
                  _saving = true;
                });
              });
            }
          } else {
            print('face is null');
            setState(() {
              faceDetected = null;
            });
          }

          _detectingFaces = false;
        } catch (e) {
          print('Error _faceDetectorService face => $e');
          _detectingFaces = false;
        }
      }
    });
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
    final isCurrentRoute = currentRoute?.settings.name == '/signup';
    if (_mlService.is5SignUp & isCurrentRoute) {
      _mlService.userListface = [];
      _reload();
    }
  }

  //圖庫 dlib
  Future<void> _pickImagedlib() async {
    final imagePicker = ImagePicker();
    final XFile? file = await imagePicker.pickImage(source: ImageSource.gallery);
    imagePath = file?.path;
    await _cameraService.stopStream();
    //處理
    if (imagePath == null) return;
    final imageBytes = await loadImage(imagePath!);
    final resizedImageBytes = resizeImage(imageBytes, imageSize!.width.toInt(), imageSize!.height.toInt());
    await _faceDetectorService2.getFacePosePoints(imageSize!.width.toInt(), imageSize!.height.toInt(), 1, resizedImageBytes);
    if (_faceDetectorService2.facepoints == null) {
      facepoints = _faceDetectorService2.facepoints;
      var image = await xFileToImage(file!);
      _mlService.setCurrentPredictionDlib2(image, facepoints);
      _mlService.userListface.add(_mlService.predictedData.cast<double>());
      //重繪 是否開啟連拍模式
      if (_mlService.is5SignUp) {
        if (_mlService.userListface.length == 3) {
          setState(() {
            _bottomSheetVisible = true;
            pictureTakenFromFile = true;
          });
        }
      } else {
        setState(() {
          _bottomSheetVisible = true;
          pictureTakenFromFile = true;
        });
      }
    } else {
      ElegantNotification.error(title: Text('失敗'), description: Text('沒有檢測到人臉!')).show(context);
      print('face is null');
      setState(() {
        faceDetected = null;
      });
    }
  }

  //圖庫 firebase
  Future<void> _pickImage() async {
    final imagePicker = ImagePicker();
    final XFile? file = await imagePicker.pickImage(source: ImageSource.gallery);
    imagePath = file?.path;
    await _cameraService.stopStream();
    //處理
    if (imagePath == null) return;
    _faceDetectorService.detectFacesFromFile(imagePath!);
    if (_faceDetectorService.faces.isNotEmpty) {
      faceDetected = _faceDetectorService.faces[0];
      var image = await xFileToImage(file!);
      _mlService.setCurrentPrediction2(image, faceDetected);
      _mlService.userListface.add(_mlService.predictedData.cast<double>());
      //重繪 是否開啟連拍模式
      if (_mlService.is5SignUp) {
        if (_mlService.userListface.length == 3) {
          setState(() {
            _bottomSheetVisible = true;
            pictureTakenFromFile = true;
          });
        }
      } else {
        setState(() {
          _bottomSheetVisible = true;
          pictureTakenFromFile = true;
        });
      }
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text('沒有檢測到人臉!'),
          );
        },
      );
      print('face is null');
      setState(() {
        faceDetected = null;
      });
    }
  }

  //圖庫的
  Widget _signUpSheet() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(
            height: 20,
          ),
          Padding(
            padding: EdgeInsets.only(left: 20, right: 20),
            child: widget.user == null
                ? AppTextField(
                    controller: _userTextEditingController,
                    labelText: "名稱",
                  )
                : Container(),
          ),
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
              await _signUp(context);
              _reload();
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
  Future _signUp(context) async {
    DatabaseHelper _databaseHelper = DatabaseHelper.instance;
    //新增 註冊
    String name = widget.user == null ? _userTextEditingController.text : widget.user!.user;
    String userid = _passwordTextEditingController.text;
    List predictedData = _mlService.predictedData;
    List<double> predictedDataAsDouble = predictedData.cast<double>();
    User? user = await _databaseHelper.getUserByUserId(userid);
    if (predictedDataAsDouble.length == 0) return; //沒有偵測到人臉 不做登入
    //判斷新增user還是新增人臉
    if (user == null) {
      if (_mlService.is5SignUp) {
        User userToSave = User(
          user: name,
          userid: userid,
          modelData: _mlService.userListface, //指向_mlService.user5face記憶體位置 因為它是一個物件
        );
        await _databaseHelper.insertUser(userToSave);
        _mlService.userListface = []; //初始化
      } else {
        List<List<double>> models = [];
        models.add(predictedDataAsDouble);

        User userToSave = User(
          user: name,
          userid: userid,
          modelData: models,
        );
        await _databaseHelper.insertUser(userToSave);
      }
    } else {
      //更新
      if (_mlService.is5SignUp) {
        _mlService.userListface.forEach((element) {
          user.modelData.add(element);
        });
      } else {
        user.modelData.add(predictedDataAsDouble);
      }
      await _databaseHelper.updateModelData(user.id!, user.modelData);
    }

    this._mlService.setPredictedData([]);
    Navigator.popUntil(context, ModalRoute.withName('/home'));
  }

  _reload() {
    setState(() {
      _bottomSheetVisible = false;
      pictureTaken = false;
      pictureTakenFromFile = false;
    });
    serviceMode ? this._start() : this._start2();
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
                  child: Image.file(File(imagePath!)),
                ),
                transform:
                    serviceMode ? Matrix4.diagonal3Values(flipX ? -1.0 : 1.0, flipY ? -1.0 : 1.0, flipX ^ flipY ? -1.0 : 1.0) : Matrix4.identity()),
            // transform: Matrix4.rotationY(mirror)),
            // transform: Matrix4.identity()),
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
    //拍照
    if (!_initializing && pictureTaken) {
      body = Container(
        width: width,
        height: height,
        child: Transform(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.cover,
              child: Image.file(File(imagePath!)),
            ),
            transform: Matrix4.rotationY(mirror)),
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
                  children: serviceMode
                      ? <Widget>[
                          CameraPreview(_cameraService.cameraController!),
                          CustomPaint(painter: FacePainter(face: faceDetected, imageSize: imageSize!))
                        ]
                      : <Widget>[
                          CameraStack(
                              cameraDescription: _cameraService.description!,
                              controller: _cameraService.cameraController!,
                              isRunninOnEmulator: isRunninOnEmulator,
                              width: width,
                              points: facepoints)
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
              onSelectImage: _pickImagedlib,
              onDetectMode: _onDetectMode,
            )
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: !_bottomSheetVisible
            ? Container()
            // AuthActionButton(
            //     onPressed: onShot_dlib,
            //     isLogin: false,
            //     reload: _reload,
            //     user: widget.user,
            //   )
            : Container());
  }
}
