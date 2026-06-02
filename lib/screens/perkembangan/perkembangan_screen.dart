import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../providers/auth_provider.dart';
import '../../core/constants/api_constants.dart';
import 'detail_perkembangan_screen.dart';

class PerkembanganScreen extends StatefulWidget {
  const PerkembanganScreen({super.key});

  @override
  State<PerkembanganScreen> createState() => _PerkembanganScreenState();
}

class _PerkembanganScreenState extends State<PerkembanganScreen>
    with SingleTickerProviderStateMixin {
  // ── FILTER STATE ──
  String _filterStatus = 'Semua'; // 'Semua' | 'Sudah Dianalisis' | 'Belum Dianalisis'
  String _sortOrder = 'Terbaru';  // 'Terbaru' | 'Terlama'

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ── PARSE DATA DARI AUTH PROVIDER ──
  List<_PerkembanganData> _parseList(dynamic dataSistem) {
    final dynamic raw = dataSistem?['perkembangan_list'];
    List<dynamic> listRaw = [];

    if (raw != null) {
      if (raw is String) {
        try {
          listRaw = jsonDecode(raw) as List<dynamic>;
        } catch (_) {
          listRaw = [];
        }
      } else if (raw is List) {
        listRaw = raw;
      }
    }

    return listRaw.map((item) {
      final Map<String, dynamic> d =
          item is String ? jsonDecode(item) : Map<String, dynamic>.from(item);
      final bool isSudah = d['status_analisis'] == true ||
          d['status_analisis'] == 1 ||
          d['status_analisis'] == '1';
      return _PerkembanganData(
        foto: dataSistem?['anak']?['foto']?.toString(),
        namaAnak: (d['nama_anak'] ?? 'Anak').toString(),
        kelompok: (d['kelompok'] ?? '-').toString(),
        minggu: int.tryParse(d['minggu']?.toString() ?? '0') ?? 0,
        tema: (d['tema'] ?? '-').toString(),
        statusAnalisis: isSudah ? 'Sudah Dianalisis' : 'Belum Dianalisis',
        isSudah: isSudah,
      );
    }).toList();
  }

  List<_PerkembanganData> _applyFilter(List<_PerkembanganData> list) {
    List<_PerkembanganData> result = [...list];

    // Filter status
    if (_filterStatus == 'Sudah Dianalisis') {
      result = result.where((e) => e.isSudah).toList();
    } else if (_filterStatus == 'Belum Dianalisis') {
      result = result.where((e) => !e.isSudah).toList();
    }

    // Sort
    result.sort((a, b) => _sortOrder == 'Terbaru'
        ? b.minggu.compareTo(a.minggu)
        : a.minggu.compareTo(b.minggu));

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dataSistem = auth.dashboardData;
    final anak = dataSistem?['anak'];

    // Fetch jika data belum ada
    if (dataSistem == null && !auth.isLoading) {
      Future.microtask(() => context.read<AuthProvider>().fetchDashboardData());
    }

    final allList = _parseList(dataSistem);
    final filteredList = _applyFilter(allList);

    final int sudahCount = allList.where((e) => e.isSudah).length;
    final int belumCount = allList.where((e) => !e.isSudah).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              // ── HEADER ──
              SliverToBoxAdapter(
                child: _buildHeader(context, anak),
              ),

              // ── SUMMARY CHIPS ──
              SliverToBoxAdapter(
                child: _buildSummaryRow(
                  total: allList.length,
                  sudah: sudahCount,
                  belum: belumCount,
                ),
              ),

              // ── FILTER BAR ──
              SliverToBoxAdapter(
                child: _buildFilterBar(),
              ),

              // ── LIST HEADER ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                  child: Row(
                    children: [
                      Text(
                        '${filteredList.length} data ditampilkan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── LOADING ──
              if (auth.isLoading && dataSistem == null)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF0E7490)),
                  ),
                )

              // ── EMPTY STATE ──
              else if (filteredList.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )

              // ── LIST ──
              // ── LIST ──
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _PerkembanganCard(
                        data: filteredList[index],
                        index: index,
                        onTap: () {
                          // 🔥 SEKARANG SUDAH TERSAMBUNG KETIKA CARD DI-TAP
                          Navigator.pushNamed(
                            context,
                            '/detail-perkembangan',
                            arguments: DetailPerkembanganArgs(
                              minggu: filteredList[index].minggu,
                              tema: filteredList[index].tema,
                              namaAnak: filteredList[index].namaAnak,
                              kelompok: filteredList[index].kelompok,
                              isSudah: filteredList[index].isSudah,
                            ),
                          );
                        },
                      ),
                      childCount: filteredList.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ── HEADER ──
  Widget _buildHeader(BuildContext context, dynamic anak) {
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
          // Top bar
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
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
              Text(
                "KB Nurul'Ain",
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              // Foto anak kecil di header
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withOpacity(0.2),
                backgroundImage: anak?['foto'] != null
                    ? NetworkImage(ApiConstants.fotoUrl(anak!['foto']))
                    : null,
                child: anak?['foto'] == null
                    ? const Icon(Icons.child_care, color: Colors.white, size: 18)
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Perkembangan',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      anak?['nama_anak'] != null
                          ? '${anak!['nama_anak']} · Kelompok ${anak['kelompok'] ?? '-'}'
                          : 'Rekap seluruh penilaian anak Anda',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Ikon dekorasi
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 26),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── SUMMARY ROW ──
  Widget _buildSummaryRow({required int total, required int sudah, required int belum}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          _SummaryChip(label: 'Total', value: total, color: const Color(0xFF0E7490), bg: const Color(0xFFE0F2FE)),
          const SizedBox(width: 10),
          _SummaryChip(label: 'Dianalisis', value: sudah, color: const Color(0xFF059669), bg: const Color(0xFFD1FAE5)),
          const SizedBox(width: 10),
          _SummaryChip(label: 'Belum', value: belum, color: const Color(0xFFDC2626), bg: const Color(0xFFFEE2E2)),
        ],
      ),
    );
  }

  // ── FILTER BAR ──
  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter status
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Semua', 'Sudah Dianalisis', 'Belum Dianalisis'].map((status) {
                final isActive = _filterStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _filterStatus = status;
                        _fadeController.reset();
                        _fadeController.forward();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF0E7490) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFF0E7490)
                              : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0E7490).withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : [],
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isActive ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // Sort
          Row(
            children: [
              Text(
                'Urutkan:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              ...[
                'Terbaru',
                'Terlama',
              ].map((sort) {
                final isActive = _sortOrder == sort;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _sortOrder = sort;
                      _fadeController.reset();
                      _fadeController.forward();
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF0E7490).withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFF0E7490).withOpacity(0.3)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            sort == 'Terbaru'
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            size: 12,
                            color: isActive
                                ? const Color(0xFF0E7490)
                                : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sort,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? const Color(0xFF0E7490)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
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
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.inbox_rounded, size: 36, color: Color(0xFF0E7490)),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada data',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _filterStatus == 'Semua'
                ? 'Belum ada penilaian dari guru.'
                : 'Tidak ada data dengan filter "$_filterStatus".',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── BOTTOM NAV ──
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: const Color(0xFF0E7490),
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11),
        elevation: 0,
        currentIndex: 1, // Tab "Data" aktif
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/dashboard');
              break;
            case 1:
              break; // Sudah di sini
            case 2:
              Navigator.pushReplacementNamed(context, '/analisis');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Data Perkembangan'),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb_rounded), label: 'Analisis AI'),
          BottomNavigationBarItem(icon: Icon(Icons.badge_rounded), label: 'Profil'),
        ],
      ),
    );
  }
}

