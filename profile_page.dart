import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color primaryBlue = Color(0xFF4DA3FF);

  final TextEditingController nameController =
      TextEditingController(text: "Dilandarrr");
  final TextEditingController roleController =
      TextEditingController(text: "Owner");
  final TextEditingController emailController =
      TextEditingController(text: "dilan@email.com");
  final TextEditingController phoneController =
      TextEditingController(text: "08123456789");

  bool isEditing = false;

  @override
  void dispose() {
    nameController.dispose();
    roleController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    setState(() {
      isEditing = false;
    });

    // TODO: simpan ke database / shared preferences
    debugPrint("Nama: ${nameController.text}");
    debugPrint("Role: ${roleController.text}");
    debugPrint("Email: ${emailController.text}");
    debugPrint("Telepon: ${phoneController.text}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profil",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (isEditing) {
                _saveProfile();
              } else {
                setState(() => isEditing = true);
              }
            },
            child: Text(
              isEditing ? "Simpan" : "Edit",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// FOTO PROFIL
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                const CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 60, color: Colors.white),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    // TODO: integrasi image_picker
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: "ubah",
                      child: Text("Ubah Foto"),
                    ),
                    const PopupMenuItem(
                      value: "hapus",
                      child: Text("Hapus Foto"),
                    ),
                  ],
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: primaryBlue,
                    child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _inputField("Nama", nameController),
            _inputField("Role", roleController, enabled: false),
            _inputField("Email", emailController),
            _inputField("Nomor Telepon", phoneController,
                keyboard: TextInputType.phone),
          ],
        ),
      ),
    );
  }

  Widget _inputField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        enabled: isEditing && enabled,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }
}
