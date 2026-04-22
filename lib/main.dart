import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'inference_service.dart';
import 'multi_modal_inference_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Get the path to the model you pushed via ADB
    final modelPath = await _getModelPath();

    // Initialize the Service
    final inferenceService = InferenceService();
    inferenceService.initializeEngine(modelPath);

    runApp(MyApp(inferenceService: inferenceService));
  } catch (e) {
    // If the model is missing, show a fallback UI instead of a white screen
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text("Startup Error: $e\n\nDid you run adb push?"),
          ),
        ),
      ),
    );
  }
}

Future<String> _getModelPath() async {
  // This points to /storage/emulated/0/Android/data/com.example.../files/
  final directory = await getExternalStorageDirectory();

  if (directory == null) {
    throw Exception("Could not access external storage.");
  }

  final modelFile = File('${directory.path}/model.litertlm');

  if (!await modelFile.exists()) {
    throw Exception("Model file not found at ${modelFile.path}.");
  }

  return modelFile.path;
}

class MyApp extends StatelessWidget {
  final InferenceService inferenceService;

  const MyApp({super.key, required this.inferenceService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LiteRT-LM Edge AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: MultiModalInferenceScreen(inferenceService: inferenceService),
    );
  }
}