// =========================================================
// DATA MODEL
// =========================================================
class _PerkembanganData {
  final String namaAnak, kelompok, tema, statusAnalisis;
  final int minggu;
  final String? foto;
  final bool isSudah;

  const _PerkembanganData({
    required this.namaAnak,
    required this.kelompok,
    required this.minggu,
    required this.tema,
    required this.statusAnalisis,
    required this.isSudah,
    this.foto,
  });
}

// =========================================================
// WIDGETS
// =========================================================

class _SummaryChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color, bg;
  const _SummaryChip({required this.label, required this.value, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
              child: Center(
                child: Text(
                  value.toString(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerkembanganCard extends StatelessWidget {
  final _PerkembanganData data;
  final int index;
  final VoidCallback onTap;
  const _PerkembanganCard({required this.data, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Memicu fungsi callback dari list di atas
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── BARIS UTAMA ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFFE0F2FE),
                        backgroundImage: data.foto != null && data.foto!.isNotEmpty
                            ? NetworkImage(ApiConstants.fotoUrl(data.foto))
                            : null,
                        child: (data.foto == null || data.foto!.isEmpty)
                            ? const Icon(Icons.face_6_rounded, color: Color(0xFF0E7490), size: 28)
                            : null,
                      ),
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E7490),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text(
                            'M${data.minggu}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                data.namaAnak,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                'Kelompok ${data.kelompok}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0E7490),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Minggu ${data.minggu}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tema: ${data.tema}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── FOOTER CARD: STATUS + DETAIL ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(color: const Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: data.isSudah ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          data.isSudah ? Icons.check_circle_rounded : Icons.schedule_rounded,
                          size: 11,
                          color: data.isSudah ? const Color(0xFF059669) : const Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          data.statusAnalisis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: data.isSudah ? const Color(0xFF059669) : const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        'Lihat Detail',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0E7490),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: Color(0xFF0E7490),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}