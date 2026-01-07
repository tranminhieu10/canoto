import 'package:flutter/material.dart';
import 'dart:typed_data';

/// Widget hiển thị camera
class CameraView extends StatelessWidget {
  final Uint8List? currentFrame;
  final bool isConnected;
  final VoidCallback? onCapture;
  final VoidCallback? onRefresh;
  final String title;

  const CameraView({
    super.key,
    this.currentFrame,
    this.isConnected = false,
    this.onCapture,
    this.onRefresh,
    this.title = 'Camera',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Icon(
                  Icons.videocam,
                  color: isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(title),
                const Spacer(),
                if (onCapture != null)
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: onCapture,
                    tooltip: 'Chụp ảnh',
                  ),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefresh,
                    tooltip: 'Làm mới',
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Camera view
          Expanded(
            child: currentFrame != null
                ? Image.memory(
                    currentFrame!,
                    fit: BoxFit.contain,
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isConnected ? Icons.videocam : Icons.videocam_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isConnected ? 'Đang tải...' : 'Chưa kết nối',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
