import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'guide_screen.dart';

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic>? resultData;
  final String? imagePath;

  const ResultScreen({super.key, this.resultData, this.imagePath});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  int _selectedIndex = 0;
  List<dynamic> _allResults = [];

  // Current selected nail info
  String _diagnosis = 'Tidak Terdeteksi';
  double _confidence = 0.0;
  String _tentangKondisi = 'Silakan coba unggah foto kuku yang lebih jelas.';
  String _indikasiKlinis = '-';
  String _saranTindakan = 'Pastikan foto kuku terlihat jelas dan fokus.';
  bool _isHealthy = false;
  Uint8List? _croppedImageBytes;

  @override
  void initState() {
    super.initState();
    _parseInitialData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_allResults.isNotEmpty &&
          !_isHealthy &&
          _diagnosis != 'Tidak Ada Kuku' &&
          _diagnosis != 'Gagal Memproses') {
        _showAttentionDialog();
      }
    });
  }

  void _parseInitialData() {
    if (widget.resultData != null &&
        widget.resultData!['status'] == 'success') {
      _allResults = widget.resultData!['results'] ?? [];
      if (_allResults.isNotEmpty) {
        _updateSelectedNail(0);
      } else {
        _diagnosis = 'Tidak Ada Kuku';
        _tentangKondisi =
            'AI tidak dapat menemukan kuku pada gambar yang diunggah.';
        _saranTindakan =
            'Coba ambil foto ulang dengan pencahayaan yang lebih baik dan fokus hanya pada area kuku.';
      }
    } else {
      _diagnosis = 'Gagal Memproses';
      _tentangKondisi =
          'Terjadi kesalahan saat memproses gambar atau server tidak merespons dengan benar.';
      _saranTindakan = 'Pastikan backend server berjalan dan coba lagi.';
    }
  }

  void _updateSelectedNail(int index) {
    if (index < 0 || index >= _allResults.length) return;

    setState(() {
      _selectedIndex = index;
      final nail = _allResults[index];
      _diagnosis = nail['prediction'] ?? 'Unknown';
      _confidence = (nail['confidence'] ?? 0.0).toDouble();

      final String? base64String = nail['cropped_image_base64'];
      if (base64String != null) {
        _croppedImageBytes = base64Decode(base64String);
      } else {
        _croppedImageBytes = null;
      }

      if (_diagnosis.toLowerCase() == 'kuku sehat') {
        _isHealthy = true;
        _tentangKondisi =
            'Kuku ini terlihat dalam kondisi sehat tanpa tanda-tanda penyakit yang jelas.';
        _indikasiKlinis =
            '• Warna kuku normal\n• Permukaan kuku halus\n• Tidak ada penebalan';
        _saranTindakan =
            '• Jaga kebersihan kuku\n• Potong kuku secara teratur\n• Makan makanan bergizi';
      } else {
        _isHealthy = false;
        _tentangKondisi =
            'Terdeteksi kemungkinan indikasi $_diagnosis pada kuku ini.';
        _indikasiKlinis =
            '• Perubahan pada struktur atau warna kuku yang terdeteksi oleh sistem AI.';
        _saranTindakan =
            '• Segera konsultasikan dengan dokter kulit atau tenaga medis profesional.\n• Jaga area tetap bersih dan kering.';
      }
    });
  }

  void _showAttentionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 28),
            ),
            const SizedBox(width: 12),
            const Text(
              'Perhatian Penting',
              style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Hasil deteksi ini bersifat referensi awal. Harap hubungi tenaga medis profesional untuk pemeriksaan lebih mendalam.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF334155), fontSize: 15, height: 1.5),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('SAYA MENGERTI',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Hasil Analisis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'guide') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GuideScreen()),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'guide',
                child: Row(
                  children: [
                    Icon(Icons.help_outline, color: Color(0xFF0F172A), size: 20),
                    SizedBox(width: 12),
                    Text('Panduan Penggunaan'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Summary
              if (_allResults.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16, left: 4),
                  child: Text(
                    'Terdeteksi ${_allResults.length} kuku. Pilih kuku untuk melihat detail:',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              // Horizontal Nails List
              if (_allResults.isNotEmpty)
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _allResults.length,
                    itemBuilder: (context, index) {
                      final bool isSelected = _selectedIndex == index;
                      final nailData = _allResults[index];
                      Uint8List? thumbBytes;
                      if (nailData['cropped_image_base64'] != null) {
                        thumbBytes =
                            base64Decode(nailData['cropped_image_base64']);
                      }

                      return GestureDetector(
                        onTap: () => _updateSelectedNail(index),
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(
                              right: 16, bottom: 8, top: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF6366F1)
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? const Color(0xFF6366F1)
                                        .withValues(alpha: 0.2)
                                    : Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(17),
                            child: thumbBytes != null
                                ? Image.memory(thumbBytes, fit: BoxFit.cover)
                                : const Center(child: Icon(Icons.fingerprint)),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 24),

              // Diagnosis Badge for selected nail
              if (_confidence > 0)
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isHealthy
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _isHealthy
                              ? const Color(0xFFA7F3D0)
                              : const Color(0xFFFECDD3)),
                    ),
                    child: Text(
                      'Kuku #${_selectedIndex + 1}: Confidence ${_confidence.toStringAsFixed(1)}%',
                      style: TextStyle(
                          color: _isHealthy
                              ? const Color(0xFF059669)
                              : const Color(0xFFE11D48),
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Selected Nail Info
              _buildPremiumInfoSection(
                'Diagnosis Kuku #${_selectedIndex + 1}',
                _diagnosis,
                Icons.biotech_rounded,
                isHighlight: true,
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 4),
                child: Text(
                  'Detail Informasi',
                  style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w800),
                ),
              ),

              _buildPremiumInfoSection(
                'Tentang Kondisi',
                _tentangKondisi,
                Icons.info_outline_rounded,
              ),
              if (_indikasiKlinis != '-')
                _buildPremiumInfoSection(
                  'Indikasi Klinis',
                  _indikasiKlinis,
                  Icons.checklist_rtl_rounded,
                ),
              _buildPremiumInfoSection(
                'Saran Tindakan',
                _saranTindakan,
                Icons.medical_services_outlined,
              ),

              const SizedBox(height: 32),

              // Bottom Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  icon: const Icon(Icons.refresh_rounded,
                      color: Color(0xFF6366F1)),
                  label: const Text('AMBIL FOTO LAGI',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Color(0xFF6366F1))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFC7D2FE), width: 2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    backgroundColor: const Color(0xFFF5F3FF),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumInfoSection(String title, String content, IconData icon,
      {bool isHighlight = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isHighlight ? const Color(0xFF818CF8) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlight
                ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isHighlight
                  ? const Color(0xFFEEF2FF)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: isHighlight
                  ? const Color(0xFF6366F1)
                  : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isHighlight
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 15,
                    color: isHighlight
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF334155),
                    height: 1.5,
                    fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
