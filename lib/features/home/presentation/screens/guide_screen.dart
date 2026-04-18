import 'package:flutter/material.dart';

class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Pusat Panduan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildCustomTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDetectionGuide(),
                  _buildGradCAMGuide(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        labelColor: const Color(0xFF6366F1),
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: const [
          Tab(text: 'Metode Deteksi'),
          Tab(text: 'Analisis AI'),
        ],
      ),
    );
  }

  Widget _buildDetectionGuide() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVisualGuideCard(),
          const SizedBox(height: 24),
          _buildStepCard(
            'Langkah Pengambilan',
            Icons.camera_alt_rounded,
            const Color(0xFF10B981),
            [
              'Gunakan pencahayaan alami (siang hari)',
              'Dekatkan kamera hingga fokus terlihat tajam',
              'Pastikan kuku bersih dari kotoran/kutek',
              'Tahan posisi selama 2 detik saat memotret',
            ],
          ),
          const SizedBox(height: 16),
          _buildStepCard(
            'Kesalahan Umum',
            Icons.error_outline_rounded,
            const Color(0xFFF43F5E),
            [
              'Foto terlalu buram atau tidak fokus',
              'Cahaya terlalu redup atau terlalu silau',
              'Posisi kuku terpotong dari bingkai',
              'Memakai perhiasan yang menutupi kuku',
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildGradCAMGuide() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const RadialGradient(
                      center: Alignment(0.2, -0.1),
                      radius: 0.8,
                      colors: [
                        Color(0xFFF43F5E),
                        Color(0xFFFBBF24),
                        Color(0xFF3B82F6),
                      ],
                      stops: [0.1, 0.4, 1.0],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.center_focus_strong, color: Colors.white, size: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Apa itu Heatmap AI?',
                  style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Teknologi visualisasi yang menunjukkan bagian kuku mana yang dianggap paling penting oleh Kecerdasan Buatan dalam menentukan diagnosis.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: const Color(0xFF64748B), height: 1.6, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildStepCard(
            'Interpretasi Warna',
            Icons.palette_outlined,
            const Color(0xFF6366F1),
            [
              'Merah: Area krusial indikasi penyakit',
              'Kuning: Area pendukung diagnosis',
              'Biru: Area normal / sehat',
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildVisualGuideCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.photo_camera_front, color: Color(0xFF6366F1), size: 20),
              SizedBox(width: 8),
              Text(
                'Posisi Kamera Ideal',
                style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildGuideImageWithLabel('Tampak Atas', Icons.center_focus_strong_rounded)),
              const SizedBox(width: 16),
              Expanded(child: _buildGuideImageWithLabel('Tampak Samping', Icons.rotate_90_degrees_ccw_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuideImageWithLabel(String label, IconData icon) {
    return Column(
      children: [
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0E7FF)),
          ),
          child: Center(
            child: Icon(icon, color: const Color(0xFF6366F1), size: 36),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF334155), fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildStepCard(String title, IconData icon, Color accentColor, List<String> steps) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...steps.map((step) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step,
                    style: const TextStyle(color: Color(0xFF475569), fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}
