enum ViewMode {
  weekly,
  monthly;

  int get dayCount {
    switch (this) {
      case ViewMode.weekly:
        return 7;
      case ViewMode.monthly:
        return 31;
    }
  }
}
