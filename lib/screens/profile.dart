import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'signup.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String displayName = "";
  String username = "";
  String email = "";
  String phone = "";
  String description = "";
  String location = "";
  ImageProvider<Object>? profileImage;

  bool isEditing = false;

  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> attendingEvents = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadAttendingEvents();
  }

  Future<void> _loadAttendingEvents() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection("users")
        .doc(user.uid)
        .collection("attendingEvents")
        .get();

    if (mounted) {
      setState(() {
        attendingEvents = snapshot.docs.map((d) => d.data()).toList();
      });
    }
  }

  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    email = user.email ?? "";
    displayName = user.displayName ?? "";

    final doc = await _firestore.collection("users").doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      if (mounted) {
        setState(() {
          username = data["username"] ?? "";
          phone = data["phone"] ?? "";
          description = data["description"] ?? "";
          location = data["location"] ?? "";
          if (data["profileImageUrl"] != null) {
            profileImage = NetworkImage(data["profileImageUrl"]);
          }
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection("users").doc(user.uid).set({
      "displayName": displayName,
      "username": username,
      "phone": phone,
      "description": description,
      "location": location,
    }, SetOptions(merge: true));

    await user.updateDisplayName(displayName);

    setState(() => isEditing = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Profile updated!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              setState(() => isEditing = !isEditing);
            },
            child: Text(
              isEditing ? "Cancel" : "Edit",
              style: const TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 24),

              _sectionTitle("Personal Information"),

              _profileSectionSwitch(
                "Display Name",
                displayName,
                onSave: (v) => displayName = v ?? "",
              ),

              _profileSectionSwitch(
                "Username",
                username,
                onSave: (v) => username = v ?? "",
              ),

              _profileSectionSwitch(
                "Phone Number",
                phone,
                onSave: (v) => phone = v ?? "",
              ),

              _profileSectionSwitch(
                "Description",
                description,
                onSave: (v) => description = v ?? "",
              ),

              _profileSectionSwitch(
                "Location",
                location,
                onSave: (v) => location = v ?? "",
              ),

              const SizedBox(height: 25),
              _sectionTitle("Email"),
              _infoRow("Email", email),

              const SizedBox(height: 30),

              if (isEditing)
                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF7086F8),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Save Changes"),
                ),

              const SizedBox(height: 30),

              _sectionTitle("Attending Events"),
              attendingEvents.isEmpty
                  ? const Text("You haven't marked any events yet.")
                  : Column(
                      children: attendingEvents.map((event) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(event["image"]),
                          ),
                          title: Text(event["title"]),
                          subtitle: Text(
                            "${event["location"]} • ${event["date"]}",
                          ),
                        );
                      }).toList(),
                    ),

              const SizedBox(height: 20),
              TextButton(
                onPressed: _logout,
                child: const Text(
                  "Sign Out",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: profileImage,
            backgroundColor: const Color(0xFF7086F8),
            child: profileImage == null
                ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 40,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            "Hi, $displayName!",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (isEditing)
            ElevatedButton(
              onPressed: _pickProfilePhoto,
              child: const Text("Change Photo"),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value.isEmpty ? "Not set" : value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const Divider(height: 20, thickness: 1),
      ],
    );
  }

  Widget _editableFieldModern(
    String label,
    String value, {
    required FormFieldSetter<String> onSave,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          onSaved: onSave,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _profileSectionSwitch(
    String label,
    String value, {
    required FormFieldSetter<String> onSave,
  }) {
    return isEditing
        ? _editableFieldModern(label, value, onSave: onSave)
        : _infoRow(label, value);
  }

  Future<void> _pickProfilePhoto() async {
    if (!isEditing) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.single.bytes == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No image selected')));
        return;
      }

      final Uint8List fileBytes = result.files.single.bytes!;
      final String fileName = '${user.uid}_profile.jpg';

      final storageRef = FirebaseStorage.instance.ref().child(
        'profile_photos/$fileName',
      );

      final uploadTask = storageRef.putData(
        fileBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('users').doc(user.uid).set({
        'profileImageUrl': downloadUrl,
      }, SetOptions(merge: true));

      setState(() {
        profileImage = NetworkImage(downloadUrl);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile photo updated!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => SignUpScreen()),
    );
  }
}
