import 'dart:convert';
import 'dart:io';

import 'package:aifixcam1/models/history_model.dart';
import 'package:aifixcam1/models/problem_model.dart';
import 'package:aifixcam1/screens/result_screen.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
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
        _showErrorDialog("No cameras found.");
        return;
      }
      final firstCamera = cameras.first;
      _controller = CameraController(firstCamera, ResolutionPreset.high, enableAudio: false);
      _initializeControllerFuture = _controller!.initialize();

      await Future.wait([_loadModel(), _loadLabels(), _loadSolutionData()]);
      if (mounted) setState(() {});
    } catch (e) {
      _showErrorDialog("Failed to initialize camera: ${e.toString()}");
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

  Future<String> _runInference(String imagePath) async {
    if (_interpreter == null || _labels.isEmpty) throw Exception("Model or labels not loaded.");
    final imageData = await File(imagePath).readAsBytes();
    final image = img.decodeImage(imageData);
    if (image == null) throw Exception("Could not decode image.");
    final resizedImage = img.copyResize(image, width: 224, height: 224);
    var inputBuffer = resizedImage.getBytes(order: img.ChannelOrder.rgb);
    final input = inputBuffer.reshape([1, 224, 224, 3]);
    final output = List.filled(1 * _labels.length, 0).reshape([1, _labels.length]);
    _interpreter!.run(input, output);
    final outputList = (output[0] as List<num>);
    int maxIndex = 0;
    for (int i = 1; i < outputList.length; i++) {
      if (outputList[i] > outputList[maxIndex]) {
        maxIndex = i;
      }
    }
    return _labels[maxIndex];
  }
    Future<void> _saveHistoryItem(String title, String tempImagePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final permanentImagePath = '${directory.path}/$fileName';
    await File(tempImagePath).copy(permanentImagePath);

    final newItem = HistoryItem(
      title: title,
      imagePath: permanentImagePath,
      date: "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
    );
    
    final prefs = await SharedPreferences.getInstance();
    final historyList = prefs.getStringList('diagnosis_history') ?? [];
    historyList.add(json.encode(newItem.toJson()));
    await prefs.setStringList('diagnosis_history', historyList);
  }

  Future<void> _onCapturePressed() async {
    if (_isProcessing || _controller == null || !_controller!.value.isInitialized) return;
    setState(() { _isProcessing = true; });

    try {
      final image = await _controller!.takePicture();
      final problemKey = await _runInference(image.path);
      final solutionJson = _solutionData[problemKey.trim()] ?? _solutionData['default'];
      if (solutionJson == null) throw Exception("Could not find a solution.");
      final solution = ProblemSolution.fromJson(solutionJson);
      
      await _saveHistoryItem(solution.title, image.path);

      if (mounted) {
        // We use pop so it goes back to the home screen after results
        Navigator.of(context).pop(); 
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => ResultScreen(solution: solution)),
        );
      }
    } catch (e) {
      _showErrorDialog("Error processing image: ${e.toString()}");
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
  void dispose() {
    _controller?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // THIS WIDGET NO LONGER RETURNS A SCAFFOLD OR APPBAR.
    // It returns a Stack so we can place the button over the camera preview.
    return Stack(
      alignment: Alignment.center,
      children: [
        FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && _controller != null) {
              return CameraPreview(_controller!);
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
        // Position the capture button at the bottom.
        Positioned(
          bottom: 40,
          child: FloatingActionButton.large(
            onPressed: _onCapturePressed,
            backgroundColor: _isProcessing ? Colors.grey : Colors.lightBlue,
            child: _isProcessing
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.camera_alt),
          ),
        ),
      ],
    );
  }
}
