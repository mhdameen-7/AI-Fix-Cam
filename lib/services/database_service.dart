import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:aifixcam/models/problem_model.dart';

class DatabaseService {
  Map<String, dynamic>? _solutionData;

  // FIX: This method was missing. It loads the JSON data from assets.
  Future<void> loadDatabase() async {
    final String response = await rootBundle.loadString('assets/data/solution_data.json');
    _solutionData = await json.decode(response);
  }

  // FIX: This method was missing. It finds and returns a solution based on the AI's result.
  ProblemSolution getSolution(String problemKey) {
    if (_solutionData == null || !_solutionData!.containsKey(problemKey)) {
      // Return the default solution if the key is not found or the database isn't loaded.
      return ProblemSolution.fromJson(_solutionData?['default'] ?? {});
    }
    return ProblemSolution.fromJson(_solutionData![problemKey]);
  }
}
