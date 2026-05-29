import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import 'dart:io';
import 'dart:async';
import 'dart:developer' as developer;
import '../../services/user_service.dart';
import '../../services/admin_image_picker.dart';
// image_uploader not used directly in this screen
import '../../services/user_image_uploader.dart';
// shared_preferences not required here

class CompleteProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final String initialPhone;

  const CompleteProfileScreen({
    super.key,
    required this.initialName,
    required this.initialEmail,
    this.initialPhone = '',
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final userService = UserService();
  bool isSaving = false;
  bool isUploadingAvatar = false;
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.initialName;
    phoneController.text = widget.initialPhone;
  }

  Future<void> saveProfile() async {
    if (nameController.text.isEmpty || phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan nomor telepon wajib diisi')),
      );
      return;
    }
    setState(() => isSaving = true);
    try {
      // If user picked an avatar, upload it first
      if (photoUrl == null) {
        // allow user to select and upload an avatar before saving
      }

      // Create or update canonical user data in Firestore / demo storage
      // Add a timeout so we don't hang indefinitely if network/rules block the request
      await userService
          .createUserData(
            name: nameController.text.trim(),
            email: widget.initialEmail,
            phone: phoneController.text.trim(),
            role: 'user',
          )
          .timeout(const Duration(seconds: 15));

      // If we have an uploaded photoUrl, persist it (also guarded by timeout)
      if (photoUrl != null) {
        await userService
            .updatePhoto(photoUrl!)
            .timeout(const Duration(seconds: 15));
      }

      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on TimeoutException catch (_) {
      // Network or firestore hung — show friendly message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Waktu tunggu habis saat menyimpan profil. Coba lagi.')),
        );
      }
    } catch (e, st) {
      // Log and surface the error so we can debug
      developer.log('Error saving profile', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan profil: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        backgroundColor: AppTheme.navy,
        elevation: 0,
        title: const Text('Lengkapi Profil'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickAvatar,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.gold,
                  child: isUploadingAvatar
                      ? const CircularProgressIndicator(color: Colors.black)
                      : (photoUrl == null || photoUrl!.isEmpty)
                          ? const Icon(Icons.person_rounded,
                              size: 40, color: Colors.black)
                          : ClipOval(
                              child: Image.network(photoUrl!,
                                  width: 80, height: 80, fit: BoxFit.cover),
                            ),
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration:
                    inputDecoration(label: 'Nama', icon: Icons.person_rounded),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: inputDecoration(
                    label: 'No. Telepon', icon: Icons.phone_rounded),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isSaving ? null : saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  child: isSaving
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('Simpan dan Lanjut'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    setState(() => isUploadingAvatar = true);
    try {
      final picked = await pickImages();
      if (picked.isEmpty) {
        return;
      }
      if (!mounted) {
        return;
      }

      // Show a preview dialog for the first picked image and ask confirmation
      final previewPath = picked.first;
      final use = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.navy,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pratinjau Avatar',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ClipOval(
                child: Image.file(
                  File(previewPath),
                  width: 160,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Pilih Ulang'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: Colors.black),
              child: const Text('Gunakan'),
            ),
          ],
        ),
      );

      if (!mounted) {
        return;
      }

      if (use != true) {
        // user cancelled or wants to choose again
        if (mounted) {
          setState(() => isUploadingAvatar = false);
        }
        return _pickAvatar();
      }

      final id = userService.uid.isEmpty
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : userService.uid;
      // Upload chosen images (uploader will remove temp files)
      final uploaded = await uploadUserImageFiles(picked, uid: id);
      if (uploaded.isEmpty) {
        return;
      }
      photoUrl = uploaded.first;
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal upload avatar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => isUploadingAvatar = false);
      }
    }
  }

  InputDecoration inputDecoration(
      {required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
