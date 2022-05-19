enum ViewMode {
  weekly,
  monthly;

  /// Returns the count of blocks in the x-axis direction.
  int get dayCount {
    switch (this) {
      case ViewMode.weekly:
        return 7;
      case ViewMode.monthly:
        return 31;
    }
  }
}
