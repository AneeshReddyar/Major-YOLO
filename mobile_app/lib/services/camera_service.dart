import 'dart:async';
import 'package:camera/camera.dart';

class CameraService {
  // Singleton pattern
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();
  
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  int _selectedCameraIndex = 0;
  
  // Camera options
  bool _flashEnabled = false;
  
  // Getters
  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get hasMultipleCameras => _cameras != null && _cameras!.length > 1;
  bool get flashEnabled => _flashEnabled;
  
  /// Initialize camera service
  Future<void> initialize() async {
    if (_cameras == null) {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        throw CameraException('No cameras available', 'No cameras were found on this device');
      }
    }
  }
  
  /// Initialize camera controller
  Future<void> initializeController() async {
    if (_cameras == null || _cameras!.isEmpty) {
      await initialize();
    }
    
    // Dispose previous controller if exists
    await _controller?.dispose();
    
    // Create new controller
    _controller = CameraController(
      _cameras![_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    
    // Initialize controller
    try {
      await _controller!.initialize();
      _isInitialized = true;
      
      // Set initial flash mode
      await _controller!.setFlashMode(FlashMode.off);
    } catch (e) {
      _isInitialized = false;
      rethrow;
    }
  }
  
  /// Take a picture
  Future<XFile> takePicture() async {
    if (_controller == null || !_isInitialized) {
      throw CameraException('Camera not initialized', 'Initialize camera before taking picture');
    }
    
    return await _controller!.takePicture();
  }
  
  /// Switch between front and back cameras
  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length <= 1) return;
    
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    await initializeController();
  }
  
  /// Toggle flash
  Future<void> toggleFlash() async {
    if (_controller == null || !_isInitialized) return;
    
    _flashEnabled = !_flashEnabled;
    await _controller!.setFlashMode(
      _flashEnabled ? FlashMode.torch : FlashMode.off
    );
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}