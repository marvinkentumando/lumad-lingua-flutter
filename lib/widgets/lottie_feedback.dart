import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_colors.dart';

class SuccessLottie extends StatelessWidget {
  final double size;
  const SuccessLottie({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return Lottie.network(
      'https://lottie.host/80131f4a-8740-4965-9856-78810298a83a/lUun9v445q.json',
      width: size,
      height: size,
      repeat: false,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.check_circle_outline_rounded,
        size: size * 0.5,
        color: AppColors.semanticGreen,
      ),
    );
  }
}

class FailureLottie extends StatelessWidget {
  final double size;
  const FailureLottie({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return Lottie.network(
      'https://lottie.host/83017a00-1c7b-406c-820d-730c4f82873c/YtHj4ZqHqS.json',
      width: size,
      height: size,
      repeat: false,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.error_outline_rounded,
        size: size * 0.5,
        color: AppColors.semanticRed,
      ),
    );
  }
}

class CelebrationLottie extends StatelessWidget {
  const CelebrationLottie({super.key});

  @override
  Widget build(BuildContext context) {
    return Lottie.network(
      'https://lottie.host/791c8907-5503-4674-8740-109437298642/hZ4y9Y8j7T.json',
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
