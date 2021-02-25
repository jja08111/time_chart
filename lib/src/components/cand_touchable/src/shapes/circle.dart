import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'constant.dart';
import 'shape.dart';
import '../types/types.dart';

class Circle extends Shape {
  final Offset center;
  final double radius;

  Circle(
      {@required this.center,
      @required this.radius,
      HitTestBehavior hitTestBehavior,
      Map<GestureType, Function> gestureMap,
      Paint paint})
      : super(
            paint: paint,
            gestureCallbackMap: gestureMap,
            hitTestBehavior: hitTestBehavior);

//   (x-a)^2 + (y-b)^2 = r^2
  @override
  bool isInside(Offset p) {
    if (paint.style == PaintingStyle.fill) {
      return _isInsideRadius(p, radius);
    } else {
      double extraWidth = paint.strokeWidth / 2;
      bool insideOuterCircle = _isInsideRadius(p, radius + extraWidth);
      bool outsideInnerCircle = !_isInsideRadius(p, radius - extraWidth);
      return insideOuterCircle && outsideInnerCircle;
    }
  }

  bool _isInsideRadius(Offset p, double radius) {
    return pow(p.dx - center.dx, 2) +
            pow(p.dy - center.dy, 2) -
            pow(radius, 2) <=
        ShapeConstant.floatPrecision;
  }
}
