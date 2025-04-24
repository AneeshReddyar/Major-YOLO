// lib/services/api_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

class ApiService {
  // Check if backend is available
  static Future<bool> checkBackendStatus() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.healthEndpoint}'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Send image for prediction
  static Future<Map<String, dynamic>> detectCropWeed(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.predictEndpoint}'),
      );
      
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ));
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to process image: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending image: $e');
      }
      throw Exception('Failed to communicate with server');
    }
  }
}