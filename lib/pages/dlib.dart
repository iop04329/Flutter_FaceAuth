import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:face_net_authentication/locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_opencv_dlib/flutter_opencv_dlib.dart';
import 'package:flutter_opencv_dlib/src/face_points.dart';
import 'package:face_net_authentication/services/camera.service.dart';

import 'widgets/camera_stack.dart';
import 'widgets/PointsPainter.dart';

// * on emulator the camera is rotated by 90°

class DlibPage extends StatefulWidget {
  const DlibPage({Key? key}) : super(key: key);

  @override
  State<DlibPage> createState() => _DlibPageState();
}

class _DlibPageState extends State<DlibPage> {
  final messengerKey = GlobalKey<ScaffoldMessengerState>();
  CameraImage? _cameraImage;
  late int rotate;
  late int flip;
  late int cameraId;
  late bool startGrab;
  late bool isComputingFrame;
  late ValueNotifier<bool> _isDetectMode;
  late ValueNotifier<FacePoints> _points;
  FacePoints? facepoints;
  late ValueNotifier<Uint8List> _adjustedImg;
  late ValueNotifier<Uint8List> _faceImage;
  late ValueNotifier<String> _textCamera;
  late ValueNotifier<String> _textDlib;
  late ValueNotifier<int> _antiShake;
  late bool detectorInitialized;
  late bool recognizerInitialized;
  late double fpsCamera;
  late double fpsDlib;
  late bool tryToAddFace;
  Timer? timer;
  int faceID = 1;

  late ValueNotifier<bool> _getFacePoints;

  DetectorInterface _faceDetectorService = locator<DetectorInterface>();
  CameraService _cameraService = locator<CameraService>();
  // late List<CameraDescription> cameras;
  bool isRunninOnEmulator = false;
  double w = 0;
  double h = 0;
  bool isSwapped = false;
  bool _initializing = false;

  Future<bool> camerainit() async {
    // cameras = await availableCameras();
    return true;
  }

