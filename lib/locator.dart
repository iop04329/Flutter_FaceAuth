import 'package:face_net_authentication/services/camera.service.dart';
import 'package:face_net_authentication/services/ml_service.dart';
import 'package:face_net_authentication/services/face_detector_service.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_opencv_dlib/flutter_opencv_dlib.dart';
import 'package:face_net_authentication/services/pub_service.dart';

final locator = GetIt.instance;

void setupServices() {
  locator.registerLazySingleton<CameraService>(() => CameraService());
  locator.registerLazySingleton<FaceDetectorService>(() => FaceDetectorService());
  locator.registerLazySingleton<MLService>(() => MLService());
  locator.registerLazySingleton<DetectorInterface>(() => DetectorInterface());
  locator.registerLazySingleton<RecognizerInterface>(() => RecognizerInterface());
  locator.registerLazySingleton<pub_service>(() => pub_service());
}
