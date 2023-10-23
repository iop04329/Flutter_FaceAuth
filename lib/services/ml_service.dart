import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:face_net_authentication/pages/db/databse_helper.dart';
import 'package:face_net_authentication/pages/models/user.model.dart';
import 'package:face_net_authentication/services/image_converter.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as imglib;
import 'package:flutter_opencv_dlib/src/face_points.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:intl/intl.dart';

class MLService {
  Interpreter? _interpreter;
  double threshold = 0.55;

  List _predictedData = [];
  List get predictedData => _predictedData;

  //新增註冊連拍功能
  bool is5SignUp = false;
  //註冊儲存相片開關
  bool isSignUpSaveImg = false;
  List<List<double>> userListface = [];

  Future initialize() async {
    late Delegate delegate;
    try {
      if (Platform.isAndroid) {
        delegate = GpuDelegateV2(
          options: GpuDelegateOptionsV2(
            isPrecisionLossAllowed: false,
            inferencePreference: TfLiteGpuInferenceUsage.fastSingleAnswer,
            inferencePriority1: TfLiteGpuInferencePriority.minLatency,
            inferencePriority2: TfLiteGpuInferencePriority.auto,
            inferencePriority3: TfLiteGpuInferencePriority.auto,
          ),
        );
      } else if (Platform.isIOS) {
        delegate = GpuDelegate(
          options: GpuDelegateOptions(allowPrecisionLoss: true, waitType: TFLGpuDelegateWaitType.active),
        );
      }
      var interpreterOptions = InterpreterOptions()..addDelegate(delegate);

      // var interpreterOptions = InterpreterOptions();
      // interpreterOptions.threads = 4;

      this._interpreter = await Interpreter.fromAsset('mobilefacenet.tflite', options: interpreterOptions);
    } catch (e) {
      print('Failed to load model.');
      print(e);
    }
  }

  //開啟註冊連拍
  void openSignUp() {
    is5SignUp = true;
    userListface = [];
  }

  void closeSignUp() {
    is5SignUp = false;
    userListface = [];
  }

  //修改辨識率
  void setThreshold(double num) {
    if (num > 0.1 && num < 1.2) {
      threshold = num;
    }
  }

  //判斷是否有加載model
  bool checkModelExist() {
    if (_interpreter != null) return true;
    return false;
  }

  saveImageToGallery(imglib.Image croppedImage) async {
    if (isSignUpSaveImg) {
      try {
        final now = DateTime.now();
        final formatter = DateFormat('yyyyMMddHHmmss');
        final fileName = '${formatter.format(now)}.jpg';
        final bytes = Uint8List.fromList(imglib.encodeJpg(croppedImage)); //注意 imglib.Image是 uint32位元 decode成jpg 再轉uint8List
        print('_preProcessDlib => bytes:${bytes.length}');
        final directory = await getTemporaryDirectory();
        final imagePath = '${directory.path}/$fileName';
        print(imagePath);
        await File(imagePath).writeAsBytes(bytes);

        await ImageGallerySaver.saveFile(imagePath);
      } catch (e) {
        print('saveImageToGallery Error => $e');
      }
    } else {
      return;
    }
  }

  saveUint8ListToGallery(Uint8List image) async {
    try {
      final now = DateTime.now();
      final formatter = DateFormat('yyyyMMddHHmmss');
      final fileName = '${formatter.format(now)}.jpg';
      final bytes = image;
      print('_preProcessDlib => bytes:${bytes.length}');
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/$fileName';
      print(imagePath);
      await File(imagePath).writeAsBytes(bytes);

      await ImageGallerySaver.saveFile(imagePath);
    } catch (e) {
      print('saveImageToGallery Error => $e');
    }
  }

  //dlib (facepoint)
  setCurrentPredictionDlib(CameraImage cameraImage, FacePoints? face) {
    if (_interpreter == null) throw Exception('Interpreter is null');
    if (face == null) throw Exception('Face is null');
    List input = _preProcessDlib(cameraImage, face); //修改使用dlib face座標切割人臉

    input = input.reshape([1, 112, 112, 3]);
    List output = List.generate(1, (index) => List.filled(192, 0));

    this._interpreter?.run(input, output);
    output = output.reshape([192]);

    this._predictedData = List.from(output);
  }

  //dlib (image path)
  setCurrentPredictionDlib2(imglib.Image? image, FacePoints? faceDetected) {
    if (_interpreter == null) throw Exception('Interpreter is null');
    if (faceDetected == null) throw Exception('Face is null');

    double left = faceDetected.points[0].toDouble();
    double top = faceDetected.points[1].toDouble();
    double right = faceDetected.points[2].toDouble();
    double bottom = faceDetected.points[3].toDouble();
    double x = left;
    double y = top;
    double w = right - left;
    double h = bottom - top;
    imglib.Image croppedImage = imglib.copyCrop(image!, x.round(), y.round(), w.round(), h.round());
    saveImageToGallery(croppedImage);

    imglib.Image img = imglib.copyResizeCropSquare(croppedImage, 112);
    List input = imageToByteListFloat32(img);

    input = input.reshape([1, 112, 112, 3]);
    List output = List.generate(1, (index) => List.filled(192, 0));

    this._interpreter?.run(input, output);
    output = output.reshape([192]);

    this._predictedData = List.from(output);
  }

