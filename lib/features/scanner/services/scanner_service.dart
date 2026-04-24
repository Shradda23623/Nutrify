import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ScannerService {
  final textRecognizer = TextRecognizer();

  Future<String> scanText(InputImage image) async {
    final RecognizedText recognizedText =
    await textRecognizer.processImage(image);

    return recognizedText.text;
  }
}