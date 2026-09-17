import 'dart:io';
import 'package:jnigen/jnigen.dart';

Future<void> main(List<String> args) async {
  final packageRoot = Platform.script.resolve('../');

  final generator = JniGenerator(
    input: Input(
      // The specific class you want to generate bindings for
      classes: ['com.example.flutter_litert_lm_app.LitertBridge'],
      // Explicitly map the paths where Flutter compiles your Kotlin code
      classPath: [
        packageRoot.resolve(
          'build/app/intermediates/built_in_kotlinc/debug/compileDebugKotlin/classes/',
        ),
        packageRoot.resolve(
          'build/app/intermediates/built_in_kotlinc/release/compileReleaseKotlin/classes/',
        ),
      ],
      // Configuration to search for Android SDK libraries.
      androidSdk: AndroidSdk(addGradleDeps: true),
    ),
    output: Output(
      dart: DartOutput(
        // Output path for generated bindings
        path: packageRoot.resolve('lib/src/generated/litertlm_bindings.dart'),
        // Write bindings into a single file (instead of one file per class).
        structure: OutputStructure.singleFile,
      ),
    ),
  );
  await generator.generate();
}
