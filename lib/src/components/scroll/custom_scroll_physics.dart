import 'dart:math';

import 'package:flutter/material.dart';
import '../view_mode.dart';

const double _kPivotVelocity = 240.0;

class ScrollPhysicsState {
  ScrollPhysicsState({required this.dayCount});

  double pixels = 0.0;
  int dayCount;
}

class CustomScrollPhysics extends ScrollPhysics {
  const CustomScrollPhysics({
    required this.blockWidth,
    required this.viewMode,
    required this.scrollPhysicsState,
    ScrollPhysics? parent,
  }) : super(parent: parent);

  final double blockWidth;
  final ViewMode viewMode;
  final ScrollPhysicsState scrollPhysicsState;

  void setPanDownPixels(double pixels) {
    scrollPhysicsState.pixels = pixels;
  }

  void addPanDownPixels(double add) {
    scrollPhysicsState.pixels += add;
  }

  void setDayCount(int dayCount) {
    scrollPhysicsState.dayCount = dayCount;
  }

  double get _maxPosition {
    var maxPosition =
        scrollPhysicsState.dayCount.toDouble() - getViewModeLimitDay(viewMode);
    return max(0.0, maxPosition);
  }

  @override
  CustomScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomScrollPhysics(
      blockWidth: blockWidth,
      viewMode: viewMode,
      scrollPhysicsState: scrollPhysicsState,
      parent: buildParent(ancestor),
    );
  }

  double _getPixels(double blockPosition) => blockPosition * blockWidth;

  double _getTargetPixels(
      ScrollPosition position, Tolerance tolerance, double velocity) {
    final double dayLimit = getViewModeLimitDay(viewMode).toDouble();
    final double startBlock = scrollPhysicsState.pixels / blockWidth;
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
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final Tolerance tolerance = this.tolerance;
    final double target =
        _getTargetPixels(position as ScrollPosition, tolerance, velocity);
    if (target != position.pixels) {
      return ScrollSpringSimulation(spring, position.pixels, target, velocity,
          tolerance: tolerance);
    }
    return null;
  }

  @override
  bool get allowImplicitScrolling => false;
}

double getCurrentBlockIndex(ScrollPosition position, double itemDimension) {
  return position.pixels / itemDimension;
}
