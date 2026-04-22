import 'dart:io';
import 'package:jnigen/jnigen.dart';

void main(List<String> args) {
  final packageRoot = Platform.script.resolve('../');

  generateJniBindings(
    Config(
      outputConfig: OutputConfig(
        dartConfig: DartCodeOutputConfig(
          path: packageRoot.resolve('lib/src/generated/litertlm_bindings.dart'),
          structure: OutputStructure.singleFile,
        ),
      ),
      // Automatically locates your project's compiled classes and dependencies
      androidSdkConfig: AndroidSdkConfig(addGradleDeps: true),

      classes: ['com.example.flutter_litert_lm_app.LitertBridge'],
    ),
  );
}
