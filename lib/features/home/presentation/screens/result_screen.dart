import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'guide_screen.dart';

// ---------------------------------------------------------------------------
// Lookup table: backend label (lowercase) → {tentang, indikasi, saran, sehat}
// ---------------------------------------------------------------------------
const Map<String, Map<String, String>> _conditionInfo = {
  'kuku sehat': {
    'tentang':
        'Kuku sehat ditandai dengan tekstur permukaan rata halus tanpa lubang '
            '(pitting), alur longitudinal/transversal yang signifikan, atau retakan kasar.',
    'indikasi': 'Tidak ada indikasi penyakit serius.',
    'saran':
        '• Jaga kebersihan kuku\n• Potong kuku secara teratur\n• Makan makanan bergizi',
    'sehat': 'true',
  },
  'onychomycosis': {
    'tentang':
        'Onychomycosis ditandai dengan perubahan warna, penebalan lempeng kuku, '
            'dan onikolisis sehingga kuku tampak rapuh dan mudah rusak.',
    'indikasi': 'Indkasi diabetes melitus, '
        'insufisiensi bena kronis, neuropati perifer, penyakit iskemik tungkai bawah, '
        'HIV, serta kondisi pada pasien hemodialisis atau terapi imunosupresif ',
    'saran':
        '• Segera konsultasikan dengan dokter kulit atau tenaga medis profesional.\n'
            '• Jaga area tetap bersih dan kering.',
    'sehat': 'false',
  },
  'clubbing': {
    'tentang':
        'Clubbing finger ditandai dengan pembesaran ujung jari, peningkatan '
            'kelengkungan kuku, dan sudut Lovibond >180°, disertai hilangnya '
            "Schamroth's window, rasio Rice & Rowland >1, serta sensasi lunak "
            'pada dasar kuku.',
    'indikasi': 'Indikasi keganasan paru, penyakit jantung bawaan sianotik, '
        'bronkiektasis, tuberkulosis, sirosis hati, dan penyakit radang usus.',
    'saran':
        '• Segera konsultasikan dengan dokter kulit atau tenaga medis profesional.\n'
            '• Jaga area tetap bersih dan kering.',
    'sehat': 'false',
  },
  'blue finger': {
    'tentang':
        'Blue finger didefinisikan sebagai perubahan warna menjadi nuansa ungu-biru pada '
            'satu atau lebih jari '
            'dan umumnya disertai rasa nyeri di area yang mengalami perubahan warna.',
    'indikasi': 'Indikasi adanya gangguan vaskular '
        'sistemik seperti trombosis, emboli, vasokonstriksi berat, lupus, '
        'penyakit respirasi atau sirkulasi.',
    'saran':
        '• Segera konsultasikan dengan dokter kulit atau tenaga medis profesional.\n'
            '• Jaga area tetap bersih dan kering.',
    'sehat': 'false',
  },
  'onychogryphosis': {
    'tentang': 'Onychogryphosis ditandai lempeng kuku yang sangat menebal, '
        'opak kekuningan hingga cokelat, memanjang dan melengkung ekstrem seperti '
        'tanduk, tampak sebagai kuku besar, kasar, dan terpuntir pada foto.',
    'indikasi': 'Onychogryphosis berhubungan '
        'dengan usia lanjut, keterbatasan perawatan diri, trauma kaki kronis, '
        'psoriasis, onikomikosis, kelainan bentuk jari kaki, penyakit vaskular '
        'perifer, ulkus tungkai, varises, dan diabetes melitus tipe 2 ',
    'saran':
        '• Segera konsultasikan dengan dokter kulit atau tenaga medis profesional.\n'
            '• Jaga area tetap bersih dan kering.',
    'sehat': 'false',
  },
  'pitting': {
    'tentang':
        'Pitting kuku tampak sebagai banyak lekukan kecil di permukaan lempeng, '
            'yang pada citra klinis menampilkan pola titik-titik cekung berulang tanpa '
            'perubahan drastis pada bentuk global kuku',
    'indikasi': 'Indikasi psoriasis dan alopecia '
        'areata.',
    'saran':
        '• Segera konsultasikan dengan dokter kulit atau tenaga medis profesional.\n'
            '• Jaga area tetap bersih dan kering.',
    'sehat': 'false',
  },
  'psoriasis': {
    'tentang':
        'Psoriasis kuku adalah kondisi autoimun kronis di mana peradangan menyebabkan sel-sel kulit di bawah kuku tumbuh terlalu cepat, memicu perubahan struktur seperti lubang kecil, penebalan, perubahan warna, hingga kuku lepas. ',
    'indikasi': 'Autoimun psoriasis.',
    'saran':
        '• Segera konsultasikan dengan dokter kulit atau tenaga medis profesional.\n'
            '• Jaga area tetap bersih dan kering.',
    'sehat': 'false',
  },
  'onycholysis': {
    'tentang': 'Onikolisis merupakan kondisi terlepasnya lempeng kuku dari nail bed yang '
        'umumnya dimulai dari bagian distal akibat gangguan pada onychocorneal band '
        'dan dapat berkembang ke arah proksimal, sehingga menyebabkan terbentuknya '
        'ruang berisi udara di bawah kuku yang membuat kuku tampak berwarna putih.',
    'indikasi': 'Indikasiinfeksi jamur, '
        'psoriasis, penyakit jaringan ikat seperti systemic lupus erythematosus (SLE), '
        'systemic sclerosis, dermatomyositis, gangguan tiroid seperti hipertiroidisme '
        'dan hipotiroidisme, serta reaksi fototoksik akibat paparan obat tertentu '
        'atau cahaya (photo-onycholysis).',
    'saran':
        '• Segera konsultasikan dengan dokter kulit atau tenaga medis profesional.\n'
            '• Jaga area tetap bersih dan kering.',
    'sehat': 'false',
  },
  'acral lentiginous melanoma': {
    'tentang': 'ALM merupakan subtipe melanoma kutan yang muncul di kulit akral (telapak, '
        'telapak kaki, dan unit kuku) dan sering tampak sebagai pita atau bercak '
        'cokelat–hitam di bawah kuku, dengan batas asimetris, warna tidak seragam, '
        'pelebaran progresif, kadang disertai distorsi atau destruksi lempeng kuku ',
    'indikasi': 'Sering salah disangka hematoma, onikomikosis, atau '
        'melanonychia jinak, mengakibatkan keterlambatan diagnosis dan prognosis yang '
        'lebih buruk dibanding melanoma non-akral.',
    'saran':
        '• Segera konsultasikan dengan dokter kulit atau tenaga medis profesional.\n'
            '• Jaga area tetap bersih dan kering.',
    'sehat': 'false',
  },
  "beau's line": {
    'tentang': "Beau's lines merupakan kelainan kuku yang ditandai dengan munculnya lekukan "
        'atau garis melintang pada lempeng kuku akibat terjadinya gangguan sementara '
        'pada pertumbuhan matriks kuku. Ciri fisiknya berupa garis atau alur melintang '
        'pada permukaan kuku yang bergerak ke arah distal seiring pertumbuhan kuku.',
    'indikasi':
        'Indikasi hand-foot-mouth disease (HFMD), infeksi SARS-CoV-2 (COVID-19), '
            'Stevens-Johnson syndrome (SJS), toxic epidermal necrolysis (TEN), '
            'gagal ginjal kronis, dan diabetes mellitus tipe 2.',
    'saran':
        '• Segera konsultasikan dengan dokter kulit atau tenaga medis profesional.\n'
            '• Jaga area tetap bersih dan kering.',
    'sehat': 'false',
  },
};

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
  Uint8List? _gradcamImageBytes;

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

      final String? gradcamBase64String = nail['gradcam_image_base64'];
      if (gradcamBase64String != null && gradcamBase64String.isNotEmpty) {
        _gradcamImageBytes = base64Decode(gradcamBase64String);
      } else {
        _gradcamImageBytes = null;
      }

      // Lookup kondisi dari map menggunakan label lowercase
      final diagLower = _diagnosis.toLowerCase();
      final info = _conditionInfo[diagLower];

      _isHealthy = info?['sehat'] == 'true';
      _tentangKondisi = info?['tentang'] ??
          'Terdeteksi kemungkinan indikasi $_diagnosis pada kuku ini.';
      _indikasiKlinis = info?['indikasi'] ??
          'Perubahan pada struktur atau warna kuku yang terdeteksi oleh sistem AI.';
      _saranTindakan = info?['saran'] ??
          '• Segera konsultasikan dengan dokter kulit atau tenaga medis profesional.\n'
              '• Jaga area tetap bersih dan kering.';
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
                    Icon(Icons.help_outline,
                        color: Color(0xFF0F172A), size: 20),
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

              // 2. Perbandingan (Cropped vs Grad-CAM) berdampingan
              if (_croppedImageBytes != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  const Text('Gambar Asli',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF64748B))),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: Colors.grey
                                              .withValues(alpha: 0.2)),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: Image.memory(_croppedImageBytes!,
                                            fit: BoxFit.cover),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                children: [
                                  const Text('Grad-CAM',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF64748B))),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: Colors.grey
                                              .withValues(alpha: 0.2)),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: _gradcamImageBytes != null
                                            ? Image.memory(_gradcamImageBytes!,
                                                fit: BoxFit.cover)
                                            : Container(
                                                color: Colors.grey.shade100,
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: const Center(
                                                  child: Text('Grad-CAM N/A',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 12)),
                                                ),
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
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              // 3. Hasil Deteksi & Confidence Score
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

              const SizedBox(height: 16),

              const SizedBox(height: 8),

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
                'Diagnosis Kuku #${_selectedIndex + 1}',
                _diagnosis,
                Icons.biotech_rounded,
                isHighlight: true,
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
