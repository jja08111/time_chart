enum ViewMode {
  weekly(7),
  monthly(31);

  const ViewMode(this.dayCount);

  final int dayCount;
}
