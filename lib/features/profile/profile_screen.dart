import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get userDoc =>
      FirebaseFirestore.instance.collection('users').doc(uid);


  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Log Out"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          "/auth",
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFEAF3DF);
    const green = Color(0xFF2E6B3F);
    const lightGreen = Color(0xFFDFF2D8);
    const textDark = Color(0xFF1E1E2D);
    const textSoft = Color(0xFF6B8E6B);
    const cardColor = Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Profile",
          style: TextStyle(
            color: green,
            fontWeight: FontWeight.w800,
            fontFamily: "Poppins",
            fontSize: 22,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userDoc.snapshots(),
        builder: (context, snap) {
          final authUser = FirebaseAuth.instance.currentUser;
          final data = snap.data?.data() ?? {};

          final firstName =
          (data['fname'] ?? data['firstName'] ?? '').toString().trim();

          final lastName =
          (data['lname'] ?? data['lastName'] ?? '').toString().trim();

          final fullName = [firstName, lastName]
              .where((e) => e.isNotEmpty)
              .join(' ')
              .trim();

          final username =
          (data['username'] ?? data['name'] ?? fullName).toString().trim();

          final email =
          (authUser?.email ?? data['email'] ?? '').toString().trim();

          final phone = (data['phone'] ?? '').toString().trim();
          final location = (data['location'] ?? '').toString().trim();

          final displayName = username.isNotEmpty
              ? username
              : fullName.isNotEmpty
              ? fullName
              : "User";

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: lightGreen, width: 5),
                      ),
                      child: const CircleAvatar(
                        radius: 52,
                        backgroundImage: NetworkImage(
                          "https://avatarfiles.alphacoders.com/375/thumb-350-375331.webp",
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),

                    const SizedBox(height: 8),

                    InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        Navigator.pushNamed(context, "/editProfile");
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: lightGreen,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          "Edit Profile",
                          style: TextStyle(
                            color: green,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    _DetailRow(
                      icon: Icons.person_outline_rounded,
                      label: "First Name",
                      value: firstName.isNotEmpty ? firstName : "Not added",
                    ),

                    const SizedBox(height: 14),

                    _DetailRow(
                      icon: Icons.person_outline_rounded,
                      label: "Last Name",
                      value: lastName.isNotEmpty ? lastName : "Not added",
                    ),

                    const SizedBox(height: 14),

                    _DetailRow(
                      icon: Icons.badge_outlined,
                      label: "Username",
                      value: username.isNotEmpty ? username : "Not added",
                    ),

                    const SizedBox(height: 14),

                    _DetailRow(
                      icon: Icons.email_outlined,
                      label: "Email",
                      value: email.isNotEmpty ? email : "Not added",
                    ),

                    const SizedBox(height: 14),

                    _DetailRow(
                      icon: Icons.call_outlined,
                      label: "Phone Number",
                      value: phone.isNotEmpty ? phone : "Not added",
                    ),

                    const SizedBox(height: 14),

                    _DetailRow(
                      icon: Icons.location_on_outlined,
                      label: "Location",
                      value: location.isNotEmpty ? location : "Not added",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: _ProfileMenuTile(
                  icon: Icons.logout_rounded,
                  iconColor: Colors.redAccent,
                  label: "Log Out",
                  labelColor: Colors.redAccent,
                  onTap: () => _confirmLogout(context),
                ),
              ),

              const SizedBox(height: 24),

              const Center(
                child: Text(
                  "Your profile details are saved securely",
                  style: TextStyle(
                    color: textSoft,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2E6B3F);
    const textDark = Color(0xFF1E1E2D);
    const textSoft = Color(0xFF6B8E6B);
    const lightGreen = Color(0xFFDFF2D8);

    return Row(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: textSoft)),
              Text(
                value,
                style: const TextStyle(
                  color: textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;

  const _ProfileMenuTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: labelColor,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}