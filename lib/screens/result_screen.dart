import 'dart:io';

import 'package:flutter/material.dart';

import '../services/trash_classifier_api.dart';

class ResultScreen extends StatefulWidget {
  final String? imagePath;
  const ResultScreen({super.key, this.imagePath});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final Future<TrashClassificationResult> _predictionFuture;
  final TrashClassificationApi _api = TrashClassificationApi();

  @override
  void initState() {
    super.initState();
    _predictionFuture = _loadPrediction();
  }

  Future<TrashClassificationResult> _loadPrediction() async {
    final imagePath = widget.imagePath;
    if (imagePath == null || imagePath.isEmpty) {
      throw Exception('No image selected for classification.');
    }
    return _api.classifyImage(imagePath);
  }

  String _categoryForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'biodegradable/organic':
        return 'Organic';
      case 'cardboard':
      case 'paper':
        return 'Recyclable';
      case 'glass':
      case 'metal':
      case 'plastic':
        return 'Recyclable';
      default:
        return 'Sorted waste';
    }
  }

  String _adviceForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'biodegradable/organic':
        return 'Place it in the organic bin or compost if your local program accepts it.';
      case 'cardboard':
        return 'Flatten it and keep it dry before putting it in paper recycling.';
      case 'glass':
        return 'Rinse the container and recycle it in the glass stream if available.';
      case 'metal':
        return 'Empty and rinse it before placing it in the metal recycling bin.';
      case 'paper':
        return 'Keep it clean and dry so it can be recycled properly.';
      case 'plastic':
        return 'Rinse it, remove the lid if required locally, and place it in plastic recycling.';
      default:
        return 'Check your local waste rules before disposing of this item.';
    }
  }

  Widget _buildPreview(TrashClassificationResult? result) {
    final imageBytes = result?.annotatedImageBytes;
    if (imageBytes != null) {
      return Image.memory(imageBytes, fit: BoxFit.cover);
    }
    if (widget.imagePath != null) {
      return Image.file(File(widget.imagePath!), fit: BoxFit.cover);
    }
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.image_outlined, size: 88, color: Colors.black26),
      ),
    );
  }

  Widget _buildBody(TrashClassificationResult result) {
    final topDetection = result.detections.isNotEmpty
        ? result.detections.first
        : null;
    final label = topDetection?.label ?? 'No detection';
    final confidence = topDetection?.confidence ?? 0;
    final category = topDetection == null
        ? 'No object detected'
        : _categoryForLabel(label);
    final advice = topDetection == null
        ? 'Try a clearer photo with the item centered in the frame.'
        : _adviceForLabel(label);

    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(height: 240, child: _buildPreview(result)),
        ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.recycling, color: Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${(confidence * 100).toStringAsFixed(0)}% confidence',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    category,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.green,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recycling Instructions',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(advice),
                if (result.detections.length > 1) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Other detections',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: result.detections
                        .map(
                          (detection) => Chip(
                            label: Text(
                              '${detection.label} ${(detection.confidence * 100).toStringAsFixed(0)}%',
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (result.model != null) ...[
          const SizedBox(height: 12),
          Text(
            'Model: ${result.model} | Threshold: ${result.confThreshold.toStringAsFixed(2)} | Detections: ${result.detectionCount}',
            style: const TextStyle(color: Colors.black54),
          ),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed('/camera'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Scan Another'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: FutureBuilder<TrashClassificationResult>(
        future: _predictionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(height: 240, child: _buildPreview(null)),
                ),
                const SizedBox(height: 20),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 12),
                const Center(
                  child: Text('Sending image to the trash classifier...'),
                ),
              ],
            );
          }

          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(height: 240, child: _buildPreview(null)),
                ),
                const SizedBox(height: 16),
                Card(
                  color: Colors.red.withValues(alpha: 0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Could not classify the image.\n${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pushReplacementNamed('/camera'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            );
          }

          final result = snapshot.data;
          if (result == null) {
            return const Center(child: Text('No result available.'));
          }
          return _buildBody(result);
        },
      ),
    );
  }
}
