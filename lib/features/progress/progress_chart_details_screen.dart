import 'package:flutter/material.dart';

import 'progress_screen.dart';

class ProgressChartDetailsScreen extends StatelessWidget {
  final RangeMode mode;
  final List<double> values;
  final List<String> labels;

  const ProgressChartDetailsScreen({
    super.key,
    required this.mode,
    required this.values,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF3F7EC);
    const green = Color(0xFF2E6B3F);
    const lineGreen = Color(0xFF86AC43);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          mode == RangeMode.day
              ? "Daily Trend"
              : mode == RangeMode.week
              ? "Weekly Trend"
              : "Monthly Trend",
          style: const TextStyle(
            fontFamily: "Poppins",
            color: green,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 8),
                color: Colors.black.withOpacity(0.04),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Oxygen Saved Trend",
                style: TextStyle(
                  fontFamily: "Poppins",
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "A smoother view of your saved oxygen over time.",
                style: TextStyle(
                  fontFamily: "Poppins",
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _LineChart(
                  values: values,
                  labels: labels,
                  lineColor: lineGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color lineColor;

  const _LineChart({
    required this.values,
    required this.labels,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue =
    values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(values.length, (index) {
              final normalizedHeight =
              maxValue == 0 ? 12.0 : (values[index] / maxValue) * 180;

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      values[index].toStringAsFixed(1),
                      style: const TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 10,
                      height: normalizedHeight < 12 ? 12 : normalizedHeight,
                      decoration: BoxDecoration(
                        color: lineColor.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          height: 16,
                          width: 16,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: lineColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: lineColor.withOpacity(0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      labels[index],
                      style: const TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}