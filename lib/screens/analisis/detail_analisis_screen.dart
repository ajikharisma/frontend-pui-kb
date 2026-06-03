import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/api_constants.dart';

// =========================================================
// MODEL DETAIL
// =========================================================
class DetailAnalisisData {
  final int minggu;
  final String tema, namaAnak, kelompok, statusDominan;
  final String? foto;
  final int totalBb, totalMb, totalBsh, totalBsb;
  final List<PerAspekData> perAspek;

  const DetailAnalisisData({
    required this.minggu,
    required this.tema,
    required this.namaAnak,
    required this.kelompok,
    required this.statusDominan,
    this.foto,
    required this.totalBb,
    required this.totalMb,
    required this.totalBsh,
    required this.totalBsb,
    required this.perAspek,
  });
}

class PerAspekData {
  final String aspek, nilaiDominan, statusPerkembangan, rekomendasiAi, tanggalAnalisis;
  final int jumlahBb, jumlahMb, jumlahBsh, jumlahBsb, totalPenilaian, confidence;
  final List<dynamic> indikatorLemah;
  final bool aiGenerated;

  const PerAspekData({
    required this.aspek,
    required this.nilaiDominan,
    required this.statusPerkembangan,
    required this.rekomendasiAi,
    required this.tanggalAnalisis,
    required this.jumlahBb,
    required this.jumlahMb,
    required this.jumlahBsh,
    required this.jumlahBsb,
    required this.totalPenilaian,
    required this.confidence,
    required this.indikatorLemah,
    required this.aiGenerated,
  });

  factory PerAspekData.fromJson(Map<String, dynamic> json) {
    return PerAspekData(
      aspek:              json['aspek']?.toString() ?? '-',
      nilaiDominan:       json['nilai_dominan']?.toString() ?? '-',
      statusPerkembangan: json['status_perkembangan']?.toString() ?? '-',
      rekomendasiAi:      json['rekomendasi_ai']?.toString() ?? '',
      tanggalAnalisis:    json['tanggal_analisis']?.toString() ?? '-',
      jumlahBb:           int.tryParse(json['jumlah_bb']?.toString() ?? '0') ?? 0,
      jumlahMb:           int.tryParse(json['jumlah_mb']?.toString() ?? '0') ?? 0,
      jumlahBsh:          int.tryParse(json['jumlah_bsh']?.toString() ?? '0') ?? 0,
      jumlahBsb:          int.tryParse(json['jumlah_bsb']?.toString() ?? '0') ?? 0,
      totalPenilaian:     int.tryParse(json['total_penilaian']?.toString() ?? '0') ?? 0,
      confidence:         int.tryParse(json['confidence']?.toString() ?? '0') ?? 0,
      indikatorLemah:     json['indikator_lemah'] is List ? json['indikator_lemah'] : [],
      aiGenerated:        json['ai_generated'] == true || json['ai_generated'] == 1,
    );
  }
}

// =========================================================
// SCREEN
// =========================================================
class DetailAnalisisScreen extends StatefulWidget {
  const DetailAnalisisScreen({super.key});

  @override
  State<DetailAnalisisScreen> createState() => _DetailAnalisisScreenState();
}

class _DetailAnalisisScreenState extends State<DetailAnalisisScreen> {
  DetailAnalisisData? _data;
  bool _isLoading = true;
  String? _error;
  int? _minggu;

