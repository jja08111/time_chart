
import 'package:flutter/material.dart';

const Size _kAmountTooltipSize = const Size(146.0, 80.0);
const Size _kTimeTooltipSize = const Size(140.0, 172.0);

Size _getFixedSize(BuildContext context, Size size) {
  final textScaleFactor = MediaQuery.of(context).textScaleFactor;
  return Size(
    size.width * textScaleFactor,
    size.height * textScaleFactor,
  );
}

Size getAmountTooltipSize(BuildContext context) {
  return _getFixedSize(context, _kAmountTooltipSize);
}

Size getTimeTooltipSize(BuildContext context) {
  return _getFixedSize(context, _kTimeTooltipSize);
}