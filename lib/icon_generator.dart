import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// This is a utility class to generate an app icon for development purposes.
/// Run the main method in this file to generate an icon and save it to assets/icon/app_icon.png.
void main() async {
  // Create a simple colored canvas with text
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  
  // Draw a gradient background
  final rect = Rect.fromLTWH(0, 0, 1024, 1024);
  final gradient = RadialGradient(
    center: Alignment.topLeft,
    radius: 1.5,
    colors: [
      Color(0xFF6200EA), // Primary color
      Color(0xFF4186F5), // HiAnime blue
      Color(0xFFF42A5D), // Miruro red
    ],
  );
  
  canvas.drawRect(
    rect,
    Paint()..shader = gradient.createShader(rect),
  );
  
  // Draw a circular mask
  final circlePaint = Paint()
    ..color = Colors.white.withOpacity(0.9)
    ..style = PaintingStyle.fill;
  
  canvas.drawCircle(
    Offset(512, 512),
    450,
    circlePaint,
  );
  
  // Draw a stylized "A" for Anime
  final textPainter = TextPainter(
    text: TextSpan(
      text: 'A',
      style: TextStyle(
        color: Color(0xFF121212),
        fontSize: 600,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(
      512 - textPainter.width / 2,
      512 - textPainter.height / 2,
    ),
  );
  
  // Draw small play icon
  final playPaint = Paint()
    ..color = Color(0xFFF42A5D)
    ..style = PaintingStyle.fill;
    
  const playIconSize = 200.0;
  final playIconPath = Path();
  playIconPath.moveTo(512 + 150, 512);
  playIconPath.lineTo(512 + 50, 512 + 100);
  playIconPath.lineTo(512 + 50, 512 - 100);
  playIconPath.close();
  
  canvas.drawPath(playIconPath, playPaint);
  
  // Convert to an image
  final picture = recorder.endRecording();
  final img = await picture.toImage(1024, 1024);
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  final buffer = byteData!.buffer.asUint8List();
  
  // Save to file
  File('assets/icon/app_icon.png').writeAsBytesSync(buffer);
  
  print('Icon created successfully at assets/icon/app_icon.png');
  exit(0);
} 