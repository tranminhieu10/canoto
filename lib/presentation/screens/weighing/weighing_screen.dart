import 'package:flutter/material.dart';

/// Màn hình cân xe chính
class WeighingScreen extends StatefulWidget {
  const WeighingScreen({super.key});

  @override
  State<WeighingScreen> createState() => _WeighingScreenState();
}

class _WeighingScreenState extends State<WeighingScreen> {
  double _currentWeight = 0;
  String _licensePlate = '';
  bool _isStable = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cân xe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDevices,
            tooltip: 'Làm mới thiết bị',
          ),
        ],
      ),
      body: Row(
        children: [
          // Left panel - Camera & License plate
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Camera view
                Expanded(
                  flex: 2,
                  child: Card(
                    margin: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              const Icon(Icons.videocam),
                              const SizedBox(width: 8),
                              const Text('Camera giám sát'),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.camera_alt),
                                onPressed: _captureImage,
                                tooltip: 'Chụp ảnh',
                              ),
                            ],
                          ),
                        ),
                        const Expanded(
                          child: Center(
                            child: Icon(
                              Icons.videocam_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // License plate recognition
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.document_scanner),
                              const SizedBox(width: 8),
                              const Text('Nhận diện biển số'),
                              const Spacer(),
                              ElevatedButton.icon(
                                onPressed: _recognizePlate,
                                icon: const Icon(Icons.search),
                                label: const Text('Nhận diện'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Biển số xe',
                              prefixIcon: Icon(Icons.directions_car),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _licensePlate = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Right panel - Weight display & Actions
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Weight display
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'KHỐI LƯỢNG',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${_currentWeight.toStringAsFixed(0)} kg',
                            style: TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: _isStable ? Colors.green : Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isStable ? Icons.check_circle : Icons.sync,
                                color: _isStable ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(_isStable ? 'Ổn định' : 'Đang cân...'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _zeroScale,
                                icon: const Icon(Icons.exposure_zero),
                                label: const Text('Zero'),
                              ),
                              ElevatedButton.icon(
                                onPressed: _tareScale,
                                icon: const Icon(Icons.remove),
                                label: const Text('Tare'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Barrier control
                Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.fence),
                        const SizedBox(width: 8),
                        const Text('Barrier'),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _openBarrier,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('MỞ'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _closeBarrier,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('ĐÓNG'),
                        ),
                      ],
                    ),
                  ),
                ),
                // Actions
                Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saveFirstWeight,
                            icon: const Icon(Icons.save),
                            label: const Text('Lưu lần 1'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saveSecondWeight,
                            icon: const Icon(Icons.check),
                            label: const Text('Lưu lần 2'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Print
                Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.print),
                        const SizedBox(width: 8),
                        const Text('In phiếu'),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _printTicket,
                          icon: const Icon(Icons.print),
                          label: const Text('In'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _refreshDevices() {
    // TODO: Refresh all device connections
  }

  void _captureImage() {
    // TODO: Capture image from camera
  }

  void _recognizePlate() {
    // TODO: Trigger license plate recognition
  }

  void _zeroScale() {
    // TODO: Zero scale
  }

  void _tareScale() {
    // TODO: Tare scale
  }

  void _openBarrier() {
    // TODO: Open barrier
  }

  void _closeBarrier() {
    // TODO: Close barrier
  }

  void _saveFirstWeight() {
    // TODO: Save first weight
  }

  void _saveSecondWeight() {
    // TODO: Save second weight and complete ticket
  }

  void _printTicket() {
    // TODO: Print weighing ticket
  }
}
