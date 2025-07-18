import 'position.dart';

class Obstacle {
  Position position;

  Obstacle(this.position);

  void update(double speed) {
    position = position.copyWith(y: position.y + speed);
  }
}