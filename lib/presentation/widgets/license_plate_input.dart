import 'package:flutter/material.dart';

/// Widget nhập biển số xe
class LicensePlateInput extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onRecognize;
  final bool isRecognizing;

  const LicensePlateInput({
    super.key,
    this.initialValue,
    this.onChanged,
    this.onRecognize,
    this.isRecognizing = false,
  });

  @override
  State<LicensePlateInput> createState() => _LicensePlateInputState();
}

class _LicensePlateInputState extends State<LicensePlateInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
                if (widget.onRecognize != null)
                  ElevatedButton.icon(
                    onPressed: widget.isRecognizing ? null : widget.onRecognize,
                    icon: widget.isRecognizing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: Text(widget.isRecognizing ? 'Đang nhận diện...' : 'Nhận diện'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Biển số xe',
                prefixIcon: const Icon(Icons.directions_car),
                hintText: '51A-12345',
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          widget.onChanged?.call('');
                        },
                      )
                    : null,
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) {
                setState(() {});
                widget.onChanged?.call(value.toUpperCase());
              },
            ),
          ],
        ),
      ),
    );
  }
}
