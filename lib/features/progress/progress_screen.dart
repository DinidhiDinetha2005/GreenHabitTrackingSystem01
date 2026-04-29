import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'progress_chart_details_screen.dart';

enum RangeMode { day, week, month }

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  RangeMode mode = RangeMode.week;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get completions =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('completions');

  String _dayKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _startOfWeek(DateTime d) =>
      _startOfDay(d).subtract(Duration(days: d.weekday - 1));

  DateTime _startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  Stream<QuerySnapshot<Map<String, dynamic>>> get _stream {
    final now = DateTime.now();
    final from = _startOfDay(now.subtract(const Duration(days: 90)));
    return completions
        .where('dayKey', isGreaterThanOrEqualTo: _dayKey(from))
        .orderBy('dayKey', descending: false)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF3F7EC);
    const green = Color(0xFF2E6B3F);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Progress",
          style: TextStyle(
            fontFamily: "Poppins",
            color: green,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            fontSize: 22,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final docs = snapshot.data?.docs ?? [];

          final Map<String, double> dayTotals = {};
          for (final d in docs) {
            final data = d.data();
            final key = (data['dayKey'] ?? d.id).toString();
            final v = data['totalOxygenKg'] ?? 0;
            final val = (v is num) ? v.toDouble() : 0.0;
            dayTotals[key] = val;
          }

          final todayKey = _dayKey(DateTime.now());
          final todayOxygen = dayTotals[todayKey] ?? 0.0;

          final bars = _buildBars(mode, dayTotals);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                        color: Colors.black.withOpacity(0.05),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "See your oxygen saved today",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        todayOxygen > 0
                            ? "You’re doing great today 🌿"
                            : "Complete a habit today to grow your impact 🌱",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _OxygenCircle(value: todayOxygen),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDF5E2),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          todayOxygen > 0 ? "Good job!" : "Start your streak",
                          style: const TextStyle(
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.w700,
                            color: green,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _Segment(
                        mode: mode,
                        onChange: (m) => setState(() => mode = m),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
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
                        "Progress Details",
                        style: TextStyle(
                          fontFamily: "Poppins",
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Tap below to view your oxygen trend in a cleaner chart.",
                        style: TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withOpacity(0.55),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _MiniPreviewRow(
                        values: bars.values,
                        labels: bars.labels,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProgressChartDetailsScreen(
                                  mode: mode,
                                  values: bars.values,
                                  labels: bars.labels,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E6B3F),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            "View Details",
                            style: TextStyle(
                              fontFamily: "Poppins",
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  _BarsResult _buildBars(RangeMode mode, Map<String, double> dayTotals) {
    final now = DateTime.now();

    if (mode == RangeMode.day) {
      final values = <double>[];
      final labels = <String>[];
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        final key = _dayKey(d);
        values.add(dayTotals[key] ?? 0.0);
        labels.add(DateFormat('E').format(d));
      }
      return _BarsResult(values: values, labels: labels);
    }

    if (mode == RangeMode.week) {
      final start = _startOfWeek(now);
      final values = <double>[];
      final labels = <String>[];
      for (int i = 0; i < 7; i++) {
        final d = start.add(Duration(days: i));
        final key = _dayKey(d);
        values.add(dayTotals[key] ?? 0.0);
        labels.add(DateFormat('E').format(d));
      }
      return _BarsResult(values: values, labels: labels);
    }

    final start = _startOfMonth(now);
    final end = (start.month == 12)
        ? DateTime(start.year + 1, 1, 1)
        : DateTime(start.year, start.month + 1, 1);

    final days = end.difference(start).inDays;
    final weeks = (days / 7).ceil();

    final values = List<double>.filled(weeks, 0.0);
    for (int i = 0; i < days; i++) {
      final d = start.add(Duration(days: i));
      final key = _dayKey(d);
      final w = (i / 7).floor();
      values[w] += (dayTotals[key] ?? 0.0);
    }

    final labels = List<String>.generate(weeks, (i) => "W${i + 1}");
    return _BarsResult(values: values, labels: labels);
  }
}

class _BarsResult {
  final List<double> values;
  final List<String> labels;

  _BarsResult({required this.values, required this.labels});
}

class _Segment extends StatelessWidget {
  final RangeMode mode;
  final ValueChanged<RangeMode> onChange;

  const _Segment({required this.mode, required this.onChange});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2E6B3F);

    Widget pill(String text, RangeMode m) {
      final selected = mode == m;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChange(m),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? green : const Color(0xFFF7F7F3),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected ? green : Colors.black12,
              ),
              boxShadow: selected
                  ? [
                BoxShadow(
                  color: green.withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
                  : null,
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: "Poppins",
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        pill("Day", RangeMode.day),
        const SizedBox(width: 10),
        pill("Week", RangeMode.week),
        const SizedBox(width: 10),
        pill("Month", RangeMode.month),
      ],
    );
  }
}

class _OxygenCircle extends StatelessWidget {
  final double value;
  const _OxygenCircle({required this.value});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2E6B3F);
    const accent = Color(0xFF7FA243);

    return Container(
      height: 150,
      width: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF9CC558),
            accent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Container(
          height: 126,
          width: 126,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "O2",
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: green,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${value.toStringAsFixed(2)} kg",
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPreviewRow extends StatelessWidget {
  final List<double> values;
  final List<String> labels;

  const _MiniPreviewRow({
    required this.values,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF86AC43);
    final maxV = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (i) {
          final h = maxV == 0 ? 8.0 : (values[i] / maxV) * 45;

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 10,
                  height: h < 8 ? 8 : h,
                  decoration: BoxDecoration(
                    color: green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[i],
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}