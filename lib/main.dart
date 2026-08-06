import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'inference_service.dart';
import 'multi_modal_inference_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Launch the app immediately so Flutter can draw the loading UI
  runApp(const MyApp());
}

Future<String> _getModelPath() async {
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<InferenceService> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initEngine();
  }

  Future<InferenceService> _initEngine() async {
    final modelPath = await _getModelPath();
    final inferenceService = InferenceService();

    // Yield the thread briefly so Flutter can paint the loading spinner UI
    await Future.delayed(const Duration(milliseconds: 100));

    // Initialize the engine natively
    inferenceService.initializeEngine(modelPath);
    return inferenceService;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LiteRT-LM Edge AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: FutureBuilder<InferenceService>(
        future: _initFuture,
        builder: (context, snapshot) {
          // Show Loading Screen while model initializes
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 24),
                    Text(
                      "Initializing LiteRT-LM Engine...",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Loading model weights into GPU memory",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          // Show Error Screen if model fails to load or file is missing
          if (snapshot.hasError) {
            return Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    "Startup Error: ${snapshot.error}\n\nDid you run adb push?",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            );
          }

          // Show Main App once initialization completes
          return MultiModalInferenceScreen(inferenceService: snapshot.data!);
        },
      ),
    );
  }
}
