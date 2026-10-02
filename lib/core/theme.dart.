import 'package:flutter/material.dart';

class C {
  static const accent = Color(0xFFFFEB3B);
  static const cyan = Color(0xFF00E5FF);
  static const panel = Color(0xFF2F2B58);
  static const panelSel = Color(0xFF4B4586);
  static const btn = Color(0xFF6D5BA8);
}

ThemeData buildTheme() => ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF05020F),
      colorScheme: const ColorScheme.dark(
        primary: C.cyan,
        secondary: C.accent,
        surface: Color(0xFF1A1236),
      ),
    );

/// خلفية متدرجة بنفس روح IBO Player (بنفسجي داكن → عنابي → أسود)
class GradientBg extends StatelessWidget {
  final Widget child;
  const GradientBg({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF160B3C), Color(0xFF3A0A22), Color(0xFF05020F)],
            stops: [0, 0.55, 1],
          ),
        ),
        child: child,
      );
}

/// شعار Waha 4K
class BrandLogo extends StatelessWidget {
  final double height;
  final bool text;
  const BrandLogo({super.key, this.height = 60, this.text = true});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(height * 0.22),
            child: Image.asset('assets/logo.png', height: height, width: height),
          ),
          if (text) ...[
            SizedBox(width: height * 0.25),
            Text.rich(TextSpan(children: [
              TextSpan(
                text: 'WAHA ',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: height * 0.42,
                    letterSpacing: 1),
              ),
              TextSpan(
                text: '4K',
                style: TextStyle(
                    color: C.cyan,
                    fontWeight: FontWeight.w800,
                    fontSize: height * 0.42),
              ),
            ])),
          ],
        ],
      );
}
