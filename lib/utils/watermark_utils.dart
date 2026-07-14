import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WatermarkUtils {
  /// Appears as a beautiful permanent banner overlay at the bottom of the captured image
  static Future<Uint8List> addPhotoWatermark({
    required Uint8List imageBytes,
    required String employeeName,
    required String employeeId,
    double? latitude,
    double? longitude,
    String? visitType,
    String? projectName,
  }) async {
    try {
      // Decode image
      final Completer<ui.Image> completer = Completer();
      ui.decodeImageFromList(imageBytes, (ui.Image img) {
        completer.complete(img);
      });
      final ui.Image img = await completer.future;

      final int width = img.width;
      final int height = img.height;

      // Initialize canvas with picture recorder
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);

      // Draw original image
      final Paint paint = Paint()..filterQuality = ui.FilterQuality.high;
      canvas.drawImage(img, Offset.zero, paint);

      // Setup banner dimensions
      final double bannerHeight = (height * 0.22).clamp(80.0, 220.0);
      final double startY = height - bannerHeight;

      // Draw semi-transparent gradient banner
      final Rect bannerRect = Rect.fromLTWH(0, startY, width.toDouble(), bannerHeight);
      final Gradient gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xED0F172A), // Deep Slate Blue (95% opacity)
          const Color(0xF2581C87), // Ruhamaa Deep Purple (95% opacity)
        ],
      );
      final Paint bannerPaint = Paint()
        ..shader = gradient.createShader(bannerRect)
        ..style = PaintingStyle.fill;
      canvas.drawRect(bannerRect, bannerPaint);

      // Draw bottom accent strip
      final Paint accentPaint = Paint()
        ..color = const Color(0xffa78bfa) // Violet
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTWH(0, height - 6.0, width.toDouble(), 6.0),
        accentPaint,
      );

      // Setup font sizing
      final double fontSizeLarge = (bannerHeight * 0.16).clamp(13.0, 24.0);
      final double fontSizeSmall = (bannerHeight * 0.11).clamp(11.0, 18.0);
      final double paddingX = (width * 0.04).clamp(15.0, 40.0);

      // Text Painter for Logo Heading
      final TextPainter logoPainter = TextPainter(
        text: TextSpan(
          text: '◆ RUHAMAA FOUNDATION',
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSizeLarge,
            fontWeight: FontWeight.bold,
            fontFamily: 'sans-serif',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      logoPainter.paint(canvas, Offset(paddingX, startY + 12.0));

      // Build left column info
      final String dateTimeStr = DateFormat('MMM dd, yyyy  hh:mm:ss a').format(DateTime.now());
      final String leftInfo = 'Field Officer: $employeeName ($employeeId)\n'
          'Date/Time: $dateTimeStr';

      final TextPainter leftPainter = TextPainter(
        text: TextSpan(
          text: leftInfo,
          style: TextStyle(
            color: const Color(0xffe2e8f0),
            fontSize: fontSizeSmall,
            height: 1.4,
            fontFamily: 'sans-serif',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      leftPainter.paint(canvas, Offset(paddingX, startY + fontSizeLarge + 22.0));

      // Build right column info
      final double rightColumnX = width * 0.52;
      final StringBuffer rightInfo = StringBuffer();
      
      if (visitType != null && visitType.isNotEmpty) {
        rightInfo.writeln('Visit Type: $visitType');
      }
      if (projectName != null && projectName.isNotEmpty) {
        rightInfo.writeln('Project: $projectName');
      }
      if (latitude != null && longitude != null) {
        final String latStr = latitude >= 0 ? '${latitude.toStringAsFixed(5)}° N' : '${latitude.abs().toStringAsFixed(5)}° S';
        final String lngStr = longitude >= 0 ? '${longitude.toStringAsFixed(5)}° E' : '${longitude.abs().toStringAsFixed(5)}° W';
        rightInfo.write('GPS: $latStr, $lngStr');
      } else {
        rightInfo.write('GPS: Not Available');
      }

      final TextPainter rightPainter = TextPainter(
        text: TextSpan(
          text: rightInfo.toString(),
          style: TextStyle(
            color: const Color(0xffe2e8f0),
            fontSize: fontSizeSmall,
            height: 1.4,
            fontWeight: FontWeight.bold,
            fontFamily: 'sans-serif',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      rightPainter.paint(canvas, Offset(rightColumnX, startY + 12.0));

      // Save picture and convert to bytes
      final ui.Picture picture = recorder.endRecording();
      final ui.Image watermarkedImg = await picture.toImage(width, height);
      final ByteData? pngBytes = await watermarkedImg.toByteData(format: ui.ImageByteFormat.png);

      if (pngBytes != null) {
        return pngBytes.buffer.asUint8List();
      }
    } catch (e) {
      print('Watermark overlay failed: $e');
    }
    // Fallback to original bytes
    return imageBytes;
  }
}