  _start() async {
    setState(() => _initializing = true);
    await _cameraService.initialize();
    detectorInitialized = await _faceDetectorService.initDetector();
    _faceDetectorService.setInputColorSpace(ColorSpace.SRC_GRAY);
    _faceDetectorService.setRotation(2);
    _faceDetectorService.setFlip(1);
    setState(() => _initializing = false);
    startGrab = true;
    timer?.cancel();
    timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      _textCamera.value = fpsCamera.toString();
      _textDlib.value = fpsDlib.toString();
      if (_isDetectMode.value && _cameraImage != null) {
        _faceDetectorService
            .getAdjustedSource(_cameraImage!.width, _cameraImage!.height, _cameraImage!.planes[0].bytesPerPixel ?? 1, _cameraImage!.planes[0].bytes)
            .then((value) => _adjustedImg.value = value);
      } else {
        RecognizerInterface()
            .getAdjustedSource(_cameraImage!.width, _cameraImage!.height, _cameraImage!.planes[0].bytesPerPixel ?? 1, _cameraImage!.planes[0].bytes)
            .then((value) => _adjustedImg.value = value);
      }
      fpsCamera = fpsDlib = 0;
    });
    _cameraService.cameraController?.startImageStream(_computeDetectorPoints);
    setState(() {});
  }

  variableinit() {
    rotate = -1;
    flip = 2;
    cameraId = 0;
    startGrab = false;
    isComputingFrame = false;
    detectorInitialized = false;
    recognizerInitialized = false;
    fpsCamera = 0;
    fpsDlib = 0;
    tryToAddFace = false;
    _isDetectMode = ValueNotifier(true);
    _points = ValueNotifier(FacePoints(0, 0, Int32List(0), []));
    _adjustedImg = ValueNotifier(Uint8List(0));
    _faceImage = ValueNotifier(Uint8List(0));
    _textCamera = ValueNotifier('');
    _textDlib = ValueNotifier('');
    _antiShake = ValueNotifier(0);

    _getFacePoints = ValueNotifier(true);
  }

  @override
  void initState() {
    super.initState();

    variableinit();
    _start();
    // camerainit().then((value) async {
    //   await controllerinit();

    //   _faceDetectorService.initDetector().then((b) {
    //     detectorInitialized = b;
    //     _faceDetectorService.setInputColorSpace(ColorSpace.SRC_GRAY);

    //     rotate = cameras[cameraId].sensorOrientation == 90 && isRunninOnEmulator ? -1 : 0;
    //     _faceDetectorService.setRotation(rotate);

    //     if (mounted) {
    //       setState(() {});
    //     }
    //   });

    //   controller.initialize().then((_) async {
    //     print('AS: ${controller.value.aspectRatio}'
    //         '   SIZE: ${controller.value.previewSize}'
    //         '   ORIENTATION: ${controller.value.deviceOrientation}'
    //         '   RES PRESET: ${controller.resolutionPreset}'
    //         '   IMG FMT GROUP: ${controller.imageFormatGroup}'
    //         '   CAMERA SENSOR: ${cameras[cameraId].sensorOrientation}');
    //     if (mounted) {
    //       setState(() {});
    //     }
    //   });
    // });
  }

  @override
  void dispose() {
    _cameraService.dispose();
    timer?.cancel();
    super.dispose();
  }

  _computeDetectorPoints(CameraImage image) async {
    fpsCamera++;
    if (isComputingFrame) return;
    isComputingFrame = true;
    // * send only Y plane of YUV frame
    _cameraImage = image;

    w = _cameraService.cameraController!.value.previewSize?.width ?? 320;
    h = _cameraService.cameraController!.value.previewSize?.height ?? 240;
    isSwapped = false;

    try {
      if (_cameraImage?.planes[0] != null) {
        await _faceDetectorService.getFacePosePoints(
          _cameraService.cameraController!.value.previewSize?.width.toInt() ?? 0,
          _cameraService.cameraController!.value.previewSize?.height.toInt() ?? 0,
          _cameraImage!.planes[0].bytesPerPixel,
          _cameraImage!.planes[0].bytes,
        );
        

        if (_faceDetectorService.facepoints != null) {
          setState(() {
            facepoints = _faceDetectorService.facepoints;
            fpsDlib++;
          });
        } else {
          setState(() {
            print('face is null');
            facepoints = null;
          });
        }

        isComputingFrame = false;
      }
    } catch (e) {
      print('Error _faceDetectorService face => $e');
      isComputingFrame = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: messengerKey,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.dark,
      home: Scaffold(
        backgroundColor: const Color(0xFF2f2f2f),
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _initializing
                  ? const CircularProgressIndicator.adaptive()
                  : CameraStack(
                      cameraDescription: _cameraService.description!,
                      controller: _cameraService.cameraController!,
                      isRunninOnEmulator: isRunninOnEmulator,
                      width: 200,
                      points: facepoints),
              // * FPS camera
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ValueListenableBuilder<String>(
                      valueListenable: _textCamera,
                      builder: (_, text, __) {
                        return Text('camera FPS: $text');
                      }),

                  const SizedBox(width: 30),

                  // * FPS DLib
                  ValueListenableBuilder<String>(
                      valueListenable: _textDlib,
                      builder: (_, text, __) {
                        return Text('FPS DLib: $text');
                      }),
                ],
              ),

              // * Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // * start / stop detect
                  if (!detectorInitialized)
                    const CircularProgressIndicator.adaptive()
                  else
                    OutlinedButton(
                      child: Text(startGrab ? 'Stop' : 'Start'),
                      onPressed: () {
                        if (startGrab) {
                          startGrab = false;
                          _cameraService.cameraController!.stopImageStream();
                          timer?.cancel();
                          setState(() {});
                        } else {
                          startGrab = true;
                          timer?.cancel();

                          /// Timer to modify fps text and debug image
                          timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
                            _textCamera.value = fpsCamera.toString();
                            _textDlib.value = fpsDlib.toString();
                            if (_isDetectMode.value && _cameraImage != null) {
                              _faceDetectorService
                                  .getAdjustedSource(_cameraImage!.width, _cameraImage!.height, _cameraImage!.planes[0].bytesPerPixel ?? 1,
                                      _cameraImage!.planes[0].bytes)
                                  .then((value) => _adjustedImg.value = value);
                            } else {
                              RecognizerInterface()
                                  .getAdjustedSource(_cameraImage!.width, _cameraImage!.height, _cameraImage!.planes[0].bytesPerPixel ?? 1,
                                      _cameraImage!.planes[0].bytes)
                                  .then((value) => _adjustedImg.value = value);
                            }
                            fpsCamera = fpsDlib = 0;
                          });

                          _cameraService.cameraController!.startImageStream(_isDetectMode.value ? _computeDetectorPoints : _computeDetectorPoints);
                          setState(() {});
                        }
                      },
                    ),

                  OutlinedButton.icon(
                    label: const Text('cam'),
                    icon: const Icon(Icons.rotate_90_degrees_ccw),
                    onPressed: () async {
                      setState(() {
                        isRunninOnEmulator = !isRunninOnEmulator;
                      });
                    },
                  ),

                  // * front / rear camera
                  if (_initializing)
                    const CircularProgressIndicator.adaptive()
                  else
                    OutlinedButton.icon(
                      label: const Text('cam'),
                      icon: cameraId == 0 ? const Icon(Icons.camera_rear_outlined) : const Icon(Icons.camera_front_outlined),
                      onPressed: () async {
                        cameraId++;
                        startGrab = false;
                        if (cameraId > 1) cameraId = 0;
                        await _cameraService.cameraController!.dispose();
                        await _cameraService.initialize();
                        if (mounted) {
                          setState(() {});
                        }
                      },
                    ),
                ],
              ),

              // * detector / recognizer buttons
              ValueListenableBuilder<bool>(
                  valueListenable: _isDetectMode,
                  builder: (_, isDetectMode, __) {
                    return Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // * detector button
                        OutlinedButton(
                          style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(isDetectMode ? Colors.greenAccent.withOpacity(0.3) : Colors.transparent)),
                          onPressed: () async {
                            if (_cameraService.cameraController!.value.isStreamingImages) {
                              await _cameraService.cameraController!.stopImageStream();
                            }
                            _isDetectMode.value = true;
                            await _cameraService.cameraController!.startImageStream(_computeDetectorPoints);
                            setState(() {});
                          },
                          child: const Text('detector'),
                        ),

                        // * recognizer button
                        OutlinedButton(
                          style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(!isDetectMode ? Colors.greenAccent.withOpacity(0.3) : Colors.transparent)),
                          onPressed: () async {
                            if (_cameraService.cameraController!.value.isStreamingImages) {
                              await _cameraService.cameraController!.stopImageStream();
                            }
                            _isDetectMode.value = false;
                            await _cameraService.cameraController!.startImageStream(_computeDetectorPoints);
                            setState(() {});
                          },
                          child: const Text('recognizer'),
                        ),
                      ],
                    );
                  }),

              // * anti shake
              if (_isDetectMode.value)
                ValueListenableBuilder<int>(
                    valueListenable: _antiShake,
                    builder: (_, antiShake, __) {
                      return Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text('anti shake ${_antiShake.value}'),
                          Expanded(
                            child: Slider.adaptive(
                              min: 0,
                              max: 10,
                              divisions: 11,
                              value: antiShake.toDouble(),
                              onChanged: (v) {
                                _antiShake.value = v.toInt();
                                _faceDetectorService.setAntiShake(_antiShake.value);
                              },
                            ),
                          ),
                        ],
                      );
                    }),

              ValueListenableBuilder<bool>(
                  valueListenable: _isDetectMode,
                  builder: (_, isDetectMode, __) {
                    return Row(
                      children: [
                        // * image which DLib will process (for debug purpose)
                        Column(
                          children: [
                            const Text('what DLib\nwill process'),
                            ValueListenableBuilder<Uint8List>(
                                valueListenable: _adjustedImg,
                                builder: (_, adjustedImg, __) {
                                  if (_cameraImage == null) {
                                    return Container();
                                  }
                                  return SizedBox(
                                    width: 130,
                                    height: 130 / _cameraService.cameraController!.value.aspectRatio,
                                    child: Image.memory(
                                      adjustedImg,
                                      width: _cameraImage!.width.toDouble(),
                                      height: _cameraImage!.height.toDouble(),
                                      gaplessPlayback: true,
                                    ),
                                  );
                                }),
                          ],
                        ),

                        // * Detect mode: Landmark points / rectangle
                        if (isDetectMode)
                          ValueListenableBuilder<bool>(
                              valueListenable: _getFacePoints,
                              builder: (_, getFacePoints, __) {
                                return OutlinedButton.icon(
                                  label: Text(getFacePoints ? 'landmaks' : 'rectangle'),
                                  icon: Icon(getFacePoints ? Icons.face : Icons.crop_square),
                                  onPressed: () {
                                    _getFacePoints.value = !_getFacePoints.value;
                                    _faceDetectorService.setGetOnlyRectangle(_getFacePoints.value);
                                  },
                                );
                              }),

                        // * add face
                        if (!isDetectMode && recognizerInitialized && startGrab)
                          OutlinedButton.icon(
                            label: const Text('add face'),
                            icon: const Icon(Icons.face),
                            onPressed: () {
                              tryToAddFace = true;
                            },
                          ),

                        // * face image added
                        if (!isDetectMode)
                          ValueListenableBuilder<Uint8List>(
                              valueListenable: _faceImage,
                              builder: (_, recognizedFaceImage, __) {
                                if (recognizedFaceImage.isEmpty) return Container();
                                return Image.memory(
                                  recognizedFaceImage,
                                  width: 100,
                                  gaplessPlayback: true,
                                );
                              }),
                      ],
                    );
                  }),

              Row(
                children: [
                  // * rotate frame to pass to dlib
                  OutlinedButton.icon(
                    label: const Text('rotate'),
                    icon: const Icon(Icons.rotate_left),
                    onPressed: () {
                      rotate--;
                      if (rotate < -1) rotate = 2;
                      if (_isDetectMode.value) {
                        _faceDetectorService.setRotation(rotate);
                      } else {
                        RecognizerInterface().setRotation(rotate);
                      }
                    },
                  ),

                  // * flip frame to pass to dlib
                  OutlinedButton.icon(
                    label: const Text('flip'),
                    icon: const Icon(Icons.flip_outlined),
                    onPressed: () {
                      flip--;
                      if (flip < -2) flip = 1;
                      if (_isDetectMode.value) {
                        _faceDetectorService.setFlip(flip);
                      } else {
                        RecognizerInterface().setFlip(flip);
                      }
                    },
                  ),
                ],
              ),

              // * points
              facepoints == null
                  ? Container()
                  : SizedBox(
                      width: 150,
                      child: FittedBox(
                        child: CustomPaint(
                          size: Size(isSwapped ? w : h, isSwapped ? h : w),
                          painter: PointsPainter(
                            pointsMap: facepoints,
                            backgroundColor: Colors.black,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
