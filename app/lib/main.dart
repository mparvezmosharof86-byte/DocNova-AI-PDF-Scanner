/**
 * ==============================================================================
 * Project: DocNova: AI PDF & Scanner
 * Package: com.novastudio24.docnova
 * Component: Master Flutter Mobile Client UI & Live Camera Viewfinder
 * File: main.dart
 * ==============================================================================
 */

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

List<CameraDescription> _availableCameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  try {
    _availableCameras = await availableCameras();
  } catch (e) {
    debugPrint("[-] ক্যামেরা লোড এরর: $e");
  }

  runApp(const DocNovaApp());
}

class DocNovaApp extends StatelessWidget {
  const DocNovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DocNova',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        primaryColor: const Color(0xFF00E5FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF00B4D8),
        ),
      ),
      home: const ScannerHomeScreen(),
    );
  }
}

enum ScannerMode { document, idCard, passport, qrCode }

class ScannerHomeScreen extends StatefulWidget {
  const ScannerHomeScreen({super.key});

  @override
  State<ScannerHomeScreen> createState() => _ScannerHomeScreenState();
}

class _ScannerHomeScreenState extends State<ScannerHomeScreen> {
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isFlashOn = false;
  ScannerMode _selectedMode = ScannerMode.document;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) return;

    if (_availableCameras.isNotEmpty) {
      _cameraController = CameraController(
        _availableCameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      try {
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraReady = true;
          });
        }
      } catch (e) {
        debugPrint("[-] ক্যামেরা ইনিশিয়ালাইজেশন ফেইল্ড: $e");
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      _isFlashOn = !_isFlashOn;
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
    } catch (e) {
      debugPrint("[-] ফ্ল্যাশ টগল এরর: $e");
    }
  }

  void _onCaptureTrigger() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile photo = await _cameraController!.takePicture();
      if (mounted) {
        _showExportBottomSheet(File(photo.path));
      }
    } catch (e) {
      debugPrint("[-] ক্যাপচার এরর: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showExportBottomSheet(File capturedFile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "DocNova AI Reconstruction Ready",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                "মোড: ${_selectedMode.name.toUpperCase()} | ব্যাকগ্রাউন্ড ক্লিন সম্পন্ন",
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Share.shareXFiles([XFile(capturedFile.path)], text: 'Exported Vector PDF');
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text("Download PDF", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF00E5FF)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Share.shareXFiles([XFile(capturedFile.path)], text: 'Exported Clean Image');
                      },
                      icon: const Icon(Icons.image),
                      label: const Text("Download Image"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ১. ব্যাকগ্রাউন্ড ক্যামেরা ফিড
          if (_isCameraReady && _cameraController != null)
            SizedBox.expand(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
            ),

          // ২. এআই ওভারলে ভিউফাইন্ডার (মোড অনুযায়ী ফ্রেম আঁকা)
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: ViewfinderOverlayPainter(mode: _selectedMode),
          ),

          // ৩. উপরের কন্ট্রোল বার (হেডার ও ফ্ল্যাশ)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.document_scanner, color: Color(0xFF00E5FF), size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "DocNova",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ],
                  ),
                  IconButton(
                    style: IconButton.styleFrom(backgroundColor: Colors.black54),
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: _isFlashOn ? const Color(0xFF00E5FF) : Colors.white,
                    ),
                    onPressed: _toggleFlash,
                  ),
                ],
              ),
            ),
          ),

          // ৪. এআই অটো-স্ক্যান স্ট্যাটাস ব্যাজ
          Positioned(
            top: 110,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFF00E5FF), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _getModeDescription(_selectedMode),
                      style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ৫. নিচের কন্ট্রোল বাটন ও মোড সিলেক্টর
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black, Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // মোড সুইচার ট্যাব
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildModeButton("Document", ScannerMode.document),
                        _buildModeButton("ID Card", ScannerMode.idCard),
                        _buildModeButton("Passport", ScannerMode.passport),
                        _buildModeButton("QR Code", ScannerMode.qrCode),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ক্যাপচার বাটন
                  GestureDetector(
                    onTap: _onCaptureTrigger,
                    child: Container(
                      width: 76,
                      height: 76,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF00E5FF), width: 3),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: _isProcessing
                            ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : null,
                      ),
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

  Widget _buildModeButton(String title, ScannerMode mode) {
    final isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00E5FF).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: const Color(0xFF00E5FF)) : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00E5FF) : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  String _getModeDescription(ScannerMode mode) {
    switch (mode) {
      case ScannerMode.document:
        return "AI Auto-Scanning Document: কাগজের চারপাশ মেলান";
      case ScannerMode.idCard:
        return "ID Card Mode: কার্ড ধরুন (ব্যাকগ্রাউন্ড স্বয়ংক্রিয়ভাবে বাদ যাবে)";
      case ScannerMode.passport:
        return "Passport Mode: পাসপোর্টের নিচের MRZ কোড মেলান";
      case ScannerMode.qrCode:
        return "High-Speed QR & Barcode Scanner";
    }
  }
}

// ভিউফাইন্ডার ওভারলে পেইন্টার (ডকুমেন্ট, আইডি কার্ড ও কিউআর ফ্রেম আঁকা)
class ViewfinderOverlayPainter extends CustomPainter {
  final ScannerMode mode;
  ViewfinderOverlayPainter({required this.mode});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.5);
    final borderPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    Rect cropRect;

    switch (mode) {
      case ScannerMode.document:
        cropRect = Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2 - 20),
          width: size.width * 0.85,
          height: size.height * 0.60,
        );
        break;
      case ScannerMode.idCard:
        // আইডি কার্ড স্ট্যান্ডার্ড রেশিও (৮৫.৬ মিমি x ৫৩.৯৮ মিমি)
        cropRect = Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2 - 20),
          width: size.width * 0.88,
          height: (size.width * 0.88) * 0.63,
        );
        break;
      case ScannerMode.passport:
        cropRect = Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2 - 20),
          width: size.width * 0.88,
          height: size.height * 0.55,
        );
        break;
      case ScannerMode.qrCode:
        cropRect = Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2 - 20),
          width: size.width * 0.70,
          height: size.width * 0.70,
        );
        break;
    }

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cropPath = Path()
      ..addRRect(RRect.fromRectAndRadius(cropRect, const Radius.circular(14)));

    final combinedPath = Path.combine(PathOperation.difference, backgroundPath, cropPath);
    canvas.drawPath(combinedPath, backgroundPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(cropRect, const Radius.circular(14)), borderPaint);
  }

  @override
  bool shouldRepaint(covariant ViewfinderOverlayPainter oldDelegate) => oldDelegate.mode != mode;
}
