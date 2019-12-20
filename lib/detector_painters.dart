import 'dart:ui' as ui;

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum Detector { barcode, face, label, text }

class BarcodeDetectorPainter extends CustomPainter {
  BarcodeDetectorPainter(this.imageSize, this.barcodes);

  final Size imageSize;
  final List<Barcode> barcodes;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (Barcode barcode in barcodes) {
      paint.color = Colors.green;
      canvas.drawRect(
        _scaleRect(
          rect: barcode.boundingBox,
          imageSize: imageSize,
          widgetSize: size,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(BarcodeDetectorPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize ||
        oldDelegate.barcodes != barcodes;
  }
}

class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(this.imageSize, this.faces);

  final Size imageSize;
  final List<Face> faces;
  final List<Rect> rects = [];
  
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..color = Colors.blueAccent;

    for (Face face in faces) {
      canvas.drawOval(
        _scaleRect(
          rect: face.boundingBox,
          imageSize: imageSize,
          widgetSize: size,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize || oldDelegate.faces != faces;
  }
}

class LabelDetectorPainter extends CustomPainter {
  LabelDetectorPainter(this.imageSize, this.labels);

  final Size imageSize;
  final List<Label> labels;

  @override
  void paint(Canvas canvas, Size size) {
    final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
          textAlign: TextAlign.center,
          fontSize: 23.0,
          textDirection: TextDirection.ltr),
    );

    builder.pushStyle(ui.TextStyle(color: Colors.white));
    for (Label label in labels) {
      builder.addText('¿Es ${label.label}?, '
          'Probabilidad: ${label.confidence.toStringAsFixed(2)}\n');
    }
    builder.pop();

    canvas.drawParagraph(
      builder.build()
        ..layout(ui.ParagraphConstraints(
          width: size.width,
        )),
      const Offset(0.0, 0.0),
    );
  }

  @override
  bool shouldRepaint(LabelDetectorPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize || oldDelegate.labels != labels;
  }
}

class TextDetectorPainter extends CustomPainter {
  TextDetectorPainter(this.imageSize, this.visionText);

  final Size imageSize;
  final VisionText visionText;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    Rect _getRect(TextContainer container) {
      return _scaleRect(
        rect: container.boundingBox,
        imageSize: imageSize,
        widgetSize: size,
      );
    }

    for (TextBlock block in visionText.blocks) {
      for (TextLine line in block.lines) {
        for (TextElement element in line.elements) {
          paint.strokeWidth = 6.0;
          paint.color = Colors.white;
          canvas.drawRect(_getRect(element), paint);
        }
        paint.strokeWidth = 4.0;
        paint.color = Colors.grey;
        canvas.drawRect(_getRect(line), paint);
      }
      paint.strokeWidth = 2.0;
      paint.color = Colors.black;
      canvas.drawRect(_getRect(block), paint);
    }
  }

  @override
  bool shouldRepaint(TextDetectorPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize ||
        oldDelegate.visionText != visionText;
  }
}

Rect _scaleRect({
  @required Rect rect,
  @required Size imageSize,
  @required Size widgetSize,
}) {
  final double scaleX = widgetSize.width / imageSize.width;
  final double scaleY = widgetSize.height / imageSize.height;

  return Rect.fromLTRB(
    rect.left.toDouble() * scaleX,
    rect.top.toDouble() * scaleY,
    rect.right.toDouble() * scaleX,
    rect.bottom.toDouble() * scaleY,
  );
}
