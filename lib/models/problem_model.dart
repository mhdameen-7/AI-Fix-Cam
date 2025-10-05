// This class defines a single step in the repair process.
class RepairStep {
  final String title;
  final String description;

  RepairStep({required this.title, required this.description});

  factory RepairStep.fromJson(Map<String, dynamic> json) {
    return RepairStep(
      title: json['title'] as String,
      description: json['description'] as String,
    );
  }
}

// This is the main data model for the entire solution.
class ProblemSolution {
  final String title;
  final List<String> safetyNotes; // New field for safety warnings
  final List<String> tools;
  final List<RepairStep> instructions; // Now uses the RepairStep class
  final String? videoId;

  ProblemSolution({
    required this.title,
    required this.safetyNotes,
    required this.tools,
    required this.instructions,
    this.videoId,
  });

  factory ProblemSolution.fromJson(Map<String, dynamic> json) {
    // Safely parse the lists from the JSON data.
    var safetyFromJson = json['safetyNotes'] as List? ?? [];
    var toolsFromJson = json['tools'] as List? ?? [];
    var instructionsFromJson = json['instructions'] as List? ?? [];

    List<String> safetyList = safetyFromJson.map((i) => i.toString()).toList();
    List<String> toolList = toolsFromJson.map((i) => i.toString()).toList();
    List<RepairStep> instructionList = instructionsFromJson
        .map((i) => RepairStep.fromJson(i as Map<String, dynamic>))
        .toList();

    return ProblemSolution(
      title: json['title'] as String,
      safetyNotes: safetyList,
      tools: toolList,
      instructions: instructionList,
      videoId: json['video_id'] as String?,
    );
  }
}
