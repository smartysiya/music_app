import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../constants.dart';
import '../providers/user_provider.dart';
import '../widgets/tappable_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>();
    _nameController = TextEditingController(text: user.name);
    _emailController = TextEditingController(text: user.email);
    _bioController = TextEditingController(text: user.bio);
    _phoneController = TextEditingController(text: user.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        if (!mounted) return;
        context.read<UserProvider>().updateProfileImage(image.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1E3A8A).withOpacity(0.8),
            kBackgroundColor,
            kTealColor.withOpacity(0.2),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: kTextColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Edit Profile', style: kTitleTextStyle),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () {
                user.updateName(_nameController.text);
                user.updateEmail(_emailController.text);
                user.updateBio(_bioController.text);
                user.updatePhone(_phoneController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully')),
                );
              },
              child: const Text('Save', style: TextStyle(color: kCyanColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Profile Picture
              Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: kCyanColor, width: 3),
                      image: user.profileImagePath != null
                          ? DecorationImage(
                              image: FileImage(File(user.profileImagePath!)),
                              fit: BoxFit.cover,
                            )
                          : const DecorationImage(
                              image: NetworkImage('https://i.pravatar.cc/150?img=32'),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: TappableCard(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: kCyanColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatColumn('Playlists', '12'),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _buildStatColumn('Followers', '1.2k'),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _buildStatColumn('Following', '458'),
                ],
              ),
              const SizedBox(height: 40),
              // Name Input
              _buildInputLabel('Name'),
              _buildTextField(_nameController, Icons.person_outline),
              const SizedBox(height: 24),
              // Bio Input
              _buildInputLabel('Bio'),
              _buildTextField(_bioController, Icons.info_outline, maxLines: 3),
              const SizedBox(height: 24),
              // Email Input
              _buildInputLabel('Email'),
              _buildTextField(_emailController, Icons.email_outlined),
              const SizedBox(height: 24),
              // Phone Input
              _buildInputLabel('Phone'),
              _buildTextField(_phoneController, Icons.phone_outlined),
              const SizedBox(height: 40),
              Text(
                'Changes will be reflected across all your devices.',
                style: kSubtitleTextStyle.copyWith(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(label, style: kTitleTextStyle.copyWith(fontSize: 14, color: kCyanColor)),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: kTitleTextStyle.copyWith(fontSize: 20)),
        const SizedBox(height: 4),
        Text(label, style: kSubtitleTextStyle.copyWith(fontSize: 12)),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: kTextColor),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: kTextColor.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
