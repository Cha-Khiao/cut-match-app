import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceAnalysisService {
  final FaceDetector _faceDetector;

  FaceAnalysisService()
    : _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          enableContours: true, // ✅ ใช้แบบนี้
          enableLandmarks: true, // ถ้าอยากได้ landmark ด้วย
        ),
      );

  Future<List<Face>?> analyzeImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final List<Face> faces = await _faceDetector.processImage(inputImage);
      return faces.isNotEmpty ? faces : null;
    } catch (e) {
      print('❌ Error during ML Kit processing: $e');
      return null;
    }
  }

  void dispose() {
    _faceDetector.close();
  }
}
