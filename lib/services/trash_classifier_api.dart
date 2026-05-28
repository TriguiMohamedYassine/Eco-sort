import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class TrashClassificationApi {
  TrashClassificationApi({String? baseUrl})
    : baseUrl = baseUrl ?? resolveDefaultBaseUrl();

  final String baseUrl;
  static const String _defaultBackendUrl = 'http://192.168.100.249:8000';

  static const String _baseUrlOverride = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: '',
  );

  static String resolveDefaultBaseUrl() {
    if (_baseUrlOverride.trim().isNotEmpty) {
      return _baseUrlOverride.trim();
    }

    return _defaultBackendUrl;
  }

  Future<TrashClassificationResult> classifyImage(
    String imagePath, {
    double confidenceThreshold = 0.25,
  }) async {
    final uri = Uri.parse('$baseUrl/predict');
    final request = http.MultipartRequest('POST', uri)
      ..fields['conf'] = confidenceThreshold.toString()
      ..files.add(await http.MultipartFile.fromPath('file', imagePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Prediction request failed (${response.statusCode}).';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
          message = decoded['detail'].toString();
        }
      } catch (_) {
        if (response.body.isNotEmpty) {
          message = response.body;
        }
      }
      throw Exception(message);
    }

    final decodedBody = jsonDecode(response.body) as Map<String, dynamic>;
    return TrashClassificationResult.fromJson(decodedBody);
  }
}

class TrashClassificationResult {
  TrashClassificationResult({
    required this.detectionCount,
    required this.detections,
    required this.annotatedImageBytes,
    required this.originalImageBytes,
    required this.model,
    required this.confThreshold,
  });

  final int detectionCount;
  final List<TrashDetection> detections;
  final Uint8List? annotatedImageBytes;
  final Uint8List? originalImageBytes;
  final String? model;
  final double confThreshold;

  factory TrashClassificationResult.fromJson(Map<String, dynamic> json) {
    final detectionsJson = (json['detections'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    return TrashClassificationResult(
      detectionCount: (json['detection_count'] as num?)?.toInt() ?? 0,
      detections: detectionsJson
          .map(TrashDetection.fromJson)
          .toList(growable: false),
      annotatedImageBytes: _decodeImage(json['annotated_image']),
      originalImageBytes: _decodeImage(json['original_image']),
      model: json['model']?.toString(),
      confThreshold: (json['conf_threshold'] as num?)?.toDouble() ?? 0.25,
    );
  }

  static Uint8List? _decodeImage(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return base64Decode(value);
  }
}

class TrashDetection {
  TrashDetection({
    required this.classId,
    required this.label,
    required this.confidence,
    required this.boundingBox,
  });

  final int classId;
  final String label;
  final double confidence;
  final Map<String, dynamic> boundingBox;

  factory TrashDetection.fromJson(Map<String, dynamic> json) {
    return TrashDetection(
      classId: (json['class_id'] as num?)?.toInt() ?? -1,
      label: json['label']?.toString() ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      boundingBox: (json['bbox'] as Map<String, dynamic>?) ?? const {},
    );
  }
}
