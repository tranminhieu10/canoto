import 'package:flutter/material.dart';
import 'package:canoto/data/models/enums/device_enums.dart';

/// Widget hiển thị trạng thái thiết bị
class DeviceStatusCard extends StatelessWidget {
  final String name;
  final DeviceType type;
  final DeviceStatus status;
  final VoidCallback? onTap;
  final VoidCallback? onRefresh;

  const DeviceStatusCard({
    super.key,
    required this.name,
    required this.type,
    required this.status,
    this.onTap,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getIcon(), size: 32, color: _getStatusColor()),
                  const Spacer(),
                  if (onRefresh != null)
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: onRefresh,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    status.displayName,
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case DeviceType.weighingIndicator:
        return Icons.scale;
      case DeviceType.camera:
        return Icons.videocam;
      case DeviceType.barrier:
        return Icons.fence;
      case DeviceType.licensePlateReader:
        return Icons.document_scanner;
      case DeviceType.printer:
        return Icons.print;
      case DeviceType.sensor:
        return Icons.sensors;
    }
  }

  Color _getStatusColor() {
    switch (status) {
      case DeviceStatus.connected:
        return Colors.green;
      case DeviceStatus.disconnected:
        return Colors.red;
      case DeviceStatus.connecting:
        return Colors.orange;
      case DeviceStatus.error:
        return Colors.red;
    }
  }
}
