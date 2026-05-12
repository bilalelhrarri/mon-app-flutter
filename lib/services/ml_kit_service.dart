import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../utils/plate_validator.dart';

class MlKitService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<String?> extractPlateFromImage(File image) async {
    try {
      final inputImage = InputImage.fromFile(image);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      String bestMatch = '';
      double bestConfidence = 0.0;

      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final rawText = line.text.replaceAll(RegExp(r'\s'), '');
          final confidence = line.confidence ?? 0.0;
          if (PlateValidator.isValidMoroccanPlate(rawText) &&
              confidence > bestConfidence) {
            bestMatch = rawText;
            bestConfidence = confidence;
          }
        }
      }
      return bestMatch.isNotEmpty ? bestMatch : null;
    } catch (e) {
      print('OCR error: $e');
      return null;
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}