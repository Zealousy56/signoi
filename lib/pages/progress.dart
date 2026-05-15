import 'package:flutter/material.dart';

class ProgressPage extends StatefulWidget {
  final int level;
  final double experience;

  const ProgressPage({
    super.key,
    required this.level,
    required this.experience,
  });

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  double _displayExperience = 0.0;
  double _previousDisplayExperience = 0.0;

  @override
  void initState() {
    super.initState();
    _displayExperience = widget.experience;
    _previousDisplayExperience = widget.experience;
  }

  @override
  void didUpdateWidget(covariant ProgressPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.experience != oldWidget.experience) {
      setState(() {
        _previousDisplayExperience = _displayExperience;
        _displayExperience = widget.experience;
      });
    }
  }

  void _onProgressAnimationEnd() {
    if (!mounted) return;
    if (_previousDisplayExperience != _displayExperience) {
      setState(() {
        _previousDisplayExperience = _displayExperience;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help selected')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Open Settings (TODO)')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: _LevelIndicator(
          level: widget.level,
          experience: widget.level == 1 && _displayExperience == 0.0
              ? 0.0
              : _displayExperience,
          previousExperience: _previousDisplayExperience,
          onAnimationEnd: _onProgressAnimationEnd,
        ),
      ),
    );
  }
}

class _LevelIndicator extends StatelessWidget {
  final int level;
  final double experience;
  final double previousExperience;
  final VoidCallback onAnimationEnd;

  const _LevelIndicator({
    required this.level,
    required this.experience,
    required this.previousExperience,
    required this.onAnimationEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: previousExperience.clamp(0.0, 1.0),
            end: experience.clamp(0.0, 1.0),
          ),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOut,
          onEnd: onAnimationEnd,
          builder: (context, value, child) {
            final clamped = value.clamp(0.0, 1.0);
            final bool isEmpty = clamped <= 0.0;
            final percent = (clamped * 100).round();

            Widget icon = const Icon(
              Icons.signal_cellular_4_bar,
              size: 320,
              color: Colors.black,
            );

            if (!isEmpty) {
              icon = ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: const [
                      Colors.green,
                      Colors.green,
                      Colors.black,
                      Colors.black,
                    ],
                    stops: [0.0, clamped, clamped, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.srcIn,
                child: icon,
              );
            }

            const iconSize = 320.0;
            final x = (iconSize * clamped).clamp(0.0, iconSize);
            final y = (iconSize * 0.78) - (iconSize * 0.45 * clamped);
            return SizedBox(
              width: iconSize,
              height: iconSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  icon,
                  Positioned(
                    left: (x - 18).clamp(0.0, iconSize - 36),
                    top: (y + 10).clamp(0.0, iconSize - 28),
                    child: Transform.rotate(
                      angle: -0.72,
                      child: Text(
                        '$percent%',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Level $level',
          style: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
