import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class CulturalAvatar extends StatefulWidget {
  final bool isHappy;
  final bool isSad;
  final bool isThinking;

  const CulturalAvatar({
    super.key,
    this.isHappy = false,
    this.isSad = false,
    this.isThinking = false,
  });

  @override
  State<CulturalAvatar> createState() => _CulturalAvatarState();
}

class _CulturalAvatarState extends State<CulturalAvatar> {
  dynamic _happyTrigger;
  dynamic _sadTrigger;
  dynamic _thinkTrigger;

  void _onRiveInit(dynamic artboard) {
    // Using dynamic to bypass analyzer issues with Rive classes
    try {
      final controller = StateMachineController.fromArtboard(
        artboard,
        'State Machine 1',
      );
      if (controller != null) {
        artboard.addController(controller);
        _happyTrigger = controller.findSMI('isHappy');
        _sadTrigger = controller.findSMI('isSad');
        _thinkTrigger = controller.findSMI('think');
      }
    } catch (e) {
      debugPrint('Rive initialization error: $e');
    }
  }

  @override
  void didUpdateWidget(covariant CulturalAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    try {
      if (widget.isHappy) _happyTrigger?.value = true;
      if (widget.isSad) _sadTrigger?.value = true;
      if (widget.isThinking) _thinkTrigger?.fire();
    } catch (e) {
      debugPrint('Rive update error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: 150,
      child: RiveAnimation.network(
        'https://public.rive.app/community/runtime-files/2195-4346-avatar-demo.riv',
        fit: BoxFit.contain,
        onInit: _onRiveInit,
      ),
    );
  }
}


