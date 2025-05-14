import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kpz_core/controllers/bluetooth_controller.dart';
import 'package:kpz_core/controllers/workout_controller.dart';
import 'package:kpz_core/widgets/widget_size.dart';
import 'package:provider/provider.dart';

class HeatZoneChart extends StatefulWidget {
  const HeatZoneChart({
    super.key,
    required this.zone1Duration,
    required this.zone2Duration,
    required this.zone3Duration,
  });

  final Duration zone1Duration;
  final Duration zone2Duration;
  final Duration zone3Duration;

  @override
  State<HeatZoneChart> createState() => _HeatZoneChartState();
}

class _HeatZoneChartState extends State<HeatZoneChart> {
  Size mainChartSize = Size.zero;

  Widget _zoneBar({
    required String label,
    required Duration zoneDuration,
    required Color color,
    required Size mainChartSize,
    required BuildContext context,
  }) {
    return Column(
      spacing: 4,
      children: [
        Text(label, style: TextStyle(fontSize: 8, color: Color(0xFFD8D8D8))),
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: mainChartSize.height * 0.7,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),
            AnimatedContainer(
              duration: Duration(seconds: 1),
              curve: Curves.easeInOut,
              height: _calculateBarHeight(
                duration: zoneDuration,
                maxHeight: mainChartSize.height,
              ),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),
          ],
        ),
        Text(WorkoutController.formatElapsedTime(zoneDuration)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WidgetSize(
      onChange: (Size size) {
        setState(() {
          mainChartSize = size;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF232323),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Heat Zones',
                    style: TextStyle(fontSize: 14, color: Color(0xFFD8D8D8)),
                  ),
                  if (context
                              .read<BluetoothController>()
                              .skinTemperatureStream !=
                          null &&
                      context
                              .read<BluetoothController>()
                              .ambientTemperatureStream !=
                          null)
                    StreamBuilder(
                      stream:
                          context
                              .read<BluetoothController>()
                              .skinTemperatureStream,
                      builder: (context, skinTemp) {
                        return StreamBuilder(
                          stream:
                              context
                                  .read<BluetoothController>()
                                  .ambientTemperatureStream,
                          builder: (context, ambientTemp) {
                            return Text(
                              '(${skinTemp.data} / ${ambientTemp.data})',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFFD8D8D8),
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
              Consumer<WorkoutController>(
                builder:
                    (context, controller, child) => Align(
                      alignment: Alignment(
                        _calculateAlignmentX(controller.coreTemp),
                        0,
                      ),
                      child: Icon(
                        Icons.arrow_downward_rounded,
                        color: Color(0xFFD8D8D8),
                      ),
                    ),
              ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 10,
                children: [
                  Expanded(
                    child: _zoneBar(
                      label: 'Chilly',
                      zoneDuration: widget.zone1Duration,
                      color: Colors.blue,
                      mainChartSize: mainChartSize,
                      context: context,
                    ),
                  ),
                  Expanded(
                    child: _zoneBar(
                      label: 'Optimal',
                      zoneDuration: widget.zone2Duration,
                      color: Colors.green,
                      mainChartSize: mainChartSize,
                      context: context,
                    ),
                  ),
                  Expanded(
                    child: _zoneBar(
                      label: 'Overheating',
                      zoneDuration: widget.zone3Duration,
                      color: Colors.red,
                      mainChartSize: mainChartSize,
                      context: context,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateBarHeight({
    required Duration duration,
    required double maxHeight,
  }) {
    return (duration.inSeconds /
            max(
              1,
              [
                widget.zone1Duration.inSeconds,
                widget.zone2Duration.inSeconds,
                widget.zone3Duration.inSeconds,
              ].reduce(max),
            )) *
        maxHeight *
        0.7;
  }

  double _calculateAlignmentX(double temperature) {
    if (temperature <= 36.5) {
      return -1.0;
    } else if (temperature >= 39.5) {
      return 1.0;
    } else if (temperature == 37.0) {
      return -0.375;
    } else if (temperature == 39.0) {
      return 0.375;
    } else if (temperature > 36.5 && temperature < 37.0) {
      // Interpolate between -1.0 (at 36.5) and -0.375 (at 37.0)
      // Temperature range: 37.0 - 36.5 = 0.5
      // Value range: -0.375 - (-1.0) = 0.625
      // Slope = 0.625 / 0.5 = 1.25
      return -1.0 + (temperature - 36.5) * 1.25;
    } else if (temperature > 37.0 && temperature < 39.0) {
      // Interpolate between -0.375 (at 37.0) and 0.375 (at 39.0)
      // Temperature range: 39.0 - 37.0 = 2.0
      // Value range: 0.375 - (-0.375) = 0.75
      // Slope = 0.75 / 2.0 = 0.375
      return -0.375 + (temperature - 37.0) * 0.375;
    } else if (temperature > 39.0 && temperature < 39.5) {
      // Interpolate between 0.375 (at 39.0) and 1.0 (at 39.5)
      // Temperature range: 39.5 - 39.0 = 0.5
      // Value range: 1.0 - 0.375 = 0.625
      // Slope = 0.625 / 0.5 = 1.25
      return 0.375 + (temperature - 39.0) * 1.25;
    }
    // This case should ideally not be reached if the above conditions are exhaustive
    // for the expected input range, but as a fallback:
    return 0.0; // Or throw an error, depending on desired behavior for unexpected values
  }
}
