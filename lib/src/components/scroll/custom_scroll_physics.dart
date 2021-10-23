import 'dart:math';

import 'package:flutter/material.dart';
import '../view_mode.dart';

const double _kPivotVelocity = 240.0;

class TapDownPosition {
  double pixels = 0.0;
}

class CustomScrollPhysics extends ScrollPhysics {
  CustomScrollPhysics({
    required this.itemDimension,
    required this.viewMode,
    required this.tapDownPosition,
    ScrollPhysics? parent,
  }) : super(parent: parent);

  final double itemDimension;
  final ViewMode viewMode;
  final TapDownPosition tapDownPosition;

  void setPanDownPixels(double pixels) {
    tapDownPosition.pixels = pixels;
  }

  void addPanDownPixels(double add) {
    tapDownPosition.pixels += add;
  }

  @override
  CustomScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomScrollPhysics(
      itemDimension: itemDimension,
      viewMode: viewMode,
      tapDownPosition: tapDownPosition,
      parent: buildParent(ancestor),
    );
  }

  double _getPixels(double page) => page * itemDimension;

  double _getTargetPixels(
      ScrollPosition position, Tolerance tolerance, double velocity) {
    final double dayLimit = getViewModeLimitDay(viewMode).toDouble();
    final double startBlock = tapDownPosition.pixels / itemDimension;
    double block = getCurrentBlockIndex(position, itemDimension);

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
    double page = block.roundToDouble();
    page = max((startBlock - dayLimit).roundToDouble(),
        min((startBlock + dayLimit).roundToDouble(), page));

    return _getPixels(page);
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
