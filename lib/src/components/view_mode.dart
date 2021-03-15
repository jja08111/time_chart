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
  assert(false, 'wrong type of viewMode');
  return null;
}
