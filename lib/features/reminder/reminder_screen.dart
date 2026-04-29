import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get reminders =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('reminders');

  CollectionReference<Map<String, dynamic>> get habits =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('habits');

  CollectionReference<Map<String, dynamic>> get communityEvents =>
      FirebaseFirestore.instance.collection('community_events');

  Future<void> _addReminderDialog() async {
    final habitSnap = await habits.get();
    final eventSnap = await communityEvents.get();

    final habitDocs = habitSnap.docs;
    final eventDocs = eventSnap.docs;

    if (!mounted) return;

    if (habitDocs.isEmpty && eventDocs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No habits or community events found.")),
      );
      return;
    }

    String reminderType = habitDocs.isNotEmpty ? "habit" : "event";

    String selectedItemId =
    reminderType == "habit" ? habitDocs.first.id : eventDocs.first.id;

    String selectedItemName = reminderType == "habit"
        ? (habitDocs.first.data()['name'] ?? "Habit").toString()
        : (eventDocs.first.data()['title'] ?? "Community Event").toString();

    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);
    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) {
          final currentList = reminderType == "habit" ? habitDocs : eventDocs;

          return AlertDialog(
            title: const Text("Add Reminder"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: reminderType,
                  decoration: const InputDecoration(labelText: "Reminder Type"),
                  items: const [
                    DropdownMenuItem(value: "habit", child: Text("Habit")),
                    DropdownMenuItem(value: "event", child: Text("Community Event")),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    setLocal(() {
                      reminderType = value;

                      final list = reminderType == "habit" ? habitDocs : eventDocs;

                      if (list.isNotEmpty) {
                        selectedItemId = list.first.id;
                        selectedItemName = reminderType == "habit"
                            ? (list.first.data()['name'] ?? "Habit").toString()
                            : (list.first.data()['title'] ?? "Community Event").toString();
                      } else {
                        selectedItemId = "";
                        selectedItemName = "";
                      }
                    });
                  },
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: selectedItemId.isEmpty ? null : selectedItemId,
                  decoration: const InputDecoration(labelText: "Select Item"),
                  items: currentList.map((doc) {
                    final data = doc.data();

                    final name = reminderType == "habit"
                        ? (data['name'] ?? "Habit").toString()
                        : (data['title'] ?? "Community Event").toString();

                    return DropdownMenuItem(
                      value: doc.id,
                      child: SizedBox(
                        width: 200,
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    final found = currentList.firstWhere((doc) => doc.id == value);
                    final data = found.data();

                    setLocal(() {
                      selectedItemId = value;
                      selectedItemName = reminderType == "habit"
                          ? (data['name'] ?? "Habit").toString()
                          : (data['title'] ?? "Community Event").toString();
                    });
                  },
                ),

                const SizedBox(height: 12),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Reminder Date"),
                  subtitle: Text(
                    "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                  ),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );

                    if (picked != null) {
                      setLocal(() => selectedDate = picked);
                    }
                  },
                ),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Reminder Time"),
                  subtitle: Text(selectedTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );

                    if (picked != null) {
                      setLocal(() => selectedTime = picked);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),

              ElevatedButton(
                onPressed: selectedItemId.isEmpty
                    ? null
                    : () async {
                  DateTime reminderDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );

                  if (reminderDateTime.isBefore(DateTime.now())) {
                    reminderDateTime =
                        reminderDateTime.add(const Duration(days: 1));
                  }

                  final doc = await reminders.add({
                    "type": reminderType,
                    "itemId": selectedItemId,
                    "title": selectedItemName,
                    "hour": selectedTime.hour,
                    "minute": selectedTime.minute,
                    "scheduledAt": Timestamp.fromDate(reminderDateTime),
                    "enabled": true,
                    "triggered": false,
                    "unread": false,
                    "createdAt": FieldValue.serverTimestamp(),
                  });

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Reminder added")),
                    );
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleEnabled(String id, bool current) async {
    await reminders.doc(id).update({"enabled": !current});
  }

  Future<void> _deleteReminder(String id) async {
    await reminders.doc(id).delete();
  }

  String _formatTime(int hour, int minute) {
    final t = TimeOfDay(hour: hour, minute: minute);
    return t.format(context);
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFEAF3DF);
    const deepGreen = Color(0xFF70950A);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Reminders",
          style: TextStyle(
              fontWeight: FontWeight.w800,
              color: deepGreen,
              fontFamily: "Poppins",
            ),
        ),
        actions: [
          IconButton(
            onPressed: _addReminderDialog,
            icon: const Icon(Icons.add_alert, color: deepGreen),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: deepGreen,
        onPressed: _addReminderDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Reminder",
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: reminders.orderBy("createdAt", descending: true).snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snap.hasError) {
              return Center(child: Text("Error: ${snap.error}"));
            }

            final docs = snap.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  "No reminders yet.\nTap “Add Reminder” to create one ⏰",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 90),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final doc = docs[i];
                final data = doc.data();

                final type = (data["type"] ?? "habit").toString();
                final title = (data["title"] ?? "").toString();
                final hour = (data["hour"] ?? 8) as int;
                final minute = (data["minute"] ?? 0) as int;
                final enabled = (data["enabled"] ?? true) as bool;
                final notificationId =
                (data["notificationId"] ?? doc.id.hashCode) as int;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 46,
                        width: 46,
                        decoration: BoxDecoration(
                          color: deepGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          type == "habit" ? Icons.eco : Icons.event_available,
                          color: deepGreen,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${type.toUpperCase()} • ${_formatTime(hour, minute)}",
                              style: const TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Switch(
                        value: enabled,
                        onChanged: (_) => _toggleEnabled(
                          doc.id,
                          enabled,
                        ),
                        ),

                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteReminder(
                          doc.id,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}