
# FaceAuth with firebase(online) and dlib(offline)

This project only run on android platform.
A simple face login system, include database, face recognition (automatic, manual, online, offline), music playback, and photo registration.
Using some important packages, please check out pubspec.
THis project is based on two project:
[Online version](https://github.com/MCarlomagno/FaceRecognitionAuth/tree/master "link")
[Offline version](https://github.com/alnitak/flutter_opencv_dlib/tree/main "link")
Thanks to the two authors.
The above techniques are all from the two authors, I just modified it. 

### Flutter, Dart 版本
flutter: ">=2.5.0"
sdk: ">=2.17.5 < 3.0.0"

### Tensorflow lite
TensorFlow Lite is an open source deep learning framework for on-device inference.
https://www.tensorflow.org/lite

#### Flutter + Tensrorflow lite = tflite_flutter package 
TensorFlow Lite plugin provides a dart API for accessing TensorFlow Lite interpreter and performing inference. It binds to TensorFlow Lite C API using dart:ffi.

https://pub.dev/packages/tflite_flutter/install

## Important

You must understand both projects to run this project better.


## Setup (online firebase)

1- Clone the project:

```
git clone https://github.com/MCarlomagno/FaceRecognitionAuth.git
```
2- Open the folder:

```
cd FaceRecognitionAuth
```
3- Install dependencies:

```
flutter pub get
```
Run in iOS directory
```
pod install
```
4- Run on device (Check device connected or any virtual device running):

```
flutter run
```
## Setup (offline dlib)
check this [Offline version](https://github.com/alnitak/flutter_opencv_dlib/tree/main "link")
and let plugin put into pubspec.yaml
```
dependencies:
  flutter:
    sdk: flutter

  flutter_opencv_dlib:     <----------------here
    # When depending on this package from a real application you should use:
    #   flutter_opencv_dlib: ^x.y.z
    # See https://dart.dev/tools/pub/dependencies#version-constraints
    # The example app is bundled with the plugin so we use a path dependency on
    # the parent directory to use the current plugin's version.
    path: ../flutter_opencv_dlib-tsai
```
and then you can use it in project 
```
import 'package:flutter_opencv_dlib/flutter_opencv_dlib.dart';
```


## Support
If you're interested in contributing, please let me know emailing me to iop04329@gmail.com