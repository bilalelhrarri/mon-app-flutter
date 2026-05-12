import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadPhoto(File image, String plateNumber) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$plateNumber.jpg';
      final ref = _storage.ref().child('plate_photos/$fileName');
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Storage error: $e');
      return '';
    }
  }
}