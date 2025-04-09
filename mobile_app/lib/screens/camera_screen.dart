import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../services/camera_service.dart';
import '../services/detection_service.dart';
import '../widgets/camera_controls.dart';
import '../utils/theme.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  final DetectionService _detectionService = DetectionService();
  final ImagePicker _picker = ImagePicker();
  
  bool _isProcessing = false;
  String _statusMessage = "Initializing...";
  String? _resultImageUrl;
  int _cropCount = 0;
  int _weedCount = 0;
  bool _showResultScreen = false;
  bool _backendConnected = true;
  bool _isReconnecting = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _checkBackendConnection();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _cameraService.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
      _checkBackendConnection();
    }
  }
  
  void _initializeCamera() async {
    setState(() {
      _statusMessage = "Initializing camera...";
    });
    
    try {
      await _cameraService.initialize();
      await _cameraService.initializeController();
      
      if (mounted) {
        setState(() {
          _statusMessage = "Ready";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Camera error: $e";
      });
    }
  }
  
  Future<void> _checkBackendConnection() async {
    if (_isReconnecting) return;
    
    setState(() {
      _isReconnecting = true;
      _statusMessage = "Checking backend connection...";
    });
    
    try {
      bool isConnected = await _detectionService.checkConnection();
      if (mounted) {
        setState(() {
          _backendConnected = isConnected;
          _isReconnecting = false;
          _statusMessage = isConnected ? "Ready" : "Backend server not connected";
          
          if (isConnected) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Connected to backend server"),
                backgroundColor: AppTheme.primaryColor,
                duration: Duration(milliseconds: 500),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Failed to connect to backend server"),
                backgroundColor: AppTheme.errorColor,
                duration: Duration(milliseconds: 500),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _backendConnected = false;
          _isReconnecting = false;
          _statusMessage = "Connection error: $e";
        });
      }
    }
  }

  Future<void> _captureAndProcess() async {
    if (!_cameraService.isInitialized || _isProcessing) return;
    
    if (!_backendConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Backend server not connected. Please reconnect and try again."),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _statusMessage = "Processing...";
    });
    
    try {
      final XFile imageFile = await _cameraService.takePicture();
      final processResult = await _detectionService.processImage(File(imageFile.path));
      
      if (mounted) {
        setState(() {
          _isProcessing = false;
          
          if (processResult != null) {
            _resultImageUrl = processResult['image_url'];
            _cropCount = processResult['detections']
                .where((d) => d['class'] == 'crop')
                .length;
            _weedCount = processResult['detections']
                .where((d) => d['class'] == 'weed')
                .length;
            _showResultScreen = true;
            _statusMessage = "Detection completed";
          } else {
            _statusMessage = "Processing failed";
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Failed to process image"),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = "Error: $e";
        });
      }
    }
  }
  
  Future<void> _pickAndProcess() async {
    if (_isProcessing) return;
    
    if (!_backendConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Backend server not connected. Please reconnect and try again."),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile == null) return;
      
      setState(() {
        _isProcessing = true;
        _statusMessage = "Processing gallery image...";
      });
      
      final processResult = await _detectionService.processImage(File(pickedFile.path));
      
      if (mounted) {
        setState(() {
          _isProcessing = false;
          
          if (processResult != null) {
            _resultImageUrl = processResult['image_url'];
            _cropCount = processResult['detections']
                .where((d) => d['class'] == 'crop')
                .length;
            _weedCount = processResult['detections']
                .where((d) => d['class'] == 'weed')
                .length;
            _showResultScreen = true;
            _statusMessage = "Detection completed";
          } else {
            _statusMessage = "Processing failed";
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Failed to process image"),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = "Error: $e";
        });
      }
    }
  }
  
  Future<void> _saveResultToGallery() async {
    if (_resultImageUrl == null) return;
    
    setState(() {
      _statusMessage = "Saving to gallery...";
    });
    
    try {
      bool saved = await _detectionService.saveProcessedImage(_resultImageUrl!);
      
      if (mounted) {
        setState(() {
          _statusMessage = saved ? "Saved to gallery!" : "Failed to save";
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_statusMessage),
            backgroundColor: saved ? AppTheme.primaryColor : AppTheme.errorColor,
            duration: const Duration(milliseconds: 500),
          ),
        );
        
        if (saved) {
          // Return to camera screen after successful save
          _backToCamera();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = "Save error: $e";
        });
      }
    }
  }
  
  void _toggleFlash() async {
    await _cameraService.toggleFlash();
    setState(() {});  // Update UI to reflect flash state
  }
  
  void _backToCamera() {
    setState(() {
      _showResultScreen = false;
      _resultImageUrl = null;
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Crop/Weed Detection'),
        backgroundColor: Colors.black87,
        actions: [
          // Backend reconnect button
          IconButton(
            icon: Icon(
              _backendConnected ? Icons.cloud_done : Icons.cloud_off,
              color: _backendConnected ? AppTheme.primaryColor : AppTheme.errorColor,
            ),
            onPressed: _isReconnecting ? null : _checkBackendConnection,
            tooltip: _backendConnected ? 'Backend connected' : 'Reconnect to backend',
          ),
        ],
      ),
      body: _showResultScreen ? _buildResultScreen() : _buildCameraScreen(),
    );
  }
  
  Widget _buildCameraScreen() {
    if (!_cameraService.isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(_statusMessage, style: const TextStyle(color: Colors.white)),
          ],
        ),
      );
    }
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        CameraPreview(_cameraService.controller!),
          
        // Status panel at top
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: _buildStatusPanel(),
        ),
        
        // Camera controls
        CameraControls(
          onCapturePressed: _captureAndProcess,
          onGalleryPressed: _pickAndProcess,
          onFlashToggle: _toggleFlash,
          isProcessing: _isProcessing,
          flashEnabled: _cameraService.flashEnabled,
        ),
      ],
    );
  }

  Widget _buildResultScreen() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status panel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.black87,
            child: Column(
              children: [
                Text(
                  _statusMessage,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.eco, color: AppTheme.primaryColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Crops: $_cropCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.grass, color: AppTheme.errorColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Weeds: $_weedCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Image result
          Expanded(
            child: _resultImageUrl != null
                ? Image.network(
                    '${_detectionService.backendUrl}$_resultImageUrl',
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: AppTheme.primaryColor,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, color: AppTheme.errorColor, size: 48),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'Failed to load image',
                                style: const TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Text(
                      'No result image available',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
          ),
          
          // Action buttons - Responsive layout
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // For narrow screens, stack buttons vertically
                if (constraints.maxWidth < 300) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSaveButton(),
                      const SizedBox(height: 8),
                      _buildDiscardButton(),
                    ],
                  );
                } else {
                  // For wider screens, place buttons side by side
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(child: _buildDiscardButton()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSaveButton()),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _resultImageUrl != null ? _saveResultToGallery : null,
      icon: const Icon(Icons.save_alt),
      label: const Text('Save'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
  
  Widget _buildDiscardButton() {
    return ElevatedButton.icon(
      onPressed: _backToCamera,
      icon: const Icon(Icons.close),
      label: const Text('Discard'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
  
  Widget _buildStatusPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isReconnecting)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
                strokeWidth: 2,
              ),
            ),
          if (_isReconnecting)
            const SizedBox(width: 8),
          Flexible(
            child: Text(
              _statusMessage,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}