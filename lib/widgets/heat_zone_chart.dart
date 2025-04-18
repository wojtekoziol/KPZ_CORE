import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kpz_core/controllers/workout_controller.dart';
import 'package:kpz_core/widgets/widget_size.dart';

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
              Text(
                'Heat Zones',
                style: TextStyle(fontSize: 14, color: Color(0xFFD8D8D8)),
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
}
