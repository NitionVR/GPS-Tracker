class SpeedCalculator {
  final List<double> _speedBuffer = [];
  final int _bufferSize = 5;

  double calculateSmoothedSpeed(double currentSpeed) {
    _speedBuffer.add(currentSpeed);
    if (_speedBuffer.length > _bufferSize) {
      _speedBuffer.removeAt(0);
    }
    return _speedBuffer.reduce((a, b) => a + b) / _speedBuffer.length;
  }
}
