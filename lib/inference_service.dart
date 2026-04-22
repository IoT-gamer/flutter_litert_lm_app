import 'package:jni/jni.dart';
import 'package:jni_flutter/jni_flutter.dart';
import 'src/generated/litertlm_bindings.dart';

class InferenceService {
  late LitertBridge _bridge;

  void initializeEngine(String modelPath) {
    // Grab the global Android Application Context provided by package:jni_flutter
    final androidContext = androidApplicationContext;

    // Convert the model path to a JString
    final jModelPath = modelPath.toJString();

    try {
      // Pass BOTH arguments to the bridge
      _bridge = LitertBridge(androidContext, jModelPath);
    } finally {
      // Clean up the string reference (no need to release the cached context)
      jModelPath.release();
    }
  }

  // Call this when the user clicks "Run Inference"
  Future<String> analyzeImage(String prompt, String imagePath) async {
    final jPrompt = prompt.toJString();
    final jPath = imagePath.toJString();

    try {
      // LiteRT will handle reading the file path natively in C++/Java.
      final result = _bridge.runVisionInference(jPrompt, jPath);
      return result.toDartString();
    } finally {
      // Always prevent memory leaks across the JNI bridge
      jPrompt.release();
      jPath.release();
    }
  }

  void dispose() {
    _bridge.close();
  }
}
