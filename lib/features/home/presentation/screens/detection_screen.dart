import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'result_screen.dart';
import 'guide_screen.dart';

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({super.key});

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCameraPermissionDenied = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _isCameraPermissionDenied = true;
        });
        return;
      }

      final firstCamera = cameras.first;
      _cameraController = CameraController(
        firstCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraPermissionDenied = true;
        });
      }
    }
  }

  Future<void> _processImage(XFile image) async {
    print('DEBUG: Memulai proses upload gambar ke backend...');
    setState(() {
      _isLoading = true;
    });

    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);

      final Uint8List bytes = await image.readAsBytes();
      
      FormData formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes, 
          filename: image.name.isEmpty ? 'image.jpg' : image.name,
        ),
      });

      print('DEBUG: Mengirim request POST ke http://127.0.0.1:8000/predict');
      final response = await dio.post(
        'http://127.0.0.1:8000/predict',
        data: formData,
      );

      print('DEBUG: Respons diterima: ${response.data}');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              resultData: response.data,
              imagePath: image.path,
            ),
          ),
        );
      }
    } catch (e) {
      print('DEBUG: Error saat upload: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghubungi server: $e')),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null && mounted) {
        await _processImage(image);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka galeri.')),
      );
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Kamera Pemindai (LIVE)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GuideScreen()),
              );
            },
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                
                // Instruction Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.center_focus_strong, color: Color(0xFF6366F1)),
                      SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'Arahkan kamera tepat ke kuku',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Camera Viewfinder
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (_isCameraInitialized && _cameraController != null)
                              FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _cameraController!.value.previewSize?.height ?? 1,
                                  height: _cameraController!.value.previewSize?.width ?? 1,
                                  child: CameraPreview(_cameraController!),
                                ),
                              )
                            else
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isCameraPermissionDenied ? Icons.no_photography_outlined : Icons.camera_alt_outlined,
                                      size: 48,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _isCameraPermissionDenied ? 'Akses Kamera Ditolak' : 'Memuat Kamera...',
                                      style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            Positioned(
                              top: 20, left: 20, right: 20, bottom: 20,
                              child: CustomPaint(
                                painter: PremiumViewfinderPainter(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Bottom Controls
                Container(
                  padding: const EdgeInsets.only(top: 24, bottom: 24, left: 24, right: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          if (_isCameraInitialized && _cameraController != null) {
                            try {
                              final XFile image = await _cameraController!.takePicture();
                              if (mounted) {
                                await _processImage(image);
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Gagal mengambil gambar: $e')),
                              );
                            }
                          }
                        },
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFFE0E7FF),
                              width: 4,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                                ),
                              ),
                              child: const Icon(Icons.camera, color: Colors.white, size: 24),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: TextButton.icon(
                          onPressed: _pickImageFromGallery,
                          icon: const Icon(Icons.photo_library_rounded, color: Color(0xFF6366F1)),
                          label: const Text(
                            'Pilih dari Galeri',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFEEF2FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF6366F1),
                      strokeWidth: 5,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'AI Menganalisis Kuku...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1.2,
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
}

class PremiumViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6366F1)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 30;

    canvas.drawPath(Path()..moveTo(0, cornerLength)..lineTo(0, 0)..lineTo(cornerLength, 0), paint);
    canvas.drawPath(Path()..moveTo(size.width - cornerLength, 0)..lineTo(size.width, 0)..lineTo(size.width, cornerLength), paint);
    canvas.drawPath(Path()..moveTo(0, size.height - cornerLength)..lineTo(0, size.height)..lineTo(cornerLength, size.height), paint);
    canvas.drawPath(Path()..moveTo(size.width - cornerLength, size.height)..lineTo(size.width, size.height)..lineTo(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
