import 'package:flutter/material.dart';
import 'package:kpz_core/models/workout.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutStatsScreen extends StatelessWidget {
  const WorkoutStatsScreen({super.key, required this.workout});

  final Workout workout;

  // Helper function to format duration
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  // Helper widget/method to build individual temperature sections
  Widget _buildTemperatureSection(
    BuildContext context, {
    required String title,
    required List<double> tempData,
    required List<DateTime> timestamps,
    required Color lineColor,
  }) {
    if (tempData.isEmpty || timestamps.length != tempData.length) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Text('No data available.'),
          const SizedBox(height: 20),
        ],
      );
    }

    double avgTemp = 0, minTemp = 0, maxTemp = 0;
    if (tempData.isNotEmpty) {
      avgTemp = tempData.reduce((a, b) => a + b) / tempData.length;
      minTemp = tempData.reduce(min);
      maxTemp = tempData.reduce(max);
    }

    double? firstTimestampEpochMs =
        timestamps.isNotEmpty
            ? timestamps.first.millisecondsSinceEpoch.toDouble()
            : null;
    double? lastTimestampEpochMs =
        timestamps.isNotEmpty
            ? timestamps.last.millisecondsSinceEpoch.toDouble()
            : null;

    List<FlSpot> spots =
        timestamps.asMap().entries.map((entry) {
          int index = entry.key;
          DateTime timestamp = entry.value;
          return FlSpot(
            timestamp.millisecondsSinceEpoch.toDouble(),
            tempData[index],
          );
        }).toList();

    // Define chart's Y display range first
    final double chartMinY = tempData.isNotEmpty ? minTemp - 1 : 0;
    final double chartMaxY =
        tempData.isNotEmpty
            ? maxTemp + 1
            : (tempData.isEmpty ? 1 : minTemp + 1);

    // Calculate interval for Y-axis (left titles) - aiming for ~4 labels
    double? leftTitleInterval;
    if (tempData.isNotEmpty) {
      if (maxTemp > minTemp) {
        leftTitleInterval = (maxTemp - minTemp) / 3.0; // 3 intervals = 4 labels
        if (leftTitleInterval == 0)
          leftTitleInterval = null; // Should not happen if maxTemp > minTemp
      } else {
        // minTemp == maxTemp, or only one data point
        leftTitleInterval =
            null; // Let FLChart show the single value or default
      }
    } else {
      leftTitleInterval = null; // No data, no interval
    }

    // Calculate X-axis range (minX, maxX) and title interval for 5 labels
    double firstTickX, lastTickX;
    double calculatedBottomTitleInterval;

    const double artificialTimespanMs = 60000.0; // 60 seconds
    const int numberOfIntervals =
        4; // For 5 labels (e.g., min, Q1, Q2, Q3, max)

    bool needsArtificialTimespan =
        timestamps.isEmpty ||
        timestamps.length == 1 ||
        (firstTimestampEpochMs != null &&
            lastTimestampEpochMs != null &&
            firstTimestampEpochMs == lastTimestampEpochMs);

    if (needsArtificialTimespan) {
      final double centerTimeMs =
          timestamps.isEmpty
              ? DateTime.now().millisecondsSinceEpoch.toDouble()
              : timestamps.first.millisecondsSinceEpoch.toDouble();
      firstTickX = centerTimeMs - (artificialTimespanMs / 2.0);
      lastTickX = centerTimeMs + (artificialTimespanMs / 2.0);
    } else {
      // Timestamps has at least two distinct values
      firstTickX = firstTimestampEpochMs!;
      lastTickX = lastTimestampEpochMs!;

      if (lastTickX <= firstTickX) {
        final double centerTimeMs = firstTickX;
        firstTickX = centerTimeMs - (artificialTimespanMs / 2.0);
        lastTickX = centerTimeMs + (artificialTimespanMs / 2.0);
      }
    }

    calculatedBottomTitleInterval =
        (lastTickX - firstTickX) / numberOfIntervals;

    if (calculatedBottomTitleInterval <= 0) {
      final nowMs = DateTime.now().millisecondsSinceEpoch.toDouble();
      firstTickX = nowMs - (artificialTimespanMs / 2.0);
      lastTickX = nowMs + (artificialTimespanMs / 2.0);
      calculatedBottomTitleInterval = artificialTimespanMs / numberOfIntervals;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          '${avgTemp.toStringAsFixed(1)} °C',
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Min: ${minTemp.toStringAsFixed(1)} °C'),
            Text('Max: ${maxTemp.toStringAsFixed(1)} °C'),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          // Explicitly size the chart
          height: 200, // Give a fixed height to each chart
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    interval: leftTitleInterval, // Use calculated interval
                    getTitlesWidget: (value, meta) {
                      // Respect chart bounds. FLChart might sometimes call with values outside.
                      if (value < chartMinY || value > chartMaxY)
                        return Container();

                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 4,
                        child: Text(
                          value.toStringAsFixed(
                            (leftTitleInterval != null &&
                                    leftTitleInterval < 1.0 &&
                                    leftTitleInterval != 0)
                                ? 1
                                : 0,
                          ),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    interval:
                        calculatedBottomTitleInterval, // Use calculated interval
                    getTitlesWidget: (value, meta) {
                      const double toleranceForEpochMs = 1.0; // 1ms tolerance

                      for (int i = 0; i <= numberOfIntervals; i++) {
                        double targetPoint =
                            firstTickX + (i * calculatedBottomTitleInterval);
                        // Ensure calculatedBottomTitleInterval is not zero to avoid infinite loop or division by zero if numberOfIntervals is 0 but targetPoint could still be valid (firstTickX)
                        if (calculatedBottomTitleInterval > 0 &&
                            (value - targetPoint).abs() < toleranceForEpochMs) {
                          final dateTime = DateTime.fromMillisecondsSinceEpoch(
                            value.round(),
                          );
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 4,
                            child: Text(
                              DateFormat('HH:mm').format(dateTime),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        } else if (calculatedBottomTitleInterval == 0 &&
                            i == 0 &&
                            (value - firstTickX).abs() < toleranceForEpochMs) {
                          // Handle case where interval is 0 (e.g. single data point, artificial span with 1 label target)
                          // Only show the first label at firstTickX
                          final dateTime = DateTime.fromMillisecondsSinceEpoch(
                            value.round(),
                          );
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 4,
                            child: Text(
                              DateFormat('HH:mm').format(dateTime),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                      }
                      return Container(); // Don't show title if not one of the target points
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: lineColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
              minX: firstTickX,
              maxX: lastTickX,
              minY: chartMinY,
              maxY: chartMaxY,
              extraLinesData: ExtraLinesData(
                // Add this to handle single data point case better for X-axis
                horizontalLines: [
                  HorizontalLine(
                    y: avgTemp,
                    color: Colors.grey.withOpacity(0.5),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ],
              ),
              lineTouchData: LineTouchData(
                // Optional: Add tooltips
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      final flSpot = barSpot;
                      final timestamp = DateTime.fromMillisecondsSinceEpoch(
                        flSpot.x.toInt(),
                      );
                      return LineTooltipItem(
                        '${flSpot.y.toStringAsFixed(1)} °C\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: DateFormat('HH:mm:ss').format(timestamp),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontWeight: FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30), // Spacing between chart sections
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Original print statements, remove if not needed for debugging
    // print(workout.timestamps.length);
    // print(workout.coreTempData.length);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Workout Stats',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDeleteWorkout(context),
            tooltip: 'Delete Workout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        // Make the column scrollable
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Display Workout Duration
            if (workout.duration != Duration.zero) ...[
              const Text(
                'Workout Duration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                _formatDuration(workout.duration),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),
            ],

            _buildTemperatureSection(
              context,
              title: 'Core Body Temperature',
              tempData: workout.coreTempData,
              timestamps: workout.timestamps,
              lineColor: Colors.green,
            ),
            _buildTemperatureSection(
              context,
              title: 'Skin Temperature',
              tempData: workout.skinTempData,
              timestamps: workout.timestamps,
              lineColor: Colors.orange,
            ),
            _buildTemperatureSection(
              context,
              title: 'Ambient Temperature',
              tempData: workout.ambientTempData,
              timestamps: workout.timestamps,
              lineColor: Colors.purple,
            ),
            // Fallback if all data is empty (optional, as individual sections handle empty data)
            if (workout.coreTempData.isEmpty &&
                workout.skinTempData.isEmpty &&
                workout.ambientTempData.isEmpty)
              const Center(
                child: Text('No workout data available to display charts.'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteWorkout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Workout?'),
          content: const Text('Are you sure you want to delete this workout? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false); // User cancelled
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop(true); // User confirmed
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteWorkoutFromPrefs(context);
    }
  }

  Future<void> _deleteWorkoutFromPrefs(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final workoutsStringList = prefs.getStringList('workouts') ?? [];

    List<String> updatedWorkoutsStringList = [];
    bool found = false;

    for (final workoutString in workoutsStringList) {
      final storedWorkout = Workout.fromJsonString(workoutString);
      // Assuming timestamps.first and duration together are unique enough
      if (storedWorkout.timestamps.isNotEmpty &&
          workout.timestamps.isNotEmpty &&
          storedWorkout.timestamps.first == workout.timestamps.first &&
          storedWorkout.duration == workout.duration) {
        found = true;
        // Skip adding this workout to the new list, effectively deleting it
      } else {
        updatedWorkoutsStringList.add(workoutString);
      }
    }

    if (found) {
      await prefs.setStringList('workouts', updatedWorkoutsStringList);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout deleted successfully')),
        );
        Navigator.of(context).pop(true); // Pop screen and signal deletion
      }
    } else {
       if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find workout to delete')),
        );
      }
    }
  }
}
