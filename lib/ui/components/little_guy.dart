import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum LittleGuyEyes { open, closed, happy }

enum LittleGuyMouth { happyOpen, neutral, frownOpen, suprisedOpen }

class ActivateListener extends ChangeNotifier {
  void activate() => notifyListeners();
}

class LittleGuy extends StatefulWidget {
  const LittleGuy({super.key});

  @override
  State<LittleGuy> createState() => LittleGuyState();
}

class _LittleGuyDialog extends StatefulWidget {
  const _LittleGuyDialog({super.key});

  @override
  State<StatefulWidget> createState() => _LittleGuyDialogState();
}

class _LittleGuyDialogState extends State<_LittleGuyDialog> {
  bool next = false;
  bool close = false;
  String text = "";

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: close,
    onPopInvokedWithResult: (didPop, result) {
      if (didPop) return;
      next = true;
    },

    child: AlertDialog(content: Text(text)),
  );
}

class LittleGuyState extends State<LittleGuy> {
  LittleGuyState({this.size = 100});

  double size;
  static const assetName = 'assets/svg/littleguy.svg';
  static final Future<PictureInfo> _bodyPicture = vg.loadPicture(
    const SvgAssetLoader(assetName),
    null,
  );

  _LittleGuyPainter? _littleGuyPainter;
  ActivateListener repaint = ActivateListener();

  Future<GlobalKey?> openTalkDialog(
    String text, {
    List<String> options = const [],
    bool close = true,
    GlobalKey? dialogKey,
  }) async {
    var done = false;
    if (dialogKey == null) {
      dialogKey = GlobalKey();
      Future<void> dialogfuture = showDialog(
        context: context,
        builder: (context) => _LittleGuyDialog(key: dialogKey),
      );

      if (close) dialogfuture.whenComplete(() => done = true);
    } else {
      if (dialogKey.currentState! is _LittleGuyDialogState)
        throw new Exception("Key not connected to dialog");
      var dialog = dialogKey.currentState as _LittleGuyDialogState;
      dialog.setState(() {
        dialog.close = close;
      });
    }

    var talkIter = [LittleGuyMouth.happyOpen, LittleGuyMouth.neutral];
    int charIndex = 0;
    while (!done) {
      _littleGuyPainter?.mouth = talkIter[(charIndex ~/ 4) % 2];

      if (charIndex <= text.length) {
        if (dialogKey.currentContext != null) {
          if (dialogKey.currentState is _LittleGuyDialogState) {
            var dialog = dialogKey.currentState as _LittleGuyDialogState;

            if (dialog.next) {
              dialog.setState(() {
                dialog.next = false;
              });
              done = true;
              break;
            }

            dialog.setState(() {
              dialog.text = text.substring(0, charIndex);
            });
          }
        }

        var duration = const Duration(milliseconds: 30);

        if (charIndex > 0) {
          if (".?!".contains(text[charIndex - 1])) {
            _littleGuyPainter?.mouth = talkIter[1];
            duration = const Duration(milliseconds: 200);
          }

          if (" ".contains(text[charIndex - 1])) {
            _littleGuyPainter?.mouth = talkIter[1];
            duration = const Duration(milliseconds: 40);
          }
        }

        charIndex += 1;
        repaint.activate();

        await Future.delayed(duration);
        if (!mounted) return null;
      }
    }

    _littleGuyPainter?.mouth = talkIter[1];
    repaint.activate();
    return dialogKey;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<PictureInfo>(
    future: _bodyPicture,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return ErrorWidget(snapshot.error!);
      }
      final pictureInfo = snapshot.data;
      if (pictureInfo == null) {
        return SizedBox(width: size, height: size * 1.5);
      }

      _littleGuyPainter = _LittleGuyPainter(
        pictureInfo: pictureInfo,
        eyes: LittleGuyEyes.open,
        mouth: LittleGuyMouth.neutral,
        repaint: repaint,
      );

      return SizedBox(
        width: size,
        height: size * 1.5,
        child: CustomPaint(painter: _littleGuyPainter),
      );
    },
  );
}

