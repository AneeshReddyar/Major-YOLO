// lib/widgets/camera_controls.dart
import 'package:flutter/material.dart';
import '../utils/theme.dart';

class CameraControls extends StatelessWidget {
  final Function() onCapturePressed;
  final Function() onGalleryPressed;
  final Function() onFlashToggle;
  final bool isProcessing;
  final bool flashEnabled;
  
  const CameraControls({
    Key? key,
    required this.onCapturePressed,
    required this.onGalleryPressed,
    required this.onFlashToggle,
    required this.isProcessing,
    required this.flashEnabled,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Column(
        children: [
          // Processing indicator when needed
          if (isProcessing)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Processing...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Main camera controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Gallery picker button
              _buildControlButton(
                icon: Icons.photo_library,
                onPressed: isProcessing ? null : onGalleryPressed,
                color: Colors.white,
              ),
              
              // Capture button
              _buildCaptureButton(),
              
              // Flash toggle button
              _buildControlButton(
                icon: flashEnabled ? Icons.flash_on : Icons.flash_off,
                onPressed: isProcessing ? null : onFlashToggle,
                color: flashEnabled ? AppTheme.primaryColor : Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required Function()? onPressed,
    Color color = Colors.white,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: onPressed == null ? Colors.grey : Colors.black38,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: onPressed == null ? Colors.grey[400] : color),
        onPressed: onPressed,
      ),
    );
  }
  
  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: isProcessing ? null : onCapturePressed,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: isProcessing ? Colors.grey[800] : Colors.black38,
              shape: BoxShape.circle,
              border: Border.all(
                color: isProcessing ? Colors.grey : Colors.white,
                width: 3,
              ),
            ),
            child: Center(
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: isProcessing ? Colors.grey : Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          if (isProcessing)
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                strokeWidth: 3,
              ),
            ),
        ],
      ),
    );
  }
}