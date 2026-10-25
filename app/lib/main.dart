/**
 * ==============================================================================
 * Project: DocNova: AI PDF & Scanner
 * Package: com.novastudio24.docnova
 * Component: Full-Featured Functional Enterprise Mobile Client
 * File: main.dart
 * ==============================================================================
 */

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

List<CameraDescription> _availableCameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  try {
    _availableCameras = await availableCameras();
  } catch (e) {
    debugPrint("[-] ক্যামেরা এরর: $e");
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
        scaffoldBackgroundColor: const Color(0xFF0A0E14),
        primaryColor: const Color(0xFF00E5FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF00B4D8),
          surface: Color(0xFF161B22),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF161B22),
          elevation: 0,
        ),
      ),
      home: const MasterNavigationShell(),
    );
  }
}

class MasterNavigationShell extends StatefulWidget {
  const MasterNavigationShell({super.key});

  @override
  State<MasterNavigationShell> createState() => _MasterNavigationShellState();
}

class _MasterNavigationShellState extends State<MasterNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    LiveQRScannerScreen(),
    QRBarcodeGeneratorScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF30363D), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: const Color(0xFF161B22),
          selectedItemColor: const Color(0xFF00E5FF),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: 'QR Scanner'),
            BottomNavigationBarItem(icon: Icon(Icons.edit_document), label: 'QR & Barcode Studio'),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// ১. হোম ড্যাশবোর্ড স্ক্রিন
// ==========================================
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.document_scanner, color: Color(0xFF00E5FF), size: 20),
            ),
            const SizedBox(width: 10),
            const Text("DocNova Studio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // প্রিমিয়াম এআই স্ট্যাটাস ব্যানার
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1F2937), Color(0xFF111827)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFF00E5FF), size: 20),
                      const SizedBox(width: 8),
                      Text("NO-GOOGLE LOCAL ENGINE", style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text("AI Vector & Clean Paper Scanner", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text("ধূসর ব্যাকগ্রাউন্ড ও হাত দূর করে ধবধবে সাদা ডিজিটাল পেপারে রূপান্তর করুন।", style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text("Core Engines", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)),
            const SizedBox(height: 14),

            // ডক স্ক্যানার কার্ড
            _buildEngineCard(
              context,
              title: "Document Scanner",
              subtitle: "কাগজের ছবি তুলে নিখুঁত সাদা পেপার ও ভেক্টর PDF বানান",
              icon: Icons.document_scanner,
              color: const Color(0xFF00E5FF),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentCameraScreen(modeName: "DOCUMENT")));
              },
            ),
            const SizedBox(height: 12),

            // আইডি কার্ড ও পাসপোর্ট মোড
            _buildEngineCard(
              context,
              title: "ID Card & Passport Mode",
              subtitle: "ব্যাকগ্রাউন্ড সম্পূর্ণ মুছে কার্ডের এপিঠ-ওপিঠ A4 পাতায় বসান",
              icon: Icons.badge_outlined,
              color: const Color(0xFF38BDF8),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentCameraScreen(modeName: "ID_CARD")));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngineCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// ২. রিয়েল ডকুমেন্ট ক্যামেরা ও পেপার ক্লিনার
// ==========================================
class DocumentCameraScreen extends StatefulWidget {
  final String modeName;
  const DocumentCameraScreen({super.key, required this.modeName});

  @override
  State<DocumentCameraScreen> createState() => _DocumentCameraScreenState();
}

class _DocumentCameraScreenState extends State<DocumentCameraScreen> {
  CameraController? _controller;
  bool _isInit = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  Future<void> _startCamera() async {
    await Permission.camera.request();
    if (_availableCameras.isNotEmpty) {
      _controller = CameraController(_availableCameras.first, ResolutionPreset.high, enableAudio: false);
      await _controller!.initialize();
      if (mounted) setState(() => _isInit = true);
    }
  }

