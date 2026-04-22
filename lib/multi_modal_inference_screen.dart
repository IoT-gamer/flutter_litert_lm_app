import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'inference_service.dart';

class MultiModalInferenceScreen extends StatefulWidget {
  final InferenceService inferenceService;

  const MultiModalInferenceScreen({super.key, required this.inferenceService});

  @override
  State<MultiModalInferenceScreen> createState() =>
      _MultiModalInferenceScreenState();
}

class _MultiModalInferenceScreenState extends State<MultiModalInferenceScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _promptController = TextEditingController();

  File? _selectedImage;
  String _inferenceResult = "Awaiting input...";
  bool _isProcessing = false;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _inferenceResult = "Image loaded. Enter a prompt.";
      });
    }
  }

  Future<void> _runInference() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image first.")),
      );
      return;
    }

    final prompt = _promptController.text;
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter a prompt.")));
      return;
    }

    setState(() {
      _isProcessing = true;
      _inferenceResult = "Processing...";
    });

    //  Yield the thread so Flutter can gray out the UI before we start processing.
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      // Grab the path of the image from the picker
      final imagePath = _selectedImage!.path;

      // Pass the text and the path directly to the clean service layer
      final resultText = await widget.inferenceService.analyzeImage(
        prompt,
        imagePath,
      );

      setState(() {
        _inferenceResult = resultText;
      });
    } catch (e) {
      setState(() {
        _inferenceResult = "Error: $e";
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    // It's usually better to let the parent (main) manage the service lifecycle,
    // but if this screen is the only place it's used, you can dispose it here.
    widget.inferenceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LiteRT-LM Inference')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[400]!),
              ),
              clipBehavior: Clip.hardEdge,
              child: _selectedImage != null
                  ? Image.file(_selectedImage!, fit: BoxFit.cover)
                  : const Center(
                      child: Icon(Icons.image, size: 50, color: Colors.grey),
                    ),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text("Select from Gallery"),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: "Ask about this image...",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              enabled: !_isProcessing,
            ),
            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: _isProcessing ? null : _runInference,
              icon: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_isProcessing ? "Analyzing..." : "Run Inference"),
            ),
            const SizedBox(height: 24),

            const Text(
              "Result:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _inferenceResult,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
