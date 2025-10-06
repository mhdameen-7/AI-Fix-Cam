import 'package:flutter/material.dart';
import 'package:aifixcam1/models/problem_model.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ProblemCard extends StatelessWidget {
  final ProblemSolution solution;

  const ProblemCard({super.key, required this.solution});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('🧰 Required Tools'),
            const SizedBox(height: 8),
            ...solution.tools.map((tool) => Text('  • $tool')).toList(),
            const Divider(height: 30),

            _buildSectionTitle('📋 Step-by-Step Instructions'),
            const SizedBox(height: 8),
            ...solution.instructions.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text('${entry.key + 1}. ${entry.value}'),
              );
            }).toList(),
            
            if (solution.videoId != null) ...[
              const Divider(height: 30),
              _buildSectionTitle('🎥 Video Tutorial'),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: YoutubePlayer(
                  controller: YoutubePlayerController(
                    initialVideoId: solution.videoId!,
                    flags: const YoutubePlayerFlags(autoPlay: false),
                  ),
                  showVideoProgressIndicator: true,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}
