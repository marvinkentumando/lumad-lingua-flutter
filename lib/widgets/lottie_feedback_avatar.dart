import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieFeedbackAvatar extends StatelessWidget {
  final bool isHappy;
  final bool isSad;
  final bool isThinking;
  final bool isCelebrating;

  const LottieFeedbackAvatar({
    super.key,
    this.isHappy = false,
    this.isSad = false,
    this.isThinking = false,
    this.isCelebrating = false,
  });

  @override
  Widget build(BuildContext context) {
    String lottieUrl;

    if (isCelebrating) {
      lottieUrl =
          'https://lottie.host/791c8907-5503-4674-8740-109437298642/hZ4y9Y8j7T.json'; // Party/Celebration
    } else if (isHappy) {
      lottieUrl =
          'https://lottie.host/80131f4a-8740-4965-9856-78810298a83a/lUun9v445q.json'; // Happy success
    } else if (isSad) {
      lottieUrl =
          'https://lottie.host/83017a00-1c7b-406c-820d-730c4f82873c/YtHj4ZqHqS.json'; // Sad/Think
    } else {
      lottieUrl =
          'https://lottie.host/80164c01-70e6-4914-8742-df2a16d55283/jOn7mB2J9T.json'; // Idle/Thinking
    }

    return SizedBox(
      height: 180,
      width: 180,
      child: Lottie.network(
        lottieUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback if network fails
          return Icon(
            isHappy
                ? Icons.sentiment_very_satisfied
                : isSad
                ? Icons.sentiment_very_dissatisfied
                : Icons.sentiment_neutral,
            size: 80,
            color: Colors.white24,
          );
        },
      ),
    );
  }
}
