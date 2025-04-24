// lib/screens/home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isBackendAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBackendStatus();
  }

  Future<void> _checkBackendStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    bool isAvailable = await ApiService.checkBackendStatus();
    
    setState(() {
      _isBackendAvailable = isAvailable;
      _isLoading = false;
    });
  }

  Future<void> _getImage(ImageSource source) async {
    if (!_isBackendAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backend server is not available')),
      );
      return;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      
      if (pickedFile == null) return;
      
      setState(() {
        _isLoading = true;
      });
      
      File imageFile = File(pickedFile.path);
      final result = await ApiService.detectCropWeed(imageFile);
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            resultData: result,
            originalImage: imageFile,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Crop Weed Detector'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkBackendStatus,
            tooltip: 'Check server connection',
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.green.shade100, Colors.green.shade50],
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.eco,
                      size: 80,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Crop & Weed Detection',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Take or select a photo to identify crops and weeds',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildOptionButton(
                          icon: Icons.camera_alt,
                          label: 'Camera',
                          onTap: () => _getImage(ImageSource.camera),
                        ),
                        _buildOptionButton(
                          icon: Icons.photo_library,
                          label: 'Gallery',
                          onTap: () => _getImage(ImageSource.gallery),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Icon(
                          _isBackendAvailable ? Icons.check_circle : Icons.error,
                          color: _isBackendAvailable ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _isBackendAvailable
                              ? 'Server connected'
                              : 'Server disconnected',
                          style: TextStyle(
                            color: _isBackendAvailable ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 50, color: Colors.green),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}