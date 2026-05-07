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
          'https://assets10.lottiefiles.com/packages/lf20_tou969lj.json'; // Party/Celebration
    } else if (isHappy) {
      lottieUrl =
          'https://assets2.lottiefiles.com/packages/lf20_7mshrhz1.json'; // Happy success
    } else if (isSad) {
      lottieUrl =
          'https://assets5.lottiefiles.com/packages/lf20_mmsvpx7y.json'; // Sad/Think
    } else {
      lottieUrl =
          'https://assets4.lottiefiles.com/packages/lf20_6p8oeyio.json'; // Idle/Thinking
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



