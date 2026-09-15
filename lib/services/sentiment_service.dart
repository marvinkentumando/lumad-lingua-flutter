import 'package:flutter_riverpod/flutter_riverpod.dart';

class SentimentData {
  final String postText;
  final String sourceUrl;
  final double sentimentScore;
  final DateTime timestamp;
  final List<String> detectedKeywords;

  SentimentData({
    required this.postText,
    required this.sourceUrl,
    required this.sentimentScore,
    required this.timestamp,
    required this.detectedKeywords,
  });
}

class SentimentService {
  // Internal dataset for embedded analysis
  Future<List<SentimentData>> getRecentSentiment() async {
    // Simulate internal processing delay
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      SentimentData(
        postText: "Madyaw na buntag kanatun tanan! Proud Mansaka here.",
        sourceUrl: "local://archive/1",
        sentimentScore: 0.85,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        detectedKeywords: ["Madyaw", "Proud", "Mansaka"],
      ),
      SentimentData(
        postText: "Looking for Mansaka dictionary. Mawara na ang kabilin naton.",
        sourceUrl: "local://archive/2",
        sentimentScore: -0.35,
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        detectedKeywords: ["Mawara", "Kabilin"],
      ),
      SentimentData(
        postText: "Salamat sa pagtudlo sa mga bata. Very helpful approach.",
        sourceUrl: "local://archive/3",
        sentimentScore: 0.9,
        timestamp: DateTime.now().subtract(const Duration(days: 12)),
        detectedKeywords: ["Salamat", "Pagtudlo", "Bata"],
      ),
      SentimentData(
        postText: "I hope we can use more Mansaka in schools. Kaulaw na dili kabalo.",
        sourceUrl: "local://archive/4",
        sentimentScore: 0.1,
        timestamp: DateTime.now().subtract(const Duration(days: 15)),
        detectedKeywords: ["Kaulaw", "Schools"],
      ),
    ];
  }

  double analyzeSentiment(String text) {
    // Basic keyword-based analysis placeholder
    final positiveWords = ['madyaw', 'proud', 'salamat', 'buntag'];
    final negativeWords = ['mawara', 'kaulaw', 'lost'];
    
    double score = 0.0;
    final words = text.toLowerCase().split(' ');
    
    for (var word in words) {
      if (positiveWords.contains(word)) score += 0.2;
      if (negativeWords.contains(word)) score -= 0.2;
    }
    
    return score.clamp(-1.0, 1.0);
  }
}

final sentimentServiceProvider = Provider((ref) => SentimentService());

final recentSentimentProvider = FutureProvider<List<SentimentData>>((ref) async {
  return ref.watch(sentimentServiceProvider).getRecentSentiment();
});
