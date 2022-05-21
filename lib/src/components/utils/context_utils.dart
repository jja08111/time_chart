import 'package:flutter/material.dart';

extension RenderBoxUtils on BuildContext {
  Offset? getRenderBoxOffset([Offset? point]) {
    RenderBox? rb = findRenderObject() as RenderBox?;
    return rb?.localToGlobal(point ?? Offset.zero);
  }
}