  // ── KEY SharedPreferences ──
  static const _kMinggu = 'analisis_minggu';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initData();
    });
  }

  Future<void> _initData() async {
    final args  = ModalRoute.of(context)?.settings.arguments;
    final prefs = await SharedPreferences.getInstance();

    int? minggu;
    if (args is int) {
      minggu = args;
    } else if (args is Map<String, dynamic>) {
      minggu = int.tryParse(args['minggu']?.toString() ?? '');
    }

    if (minggu != null) {
      // Ada arguments → simpan ke SharedPreferences
      await prefs.setInt(_kMinggu, minggu);
      _minggu = minggu;
    } else {
      // Tidak ada arguments (habis refresh) → baca dari SharedPreferences
      final saved = prefs.getInt(_kMinggu);
      if (saved == null) {
        if (!mounted) return;
        setState(() {
          _error    = 'Silakan buka dari halaman Analisis';
          _isLoading = false;
        });
        return;
      }
      _minggu = saved;
    }

    // Pastikan session siap
    final auth = context.read<AuthProvider>();
    if (auth.user == null) await auth.loadSession();
    if (!mounted) return;

    if (context.read<AuthProvider>().user == null) {
      setState(() {
        _error    = 'Sesi berakhir, silakan login ulang';
        _isLoading = false;
      });
      return;
    }

    _fetchDetail(_minggu!);
  }

  Future<void> _fetchDetail(int minggu) async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      final auth = context.read<AuthProvider>();
      final dio  = Dio();
      final response = await dio.get(
        '${ApiConstants.baseUrl}/parent/analisis/$minggu',
        options: Options(headers: {
          'Authorization': 'Bearer ${auth.user!.token}',
          'Accept': 'application/json',
        }),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final d = response.data;
        final perAspek = (d['per_aspek'] as List)
            .map((e) => PerAspekData.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        if (!mounted) return;
        setState(() {
          _data = DetailAnalisisData(
            minggu:        int.tryParse(d['minggu']?.toString() ?? '0') ?? 0,
            tema:          d['tema']?.toString() ?? '-',
            namaAnak:      d['nama_anak']?.toString() ?? '-',
            kelompok:      d['kelompok']?.toString() ?? '-',
            statusDominan: d['status_dominan']?.toString() ?? '-',
            foto:          d['foto']?.toString(),
            totalBb:       int.tryParse(d['total_bb']?.toString() ?? '0') ?? 0,
            totalMb:       int.tryParse(d['total_mb']?.toString() ?? '0') ?? 0,
            totalBsh:      int.tryParse(d['total_bsh']?.toString() ?? '0') ?? 0,
            totalBsb:      int.tryParse(d['total_bsb']?.toString() ?? '0') ?? 0,
            perAspek:      perAspek,
          );
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() { _error = 'Gagal memuat data'; _isLoading = false; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  // ── STRIP MARKDOWN ──
  String _stripMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'#{1,6}\s*'), '')
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*(.+?)\*'), r'$1')
        .replaceAll(RegExp(r'__(.+?)__'), r'$1')
        .replaceAll(RegExp(r'_(.+?)_'), r'$1')
        .replaceAll(RegExp(r'^\s*[-*]\s+', multiLine: true), '• ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  // ── HELPERS WARNA ──
  Color _statusColor(String s) {
    switch (s) {
      case 'Berkembang Sangat Baik':    return const Color(0xFF059669);
      case 'Berkembang Sesuai Harapan': return const Color(0xFF0E7490);
      case 'Mulai Berkembang':          return const Color(0xFFD97706);
      case 'Belum Berkembang':          return const Color(0xFFDC2626);
      default:                          return const Color(0xFF64748B);
    }
  }

  Color _statusBg(String s) {
    switch (s) {
      case 'Berkembang Sangat Baik':    return const Color(0xFFD1FAE5);
      case 'Berkembang Sesuai Harapan': return const Color(0xFFE0F2FE);
      case 'Mulai Berkembang':          return const Color(0xFFFEF3C7);
      case 'Belum Berkembang':          return const Color(0xFFFEE2E2);
      default:                          return const Color(0xFFF1F5F9);
    }
  }

  Color _capaianColor(String c) {
    switch (c.toUpperCase()) {
      case 'BSB': return const Color(0xFF059669);
      case 'BSH': return const Color(0xFF0E7490);
      case 'MB':  return const Color(0xFFD97706);
      case 'BB':  return const Color(0xFFDC2626);
      default:    return const Color(0xFF64748B);
    }
  }

  Color _capaianBg(String c) {
    switch (c.toUpperCase()) {
      case 'BSB': return const Color(0xFFD1FAE5);
      case 'BSH': return const Color(0xFFE0F2FE);
      case 'MB':  return const Color(0xFFFEF3C7);
      case 'BB':  return const Color(0xFFFEE2E2);
      default:    return const Color(0xFFF1F5F9);
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'Berkembang Sangat Baik':    return Icons.star_rounded;
      case 'Berkembang Sesuai Harapan': return Icons.check_circle_rounded;
      case 'Mulai Berkembang':          return Icons.trending_up_rounded;
      case 'Belum Berkembang':          return Icons.warning_amber_rounded;
      default:                          return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FA),
      body: SafeArea(
        child: _isLoading
            ? _buildLoading()
            : _error != null
                ? _buildErrorState()
                : _buildContent(),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator(color: Color(0xFF0E7490)));
  }

  Widget _buildContent() {
    final d = _data!;

    final totalAspek     = d.perAspek.length;
    final aspekBaik      = d.perAspek.where((e) =>
        e.statusPerkembangan == 'Berkembang Sangat Baik' ||
        e.statusPerkembangan == 'Berkembang Sesuai Harapan').length;
    final perluStimulasi = d.perAspek.where((e) =>
        e.statusPerkembangan == 'Mulai Berkembang' ||
        e.statusPerkembangan == 'Belum Berkembang').length;
    final dataValid      = d.perAspek.where((e) => e.totalPenilaian >= 3).length;
    final statusDominan  = d.statusDominan;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(d)),
        SliverToBoxAdapter(child: _buildStatRow(totalAspek, aspekBaik, perluStimulasi, dataValid, totalAspek)),
        SliverToBoxAdapter(child: _buildKesimpulan(d, statusDominan)),
        SliverToBoxAdapter(child: _buildCapaianBar(d)),
        SliverToBoxAdapter(child: _buildSectionTitle('Analisis Per Aspek', Icons.bar_chart_rounded)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _buildAspekCard(d.perAspek[i]),
              childCount: d.perAspek.length,
            ),
          ),
        ),
        if (d.perAspek.any((e) => e.rekomendasiAi.isNotEmpty && e.rekomendasiAi != '-')) ...[
          SliverToBoxAdapter(child: _buildSectionTitle('Rekomendasi AI — Gemini', Icons.auto_awesome_rounded)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverToBoxAdapter(
              child: _buildRekomendasiCard(
                d.perAspek.firstWhere((e) => e.rekomendasiAi.isNotEmpty && e.rekomendasiAi != '-'),
                d.namaAnak,
              ),
            ),
          ),
        ] else ...[
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ],
    );
  }

  // ── HEADER ──
  Widget _buildHeader(DetailAnalisisData d) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E7490), Color(0xFF0A5F73)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pushReplacementNamed(context, '/analisis'),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Text("KB Nurul'Ain", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text('AI Generated', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: d.foto != null && d.foto!.isNotEmpty
                      ? NetworkImage(ApiConstants.fotoUrl(d.foto))
                      : null,
                  child: (d.foto == null || d.foto!.isEmpty)
                      ? const Icon(Icons.face_6_rounded, color: Colors.white, size: 28)
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.namaAnak, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _headerBadge('Kelompok ${d.kelompok}'),
                        const SizedBox(width: 6),
                        _headerBadge('Minggu ${d.minggu}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Tema: ${d.tema}',
                        style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.8), fontSize: 12),
                        maxLines: 2),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(7)),
      child: Text(text, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  // ── STAT ROW ──
  Widget _buildStatRow(int total, int baik, int perlu, int valid, int totalAspek) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          _statBox('$total',          'Total Aspek',     Icons.layers_rounded,        const Color(0xFFE0F2FE), const Color(0xFF0E7490)),
          const SizedBox(width: 10),
          _statBox('$baik',           'Aspek Baik',      Icons.check_circle_rounded,  const Color(0xFFD1FAE5), const Color(0xFF059669)),
          const SizedBox(width: 10),
          _statBox('$perlu',          'Perlu Stimulasi', Icons.warning_amber_rounded,  const Color(0xFFFEF3C7), const Color(0xFFD97706)),
          const SizedBox(width: 10),
          _statBox('$valid/$totalAspek', 'Data Valid',   Icons.verified_rounded,      const Color(0xFFEDE9FE), const Color(0xFF7C3AED)),
        ],
      ),
    );
  }

  Widget _statBox(String value, String label, IconData icon, Color bg, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), height: 1.3), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── KESIMPULAN ──
  Widget _buildKesimpulan(DetailAnalisisData d, String statusDominan) {
    final tanggal = d.perAspek.isNotEmpty ? d.perAspek.first.tanggalAnalisis : '-';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0E7490).withOpacity(0.06),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: const Color(0xFF0E7490), borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 10),
                Text('KESIMPULAN PERKEMBANGAN MINGGU INI',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF0E7490), letterSpacing: 0.5)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: _statusBg(statusDominan), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(statusDominan), color: _statusColor(statusDominan), size: 16),
                      const SizedBox(width: 6),
                      Text(statusDominan, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: _statusColor(statusDominan))),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text('${d.namaAnak} • Tema: ${d.tema} • Minggu ke-${d.minggu}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B))),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _capaianPill('BSB', d.totalBsb),
                    const SizedBox(width: 6),
                    _capaianPill('BSH', d.totalBsh),
                    const SizedBox(width: 6),
                    _capaianPill('MB',  d.totalMb),
                    const SizedBox(width: 6),
                    _capaianPill('BB',  d.totalBb),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text('Dicetak pada: $tanggal', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF94A3B8))),
                  ],
                ),
                if (d.perAspek.any((e) => e.totalPenilaian < 3)) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFD97706)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Data masih terbatas. Tambahkan lebih banyak penilaian untuk hasil yang lebih akurat.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFFD97706)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _capaianPill(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: _capaianBg(label), borderRadius: BorderRadius.circular(7)),
      child: Text('$label: $count aspek', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: _capaianColor(label))),
    );
  }

  // ── CAPAIAN BAR ──
  Widget _buildCapaianBar(DetailAnalisisData d) {
    final total = d.totalBb + d.totalMb + d.totalBsh + d.totalBsb;
    if (total == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Distribusi Capaian', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                if (d.totalBsb > 0) Expanded(flex: d.totalBsb, child: Container(height: 10, color: const Color(0xFF059669))),
                if (d.totalBsh > 0) Expanded(flex: d.totalBsh, child: Container(height: 10, color: const Color(0xFF0E7490))),
                if (d.totalMb  > 0) Expanded(flex: d.totalMb,  child: Container(height: 10, color: const Color(0xFFD97706))),
                if (d.totalBb  > 0) Expanded(flex: d.totalBb,  child: Container(height: 10, color: const Color(0xFFDC2626))),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _legendItem('BSB', d.totalBsb, total, const Color(0xFF059669)),
              _legendItem('BSH', d.totalBsh, total, const Color(0xFF0E7490)),
              _legendItem('MB',  d.totalMb,  total, const Color(0xFFD97706)),
              _legendItem('BB',  d.totalBb,  total, const Color(0xFFDC2626)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, int count, int total, Color color) {
    final pct = total > 0 ? ((count / total) * 100).round() : 0;
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          Text('$pct%', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
        ],
      ),
    );
  }

  // ── SECTION TITLE ──
  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: const Color(0xFF0E7490).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: const Color(0xFF0E7490), size: 17),
          ),
          const SizedBox(width: 10),
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
        ],
      ),
    );
  }

  // ── ASPEK CARD ──
  Widget _buildAspekCard(PerAspekData a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: _statusBg(a.statusPerkembangan).withOpacity(0.5),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Expanded(child: Text(a.aspek, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: const Color(0xFF1E293B)))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _statusBg(a.statusPerkembangan), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(a.statusPerkembangan), size: 11, color: _statusColor(a.statusPerkembangan)),
                      const SizedBox(width: 4),
                      Text(a.statusPerkembangan, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor(a.statusPerkembangan))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: _capaianBg(a.nilaiDominan), borderRadius: BorderRadius.circular(8)),
                      child: Text('Dominan: ${a.nilaiDominan}', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: _capaianColor(a.nilaiDominan))),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(color: const Color(0xFFF0F7FA), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 11, color: Color(0xFF7C3AED)),
                          const SizedBox(width: 4),
                          Text('${a.confidence}% confidence', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF7C3AED))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _aspekCapaianItem('BB',  a.jumlahBb),
                    _aspekCapaianItem('MB',  a.jumlahMb),
                    _aspekCapaianItem('BSH', a.jumlahBsh),
                    _aspekCapaianItem('BSB', a.jumlahBsb),
                  ],
                ),
                if (a.indikatorLemah.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.flag_rounded, size: 13, color: Color(0xFFDC2626)),
                            const SizedBox(width: 4),
                            Text('Indikator Perlu Perhatian', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFFDC2626))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...a.indikatorLemah.map((ind) {
                          final nama = ind is Map
                              ? (ind['nama']?.toString() ?? ind.toString())
                              : ind.toString();
                          return Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(color: Color(0xFFDC2626), fontSize: 12)),
                                Expanded(child: Text(nama, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFFDC2626)))),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _aspekCapaianItem(String label, int count) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: _capaianBg(label), borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: _capaianColor(label))),
            const SizedBox(height: 2),
            Text(count.toString(), style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: _capaianColor(label))),
          ],
        ),
      ),
    );
  }

  // ── REKOMENDASI AI ──
  Widget _buildRekomendasiCard(PerAspekData a, String namaAnak) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE9FE)),
        boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(
              color: Color(0xFFEDE9FE),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Color(0xFF7C3AED), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Dihasilkan berdasarkan analisis perkembangan minggu ini',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF7C3AED))),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF7C3AED).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 10, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 3),
                      Text('AI Generated', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF7C3AED))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _stripMarkdown(a.rekomendasiAi),
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF334155), height: 1.6, letterSpacing: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  // ── ERROR STATE ──
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.error_outline_rounded, size: 32, color: Color(0xFFDC2626)),
          ),
          const SizedBox(height: 16),
          Text('Gagal memuat data', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF1E293B))),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_error!, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8)), textAlign: TextAlign.center),
            ),
          ],
          const SizedBox(height: 20),
          if (_minggu != null)
            GestureDetector(
              onTap: () => _fetchDetail(_minggu!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: const Color(0xFF0E7490), borderRadius: BorderRadius.circular(12)),
                child: Text('Coba Lagi', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            )
          else
            GestureDetector(
              onTap: () => Navigator.pushReplacementNamed(context, '/analisis'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: const Color(0xFF0E7490), borderRadius: BorderRadius.circular(12)),
                child: Text('Kembali ke Analisis', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}