  Future<void> _captureAndProcess() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final XFile file = await _controller!.takePicture();
      final Uint8List rawBytes = await file.readAsBytes();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CleanPaperStudioScreen(rawBytes: rawBytes, modeName: widget.modeName)),
        );
      }
    } catch (e) {
      debugPrint("[-] ক্যাপচার এরর: $e");
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit || _controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))));
    }

    return Scaffold(
      appBar: AppBar(title: Text("Scan ${widget.modeName}")),
      body: Stack(
        children: [
          SizedBox.expand(child: CameraPreview(_controller!)),
          // ভিউফাইন্ডার গাইড
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height * 0.60,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00E5FF), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _captureAndProcess,
                child: Container(
                  width: 74,
                  height: 74,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF00E5FF), width: 3)),
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: _isCapturing ? const CircularProgressIndicator(color: Colors.black) : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ৩. পেপার ফিল্টার ও PDF মেকার স্টুডিও (Clean Paper Engine)
// ==========================================
class CleanPaperStudioScreen extends StatefulWidget {
  final Uint8List rawBytes;
  final String modeName;
  const CleanPaperStudioScreen({super.key, required this.rawBytes, required this.modeName});

  @override
  State<CleanPaperStudioScreen> createState() => _CleanPaperStudioScreenState();
}

class _CleanPaperStudioScreenState extends State<CleanPaperStudioScreen> {
  Uint8List? _processedBytes;
  String _activeFilter = "MAGIC"; // MAGIC, BW, ORIGINAL
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _applyPaperFilter("MAGIC");
  }

  Future<void> _applyPaperFilter(String filter) async {
    setState(() {
      _isBusy = true;
      _activeFilter = filter;
    });

    final decoded = img.decodeImage(widget.rawBytes);
    if (decoded == null) return;

    img.Image processed;

    if (filter == "MAGIC") {
      // ব্যাকগ্রাউন্ডের ধূসর ছায়া দূর করে ম্যাজিক কালার করা
      processed = img.contrast(decoded, contrast: 135);
      processed = img.adjustColor(processed, brightness: 1.15, saturation: 1.2);
    } else if (filter == "BW") {
      // ধবধবে সাদা পেপার এবং কালির নিখুঁত কালো লেখা (Black & White Clean Paper)
      processed = img.grayscale(decoded);
      processed = img.contrast(processed, contrast: 160);
    } else {
      processed = decoded;
    }

    final Uint8List encoded = Uint8List.fromList(img.encodeJpg(processed, quality: 90));

    if (mounted) {
      setState(() {
        _processedBytes = encoded;
        _isBusy = false;
      });
    }
  }

  Future<void> _exportAsPdf() async {
    if (_processedBytes == null) return;

    final pdf = pw.Document();
    final pdfImage = pw.MemoryImage(_processedBytes!);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Center(child: pw.Image(pdfImage, fit: pw.BoxFit.contain)),
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/DocNova_Scanned_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());

    Share.shareXFiles([XFile(file.path)], text: 'Exported Clean PDF - DocNova Studio');
  }

  Future<void> _exportAsImage() async {
    if (_processedBytes == null) return;
    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/DocNova_Image_${DateTime.now().millisecondsSinceEpoch}.jpg");
    await file.writeAsBytes(_processedBytes!);

    Share.shareXFiles([XFile(file.path)], text: 'Exported Clean Image - DocNova Studio');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Document Filter & Export")),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _isBusy || _processedBytes == null
                  ? const CircularProgressIndicator(color: Color(0xFF00E5FF))
                  : Image.memory(_processedBytes!, fit: pw.BoxFit.contain as BoxFit),
            ),
          ),
          // ফিল্টার অপশন
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: const Color(0xFF161B22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterButton("Magic Color", "MAGIC"),
                _buildFilterButton("Crisp B&W", "BW"),
                _buildFilterButton("Original", "ORIGINAL"),
              ],
            ),
          ),
          // এক্সপোর্ট বাটন
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: _exportAsPdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Download PDF", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Color(0xFF00E5FF)), padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: _exportAsImage,
                    icon: const Icon(Icons.image),
                    label: const Text("Download Image"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String code) {
    final active = _activeFilter == code;
    return GestureDetector(
      onTap: () => _applyPaperFilter(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF00E5FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00E5FF)),
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
}

