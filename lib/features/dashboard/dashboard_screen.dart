import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _habitName = TextEditingController();
  int _navIndex = 0;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  String get displayName {
    final user = FirebaseAuth.instance.currentUser;
    return (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : (user?.email?.split('@').first ?? 'User');
  }

  CollectionReference<Map<String, dynamic>> get habits =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('habits');

  Future<void> _addHabit() async {
    final name = _habitName.text.trim();
    if (name.isEmpty) return;

    await habits.add({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
      'done': false,
    });

    _habitName.clear();
  }

  Future<void> _toggleDone(String docId, bool current) async {
    await habits.doc(docId).update({'done': !current});
  }


  @override
  void dispose() {
    _habitName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateText = DateFormat("d MMMM, yyyy").format(now); // 19 October, 2025
    final timeText = DateFormat("hh : mm a").format(now);     // 09 : 25 AM

    const bg = Color(0xFFEAF3DF);
    const card = Color(0xFFCBDDBE);
    const deepGreen = Color(0xFF2E6B3F);
    const tileGreen = Color(0xFF7FA243);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text(
          "Dashboard",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24,),

        ),
      ),


      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // =========================
            // Top card (Welcome + image)
            // =========================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        // If you don’t want assets yet, this still works.
                        Image.network(
                          "https://shutterstock.com/image-photo/aerial-top-view-green-trees-260nw-2473897973.jpg",
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          left: 14,
                          top: 18,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Welcome Home",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Date & time row like your prototype
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: tileGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dateText, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(timeText, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // CO2 box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: const Center(
                      child: Text(
                        "Let's Save the Nature",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Small pill / placeholder bar (like your grey bar)
            Container(
              height: 22,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(30),
              ),
            ),

            const SizedBox(height: 10),
            const Text("...", style: TextStyle(fontSize: 20)),
            const SizedBox(height: 12),

            // =========================
            // Icon grid (8 buttons)
            // =========================
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3, // ✅ 3 on top, 3 on bottom
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1, // ✅ makes boxes wider & cleaner
              children: [
                _DashTile(
                  color: tileGreen,
                  label: "Habit",
                  icon: Icons.eco,
                  onTap: () {Navigator.pushNamed(context, "/habit");},
                ),
                _DashTile(
                  color: tileGreen,
                  label: "Progress",
                  icon: Icons.show_chart,
                  onTap: () {Navigator.pushNamed(context, "/progress");},
                ),
                _DashTile(
                  color: tileGreen,
                  label: "Achievement",
                  icon: Icons.emoji_events,
                  onTap: () {Navigator.pushNamed(context, "/achievement");},
                ),
                _DashTile(
                  color: tileGreen,
                  label: "Challanges",
                  icon: Icons.flag,
                  onTap: () {Navigator.pushNamed(context, "/challenges");},
                ),
                _DashTile(
                  color: tileGreen,
                  label: "Reminder",
                  icon: Icons.notifications,
                  onTap: () {Navigator.pushNamed(context, "/reminder");},
                ),
                _DashTile(
                  color: tileGreen,
                  label: "Profile",
                  icon: Icons.person,
                  onTap: () {Navigator.pushNamed(context, "/profile");},
                ),
              ],
            ),

            const SizedBox(height: 18),
          ],
        ),
      ),

    );
  }
}

class _DashTile extends StatelessWidget {
  final Color color;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DashTile({
    required this.color,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon, // 🌿 icon
              color: Colors.white, // icon color
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}