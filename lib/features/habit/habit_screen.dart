import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HabitScreen extends StatefulWidget {
  const HabitScreen({super.key});

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  final _habitName = TextEditingController();

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get habits =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('habits');

  DateTime _selectedDate = DateTime.now();

  late final List<double> _kgValues;
  late final PageController _kgController;

  double _selectedKg = 0.4;

  @override
  void initState() {
    super.initState();

    final values = List.generate(10, (i) => (i + 1) / 10.0).toList();
    values.add(0.12);

    _kgValues = values.toSet().toList()..sort();

    final initialIndex = _closestIndex(_kgValues, 0.4);
    _selectedKg = _kgValues[initialIndex];

    _kgController = PageController(
      viewportFraction: 0.35,
      initialPage: initialIndex,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recalculateTotalsForDate(_selectedDate);
    });
  }

  String _dayKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  DocumentReference<Map<String, dynamic>> completionDocForDate(DateTime date) {
    final dayKey = _dayKey(date);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('completions')
        .doc(dayKey);
  }

  int _closestIndex(List<double> list, double target) {
    var bestIndex = 0;
    var bestDiff = (list[0] - target).abs();
    for (int i = 1; i < list.length; i++) {
      final diff = (list[i] - target).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  void _changeDay(int offset) {
    setState(() {
      _selectedDate = _startOfDay(_selectedDate.add(Duration(days: offset)));
    });
  }

  Future<void> _addHabit() async {
    final name = _habitName.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a habit name")),
      );
      return;
    }

    try {
      await habits.add({
        'name': name,
        'oxygenKgPerCompletion': _selectedKg,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _habitName.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Habit added successfully")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add habit: $e")),
      );
    }
  }

  Future<void> _toggleDoneForSelectedDate({
    required String habitId,
    required bool current,
  }) async {
    final docRef = completionDocForDate(_selectedDate);
    final newValue = !current;

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      final data = snap.data() ?? {};

      final habitsDone = Map<String, dynamic>.from(data['habitsDone'] ?? {});
      habitsDone[habitId] = newValue;

      tx.set(
        docRef,
        {
          'dayKey': _dayKey(_selectedDate),
          'habitsDone': habitsDone,
          'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    await _recalculateTotalsForDate(_selectedDate);
  }

  Future<void> _recalculateTotalsForDate(DateTime date) async {
    final docRef = completionDocForDate(date);
    final snap = await docRef.get();
    final data = snap.data() ?? {};
    final habitsDone = Map<String, dynamic>.from(data['habitsDone'] ?? {});
    final habitSnap = await habits.get();

    double oxygenTotal = 0.0;
    int completedCount = 0;

    for (final h in habitSnap.docs) {
      final habitData = h.data();

      final isActive = (habitData['isActive'] ?? true) == true;
      if (!isActive) continue;

      final isDone = (habitsDone[h.id] ?? false) == true;
      if (!isDone) continue;

      final o2 = habitData['oxygenKgPerCompletion'] ?? 0.0;
      final o2Double = (o2 is num) ? o2.toDouble() : 0.0;

      oxygenTotal += o2Double;
      completedCount++;
    }

    await docRef.set(
      {
        'dayKey': _dayKey(date),
        'totalOxygenKg': oxygenTotal,
        'completedCount': completedCount,
        'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _archiveHabit(String habitId) async {
    await habits.doc(habitId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _recalculateTotalsForDate(_selectedDate);
  }

  Future<bool> _confirmDelete(BuildContext context, String habitName) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete habit?"),
        content: Text("Are you sure you want to delete '$habitName'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  @override
  void dispose() {
    _habitName.dispose();
    _kgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const deepGreen = Color(0xFF2E6B3F);

    final selectedDoc = completionDocForDate(_selectedDate);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Habits',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              "https://plus.unsplash.com/premium_photo-1664637350982-18512d9d0333?w=700&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8ODU4fHxncmVlbiUyMGZvcmVzdHxlbnwwfHwwfHx8MA%3D%3D",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.45),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.80),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => _changeDay(-1),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                DateFormat('EEE, dd MMM yyyy').format(_selectedDate),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isToday(_selectedDate) ? "Today" : "Saved day record",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                  color: Colors.black.withOpacity(0.6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _isToday(_selectedDate) ? null : () => _changeDay(1),
                          icon: Icon(
                            Icons.chevron_right,
                            color: _isToday(_selectedDate) ? Colors.grey : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _habitName,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            color: Colors.white,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'New habit (e.g., Reusable bottle)',
                            labelStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: deepGreen,
                        ),
                        onPressed: _addHabit,
                        child: const Text(
                          'Add',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Select O₂ saved per completion:",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  SizedBox(
                    height: 40,
                    child: PageView.builder(
                      controller: _kgController,
                      itemCount: _kgValues.length,
                      onPageChanged: (index) {
                        setState(() => _selectedKg = _kgValues[index]);
                      },
                      itemBuilder: (context, index) {
                        final v = _kgValues[index];
                        final isSelected = v == _selectedKg;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? deepGreen
                                : Colors.white.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Center(
                            child: Text(
                              "${v.toStringAsFixed(2)} kg",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w800,
                                color: isSelected ? Colors.white : Colors.black87,
                                fontSize: isSelected ? 18 : 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    "Selected: ${_selectedKg.toStringAsFixed(2)} kg",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Poppins',
                    ),
                  ),

                  const SizedBox(height: 16),

                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: selectedDoc.snapshots(),
                    builder: (context, snap) {
                      final data = snap.data?.data() ?? {};
                      final totalOxygenKg = data['totalOxygenKg'] ?? 0;
                      final total = (totalOxygenKg is num) ? totalOxygenKg.toDouble() : 0.0;

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Oxygen Saved: ${total.toStringAsFixed(2)} kg",
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Saved for ${DateFormat('dd MMM yyyy').format(_selectedDate)}",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Colors.black.withOpacity(0.65),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: habits.snapshots(),
                      builder: (context, habitSnap) {
                        if (habitSnap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (habitSnap.hasError) {
                          return Center(child: Text('Error: ${habitSnap.error}'));
                        }

                        final allDocs = habitSnap.data?.docs ?? [];

                        final habitDocs = allDocs.where((d) {
                          final data = d.data();
                          return (data['isActive'] ?? true) == true;
                        }).toList();

                        habitDocs.sort((a, b) {
                          final aTime = a.data()['createdAt'];
                          final bTime = b.data()['createdAt'];

                          if (aTime == null && bTime == null) return 0;
                          if (aTime == null) return 1;
                          if (bTime == null) return -1;

                          return (bTime as Timestamp).compareTo(aTime as Timestamp);
                        });

                        if (habitDocs.isEmpty) {
                          return const Center(
                            child: Text(
                              'No habits yet. Add one above!',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          );
                        }

                        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: selectedDoc.snapshots(),
                          builder: (context, selectedSnap) {
                            final selectedData = selectedSnap.data?.data() ?? {};
                            final habitsDone = Map<String, dynamic>.from(
                              selectedData['habitsDone'] ?? {},
                            );

                            return ListView.separated(
                              itemCount: habitDocs.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final d = habitDocs[i];
                                final data = d.data();

                                final name = (data['name'] ?? '').toString();
                                final o2 = data['oxygenKgPerCompletion'] ?? 0.0;
                                final o2Double = (o2 is num) ? o2.toDouble() : 0.0;

                                final doneForSelectedDate = (habitsDone[d.id] ?? false) == true;

                                return Dismissible(
                                  key: ValueKey(d.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    color: Colors.red,
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  confirmDismiss: (_) => _confirmDelete(context, name),
                                  onDismissed: (_) async {
                                    await _archiveHabit(d.id);
                                  },
                                  child: ListTile(
                                    title: Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Poppins',
                                        color: Colors.white,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "O₂ per completion: ${o2Double.toStringAsFixed(2)} kg",
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    leading: Checkbox(
                                      value: doneForSelectedDate,
                                      onChanged: (_) async {
                                        await _toggleDoneForSelectedDate(
                                          habitId: d.id,
                                          current: doneForSelectedDate,
                                        );
                                      },
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.white,
                                      ),
                                      onPressed: () async {
                                        final ok = await _confirmDelete(context, name);
                                        if (!ok) return;
                                        await _archiveHabit(d.id);
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}