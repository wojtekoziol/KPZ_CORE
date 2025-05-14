class Workout {
  List<DateTime> timestamps = [];
  List<int> heartRateData = [];
  List<double> skinTempData = [];
  List<double> ambientTempData = [];
  List<double> coreTempData = [];

  Duration duration = Duration.zero;

  void addDataEntry({
    required DateTime timestamp,
    required int heartRate,
    required double skinTemp,
    required double ambientTemp,
    required double coreTemp,
  }) {
    timestamps.add(timestamp);
    heartRateData.add(heartRate);
    skinTempData.add(skinTemp);
    ambientTempData.add(ambientTemp);
    coreTempData.add(coreTemp);
  }

  void finish(Duration duration) {
    this.duration = duration;

    // TODO: Save workout item
  }
}
