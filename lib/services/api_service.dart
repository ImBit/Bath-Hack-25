import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AnimalDetectionApi {
  // Use your computer's IP address on your local network
  // For testing on an emulator, you can use 10.0.2.2 instead of localhost
  final String baseUrl;

  AnimalDetectionApi({this.baseUrl = 'http://172.26.15.254:8000'});

  Future<Map<String, dynamic>> startDetection(List<File> images) async {
    try {
      final Uri url = Uri.parse('$baseUrl/detect-animals');

      var request = http.MultipartRequest('POST', url);

      // Add all images to the request
      for (var i = 0; i < images.length; i++) {
        final file = images[i];
        final fileName = file.path.split('/').last;

        final multipartFile = await http.MultipartFile.fromPath(
          'files', // Must match the parameter name in your FastAPI function
          file.path,
          filename: fileName,
          contentType: MediaType('image', fileName.split('.').last),
        );

        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse;
      } else {
        throw Exception('Failed to upload images: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API error: $e');
    }
  }

  Future<Map<String, dynamic>> checkStatus(String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/detection-status/$sessionId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to check status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API error: $e');
    }
  }
}