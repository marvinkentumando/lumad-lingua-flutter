import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SuccessLottie extends StatelessWidget {
  final double size;
  const SuccessLottie({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return Lottie.network(
      'https://assets10.lottiefiles.com/packages/lf20_afmre9.json', // Checkmark animation
      width: size,
      height: size,
      repeat: false,
    );
  }
}

class FailureLottie extends StatelessWidget {
  final double size;
  const FailureLottie({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return Lottie.network(
      'https://assets10.lottiefiles.com/packages/lf20_hp8scvub.json', // Red cross / failure
      width: size,
      height: size,
      repeat: false,
    );
  }
}

class CelebrationLottie extends StatelessWidget {
  const CelebrationLottie({super.key});

  @override
  Widget build(BuildContext context) {
    return Lottie.network(
      'https://assets10.lottiefiles.com/packages/lf20_u4yrau.json', // Confetti / Celebration
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
    );
  }
}


