import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/message_model.dart';

const _uuid = Uuid();
const int _maxImageBytes = 10 * 1024 * 1024; // 10 MB
const int _maxAudioBytes = 5 * 1024 * 1024;  // 5 MB

class UploadResult {
  final String url;
  final MessageMetadata? metadata;

  const UploadResult({required this.url, this.metadata});
}

class FileUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<UploadResult> uploadImage(String chatId, String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();

    if (bytes.length > _maxImageBytes) {
      throw Exception('Image file exceeds 10 MB limit');
    }

    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Could not decode image');

    // Compress to WebP
    final compressed = img.encodeJpg(decoded, quality: 75) ;
    final fileName = '${_uuid.v4()}.Jpg';
    final ref = _storage.ref().child('chats/$chatId/images/$fileName');

    final uploadTask = ref.putData(
      compressed,
      SettableMetadata(contentType: 'image/Jpeg'),
    );

    final snapshot = await _retryUpload(uploadTask);
    final url = await snapshot.ref.getDownloadURL();

    return UploadResult(
      url: url,
      metadata: MessageMetadata(
        imageWidth: decoded.width.toDouble(),
        imageHeight: decoded.height.toDouble(),
      ),
    );
  }

  Future<UploadResult> uploadVoice(String chatId, String filePath, int durationSeconds) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();

    if (bytes.length > _maxAudioBytes) {
      throw Exception('Audio file exceeds 5 MB limit');
    }

    final ext = path.extension(filePath).toLowerCase();
    final fileName = '${_uuid.v4()}$ext';
    final ref = _storage.ref().child('chats/$chatId/voice/$fileName');

    final contentType = ext == '.aac' ? 'audio/aac' : 'audio/mp4';
    final uploadTask = ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );

    final snapshot = await _retryUpload(uploadTask);
    final url = await snapshot.ref.getDownloadURL();

    return UploadResult(
      url: url,
      metadata: MessageMetadata(duration: durationSeconds),
    );
  }

  Future<TaskSnapshot> _retryUpload(UploadTask task, {int maxAttempts = 3}) async {
    int attempt = 0;
    while (true) {
      try {
        attempt++;
        return await task;
      } catch (e) {
        if (attempt >= maxAttempts) rethrow;
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
  }

  Future<Uint8List> compressImageToWebp(String filePath, {int quality = 75}) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Could not decode image');
    return img.encodeJpg(decoded, quality: quality);
  }

  Future<String> saveTempFile(Uint8List bytes, String extension) async {
    final tmpDir = await getTemporaryDirectory();
    final file = File('${tmpDir.path}/${_uuid.v4()}.$extension');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
