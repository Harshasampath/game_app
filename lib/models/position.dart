class Position {
  double x;
  double y;

  Position(this.x, this.y);

  Position copyWith({
    double? x,
    double? y,
  }) {
    return Position(
      x ?? this.x,
      y ?? this.y,
    );
  }
}