class _LittleGuyPainter extends CustomPainter {
  _LittleGuyPainter({
    required this.pictureInfo,
    required this.eyes,
    required this.mouth,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final PictureInfo pictureInfo;
  LittleGuyEyes eyes;
  LittleGuyMouth mouth;

  static const _viewBoxWidth = 12.0;
  static const _viewBoxHeight = 18.0;
  static const _ink = Color(0xFF000000);
  static const _paper = Color(0xFFFFFFFF);

  static const mouthCenter = const Offset(5.7, 6.1);
  static const eyeCenter = const Offset(5.7, 4.0);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _viewBoxWidth, size.height / _viewBoxHeight);

    canvas.save();
    canvas.translate(_viewBoxWidth * 0.2, _viewBoxHeight * 0.4);
    canvas.scale(
      (_viewBoxWidth / pictureInfo.size.width) * 0.5,
      (_viewBoxWidth / pictureInfo.size.height) * 0.5,
    );
    canvas.drawPicture(pictureInfo.picture);
    canvas.restore();

    final eyePaint = Paint()
      ..color = _ink
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final eyeFill = Paint()
      ..color = _paper
      ..style = PaintingStyle.fill;

    _paintHead(canvas);
    _paintEye(canvas, eyeCenter - const Offset(2.0, 0.2), eyePaint, eyeFill);
    _paintEye(canvas, eyeCenter + const Offset(2.0, 0.0), eyePaint, eyeFill);
    _paintMouth(canvas);
    canvas.restore();
  }

  void _paintHead(Canvas canvas) {
    final head = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0.8, 1.17, 9.96, 6.52),
      const Radius.circular(2.15),
    );
    canvas.drawRRect(
      head,
      Paint()
        ..color = _paper
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      head,
      Paint()
        ..color = _ink
        ..strokeWidth = 0.6
        ..style = PaintingStyle.stroke,
    );
  }

  void _paintEye(Canvas canvas, Offset center, Paint outline, Paint fill) {
    switch (eyes) {
      case LittleGuyEyes.open:
        final eye = Rect.fromCenter(center: center, width: 1.5, height: 1.7);
        canvas.drawOval(eye, fill);
        canvas.drawOval(eye, outline);
      case LittleGuyEyes.closed:
        canvas.drawLine(
          center + const Offset(-0.75, 0.1),
          center + const Offset(0.75, 0.1),
          outline,
        );
      case LittleGuyEyes.happy:
        final arc = Path()
          ..moveTo(center.dx - 0.75, center.dy + 0.15)
          ..quadraticBezierTo(
            center.dx,
            center.dy - 0.8,
            center.dx + 0.75,
            center.dy + 0.15,
          );
        canvas.drawPath(arc, outline);
    }
  }

  void _paintMouth(Canvas canvas) {
    final outline = Paint()
      ..color = _ink
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    switch (mouth) {
      case LittleGuyMouth.happyOpen:
        final path = Path()
          ..moveTo(mouthCenter.dx - 1.0, mouthCenter.dy)
          ..lineTo(mouthCenter.dx, mouthCenter.dy + 0.8)
          ..lineTo(mouthCenter.dx + 1.0, mouthCenter.dy)
          ..close();
        canvas.drawPath(
          path,
          Paint()
            ..color = _ink
            ..style = PaintingStyle.fill,
        );
        canvas.drawPath(path, outline);
      case LittleGuyMouth.neutral:
        canvas.drawLine(
          mouthCenter + const Offset(-1, 0.3),
          mouthCenter + const Offset(1, 0.4),
          outline,
        );
      case LittleGuyMouth.frownOpen:
        final path = Path()
          ..moveTo(mouthCenter.dx - 1.0, mouthCenter.dy + 0.8)
          ..lineTo(mouthCenter.dx, mouthCenter.dy)
          ..lineTo(mouthCenter.dx + 1.0, mouthCenter.dy + 0.8)
          ..close();
        canvas.drawPath(
          path,
          Paint()
            ..color = _ink
            ..style = PaintingStyle.fill,
        );
        canvas.drawPath(path, outline);
      case LittleGuyMouth.suprisedOpen:
        final mouthShape = Path()
          ..addOval(
            Rect.fromCenter(center: mouthCenter, width: 1.7, height: 2.0),
          );
        canvas.drawPath(
          mouthShape,
          Paint()
            ..color = _paper
            ..style = PaintingStyle.fill,
        );
        canvas.drawPath(mouthShape, outline);
    }
  }

  @override
  bool shouldRepaint(_LittleGuyPainter oldDelegate) =>
      pictureInfo.picture != oldDelegate.pictureInfo.picture ||
      eyes != oldDelegate.eyes ||
      mouth != oldDelegate.mouth;
}
