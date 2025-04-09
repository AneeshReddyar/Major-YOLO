import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

class Detection {
  final String className;
  final double confidence;
  final List<double> bbox;

  Detection({
    required this.className,
    required this.confidence,
    required this.bbox,
  });

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      className: json['class'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      bbox: (json['bbox'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }
}

class DetectionService {
  // Server URL
  final String _backendUrl;
  String get backendUrl => _backendUrl;

  DetectionService({String? backendUrl})
      : _backendUrl = backendUrl ?? "http://192.168.1.9:5000";

  /// Check if backend server is connected
  Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$_backendUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('Backend connection error: $e');
      return false;
    }
  }

  /// Process image and get detections with result image
  Future<Map<String, dynamic>?> processImage(File imageFile) async {
    try {
      var request =
          http.MultipartRequest('POST', Uri.parse('$_backendUrl/predict'));

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ));

      var streamedResponse = await request.send().timeout(
            const Duration(seconds: 15),
          );

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Processing error: $e');
      return null;
    }
  }

  /// Save the processed image to gallery
  Future<bool> saveProcessedImage(String imageUrl) async {
    try {
      // Download processed image
      var imageResponse = await http.get(Uri.parse('$_backendUrl$imageUrl'));

      // Save to temp directory first
      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/detected_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(imagePath).writeAsBytes(imageResponse.bodyBytes);

      // Then save to gallery
      final result = await GallerySaver.saveImage(imagePath,
          albumName: 'CropWeedDetection');

      return result ?? false;
    } catch (e) {
      print('Save error: $e');
      return false;
    }
  }
}