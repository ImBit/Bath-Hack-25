import 'package:flutter/material.dart';

class PressableMarker extends StatefulWidget {
  final double normalWidth;
  final double normalHeight;
  final double pressedWidth;
  final double pressedHeight;
  final String imagePath;
  final Color? markerColor;  // Added parameter for color
  final Function? onPressed; // Added callback for when marker is pressed

  const PressableMarker({
    super.key,
    required this.normalWidth,
    required this.normalHeight,
    required this.pressedWidth,
    required this.pressedHeight,
    required this.imagePath,
    this.markerColor,  // Optional with default color
    this.onPressed,    // Optional callback
  });

  @override
  PressableMarkerState createState() => PressableMarkerState();
}

class PressableMarkerState extends State<PressableMarker> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    if (widget.onPressed != null) {
      widget.onPressed!();
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _isPressed ? widget.pressedWidth : widget.normalWidth,
          height: _isPressed ? widget.pressedHeight : widget.normalHeight,
          child: ColorFiltered(
            colorFilter: widget.markerColor != null
                ? ColorFilter.mode(widget.markerColor!, BlendMode.modulate)
                : const ColorFilter.mode(Colors.white, BlendMode.dst),
            child: Image.asset(
              widget.imagePath,
              fit: BoxFit.contain,
            ),
          ),
        )
    );
  }
}