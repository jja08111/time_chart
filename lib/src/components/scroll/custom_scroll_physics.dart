import 'dart:math';

import 'package:flutter/material.dart';
import '../view_mode.dart';

const double _kPivotVelocity = 240.0;

class TapDownPosition {
  double pixels = 0.0;
}

class CustomScrollPhysics extends ScrollPhysics {
  CustomScrollPhysics({
    required this.blockWidth,
    required this.viewMode,
    required this.tapDownPosition,
    required this.maxWidth,
    ScrollPhysics? parent,
  }) : super(parent: parent);

  final double blockWidth;
  final ViewMode viewMode;
  final TapDownPosition tapDownPosition;
  final double maxWidth;

  void setPanDownPixels(double pixels) {
    tapDownPosition.pixels = pixels;
  }

  void addPanDownPixels(double add) {
    tapDownPosition.pixels += add;
  }

  double get _maxPosition {
    return (maxWidth / blockWidth) - getViewModeLimitDay(viewMode);
  }

  @override
  CustomScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomScrollPhysics(
      blockWidth: blockWidth,
      viewMode: viewMode,
      tapDownPosition: tapDownPosition,
      maxWidth: maxWidth,
      parent: buildParent(ancestor),
    );
  }

  double _getPixels(double blockPosition) => blockPosition * blockWidth;

  double _getTargetPixels(
      ScrollPosition position, Tolerance tolerance, double velocity) {
    final double dayLimit = getViewModeLimitDay(viewMode).toDouble();
    final double startBlock = tapDownPosition.pixels / blockWidth;
    double block = getCurrentBlockIndex(position, blockWidth);

    if (velocity.abs() > _kPivotVelocity) {
      if (velocity < -tolerance.velocity) {
        block -= dayLimit;
      } else if (velocity > tolerance.velocity) {
        block += dayLimit;
      }
    } else {
      if (velocity < -tolerance.velocity) {
        block -= 1;
      } else if (velocity > tolerance.velocity) {
        block += 1;
      }
    }
    double blockPosition = block.roundToDouble();

    blockPosition = min((startBlock + dayLimit).roundToDouble(), blockPosition);
    blockPosition = max((startBlock - dayLimit).roundToDouble(), blockPosition);

    blockPosition = max(0, blockPosition);
    blockPosition = min(_maxPosition, blockPosition);

    return _getPixels(blockPosition);
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    // If we're out of range and not headed back in range, defer to the parent
    // ballistics, which should put us back in range at a page boundary.
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent))
      return super.createBallisticSimulation(position, velocity);

    final Tolerance tolerance = this.tolerance;
    final double target =
        _getTargetPixels(position as ScrollPosition, tolerance, velocity);
    if (target != position.pixels)
      return ScrollSpringSimulation(spring, position.pixels, target, velocity,
          tolerance: tolerance);
    return null;
  }

  @override
  bool get allowImplicitScrolling => false;
}

double getCurrentBlockIndex(ScrollPosition position, double itemDimension) {
  return position.pixels / itemDimension;
}
