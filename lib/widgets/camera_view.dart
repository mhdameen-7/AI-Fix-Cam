import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aifixcam/models/problem_model.dart';
import 'package:aifixcam/screens/result_screen.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  Interpreter? _interpreter;
  List<String> _labels = [];
  Map<String, dynamic> _solutionData = {};
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showErrorDialog("No cameras found on this device.");
        return;
      }
      final firstCamera = cameras.first;
      _controller = CameraController(firstCamera, ResolutionPreset.high, enableAudio: false);
      _initializeControllerFuture = _controller!.initialize();
      
      await Future.wait([_loadModel(), _loadLabels(), _loadSolutionData()]);
      if (mounted) setState(() {});
    } catch (e) {
      _showErrorDialog("Failed to initialize camera or AI model: ${e.toString()}");
    }
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
    } catch (e) {
      print('FATAL ERROR: Failed to load TFLite model: $e');
    }
  }

  Future<void> _loadLabels() async {
    try {
      final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();
    } catch (e) {
      print('FATAL ERROR: Failed to load labels: $e');
    }
  }

  Future<void> _loadSolutionData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/solution_data.json');
      _solutionData = json.decode(jsonString);
    } catch (e) {
      print('FATAL ERROR: Failed to load solution data: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  // THIS FUNCTION CONTAINS THE PERMANENT FIX
  Future<String> _runInference(String imagePath) async {
    if (_interpreter == null || _labels.isEmpty) throw Exception("Model or labels not loaded.");

    // 1. Read the image file as bytes
    final imageData = await File(imagePath).readAsBytes();
    final image = img.decodeImage(imageData);
    if (image == null) throw Exception("Could not decode image.");

    // 2. Resize the image to the model's expected input size (224x224)
    final resizedImage = img.copyResize(image, width: 224, height: 224);

    // 3. Create a byte buffer. This is a list of whole numbers (integers).
    var inputBuffer = Uint8List(1 * 224 * 224 * 3);
    int bufferIndex = 0;
    for (var y = 0; y < resizedImage.height; y++) {
      for (var x = 0; x < resizedImage.width; x++) {
        var pixel = resizedImage.getPixel(x, y);
        // THE FIX: We add the raw integer color values (0-255) to the buffer.
        // We DO NOT divide by 255.0 here. This ensures the data type is uint8.
        inputBuffer[bufferIndex++] = pixel.r.toInt();
        inputBuffer[bufferIndex++] = pixel.g.toInt();
        inputBuffer[bufferIndex++] = pixel.b.toInt();
      }
    }
    
    // 4. Reshape the buffer to the model's input shape and prepare the output buffer
    final input = inputBuffer.reshape([1, 224, 224, 3]);
    final output = List.filled(1 * _labels.length, 0).reshape([1, _labels.length]);

    // 5. Run the inference
    _interpreter!.run(input, output);

    // 6. Find the result with the highest score
    final outputList = output[0] as List<int>;
    int maxIndex = 0;
    for (int i = 1; i < outputList.length; i++) {
      if (outputList[i] > outputList[maxIndex]) {
        maxIndex = i;
      }
    }
    return _labels[maxIndex];
  }

  Future<void> _onCapturePressed() async {
    if (_isProcessing || _controller == null || !_controller!.value.isInitialized) return;

    setState(() { _isProcessing = true; });

    try {
      final image = await _controller!.takePicture();
      final problemKey = await _runInference(image.path);

      final solutionJson = _solutionData[problemKey.trim()] ?? _solutionData['default'];
      if (solutionJson == null) throw Exception("Could not find a solution for key: $problemKey");
      
      final solution = ProblemSolution.fromJson(solutionJson);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => ResultScreen(solution: solution)),
        );
      }
    } catch (e) {
      _showErrorDialog("Failed to process image: ${e.toString()}");
    } finally {
      if (mounted) setState(() { _isProcessing = false; });
    }
  }

  void _showErrorDialog(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture Problem')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && _controller != null) {
            return Center(child: CameraPreview(_controller!));
          } else if (snapshot.hasError) {
            return Center(child: Text("Error initializing camera: ${snapshot.error}"));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: _onCapturePressed,
        child: _isProcessing 
            ? const CircularProgressIndicator(color: Colors.white) 
            : const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
