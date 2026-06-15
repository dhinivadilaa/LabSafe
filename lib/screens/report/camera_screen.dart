import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _capturedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openCamera();
    });
  }

  Future<void> _openCamera() async {
    setState(() => _isLoading = true);
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 40,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (photo != null) {
        setState(() {
          _capturedImage = File(photo.path);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak bisa mengakses kamera. Gunakan pilih dari galeri.'),
            backgroundColor: AppTheme.warningOrange,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
    );
    if (photo != null) {
      setState(() => _capturedImage = File(photo.path));
    }
  }

  void _proceedWithPhoto() {
    Navigator.pushNamed(
      context,
      '/location',
      arguments: {'photoPath': _capturedImage?.path},
    );
  }

  void _skipPhoto() {
    Navigator.pushNamed(
      context,
      '/location',
      arguments: {'photoPath': null},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Ambil Bukti'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Image preview area
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppTheme.accentCyan),
                        SizedBox(height: 16),
                        Text(
                          'Membuka kamera...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  )
                : _capturedImage != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_capturedImage!, fit: BoxFit.cover),
                          // Top overlay
                          Positioned(
                            top: 12,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Foto Bukti',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white.withOpacity(0.3),
                              size: 80,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Ambil foto aktivitas mencurigakan',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.6)),
                            ),
                          ],
                        ),
                      ),
          ),
          // Bottom controls
          Container(
            color: Colors.black,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (_capturedImage != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openCamera,
                          icon: const Icon(Icons.refresh_rounded,
                              color: Colors.white),
                          label: const Text('Foto Ulang',
                              style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _proceedWithPhoto,
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Gunakan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _cameraActionBtn(
                        icon: Icons.photo_library_rounded,
                        label: 'Galeri',
                        onTap: _pickFromGallery,
                      ),
                      GestureDetector(
                        onTap: _openCamera,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppTheme.accentCyan, width: 3),
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              color: AppTheme.primaryDark, size: 34),
                        ),
                      ),
                      _cameraActionBtn(
                        icon: Icons.skip_next_rounded,
                        label: 'Lewati',
                        onTap: _skipPhoto,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cameraActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
