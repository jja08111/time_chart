enum ViewMode {
  weekly,
  monthly,
}

int getViewModeLimitDay(ViewMode viewMode) {
  switch (viewMode) {
    case ViewMode.weekly:
      return 7;
    case ViewMode.monthly:
      return 31;
  }
}
