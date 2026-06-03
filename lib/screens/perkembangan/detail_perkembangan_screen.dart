import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/api_constants.dart';

// =========================================================
// MODEL
// =========================================================
class DetailPerkembanganItem {
  final String tanggal, topikHarian, aspek, capaian, deskripsi;
  const DetailPerkembanganItem({
    required this.tanggal,
    required this.topikHarian,
    required this.aspek,
    required this.capaian,
    required this.deskripsi,
  });

  factory DetailPerkembanganItem.fromJson(Map<String, dynamic> json) {
    return DetailPerkembanganItem(
      tanggal:    json['tanggal']?.toString() ?? '-',
      topikHarian: json['topik_harian']?.toString() ?? '-',
      aspek:      json['aspek']?.toString() ?? '-',
      capaian:    json['capaian']?.toString() ?? '-',
      deskripsi:  json['deskripsi']?.toString() ?? '-',
    );
  }
}

// =========================================================
// ARGUMENTS
// =========================================================
class DetailPerkembanganArgs {
  final int minggu;
  final String tema, namaAnak, kelompok;
  final bool isSudah;
  const DetailPerkembanganArgs({
    required this.minggu,
    required this.tema,
    required this.namaAnak,
    required this.kelompok,
    required this.isSudah,
  });
}

// =========================================================
// SCREEN
// =========================================================
class DetailPerkembanganScreen extends StatefulWidget {
  const DetailPerkembanganScreen({super.key});

  @override
  State<DetailPerkembanganScreen> createState() => _DetailPerkembanganScreenState();
}

class _DetailPerkembanganScreenState extends State<DetailPerkembanganScreen> {
  List<DetailPerkembanganItem> _data = [];
  bool _isLoading = true;
  String? _error;

  // State metadata header
  int?   _savedMinggu;
  String _savedTema     = '-';
  String _savedNamaAnak = '-';
  String _savedKelompok = '-';
  bool   _savedIsSudah  = false;

  Map<String, List<DetailPerkembanganItem>> _grouped = {};

