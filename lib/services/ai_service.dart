import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class AiService {
  late Interpreter _interpreter;
  late List<String> _labels;
  bool _isModelLoaded = false;

  Future<void> loadModel() async {
    if (_isModelLoaded) return;
    try {
      final interpreterOptions = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset(
        'assets/models/model.tflite',
        options: interpreterOptions,
      );

      final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsData.split('\n');

      _interpreter.allocateTensors();
      _isModelLoaded = true;
      print("Model loaded successfully");
    } catch (e) {
      print("Failed to load model: $e");
    }
  }

  Future<String> classifyImage(String imagePath) async {
    if (!_isModelLoaded) {
      return "Model not loaded";
    }

    // 1. Decode image directly from the file path
    final imageData = File(imagePath).readAsBytesSync();
    img.Image? image = img.decodeImage(imageData);

    if (image == null) return "Could not decode image";
    
    // 2. Resize it to the model's input size
    img.Image resizedImage = img.copyResize(image, width: 224, height: 224);

    // 3. Convert to a byte buffer
    var buffer = Uint8List(1 * 224 * 224 * 3);
    var bufferIndex = 0;
    for (var y = 0; y < 224; y++) {
      for (var x = 0; x < 224; x++) {
        var pixel = resizedImage.getPixel(x, y);
        
        // FIX: The image library was updated. Use .r, .g, .b instead of getRed(), etc.
        buffer[bufferIndex++] = pixel.r.toInt();
        buffer[bufferIndex++] = pixel.g.toInt();
        buffer[bufferIndex++] = pixel.b.toInt();
      }
    }

    // 4. Reshape buffer to the model's input shape and run inference
    var input = buffer.reshape([1, 224, 224, 3]);
    var output = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);

    _interpreter.run(input, output);

    // 5. Find the index with the highest probability
    double highestProb = 0;
    int bestIndex = 0;
    for (int i = 0; i < output[0].length; i++) {
        if (output[0][i] > highestProb) {
            highestProb = output[0][i];
            bestIndex = i;
        }
    }
    
    return _labels[bestIndex];
  }

  void dispose() {
    _interpreter.close();
  }
}
