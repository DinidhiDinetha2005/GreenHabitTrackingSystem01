import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();

  String? _gender;
  bool _saving = false;
  bool _loading = true;
  String? _error;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get userDoc =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      _email.text = authUser?.email ?? "";

      final snap = await userDoc.get();
      final data = snap.data() ?? {};

      final fname = (data['fname'] ?? data['firstName'] ?? '').toString();
      final lname = (data['lname'] ?? data['lastName'] ?? '').toString();
      final fullName = "$fname $lname".trim();

      _firstName.text = fname;
      _lastName.text = lname;

      _username.text = (data['username'] ?? data['name'] ?? fullName).toString();

      _phone.text = (data['phone'] ?? '').toString();

      _gender = (data['gender'] ?? '').toString().isEmpty
          ? null
          : data['gender'].toString();

      _location.text = (data['location'] ?? '').toString();
    } catch (e) {
      _error = "Failed to load profile details.";
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final authUser = FirebaseAuth.instance.currentUser!;
      final newEmail = _email.text.trim();

      final fname = _firstName.text.trim();
      final lname = _lastName.text.trim();
      final username = _username.text.trim().isNotEmpty
          ? _username.text.trim()
          : "$fname $lname".trim();

      if (newEmail.isNotEmpty && newEmail != authUser.email) {
        await authUser.verifyBeforeUpdateEmail(newEmail);
      }

      await userDoc.set({
        'fname': fname,
        'lname': lname,
        'firstName': fname,
        'lastName': lname,
        'name': "$fname $lname".trim(),
        'username': username,
        'phone': _phone.text.trim(),
        'gender': _gender ?? '',
        'location': _location.text.trim(),
        'email': newEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? e.code);
    } catch (e) {
      setState(() => _error = "Something went wrong while saving.");
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _username.dispose();
    _email.dispose();
    _phone.dispose();
    _location.dispose();
    super.dispose();
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
          icon: const Icon(Icons.arrow_back, color: textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: green))
          : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 52,
                    backgroundImage: NetworkImage(
                      "https://avatarfiles.alphacoders.com/375/thumb-350-375331.webp",
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    "Update your personal details",
                    style: TextStyle(
                      fontSize: 15,
                      color: textSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 24),

                  _ModernField(
                    label: "First Name",
                    controller: _firstName,
                  ),

                  const SizedBox(height: 14),

                  _ModernField(
                    label: "Last Name",
                    controller: _lastName,
                  ),

                  const SizedBox(height: 14),

                  _ModernField(
                    label: "Username",
                    controller: _username,
                  ),

                  const SizedBox(height: 14),

                  _ModernField(
                    label: "Email",
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 14),

                  _ModernField(
                    label: "Phone Number",
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 14),

                  _ModernDropdown(
                    label: "Gender",
                    value: _gender,
                    onChanged: (value) {
                      setState(() => _gender = value);
                    },
                  ),

                  const SizedBox(height: 14),

                  _ModernField(
                    label: "Location",
                    controller: _location,
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Save Changes",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _ModernField({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2E6B3F);
    const lightGreen = Color(0xFFDFF2D8);
    const textDark = Color(0xFF1E1E2D);
    const textSoft = Color(0xFF6B8E6B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: textSoft,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: textDark,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: lightGreen.withOpacity(0.45),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: green, width: 1.3),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModernDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _ModernDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2E6B3F);
    const lightGreen = Color(0xFFDFF2D8);
    const textDark = Color(0xFF1E1E2D);
    const textSoft = Color(0xFF6B8E6B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: textSoft,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: lightGreen.withOpacity(0.45),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
          dropdownColor: Colors.white,
          style: const TextStyle(
            color: textDark,
            fontWeight: FontWeight.w600,
          ),
          items: const [
            DropdownMenuItem(value: "Male", child: Text("Male")),
            DropdownMenuItem(value: "Female", child: Text("Female")),
            DropdownMenuItem(value: "Other", child: Text("Other")),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}