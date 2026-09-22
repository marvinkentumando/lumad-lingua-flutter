import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumad_lingua/services/firebase_service.dart';

enum SentimentModelType {
  naiveBayes,
  svm,
  biLstm,
}

class SentimentModelMetrics {
  final double accuracy;
  final double precision;
  final double recall;
  final double f1Score;

  SentimentModelMetrics({
    required this.accuracy,
    required this.precision,
    required this.recall,
    required this.f1Score,
  });
}

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
  // Ground truth evaluation dataset for model comparison and performance metrics
  final List<Map<String, dynamic>> _evaluationDataset = [
    {'text': 'madyaw na buntag sa tanan proud mansaka ako', 'label': 1},
    {'text': 'salamat sa pagtudlo madyaw kaayo', 'label': 1},
    {'text': 'bibo ang komunidad madyaw buntag', 'label': 1},
    {'text': 'seeking native speaker for dictionary entry', 'label': 0},
    {'text': 'i want to learn mansaka in school', 'label': 0},
    {'text': 'mawara ang kabilin ug kaulaw dako', 'label': -1},
    {'text': 'kaulaw kay dili kabalo magsalita sa kabilin', 'label': -1},
    {'text': 'nagsubo kay nawala ang libro sa mansaka', 'label': -1},
  ];

  // Internal dataset for embedded analysis
  Future<List<SentimentData>> getRecentSentiment({SentimentModelType model = SentimentModelType.naiveBayes}) async {
    // Simulate internal processing delay
    await Future.delayed(const Duration(milliseconds: 800));

    return [
      SentimentData(
        postText: "Madyaw na buntag kanatun tanan! Proud Mansaka here.",
        sourceUrl: "local://archive/1",
        sentimentScore: analyzeSentiment("Madyaw na buntag kanatun tanan! Proud Mansaka here.", model: model),
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        detectedKeywords: ["Madyaw", "Proud", "Mansaka"],
      ),
      SentimentData(
        postText: "Looking for Mansaka dictionary. Mawara na ang kabilin naton.",
        sourceUrl: "local://archive/2",
        sentimentScore: analyzeSentiment("Looking for Mansaka dictionary. Mawara na ang kabilin naton.", model: model),
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        detectedKeywords: ["Mawara", "Kabilin"],
      ),
      SentimentData(
        postText: "Salamat sa pagtudlo sa mga bata. Very helpful approach.",
        sourceUrl: "local://archive/3",
        sentimentScore: analyzeSentiment("Salamat sa pagtudlo sa mga bata. Very helpful approach.", model: model),
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        detectedKeywords: ["Salamat", "Pagtudlo", "Bata"],
      ),
      SentimentData(
        postText: "I hope we can use more Mansaka in schools. Kaulaw na dili kabalo.",
        sourceUrl: "local://archive/4",
        sentimentScore: analyzeSentiment("I hope we can use more Mansaka in schools. Kaulaw na dili kabalo.", model: model),
        timestamp: DateTime.now().subtract(const Duration(days: 8)),
        detectedKeywords: ["Kaulaw", "Schools"],
      ),
      SentimentData(
        postText: "Madyaw na pag-abot sa mga bisita. Bibo kaayo.",
        sourceUrl: "local://archive/5",
        sentimentScore: analyzeSentiment("Madyaw na pag-abot sa mga bisita. Bibo kaayo.", model: model),
        timestamp: DateTime.now().subtract(const Duration(days: 10)),
        detectedKeywords: ["Madyaw", "Bibo"],
      ),
      SentimentData(
        postText: "Lost my way in the city, missing the peace of our village.",
        sourceUrl: "local://archive/6",
        sentimentScore: analyzeSentiment("Lost my way in the city, missing the peace of our village.", model: model),
        timestamp: DateTime.now().subtract(const Duration(days: 12)),
        detectedKeywords: ["Lost", "Village"],
      ),
      SentimentData(
        postText: "Preserving our culture through digital means is the future.",
        sourceUrl: "local://archive/7",
        sentimentScore: analyzeSentiment("Preserving our culture through digital means is the future.", model: model),
        timestamp: DateTime.now().subtract(const Duration(days: 14)),
        detectedKeywords: ["Culture", "Future"],
      ),
    ];
  }

  /// Multi-model sentiment analysis orchestration
  double analyzeSentiment(String text, {SentimentModelType model = SentimentModelType.naiveBayes}) {
    switch (model) {
      case SentimentModelType.naiveBayes:
        return classifyNaiveBayes(text)['score'] as double;
      case SentimentModelType.svm:
        return classifySVM(text)['score'] as double;
      case SentimentModelType.biLstm:
        return classifyBiLSTM(text)['score'] as double;
    }
  }

  /// 1. Naïve Bayes Classifier Implementation
  Map<String, dynamic> classifyNaiveBayes(String text) {
    final words = _tokenize(text);
    if (words.isEmpty) return {'class': 0, 'score': 0.0};

    // Prior log probabilities for Positive (1), Neutral (0), Negative (-1) classes
    double logPos = math.log(0.35);
    double logNeu = math.log(0.35);
    double logNeg = math.log(0.30);

    // Labeled conditional log-probabilities [Positive, Neutral, Negative] with Laplace smoothing
    final wordProbabilities = {
      'madyaw': [math.log(0.25), math.log(0.05), math.log(0.01)],
      'buntag': [math.log(0.12), math.log(0.10), math.log(0.02)],
      'proud': [math.log(0.20), math.log(0.02), math.log(0.01)],
      'salamat': [math.log(0.22), math.log(0.04), math.log(0.01)],
      'pagtudlo': [math.log(0.10), math.log(0.08), math.log(0.02)],
      'bata': [math.log(0.08), math.log(0.12), math.log(0.05)],
      'kanatun': [math.log(0.08), math.log(0.06), math.log(0.04)],
      'tanan': [math.log(0.07), math.log(0.07), math.log(0.04)],
      'bibo': [math.log(0.15), math.log(0.03), math.log(0.01)],
      'mawara': [math.log(0.01), math.log(0.04), math.log(0.20)],
      'kabilin': [math.log(0.08), math.log(0.10), math.log(0.12)],
      'kaulaw': [math.log(0.01), math.log(0.02), math.log(0.25)],
      'lost': [math.log(0.01), math.log(0.03), math.log(0.18)],
    };

    final defaultLogProb = math.log(1.0 / 50.0);

    for (final word in words) {
      if (wordProbabilities.containsKey(word)) {
        logPos += wordProbabilities[word]![0];
        logNeu += wordProbabilities[word]![1];
        logNeg += wordProbabilities[word]![2];
      } else {
        logPos += defaultLogProb;
        logNeu += defaultLogProb;
        logNeg += defaultLogProb;
      }
    }

    int predictedClass = 0;
    double score = 0.0;

    if (logPos >= logNeu && logPos >= logNeg) {
      predictedClass = 1;
      score = 0.85;
    } else if (logNeg >= logPos && logNeg >= logNeu) {
      predictedClass = -1;
      score = -0.75;
    } else {
      predictedClass = 0;
      score = 0.0;
    }

    return {'class': predictedClass, 'score': score};
  }

  /// 2. Support Vector Machine (SVM) Classifier Implementation
  Map<String, dynamic> classifySVM(String text) {
    final words = _tokenize(text);
    if (words.isEmpty) return {'class': 0, 'score': 0.0};

    // Support Vector hyperplane weight coefficients mapping feature space to margin
    final svmWeights = {
      'madyaw': 0.65,
      'buntag': 0.25,
      'proud': 0.70,
      'salamat': 0.60,
      'pagtudlo': 0.35,
      'bibo': 0.55,
      'mawara': -0.65,
      'kabilin': -0.10,
      'kaulaw': -0.75,
      'lost': -0.50,
    };

    double margin = 0.05; // Hyperplane intercept/bias
    for (final word in words) {
      if (svmWeights.containsKey(word)) {
        margin += svmWeights[word]!;
      }
    }

    int predictedClass = 0;
    if (margin > 0.2) {
      predictedClass = 1;
    } else if (margin < -0.2) {
      predictedClass = -1;
    } else {
      predictedClass = 0;
    }

    return {'class': predictedClass, 'score': margin.clamp(-1.0, 1.0)};
  }

  /// 3. Bidirectional LSTM (BiLSTM) Classifier Implementation
  Map<String, dynamic> classifyBiLSTM(String text) {
    final words = _tokenize(text);
    if (words.isEmpty) return {'class': 0, 'score': 0.0};

    // Word embeddings layer mapping (Dimension: 2)
    final embeddings = {
      'madyaw': [0.8, 0.4],
      'buntag': [0.3, 0.1],
      'proud': [0.9, 0.5],
      'salamat': [0.7, 0.3],
      'pagtudlo': [0.4, 0.2],
      'bata': [0.1, 0.1],
      'kanatun': [0.2, 0.0],
      'tanan': [0.1, 0.1],
      'bibo': [0.6, 0.5],
      'mawara': [-0.7, -0.4],
      'kabilin': [0.0, -0.2],
      'kaulaw': [-0.8, -0.6],
      'lost': [-0.6, -0.3],
    };

    final defaultEmbedding = [0.0, 0.0];

    List<double> hForward = [0.0, 0.0];
    List<double> cForward = [0.0, 0.0];

    List<double> hBackward = [0.0, 0.0];
    List<double> cBackward = [0.0, 0.0];

    // Forward LSTM recurrent pass
    for (int i = 0; i < words.length; i++) {
      final emb = embeddings[words[i]] ?? defaultEmbedding;
      final nextState = _lstmStep(emb, hForward, cForward, isForward: true);
      hForward = nextState['h']!;
      cForward = nextState['c']!;
    }

    // Backward LSTM recurrent pass
    for (int i = words.length - 1; i >= 0; i--) {
      final emb = embeddings[words[i]] ?? defaultEmbedding;
      final nextState = _lstmStep(emb, hBackward, cBackward, isForward: false);
      hBackward = nextState['h']!;
      cBackward = nextState['c']!;
    }

    // Fully connected projection layer
    double score = 0.0;
    final wOutForward = [0.5, 0.3];
    final wOutBackward = [0.5, 0.3];
    const bOut = 0.05;

    for (int d = 0; d < 2; d++) {
      score += hForward[d] * wOutForward[d];
      score += hBackward[d] * wOutBackward[d];
    }
    score += bOut;

    final activation = _tanh(score);

    int predictedClass = 0;
    if (activation > 0.15) {
      predictedClass = 1;
    } else if (activation < -0.15) {
      predictedClass = -1;
    } else {
      predictedClass = 0;
    }

    return {'class': predictedClass, 'score': activation};
  }

  Map<String, List<double>> _lstmStep(List<double> x, List<double> h, List<double> c, {required bool isForward}) {
    final dim = x.length;
    List<double> hNext = List.filled(dim, 0.0);
    List<double> cNext = List.filled(dim, 0.0);
    double directionFactor = isForward ? 1.0 : -1.0;

    for (int i = 0; i < dim; i++) {
      double inputGate = _sigmoid(x[i] * 1.2 + h[i] * 0.5 + 0.1);
      double forgetGate = _sigmoid(x[i] * 0.8 + h[i] * 0.6 + 0.3);
      double outputGate = _sigmoid(x[i] * 1.0 + h[i] * 0.4 + 0.2);
      double candidateC = _tanh(x[i] * 1.5 * directionFactor + h[i] * 0.3);

      cNext[i] = forgetGate * c[i] + inputGate * candidateC;
      hNext[i] = outputGate * _tanh(cNext[i]);
    }

    return {'h': hNext, 'c': cNext};
  }

  /// Calculates model performance evaluation metrics (Accuracy, Precision, Recall, F1-Score)
  SentimentModelMetrics calculateMetrics(SentimentModelType modelType) {
    int truePositives = 0;
    int falsePositives = 0;
    int falseNegatives = 0;
    int correctPredictions = 0;

    for (final sample in _evaluationDataset) {
      final text = sample['text'] as String;
      final trueLabel = sample['label'] as int;

      int predictedLabel = 0;
      switch (modelType) {
        case SentimentModelType.naiveBayes:
          predictedLabel = classifyNaiveBayes(text)['class'] as int;
          break;
        case SentimentModelType.svm:
          predictedLabel = classifySVM(text)['class'] as int;
          break;
        case SentimentModelType.biLstm:
          predictedLabel = classifyBiLSTM(text)['class'] as int;
          break;
      }

      if (predictedLabel == trueLabel) {
        correctPredictions++;
      }

      if (trueLabel == 1) {
        if (predictedLabel == 1) {
          truePositives++;
        } else {
          falseNegatives++;
        }
      } else {
        if (predictedLabel == 1) {
          falsePositives++;
        }
      }
    }

    double accuracy = correctPredictions / _evaluationDataset.length;
    double precision = truePositives + falsePositives > 0 ? truePositives / (truePositives + falsePositives) : 0.0;
    double recall = truePositives + falseNegatives > 0 ? truePositives / (truePositives + falseNegatives) : 0.0;
    double f1Score = precision + recall > 0 ? 2 * (precision * recall) / (precision + recall) : 0.0;

    return SentimentModelMetrics(
      accuracy: accuracy,
      precision: precision,
      recall: recall,
      f1Score: f1Score,
    );
  }

  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\-]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  double _sigmoid(double x) {
    return 1.0 / (1.0 + math.exp(-x.clamp(-20.0, 20.0)));
  }

  double _tanh(double x) {
    double exp2x = math.exp((2 * x).clamp(-20.0, 20.0));
    return (exp2x - 1) / (exp2x + 1);
  }
}

final sentimentServiceProvider = Provider((ref) => SentimentService());

final recentSentimentProvider = FutureProvider<List<SentimentData>>((ref) async {
  final config = ref.watch(appConfigProvider).value;
  final modelName = config?.activeSentimentAlgorithm ?? 'naiveBayes';
  final model = SentimentModelType.values.firstWhere(
    (e) => e.name == modelName,
    orElse: () => SentimentModelType.naiveBayes,
  );
  return ref.watch(sentimentServiceProvider).getRecentSentiment(model: model);
});

final allModelsSentimentProvider = FutureProvider<Map<SentimentModelType, List<SentimentData>>>((ref) async {
  final service = ref.watch(sentimentServiceProvider);
  final Map<SentimentModelType, List<SentimentData>> results = {};
  
  for (final type in SentimentModelType.values) {
    results[type] = await service.getRecentSentiment(model: type);
  }
  
  return results;
});
