import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/camera_screen.dart';
import 'utils/theme.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  // Request required permissions
  await [Permission.camera, Permission.storage, Permission.photos].request();
  
  runApp(const CropWeedDetectionApp());
}

class CropWeedDetectionApp extends StatelessWidget {
  const CropWeedDetectionApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crop Weed Detection',
      theme: AppTheme.darkTheme,
      home: const CameraScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}