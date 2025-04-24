// lib/screens/result_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/constants.dart';

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> resultData;
  final File originalImage;

  const ResultScreen({
    Key? key,
    required this.resultData,
    required this.originalImage,
  }) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isSaving = false;

  Future<void> _saveImageToGallery() async {
  try {
    setState(() {
      _isSaving = true;
    });

    // Get the image URL
    final imageUrl = widget.resultData['image_url'] as String;
    final fullUrl = '${ApiConstants.baseUrl}$imageUrl';
    
    // Download the image
    final response = await http.get(Uri.parse(fullUrl));
    
    if (response.statusCode == 200) {
      // Create a temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/crop_weed_detection.jpg');
      await file.writeAsBytes(response.bodyBytes);
      
      // Save to gallery
      final success = await GallerySaver.saveImage(
        file.path,
        albumName: "Crop Weed Detection"
      );
      
      if (success == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image saved to gallery successfully')),
        );
      } else {
        throw Exception('Failed to save image to gallery');
      }
    } else {
      throw Exception('Failed to download image');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error saving image: ${e.toString()}')),
    );
  } finally {
    setState(() {
      _isSaving = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final detections = widget.resultData['detections'] as List;
    final imageUrl = widget.resultData['image_url'] as String;
    final detectionCount = widget.resultData['detection_count'] as int;
    
    // Count by class
    int cropCount = 0;
    int weedCount = 0;
    
    for (var detection in detections) {
      if (detection['class'] == 'crop') {
        cropCount++;
      } else if (detection['class'] == 'weed') {
        weedCount++;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection Results'),
        actions: [
          _isSaving
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.save_alt),
                  tooltip: 'Save to gallery',
                  onPressed: _saveImageToGallery,
                ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Detection stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem(
                          'Total', 
                          detectionCount.toString(), 
                          Icons.analytics
                        ),
                        _buildStatItem(
                          'Crops', 
                          cropCount.toString(), 
                          Icons.spa
                        ),
                        _buildStatItem(
                          'Weeds', 
                          weedCount.toString(), 
                          Icons.pest_control
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Detected Image
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detection Results:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                    onPressed: _isSaving ? null : _saveImageToGallery,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  '${ApiConstants.baseUrl}$imageUrl',
                  width: double.infinity,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 300,
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 300,
                      width: double.infinity,
                      alignment: Alignment.center,
                      color: Colors.grey.shade200,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 50, color: Colors.red),
                          SizedBox(height: 10),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Detection Details
              const Text(
                'Detection Details:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: detections.length,
                itemBuilder: (context, index) {
                  final detection = detections[index];
                  final isWeed = detection['class'] == 'weed';
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 1,
                    child: ListTile(
                      leading: Icon(
                        isWeed ? Icons.pest_control : Icons.spa,
                        color: isWeed ? Colors.red : Colors.green,
                        size: 30,
                      ),
                      title: Text(
                        detection['class'].toString().toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isWeed ? Colors.red : Colors.green,
                        ),
                      ),
                      subtitle: Text(
                        'Confidence: ${(detection['confidence'] * 100).toStringAsFixed(1)}%',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon) {
    Color iconColor = label == 'Weeds' ? Colors.red : Colors.green;
    
    return Column(
      children: [
        Icon(icon, size: 30, color: iconColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22, 
            fontWeight: FontWeight.bold,
            color: iconColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
} 