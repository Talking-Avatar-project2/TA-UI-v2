import 'package:flutter/material.dart';

/// Estados posibles del botón de grabación
enum RecordingState {
  idle,
  recording,
  processing,
  playing,
}

/// Botón de grabación con indicadores visuales
class RecordingButton extends StatefulWidget {
  final RecordingState state;
  final VoidCallback? onStartRecording;
  final VoidCallback? onStopRecording;
  final double size;

  const RecordingButton({
    super.key,
    required this.state,
    this.onStartRecording,
    this.onStopRecording,
    this.size = 80.0,
  });

  @override
  State<RecordingButton> createState() => _RecordingButtonState();
}

class _RecordingButtonState extends State<RecordingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
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

  Color _getButtonColor() {
    switch (widget.state) {
      case RecordingState.idle:
        return Colors.blue;
      case RecordingState.recording:
        return Colors.red;
      case RecordingState.processing:
        return Colors.orange;
      case RecordingState.playing:
        return Colors.green;
    }
  }

  IconData _getIcon() {
    switch (widget.state) {
      case RecordingState.idle:
        return Icons.mic_none;
      case RecordingState.recording:
        return Icons.mic;
      case RecordingState.processing:
        return Icons.hourglass_empty;
      case RecordingState.playing:
        return Icons.volume_up;
    }
  }

  String _getHintText() {
    switch (widget.state) {
      case RecordingState.idle:
        return 'Mantén presionado para hablar';
      case RecordingState.recording:
        return 'Suelta para enviar';
      case RecordingState.processing:
        return 'Procesando...';
      case RecordingState.playing:
        return 'Reproduciendo respuesta...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = widget.state == RecordingState.recording;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón principal
        GestureDetector(
          onTapDown: widget.state == RecordingState.idle
              ? (_) => widget.onStartRecording?.call()
              : null,
          onTapUp: isRecording ? (_) => widget.onStopRecording?.call() : null,
          onTapCancel: isRecording ? () => widget.onStopRecording?.call() : null,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isRecording ? _scaleAnimation.value : 1.0,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: _getButtonColor(),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getButtonColor().withValues(alpha: 0.5),
                        blurRadius: isRecording ? 20 : 10,
                        spreadRadius: isRecording ? 5 : 2,
                      ),
                    ],
                  ),
                  child: widget.state == RecordingState.processing
                      ? const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Icon(
                          _getIcon(),
                          color: Colors.white,
                          size: widget.size * 0.5,
                        ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Texto de ayuda
        Text(
          _getHintText(),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),

        // Indicador visual de grabación
        if (isRecording) ...[
          const SizedBox(height: 8),
          _buildRecordingIndicator(),
        ],
      ],
    );
  }

  Widget _buildRecordingIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final delay = index * 0.2;
              final value = (_animationController.value + delay) % 1.0;
              final height = 4 + (value * 12);

              return Container(
                width: 4,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
