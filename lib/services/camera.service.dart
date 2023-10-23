import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:face_net_authentication/pages/database_Data.dart';
import 'package:face_net_authentication/pages/models/param.model.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:face_net_authentication/pages/db/databse_helper.dart';
import 'package:face_net_authentication/services/pub_service.dart';

class CameraService {
  CameraController? _cameraController;
  CameraController? get cameraController => this._cameraController;

  InputImageRotation? _cameraRotation;
  InputImageRotation? get cameraRotation => this._cameraRotation;

  String? _imagePath;
  String? get imagePath => this._imagePath;

  CameraDescription? description;

  double minAvailableExposureOffset = 0.0;
  double maxAvailableExposureOffset = 0.0;
  double currentExposureOffset = 0.0;

  Future<void> initialize() async {
    if (_cameraController != null) return;
    description = await _getCameraDescription();

    await _setupCameraController(description: description!);
    this._cameraRotation = rotationIntToImageRotation(
      description!.sensorOrientation,
    );
    loadExposureVal();
  }

  void saveExposureVal() async {
    DatabaseHelper _databaseHelper = DatabaseHelper.instance;
    final param_exposure = await _databaseHelper.queryByColumn(DatabaseHelper.param_table, DatabaseHelper.columnKey, Param_enum.exposure.description);
    if(param_exposure.isNotEmpty){
      _databaseHelper.updateParamVal(param_exposure[0].id!, currentExposureOffset.toString());
    }
    else{
      Param pr = Param(key: Param_enum.exposure.description, val: currentExposureOffset.toString());
      _databaseHelper.insertParam(pr);
    }
  }

  void loadExposureVal() async {
    DatabaseHelper _databaseHelper = DatabaseHelper.instance;
    final param_exposure = await _databaseHelper.queryByColumn(DatabaseHelper.param_table, DatabaseHelper.columnKey, Param_enum.exposure.description);
    if(param_exposure.isNotEmpty){
      currentExposureOffset = double.tryParse(param_exposure[0].val)!;
      _cameraController!.setExposureOffset(currentExposureOffset);
    }

  }

  void onNewCameraSelected({cameraDirection = CameraLensDirection.front, resolution = ResolutionPreset.veryHigh}) async {
    await stopStream();
    await dispose();
    description = await _getCameraDescription(cameraDirection: cameraDirection);
    await _setupCameraController(description: description!, resolution: resolution);
    this._cameraRotation = rotationIntToImageRotation(
      description!.sensorOrientation,
    );
  }

  void setOrientation(DeviceOrientation orientation) {
    _cameraController?.lockCaptureOrientation(orientation);
  }

  Future<CameraDescription> _getCameraDescription({cameraDirection = CameraLensDirection.front}) async {
    List<CameraDescription> cameras = await availableCameras();
    return cameras.firstWhere((CameraDescription camera) => camera.lensDirection == cameraDirection);
  }

  void setExposureValue(double val) async {
    await _cameraController!.setExposureOffset(val);
  }

  Future _setupCameraController({required CameraDescription description, resolution = ResolutionPreset.veryHigh}) async {
    this._cameraController = CameraController(
      description,
      resolution,
      enableAudio: false,
    );
    await _cameraController?.initialize();

    await _cameraController!.getMinExposureOffset().then((value) => minAvailableExposureOffset = value);
    await _cameraController!.getMaxExposureOffset().then((value) => maxAvailableExposureOffset = value);
    await _cameraController!.setExposureOffset(currentExposureOffset);
  }

  InputImageRotation rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Future<XFile?> takePicture() async {
    assert(_cameraController != null, 'Camera controller not initialized');
    if (_cameraController!.value.isStreamingImages) await _cameraController?.stopImageStream();
    XFile? file = await _cameraController?.takePicture();
    _imagePath = file?.path;
    return file;
  }

  //設定retry功能
  Future<XFile?> trytakePicture() async {
    assert(_cameraController != null, 'Camera controller not initialized');
    if (_cameraController!.value.isStreamingImages) await _cameraController?.stopImageStream();

    int numTries = 0;
    while (numTries < 3) {
      try {
        XFile? file = await _cameraController?.takePicture();
        _imagePath = file?.path;
        return file;
      } catch (e) {
        numTries++;
        print('Error taking picture: $e');
        print('Retrying...');
      }
    }

    throw CameraException(
      'Unable to take picture after 3 attempts.',
      'takePicture failed after trying 3 times.',
    );
  }

  Future<void> stopStream() async {
    assert(_cameraController != null, 'Camera controller not initialized');
    if (_cameraController!.value.isStreamingImages) await _cameraController?.stopImageStream();
  }

  Size getImageSize() {
    assert(_cameraController != null, 'Camera controller not initialized');
    assert(_cameraController!.value.previewSize != null, 'Preview size is null');
    return Size(
      _cameraController!.value.previewSize!.height,
      _cameraController!.value.previewSize!.width,
    );
  }

  dispose() async {
    await this._cameraController?.dispose();
    this._cameraController = null;
  }
}
