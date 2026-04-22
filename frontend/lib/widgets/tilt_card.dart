import 'package:flutter/material.dart';
import 'glass_card.dart';

class TiltCard extends StatefulWidget {
  final Widget child;
  const TiltCard({super.key, required this.child});

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> {
  double _tilt = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              final position = renderBox.localToGlobal(Offset.zero);
              final screenWidth = MediaQuery.of(context).size.width;
              final center = screenWidth / 2;
              final cardCenter = position.dx + (renderBox.size.width / 2);
              
              // Calculate tilt based on distance from center
              setState(() {
                _tilt = (center - cardCenter) / (screenWidth * 2);
              });
            }
            return false;
          },
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateY(_tilt),
            alignment: Alignment.center,
            child: GlassCard(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}