  // ── KEY SharedPreferences ──
  static const _kMinggu   = 'perk_minggu';
  static const _kTema     = 'perk_tema';
  static const _kNama     = 'perk_nama';
  static const _kKelompok = 'perk_kelompok';
  static const _kIsSudah  = 'perk_issudah';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initData();
    });
  }

  Future<void> _initData() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    final prefs = await SharedPreferences.getInstance();

    if (args != null && args is DetailPerkembanganArgs) {
      // ── Ada arguments → simpan ke SharedPreferences ──
      await prefs.setInt(   _kMinggu,   args.minggu);
      await prefs.setString(_kTema,     args.tema);
      await prefs.setString(_kNama,     args.namaAnak);
      await prefs.setString(_kKelompok, args.kelompok);
      await prefs.setBool(  _kIsSudah,  args.isSudah);

      if (!mounted) return;
      setState(() {
        _savedMinggu   = args.minggu;
        _savedTema     = args.tema;
        _savedNamaAnak = args.namaAnak;
        _savedKelompok = args.kelompok;
        _savedIsSudah  = args.isSudah;
      });
    } else {
      // ── Tidak ada arguments (habis refresh) → baca dari SharedPreferences ──
      final minggu = prefs.getInt(_kMinggu);

      if (minggu == null) {
        // Belum pernah buka halaman ini sama sekali
        if (!mounted) return;
        setState(() {
          _error    = 'Silakan buka dari halaman Perkembangan';
          _isLoading = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _savedMinggu   = minggu;
        _savedTema     = prefs.getString(_kTema)     ?? '-';
        _savedNamaAnak = prefs.getString(_kNama)     ?? '-';
        _savedKelompok = prefs.getString(_kKelompok) ?? '-';
        _savedIsSudah  = prefs.getBool(_kIsSudah)    ?? false;
      });
    }

    // ── Pastikan session siap ──
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

    _fetchDetail(_savedMinggu!);
  }

  Future<void> _fetchDetail(int minggu) async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      final auth = context.read<AuthProvider>();
      final dio  = Dio();
      final response = await dio.get(
        '${ApiConstants.baseUrl}/parent/perkembangan/$minggu',
        options: Options(headers: {
          'Authorization': 'Bearer ${auth.user!.token}',
          'Accept': 'application/json',
        }),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> rawData = response.data['data'] ?? [];
        final items = rawData
            .map((e) => DetailPerkembanganItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        final Map<String, List<DetailPerkembanganItem>> grouped = {};
        for (final item in items) {
          grouped.putIfAbsent(item.topikHarian, () => []).add(item);
        }

        if (!mounted) return;
        setState(() {
          _data     = items;
          _grouped  = grouped;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() { _error = 'Gagal memuat data'; _isLoading = false; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Terjadi kesalahan: $e'; _isLoading = false; });
    }
  }

  // ── HELPERS WARNA ──
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

  String _capaianLabel(String c) {
    switch (c.toUpperCase()) {
      case 'BSB': return 'Berkembang Sangat Baik';
      case 'BSH': return 'Berkembang Sesuai Harapan';
      case 'MB':  return 'Mulai Berkembang';
      case 'BB':  return 'Belum Berkembang';
      default:    return c;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),

            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: Color(0xFF0E7490))),
              )
            else if (_error != null)
              SliverFillRemaining(hasScrollBody: false, child: _buildErrorState())
            else if (_data.isEmpty)
              SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
            else ...[
              SliverToBoxAdapter(child: _buildCapaianSummary()),
              SliverToBoxAdapter(child: _buildSectionTitle()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final topik = _grouped.keys.elementAt(index);
                      return _buildTopikGroup(topik, _grouped[topik]!);
                    },
                    childCount: _grouped.length,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── HEADER ──
  Widget _buildHeader(BuildContext context) {
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
                // Selalu kembali ke /perkembangan
                onTap: () => Navigator.pushReplacementNamed(context, '/perkembangan'),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Text("KB Nurul'Ain",
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _savedIsSudah
                      ? Colors.white.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _savedIsSudah ? Icons.check_circle_rounded : Icons.schedule_rounded,
                      color: Colors.white, size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _savedIsSudah ? 'Dianalisis' : 'Belum Dianalisis',
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Minggu $_savedMinggu',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),

          const SizedBox(height: 8),

          Text(_savedTema,
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
              maxLines: 2),

          const SizedBox(height: 6),

          Text('$_savedNamaAnak · Kelompok $_savedKelompok',
              style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.8), fontSize: 13)),
        ],
      ),
    );
  }

  // ── SUMMARY CAPAIAN ──
  Widget _buildCapaianSummary() {
    final counts = {'BB': 0, 'MB': 0, 'BSH': 0, 'BSB': 0};
    for (final item in _data) {
      final key = item.capaian.toUpperCase();
      if (counts.containsKey(key)) counts[key] = counts[key]! + 1;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: counts.entries.map((e) => Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Column(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: _capaianBg(e.key), borderRadius: BorderRadius.circular(8)),
                    child: Center(
                      child: Text(e.key, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: _capaianColor(e.key))),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(e.value.toString(), style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
                  Text('item', style: GoogleFonts.plusJakartaSans(fontSize: 9, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  // ── SECTION TITLE ──
  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: const Color(0xFF0E7490).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.list_alt_rounded, color: Color(0xFF0E7490), size: 17),
          ),
          const SizedBox(width: 10),
          Text('Data Perkembangan Mentah',
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
          const Spacer(),
          Text('${_data.length} data',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  // ── GROUPED BY TOPIK HARIAN ──
  Widget _buildTopikGroup(String topikHarian, List<DetailPerkembanganItem> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header topik
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
                Expanded(
                  child: Text(topikHarian,
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13, color: const Color(0xFF0E7490))),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF0E7490).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    items.isNotEmpty ? items.first.tanggal : '-',
                    style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF0E7490)),
                  ),
                ),
              ],
            ),
          ),

          // Rows penilaian
          ...items.asMap().entries.map((entry) {
            final i    = entry.key;
            final item = entry.value;
            final isLast = i == items.length - 1;

            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Aspek
                  Container(
                    width: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFF0F7FA), borderRadius: BorderRadius.circular(7)),
                    child: Text(item.aspek,
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF374151)),
                        textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 10),
                  // Deskripsi
                  Expanded(
                    child: Text(item.deskripsi,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF374151))),
                  ),
                  const SizedBox(width: 10),
                  // Capaian badge
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: _capaianBg(item.capaian), borderRadius: BorderRadius.circular(8)),
                        child: Text(item.capaian,
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: _capaianColor(item.capaian))),
                      ),
                      const SizedBox(height: 3),
                      SizedBox(
                        width: 50,
                        child: Text(_capaianLabel(item.capaian),
                            style: GoogleFonts.plusJakartaSans(fontSize: 8, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center, maxLines: 2),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
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
          Text('Gagal memuat data',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF1E293B))),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_error!,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8)),
                  textAlign: TextAlign.center),
            ),
          ],
          const SizedBox(height: 20),
          if (_savedMinggu != null)
            GestureDetector(
              onTap: () => _fetchDetail(_savedMinggu!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: const Color(0xFF0E7490), borderRadius: BorderRadius.circular(12)),
                child: Text('Coba Lagi', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            )
          else
            GestureDetector(
              onTap: () => Navigator.pushReplacementNamed(context, '/perkembangan'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: const Color(0xFF0E7490), borderRadius: BorderRadius.circular(12)),
                child: Text('Kembali ke Perkembangan',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }

  // ── EMPTY STATE ──
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.inbox_rounded, size: 32, color: Color(0xFF0E7490)),
          ),
          const SizedBox(height: 16),
          Text('Belum ada data penilaian',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF1E293B))),
          const SizedBox(height: 6),
          Text('Guru belum menginput penilaian\nuntuk minggu ini.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF94A3B8)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}