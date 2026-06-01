import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../../core/theme/app_theme.dart';

class VoiceButton extends StatefulWidget {
  const VoiceButton({super.key});

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startPulseAnimation() {
    _animationController.repeat(reverse: true);
  }

  void _stopPulseAnimation() {
    _animationController.stop();
    _animationController.reset();
  }

  Future<void> _handleVoiceInput() async {
    final provider = context.read<ChatProvider>();
    HapticFeedback.mediumImpact();

    if (provider.isListening) {
      await provider.stopListening();
      _stopPulseAnimation();
      return;
    }

    _startPulseAnimation();
    await provider.startListening();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        if (provider.isListening) {
          _startPulseAnimation();
        } else {
          _stopPulseAnimation();
        }

        final label = provider.isListening
            ? 'Arrêter la reconnaissance vocale'
            : 'Démarrer la reconnaissance vocale';

        return Semantics(
          button: true,
          label: label,
          enabled: true,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: provider.isListening ? _scaleAnimation.value : 1.0,
                child: FloatingActionButton(
                  onPressed: _handleVoiceInput,
                  tooltip: label,
                  backgroundColor: provider.isListening
                      ? AppTheme.errorColor
                      : AppTheme.primaryColor,
                  child: ExcludeSemantics(
                    child: Icon(
                      provider.isListening ? Icons.stop : Icons.mic,
                      size: 32,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
