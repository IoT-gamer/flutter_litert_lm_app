import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'audio_recorder_service.dart';
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

  double? _selectedDimension = 700; // Default to 280 Token Budget

  final AudioRecorderService _audioService = AudioRecorderService();
  bool _isRecording = false;
  int _timeRemaining = 10;
  Timer? _uiTimer;
  String? _audioPath;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxHeight: _selectedDimension,
      maxWidth: _selectedDimension,
      imageQuality: 85, // Leave this at a static 80-85
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

  void _startAudioRecording() {
    setState(() {
      _isRecording = true;
      _timeRemaining = 10;
      _inferenceResult = "Recording... $_timeRemaining s";
    });

    // Update the UI countdown every second
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeRemaining > 1) {
          _timeRemaining--;
          _inferenceResult = "Recording... $_timeRemaining s";
        } else {
          timer.cancel();
        }
      });
    });

    _audioService.startRecordingWithLimit(
      timeLimitSeconds: 10,
      onRecordingComplete: (path) {
        _uiTimer?.cancel();
        setState(() {
          _isRecording = false;
          _audioPath = path;
          _inferenceResult = path != null
              ? "Audio saved. Ready for inference."
              : "Permission denied or recording failed.";
        });
      },
    );
  }

  Future<void> _runAudioInference() async {
    if (_audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please record audio first.")),
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
      _inferenceResult = "Analyzing audio...";
    });

    await Future.delayed(const Duration(milliseconds: 50));

    try {
      final resultText = await widget.inferenceService.analyzeAudio(
        prompt,
        _audioPath!,
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
    _uiTimer?.cancel();
    _audioService.dispose();
    _promptController.dispose();
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

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Gemma Token Budget: "),
                DropdownButton<double>(
                  value: _selectedDimension,
                  items: const [
                    DropdownMenuItem(value: 350, child: Text("70 (Fast)")),
                    DropdownMenuItem(value: 500, child: Text("140")),
                    DropdownMenuItem(value: 700, child: Text("280 (Balanced)")),
                    DropdownMenuItem(value: 1000, child: Text("560")),
                    DropdownMenuItem(
                      value: 1400,
                      child: Text("1120 (OCR / Detail)"),
                    ),
                  ],
                  onChanged: _isProcessing
                      ? null
                      : (value) {
                          setState(() {
                            _selectedDimension = value;
                          });
                        },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Image selection button
            ElevatedButton.icon(
              onPressed: _isProcessing || _isRecording ? null : _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text("Select from Gallery"),
            ),
            const SizedBox(height: 12),

            // Audio recording button
            ElevatedButton.icon(
              onPressed: _isProcessing || _isRecording
                  ? null
                  : _startAudioRecording,
              icon: Icon(
                _isRecording ? Icons.mic : Icons.mic_none,
                color: _isRecording ? Colors.red : null,
              ),
              label: Text(
                _isRecording
                    ? "Recording ($_timeRemaining s)"
                    : "Record Audio (10s limit)",
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _promptController,
              decoration: InputDecoration(
                labelText: _audioPath != null
                    ? "Ask about this audio..."
                    : _selectedImage != null
                    ? "Ask about this image..."
                    : "Ask about your media...",
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              enabled: !_isProcessing,
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilledButton.icon(
                  onPressed: _isProcessing || _selectedImage == null
                      ? null
                      : _runInference,
                  icon: const Icon(Icons.image),
                  label: const Text("Analyze Image"),
                ),
                FilledButton.icon(
                  onPressed: _isProcessing || _audioPath == null
                      ? null
                      : _runAudioInference,
                  icon: const Icon(Icons.audiotrack),
                  label: const Text("Analyze Audio"),
                ),
              ],
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
