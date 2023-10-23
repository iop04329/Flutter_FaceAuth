import 'dart:ui';
import 'package:face_net_authentication/services/pub_service.dart';
import 'package:face_net_authentication/locator.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/material.dart';

class RectWindowPainter extends CustomPainter{
  RectWindowPainter({required this.imageSize,required this.isOK});
  final Size imageSize;
  final bool isOK;
  pub_service _pubService = locator<pub_service>();

  @override
  void paint(Canvas canvas, Size size) {
    // TODO: implement paint
    Paint paint;
    if(isOK){
      paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = Colors.green;
    } else{
      paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = Colors.red;
    }

    double lineLen = 70;
    double centerX = _pubService.centerX;
    double centerY = _pubService.centerY;
    double top = _pubService.WindowRect!.top;
    double left = _pubService.WindowRect!.left;
    double bottom = _pubService.WindowRect!.bottom;
    double right = _pubService.WindowRect!.right;

    canvas.drawPoints(PointMode.points, <Offset>[Offset(centerX, centerY)], paint);
    //左上角
    canvas.drawLine(Offset(left,top), Offset(left,top+lineLen), paint); // -
    canvas.drawLine(Offset(left,top), Offset(left+lineLen,top), paint); // |
    //右上角
    canvas.drawLine(Offset(right,top), Offset(right,top+lineLen), paint); // |
    canvas.drawLine(Offset(right,top), Offset(right-lineLen,top), paint); // -
    //左下角
    canvas.drawLine(Offset(left,bottom), Offset(left,bottom-lineLen), paint); // |
    canvas.drawLine(Offset(left,bottom), Offset(left+lineLen,bottom), paint); // -
    //右下角
    canvas.drawLine(Offset(right,bottom), Offset(right,bottom-lineLen), paint); // |
    canvas.drawLine(Offset(right,bottom), Offset(right-lineLen,bottom), paint); // -

  }

  @override
  bool shouldRepaint(RectWindowPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize || oldDelegate.isOK != isOK;
  }

}
