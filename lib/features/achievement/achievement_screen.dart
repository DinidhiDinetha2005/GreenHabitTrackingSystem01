import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen>
    with SingleTickerProviderStateMixin {
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get userDoc =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> get completions =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('completions');

  late ConfettiController _confettiController;
  late AnimationController _popController;
  late Animation<double> _popAnimation;

  String _dayKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _startOfWeek(DateTime d) =>
      _startOfDay(d).subtract(Duration(days: d.weekday - 1));

  DateTime _startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  Stream<QuerySnapshot<Map<String, dynamic>>> _completionsStream() {
    final now = DateTime.now();
    final from = _startOfDay(now.subtract(const Duration(days: 90)));
    return completions
        .where('dayKey', isGreaterThanOrEqualTo: _dayKey(from))
        .orderBy('dayKey', descending: false)
        .snapshots();
  }

  String _tokenFor(double kg) {
    if (kg < 10) return "Nice";
    if (kg >= 10 && kg < 50) return "Best";
    if (kg >= 50 && kg < 100) return "Brilliant";
    if (kg >= 100 && kg <= 500) return "Awesome";
    if (kg > 500) return "Legend";
    return "Nice";
  }

  @override
  void initState() {
    super.initState();

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _popAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.9, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.12, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_popController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _popController.forward(from: 0);
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF3F7EC);
    const green = Color(0xFF2E6B3F);
    const accent = Color(0xFF8EBB67);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Achievement",
          style: TextStyle(
            fontFamily: "Poppins",
            color: green,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            fontSize: 24,
          ),
        ),
      ),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 25,
              gravity: 0.18,
              shouldLoop: false,
              maxBlastForce: 18,
              minBlastForce: 8,
            ),
          ),
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: userDoc.snapshots(),
            builder: (context, userSnap) {
              final user = FirebaseAuth.instance.currentUser;
              final udata = userSnap.data?.data();

              final name =
              (udata?['name']?.toString().trim().isNotEmpty ?? false)
                  ? udata!['name'].toString()
                  : (user?.displayName?.trim().isNotEmpty ?? false)
                  ? user!.displayName!
                  : (user?.email != null
                  ? user!.email!.split("@").first
                  : "User");

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _completionsStream(),
                builder: (context, compSnap) {
                  if (userSnap.connectionState == ConnectionState.waiting ||
                      compSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (userSnap.hasError) {
                    return Center(child: Text("User Error: ${userSnap.error}"));
                  }

                  if (compSnap.hasError) {
                    return Center(
                      child: Text("Progress Error: ${compSnap.error}"),
                    );
                  }

                  final docs = compSnap.data?.docs ?? [];

                  final Map<String, double> dayTotals = {};
                  for (final d in docs) {
                    final m = d.data();
                    final key = (m['dayKey'] ?? d.id).toString();
                    final v = m['totalOxygenKg'] ?? 0;
                    final val = (v is num) ? v.toDouble() : 0.0;
                    dayTotals[key] = val;
                  }

                  final now = DateTime.now();

                  final todayKey = _dayKey(now);
                  final dailyKg = dayTotals[todayKey] ?? 0.0;

                  final startW = _startOfWeek(now);
                  double weeklyKg = 0.0;
                  for (int i = 0; i < 7; i++) {
                    final key = _dayKey(startW.add(Duration(days: i)));
                    weeklyKg += (dayTotals[key] ?? 0.0);
                  }

                  final startM = _startOfMonth(now);
                  final endM = (startM.month == 12)
                      ? DateTime(startM.year + 1, 1, 1)
                      : DateTime(startM.year, startM.month + 1, 1);

                  double monthlyKg = 0.0;
                  final daysInMonth = endM.difference(startM).inDays;
                  for (int i = 0; i < daysInMonth; i++) {
                    final key = _dayKey(startM.add(Duration(days: i)));
                    monthlyKg += (dayTotals[key] ?? 0.0);
                  }

                  final token = _tokenFor(monthlyKg);

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
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              AnimatedBuilder(
                                animation: _popAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _popAnimation.value,
                                    child: child,
                                  );
                                },
                                child: Container(
                                  height: 100,
                                  width: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: accent.withOpacity(0.18),
                                    border: Border.all(
                                      color: accent,
                                      width: 3,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.emoji_events_rounded,
                                    size: 46,
                                    color: green,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: "Poppins",
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Congratulations! You’ve levelled up!",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: "Poppins",
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: green,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  token,
                                  style: const TextStyle(
                                    fontFamily: "Poppins",
                                    fontWeight: FontWeight.w700,
                                    color: green,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          "Your Progress",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: "Daily",
                                value: "${dailyKg.toStringAsFixed(2)} kg",
                                icon: Icons.today_rounded,
                                accent: accent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: "Weekly",
                                value: "${weeklyKg.toStringAsFixed(2)} kg",
                                icon: Icons.date_range_rounded,
                                accent: accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _StatCard(
                          title: "Monthly",
                          value: "${monthlyKg.toStringAsFixed(2)} kg",
                          icon: Icons.calendar_month_rounded,
                          accent: accent,
                          wide: true,
                        ),
                        const SizedBox(height: 26),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "Daily Motivation",
                                style: TextStyle(
                                  fontFamily: "Poppins",
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: green,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Tap below to see today’s surprise quote 💚",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: "Poppins",
                                  color: Colors.black.withOpacity(0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: 150,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () => _showSurpriseQuote(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: green,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: const Text(
                                    "Surprise",
                                    style: TextStyle(
                                      fontFamily: "Poppins",
                                      fontSize: 16,
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
              );
            },
          ),
        ],
      ),
    );
  }
}

String _dailyQuote() {
  const quotes = [
    "Every small habit makes a big difference 🌿",
    "Today’s effort is tomorrow’s cleaner planet 🌍",
    "Keep going — consistency creates change 💚",
    "You’re not just saving oxygen, you’re building a future ✨",
    "Small steps, strong impact — you’ve got this 🌱",
    "Your habits inspire others. Lead by example 🌟",
    "One green choice at a time — progress matters ✅",
    "Stay proud. Stay green. Keep growing 🌿",
  ];

  final dayNumber = int.parse(DateFormat("yyyyMMdd").format(DateTime.now()));
  return quotes[dayNumber % quotes.length];
}

void _showSurpriseQuote(BuildContext context) {
  final quote = _dailyQuote();
  final heartController = ConfettiController(
    duration: const Duration(seconds: 2),
  );

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Quote",
    barrierColor: Colors.black.withOpacity(0.35),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, anim1, anim2) {
      heartController.play();

      return Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: heartController,
              blastDirection: pi / 2,
              emissionFrequency: 0.12,
              numberOfParticles: 35,
              maxBlastForce: 18,
              minBlastForce: 8,
              gravity: 0.18,
              shouldLoop: false,
              colors: const [
                Colors.pink,
                Colors.red,
                Color(0xFFFF6FAF),
                Color(0xFFFF8FB1),
              ],
              createParticlePath: drawHeart,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 22),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDAF390),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 24,
                      offset: const Offset(0, 14),
                      color: Colors.black.withOpacity(0.25),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite,
                      size: 34,
                      color: Colors.pink,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      quote,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E6B3F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          heartController.dispose();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Close",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
    transitionBuilder: (ctx, anim1, anim2, child) {
      final curved = Curves.easeOutBack.transform(anim1.value);
      return Transform.scale(
        scale: 0.9 + (0.1 * curved),
        child: Opacity(
          opacity: anim1.value,
          child: child,
        ),
      );
    },
  ).then((_) {
    heartController.dispose();
  });
}

Path drawHeart(Size size) {
  final Path path = Path();
  final double width = size.width;
  final double height = size.height;

  path.moveTo(width / 2, height * 0.9);
  path.cubicTo(
    width * 1.2,
    height * 0.6,
    width * 0.8,
    height * 0.1,
    width / 2,
    height * 0.3,
  );
  path.cubicTo(
    width * 0.2,
    height * 0.1,
    -width * 0.2,
    height * 0.6,
    width / 2,
    height * 0.9,
  );

  path.close();
  return path;
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accent;
  final bool wide;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2E6B3F);

    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: green, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}