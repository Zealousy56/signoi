import 'package:flutter/material.dart';

class ProgressPage extends StatefulWidget {
  final int level;
  final double experience;
  final bool isActive;

  const ProgressPage({
    super.key,
    required this.level,
    required this.experience,
    required this.isActive,
  });

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late Tween<double> _experienceTween;
  late double _displayExperience;
  late int _displayLevel;
  double _targetExperience = 0.0;
  double _levelUpStartExperience = 0.0;
  bool _isLevelUpFilling = false;
  bool _isLevelUpRising = false;

  double get _animatedExperience {
    if (_isLevelUpFilling) {
      return _interpolateExperience(
        _levelUpStartExperience,
        1.0,
        _animationController.value,
      );
    }
    if (_isLevelUpRising) {
      return _interpolateExperience(
        0.0,
        _targetExperience,
        _animationController.value,
      );
    }
    return _experienceTween.transform(
      Curves.easeInOut.transform(_animationController.value),
    );
  }

  double _interpolateExperience(double start, double end, double progress) {
    return Tween<double>(begin: start, end: end).transform(
      Curves.easeInOut.transform(progress.clamp(0.0, 1.0)),
    );
  }

  @override
  void initState() {
    super.initState();
    _displayExperience = widget.experience;
    _displayLevel = widget.level;
    _targetExperience = widget.experience;
    _experienceTween = Tween<double>(
      begin: widget.experience,
      end: widget.experience,
    );
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addStatusListener(_handleAnimationStatus);
  }

  @override
  void didUpdateWidget(covariant ProgressPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive &&
        (widget.level != _displayLevel ||
            widget.experience != _displayExperience)) {
      if (widget.level != _displayLevel) {
        _startLevelUpAnimation(widget.experience);
      } else {
        _startExperienceAnimation(widget.experience);
      }
    }
  }

  void _startExperienceAnimation(double target) {
    final currentExperience = _animatedExperience;
    _isLevelUpFilling = false;
    _isLevelUpRising = false;
    _animationController.duration = const Duration(milliseconds: 900);
    _targetExperience = target;
    _experienceTween = Tween<double>(
      begin: currentExperience,
      end: target,
    );
    _animationController.forward(from: 0.0);
  }

  void _startLevelUpAnimation(double target) {
    _levelUpStartExperience = _animatedExperience;
    _isLevelUpFilling = true;
    _isLevelUpRising = false;
    _displayLevel = widget.level;
    _targetExperience = target;
    _animationController.duration = const Duration(milliseconds: 900);
    _animationController.forward(from: 0.0);
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_isLevelUpFilling) {
      setState(() {
        _isLevelUpFilling = false;
        _isLevelUpRising = true;
        _experienceTween = Tween<double>(
          begin: 0.0,
          end: _targetExperience,
        );
      });
      _animationController.forward(from: 0.0);
      return;
    }

    setState(() {
      _isLevelUpFilling = false;
      _isLevelUpRising = false;
      _displayExperience = _targetExperience;
      _experienceTween = Tween<double>(
        begin: _targetExperience,
        end: _targetExperience,
      );
      _animationController.duration = const Duration(milliseconds: 900);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) => _LevelIndicator(
            level: _displayLevel,
            experience: _displayLevel == 1 && _animatedExperience == 0.0
                ? 0.0
                : _animatedExperience,
          ),
        ),
      ),
    );
  }
}

class _LevelIndicator extends StatelessWidget {
  final int level;
  final double experience;

  const _LevelIndicator({
    required this.level,
    required this.experience,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Builder(
          builder: (context) {
            final clamped = experience.clamp(0.0, 1.0);
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
            final y = (iconSize * 0.8) - (iconSize * 1 * clamped);
            return SizedBox(
              width: iconSize,
              height: iconSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  icon,
                  Positioned(
                    left: (x - 20).clamp(0.0, iconSize - 36),
                    top: (y + 40).clamp(0.0, iconSize - 28),
                    child: Transform.rotate(
                      angle: -0.77 ,
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
