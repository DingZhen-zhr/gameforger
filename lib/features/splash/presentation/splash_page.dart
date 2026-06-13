import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cosmic_forge.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CosmicBackground(
        child: Center(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NebulaOrb(size: 180),
                SizedBox(height: 38),
                _GradientLogoText(),
                SizedBox(height: 10),
                Text(
                  '把你的游戏创意 · 变成现实',
                  style: TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 13.5,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 72),
                StarRingLoader(label: '正在启动'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientLogoText extends StatelessWidget {
  const _GradientLogoText();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [Colors.white, AppTheme.cyan, Color(0xFF9A7DFF)],
      ).createShader(bounds),
      child: Text(
        'GameForger',
        style: TextStyle(
          color: Colors.white,
          fontSize: 38,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
