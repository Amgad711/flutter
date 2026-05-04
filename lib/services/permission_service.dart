import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> requestPhotos() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  Future<bool> requestMicrophone() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> requestStorage() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<Map<Permission, PermissionStatus>> requestCameraAndPhotos() async {
    return await [Permission.camera, Permission.photos].request();
  }

  Future<bool> isCameraGranted() async => await Permission.camera.isGranted;
  Future<bool> isPhotosGranted() async => await Permission.photos.isGranted;
  Future<bool> isMicrophoneGranted() async => await Permission.microphone.isGranted;

  Future<void> openSettings() async => await openAppSettings();
}