  //dlib
  List _preProcessDlib(CameraImage image, FacePoints faceDetected) {
    imglib.Image croppedImage = _cropFaceDlib(image, faceDetected);
    saveImageToGallery(croppedImage);
    imglib.Image img = imglib.copyResizeCropSquare(croppedImage, 112);

    Float32List imageAsList = imageToByteListFloat32(img);
    return imageAsList;
  }

  //dlib
  imglib.Image _cropFaceDlib(CameraImage image, FacePoints faceDetected) {
    imglib.Image convertedImage = _convertCameraImage(image, serviceMode: false);
    double left = faceDetected.points[0].toDouble();
    double top = faceDetected.points[1].toDouble();
    double right = faceDetected.points[2].toDouble();
    double bottom = faceDetected.points[3].toDouble();
    double x = left;
    double y = top;
    double w = right - left;
    double h = bottom - top;
    print('切割 x:$x y:$y y:$w y:$h');
    return imglib.copyCrop(convertedImage, x.round(), y.round(), w.round(), h.round());
  }

  //firebase (image path)
  void setCurrentPrediction2(imglib.Image? image, Face? face) {
    if (_interpreter == null) throw Exception('Interpreter is null');
    if (face == null) throw Exception('Face is null');

    double x = face.boundingBox.left - 20.0;
    double y = face.boundingBox.top - 10.0;
    double w = face.boundingBox.width + 20.0;
    double h = face.boundingBox.height + 20.0;
    imglib.Image croppedImage = imglib.copyCrop(image!, x.round(), y.round(), w.round(), h.round());
    saveImageToGallery(croppedImage);

    imglib.Image img = imglib.copyResizeCropSquare(croppedImage, 112);
    List input = imageToByteListFloat32(img);

    input = input.reshape([1, 112, 112, 3]);
    List output = List.generate(1, (index) => List.filled(192, 0));

    this._interpreter?.run(input, output);
    output = output.reshape([192]);

    this._predictedData = List.from(output);
  }

  //firebase (face)
  void setCurrentPrediction(CameraImage cameraImage, Face? face) {
    if (_interpreter == null) throw Exception('Interpreter is null');
    if (face == null) throw Exception('Face is null');
    List input = _preProcess(cameraImage, face);

    input = input.reshape([1, 112, 112, 3]);
    List output = List.generate(1, (index) => List.filled(192, 0));

    this._interpreter?.run(input, output);
    output = output.reshape([192]);

    this._predictedData = List.from(output);
  }

  Future<User?> predict() async {
    return _searchResult(this._predictedData);
  }

  List _preProcess(CameraImage image, Face faceDetected) {
    imglib.Image croppedImage = _cropFace(image, faceDetected);
    saveImageToGallery(croppedImage);
    imglib.Image img = imglib.copyResizeCropSquare(croppedImage, 112);

    Float32List imageAsList = imageToByteListFloat32(img);
    return imageAsList;
  }

  imglib.Image _cropFace(CameraImage image, Face faceDetected) {
    imglib.Image convertedImage = _convertCameraImage(image);
    double x = faceDetected.boundingBox.left;
    double y = faceDetected.boundingBox.top;
    double w = faceDetected.boundingBox.width;
    double h = faceDetected.boundingBox.height;
    return imglib.copyCrop(convertedImage, x.round(), y.round(), w.round(), h.round());
  }

  imglib.Image _convertCameraImage(CameraImage image, {bool serviceMode = true}) {
    var img = convertToImage(image);
    var img1 = imglib.copyRotate(img, -90);
    if (!serviceMode) img1 = imglib.flipHorizontal(img1); // true firebase false dlib
    return img1;
  }

  Float32List imageToByteListFloat32(imglib.Image image) {
    var convertedBytes = Float32List(1 * 112 * 112 * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var i = 0; i < 112; i++) {
      for (var j = 0; j < 112; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (imglib.getRed(pixel) - 128) / 128;
        buffer[pixelIndex++] = (imglib.getGreen(pixel) - 128) / 128;
        buffer[pixelIndex++] = (imglib.getBlue(pixel) - 128) / 128;
      }
    }
    return convertedBytes.buffer.asFloat32List();
  }

  Future<User?> _searchResult(List predictedData) async {
    DatabaseHelper _dbHelper = DatabaseHelper.instance;

    List<User> users = await _dbHelper.queryAllUsers();
    double minDist = 999;
    double currDist = 0.0;
    User? predictedResult;

    print('users.length=> ${users.length}');

    //與資料庫使用者比對 找出歐幾里德距離最小的 代表越相似 但至少也要小於門檻值
    // for (User u in users) {
    //   currDist = _euclideanDistance(u.modelData, predictedData);
    //   if (currDist <= threshold && currDist < minDist) {
    //     minDist = currDist;
    //     predictedResult = u;
    //   }
    // }
    for (User u in users) {
      u.modelData.forEach((element) {
        currDist = _euclideanDistance(element, predictedData);
        if (currDist <= threshold && currDist < minDist) {
          minDist = currDist;
          predictedResult = u;
        }
      });
    }
    return predictedResult;
  }

  double _euclideanDistance(List? e1, List? e2) {
    if (e1 == null || e2 == null) throw Exception("Null argument");

    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      sum += pow((e1[i] - e2[i]), 2);
    }
    return sqrt(sum);
  }

  void setPredictedData(value) {
    this._predictedData = value;
  }

  dispose() {}
}