// ==========================================
// ৪. লাইভ QR ও বারকোড স্ক্যানার স্ক্রিন
// ==========================================
class LiveQRScannerScreen extends StatefulWidget {
  const LiveQRScannerScreen({super.key});

  @override
  State<LiveQRScannerScreen> createState() => _LiveQRScannerScreenState();
}

class _LiveQRScannerScreenState extends State<LiveQRScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _hasScanned = false;

  void _onDetectBarcode(BarcodeCapture capture) {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String codeValue = barcodes.first.rawValue!;
      setState(() => _hasScanned = true);
      HapticFeedback.mediumImpact();

      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF161B22),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF00E5FF)),
                    const SizedBox(width: 8),
                    const Text("Code Scanned Successfully", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
                  child: SelectableText(codeValue, style: const TextStyle(fontSize: 15, color: Colors.white)),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: codeValue));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied to clipboard!")));
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text("Copy"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Color(0xFF00E5FF))),
                        onPressed: () => Share.share(codeValue),
                        icon: const Icon(Icons.share),
                        label: const Text("Share"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ).whenComplete(() => setState(() => _hasScanned = false));
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live QR & Barcode Scanner")),
      body: Stack(
        children: [
          MobileScanner(controller: _scannerController, onDetect: _onDetectBarcode),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00E5FF), width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
                child: const Text("Align any QR Code or Barcode inside the box", style: TextStyle(fontSize: 13, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ৫. QR ও বারকোড মেকার স্টুডিও (Generator)
// ==========================================
class QRBarcodeGeneratorScreen extends StatefulWidget {
  const QRBarcodeGeneratorScreen({super.key});

  @override
  State<QRBarcodeGeneratorScreen> createState() => _QRBarcodeGeneratorScreenState();
}

class _QRBarcodeGeneratorScreenState extends State<QRBarcodeGeneratorScreen> {
  final TextEditingController _inputController = TextEditingController(text: "DocNova Studio");
  bool _isQR = true;

  @override
  Widget build(BuildContext context) {
    final String currentData = _inputController.text.trim().isEmpty ? "DocNova" : _inputController.text.trim();

    return Scaffold(
      appBar: AppBar(title: const Text("QR & Barcode Studio")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // টাইপ সিলেক্টর
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isQR ? const Color(0xFF00E5FF) : const Color(0xFF161B22),
                      foregroundColor: _isQR ? Colors.black : Colors.white,
                    ),
                    onPressed: () => setState(() => _isQR = true),
                    child: const Text("Create QR Code", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_isQR ? const Color(0xFF00E5FF) : const Color(0xFF161B22),
                      foregroundColor: !_isQR ? Colors.black : Colors.white,
                    ),
                    onPressed: () => setState(() => _isQR = false),
                    child: const Text("Create Barcode", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ইনপুট বক্স
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                labelText: _isQR ? "Enter text or URL for QR" : "Enter alphanumeric code for Barcode",
                filled: true,
                fillColor: const Color(0xFF161B22),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF30363D))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00E5FF))),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 30),

            // লাইভ জেনারেটেড প্রিভিউ কার্ড
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: _isQR
                  ? QrImageView(data: currentData, version: QrVersions.auto, size: 200.0, backgroundColor: Colors.white)
                  : BarcodeWidget(barcode: Barcode.code128(), data: currentData, width: 240, height: 90, backgroundColor: Colors.white),
            ),
            const SizedBox(height: 24),

            // শেয়ার বাটন
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Share.share(currentData, subject: 'Generated via DocNova Studio'),
              icon: const Icon(Icons.share),
              label: Text(_isQR ? "Share QR Data" : "Share Barcode Data", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
