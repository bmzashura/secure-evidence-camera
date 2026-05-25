import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/colors.dart';

class PinInput extends StatefulWidget {
  final Function(String) onPinComplete;
  final bool isError;
  final bool isDisabled;
  final int pinLength;
  final String resetSignal; // Change this to trigger reset

  const PinInput({
    super.key,
    required this.onPinComplete,
    this.isError = false,
    this.isDisabled = false,
    this.pinLength = 4,
    this.resetSignal = '',
  });

  @override
  State<PinInput> createState() => _PinInputState();
}

class _PinInputState extends State<PinInput>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void didUpdateWidget(PinInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isError && !oldWidget.isError) {
      _shakeController.forward().then((_) {
        _shakeController.reset();
        setState(() => _pin = '');
      });
      HapticFeedback.heavyImpact();
    }
    if (widget.isDisabled && !oldWidget.isDisabled) {
      setState(() => _pin = '');
    }
    // Reset when resetSignal changes (for switching between enter/confirm)
    if (widget.resetSignal != oldWidget.resetSignal && widget.resetSignal.isNotEmpty) {
      setState(() => _pin = '');
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyTap(String key) {
    if (widget.isDisabled) return;
    if (_pin.length >= widget.pinLength) return;

    HapticFeedback.lightImpact();
    setState(() => _pin += key);

    if (_pin.length == widget.pinLength) {
      widget.onPinComplete(_pin);
    }
  }

  void _onBackspace() {
    if (widget.isDisabled) return;
    if (_pin.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // PIN dots
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            final shake = _shakeAnimation.value * 10;
            return Transform.translate(
              offset: Offset(shake * (_shakeAnimation.value % 2 == 0 ? 1 : -1), 0),
              child: child,
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(widget.pinLength, (index) {
              final isFilled = index < _pin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled
                      ? (widget.isError ? AppColors.error : AppColors.primary)
                      : Colors.transparent,
                  border: Border.all(
                    color: widget.isError
                        ? AppColors.error
                        : (isFilled ? AppColors.primary : AppColors.textSecondary),
                    width: 2,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 48),
        // Keypad
        _buildKeypad(),
      ],
    );
  }

  Widget _buildKeypad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'back'],
    ];

    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: row.map((key) {
            if (key.isEmpty) {
              return const SizedBox(width: 80, height: 80);
            }
            if (key == 'back') {
              return _buildKeypadButton(
                child: const Icon(Icons.backspace_outlined,
                    color: AppColors.textPrimary, size: 28),
                onTap: _onBackspace,
              );
            }
            return _buildKeypadButton(
              child: Text(
                key,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textPrimary,
                ),
              ),
              onTap: () => _onKeyTap(key),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.all(8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(40),
          child: Center(child: child),
        ),
      ),
    );
  }
}