import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/api_constants.dart';

// =========================================================
// MODEL
// =========================================================
class AnalisisItem {
  final int minggu;
  final String tema, namaAnak, kelompok, statusDominan;
  final String? foto;
  final int avgConfidence, jumlahAspek;

  const AnalisisItem({
    required this.minggu,
    required this.tema,
    required this.namaAnak,
    required this.kelompok,
    required this.statusDominan,
    required this.avgConfidence,
    required this.jumlahAspek,
    this.foto,
  });

  factory AnalisisItem.fromJson(Map<String, dynamic> json) {
    return AnalisisItem(
      minggu:         int.tryParse(json['minggu']?.toString() ?? '0') ?? 0,
      tema:           json['tema']?.toString() ?? '-',
      namaAnak:       json['nama_anak']?.toString() ?? '-',
      kelompok:       json['kelompok']?.toString() ?? '-',
      statusDominan:  json['status_dominan']?.toString() ?? '-',
      avgConfidence:  int.tryParse(json['avg_confidence']?.toString() ?? '0') ?? 0,
      jumlahAspek:    int.tryParse(json['jumlah_aspek']?.toString() ?? '0') ?? 0,
      foto:           json['foto']?.toString(),
    );
  }
}

// =========================================================
// SCREEN
// =========================================================
class AnalisisScreen extends StatefulWidget {
  const AnalisisScreen({super.key});

  @override
  State<AnalisisScreen> createState() => _AnalisisScreenState();
}

class _AnalisisScreenState extends State<AnalisisScreen> {
  List<AnalisisItem> _list = [];
  List<AnalisisItem> _filtered = [];
  bool _isLoading = true;
  String? _error;
  String _filterStatus = 'Semua';

  final List<String> _statusOptions = [
    'Semua',
    'Berkembang Sangat Baik',
    'Berkembang Sesuai Harapan',
    'Mulai Berkembang',
    'Belum Berkembang',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();

      // Tunggu session siap dulu jika user masih null
      if (auth.user == null) {
        await auth.loadSession();
      }

      if (mounted) _fetchList();
    });
  }

  Future<void> _fetchList() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final auth = context.read<AuthProvider>();
      final dio = Dio();
      final response = await dio.get(
        '${ApiConstants.baseUrl}/parent/analisis',
        options: Options(headers: {
          'Authorization': 'Bearer ${auth.user!.token}',
          'Accept': 'application/json',
        }),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final items = (response.data['data'] as List)
            .map((e) => AnalisisItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        setState(() {
          _list = items;
          _filtered = items;
          _isLoading = false;
        });
      } else {
        setState(() { _error = 'Gagal memuat data'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _applyFilter(String status) {
    setState(() {
      _filterStatus = status;
      _filtered = status == 'Semua'
          ? _list
          : _list.where((e) => e.statusDominan == status).toList();
    });
  }

  // ── WARNA STATUS ──
  Color _statusColor(String status) {
    switch (status) {
      case 'Berkembang Sangat Baik':    return const Color(0xFF059669);
      case 'Berkembang Sesuai Harapan': return const Color(0xFF0E7490);
      case 'Mulai Berkembang':          return const Color(0xFFD97706);
      case 'Belum Berkembang':          return const Color(0xFFDC2626);
      default:                          return const Color(0xFF64748B);
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'Berkembang Sangat Baik':    return const Color(0xFFD1FAE5);
      case 'Berkembang Sesuai Harapan': return const Color(0xFFE0F2FE);
      case 'Mulai Berkembang':          return const Color(0xFFFEF3C7);
      case 'Belum Berkembang':          return const Color(0xFFFEE2E2);
      default:                          return const Color(0xFFF1F5F9);
    }
  }

  String _statusShort(String status) {
    switch (status) {
      case 'Berkembang Sangat Baik':    return 'BSB';
      case 'Berkembang Sesuai Harapan': return 'BSH';
      case 'Mulai Berkembang':          return 'MB';
      case 'Belum Berkembang':          return 'BB';
      default:                          return '-';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
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
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildSummaryRow()),
            SliverToBoxAdapter(child: _buildFilterBar()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: Text(
                  '${_filtered.length} hasil analisis',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                ),
              ),
            ),

            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: Color(0xFF0E7490))),
              )
            else if (_error != null)
              SliverFillRemaining(hasScrollBody: false, child: _buildErrorState())
            else if (_filtered.isEmpty)
              SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _AnalisisCard(
                      item: _filtered[i],
                      statusColor: _statusColor(_filtered[i].statusDominan),
                      statusBg: _statusBg(_filtered[i].statusDominan),
                      statusShort: _statusShort(_filtered[i].statusDominan),
                      statusIcon: _statusIcon(_filtered[i].statusDominan),
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/detail-analisis',
                        arguments: _filtered[i],
                      ),
                    ),
                    childCount: _filtered.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

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
                onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Text("KB Nurul'Ain", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              GestureDetector(
                onTap: _fetchList,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                ),
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
                    Text('Hasil Analisis AI', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24)),
                    const SizedBox(height: 6),
                    Text('Rekap analisis perkembangan anak berbasis AI', style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                  ],
                ),
              ),
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 26),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    if (_list.isEmpty) return const SizedBox.shrink();
    final bsb = _list.where((e) => e.statusDominan == 'Berkembang Sangat Baik').length;
    final bsh = _list.where((e) => e.statusDominan == 'Berkembang Sesuai Harapan').length;
    final mb  = _list.where((e) => e.statusDominan == 'Mulai Berkembang').length;
    final bb  = _list.where((e) => e.statusDominan == 'Belum Berkembang').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          _buildChip('BSB', bsb, const Color(0xFF059669), const Color(0xFFD1FAE5)),
          const SizedBox(width: 8),
          _buildChip('BSH', bsh, const Color(0xFF0E7490), const Color(0xFFE0F2FE)),
          const SizedBox(width: 8),
          _buildChip('MB',  mb,  const Color(0xFFD97706), const Color(0xFFFEF3C7)),
          const SizedBox(width: 8),
          _buildChip('BB',  bb,  const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
        ],
      ),
    );
  }

  Widget _buildChip(String label, int value, Color color, Color bg) {
    return Expanded(
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
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: color))),
            ),
            const SizedBox(height: 6),
            Text(value.toString(), style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
            Text('minggu', style: GoogleFonts.plusJakartaSans(fontSize: 9, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 0, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusOptions.map((status) {
            final isActive = _filterStatus == status;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _applyFilter(status),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF0E7490) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isActive ? const Color(0xFF0E7490) : const Color(0xFFE2E8F0)),
                    boxShadow: isActive ? [BoxShadow(color: const Color(0xFF0E7490).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))] : [],
                  ),
                  child: Text(
                    status == 'Semua' ? 'Semua' : _statusShort(status),
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: isActive ? Colors.white : const Color(0xFF64748B)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 64, height: 64, decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.error_outline_rounded, size: 32, color: Color(0xFFDC2626))),
          const SizedBox(height: 16),
          Text('Gagal memuat data', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF1E293B))),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _fetchList,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFF0E7490), borderRadius: BorderRadius.circular(12)),
              child: Text('Coba Lagi', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 64, height: 64, decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.psychology_outlined, size: 32, color: Color(0xFF7C3AED))),
          const SizedBox(height: 16),
          Text('Belum ada hasil analisis', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF1E293B))),
          const SizedBox(height: 6),
          Text(_filterStatus == 'Semua' ? 'Guru belum mengenerate analisis.' : 'Tidak ada data dengan filter ini.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF94A3B8)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, -4))]),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: const Color(0xFF0E7490),
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11),
        elevation: 0,
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0: Navigator.pushReplacementNamed(context, '/dashboard'); break;
            case 1: Navigator.pushReplacementNamed(context, '/perkembangan'); break;
            case 2: break;
            case 3: Navigator.pushReplacementNamed(context, '/profile'); break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Data'),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb_rounded), label: 'Analisis AI'),
          BottomNavigationBarItem(icon: Icon(Icons.badge_rounded), label: 'Profil'),
        ],
      ),
    );
  }
}

// =========================================================
// CARD WIDGET
// =========================================================
class _AnalisisCard extends StatelessWidget {
  final AnalisisItem item;
  final Color statusColor, statusBg;
  final String statusShort;
  final IconData statusIcon;
  final VoidCallback onTap;

  const _AnalisisCard({
    required this.item,
    required this.statusColor,
    required this.statusBg,
    required this.statusShort,
    required this.statusIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            // ── MAIN ROW ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + minggu badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFFEDE9FE),
                        backgroundImage: item.foto != null && item.foto!.isNotEmpty
                            ? NetworkImage(ApiConstants.fotoUrl(item.foto))
                            : null,
                        child: (item.foto == null || item.foto!.isEmpty)
                            ? const Icon(Icons.face_6_rounded, color: Color(0xFF7C3AED), size: 28)
                            : null,
                      ),
                      Positioned(
                        bottom: -4, right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text('M${item.minggu}', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
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
                              child: Text(item.namaAnak, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15, color: const Color(0xFF1E293B))),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(7)),
                              child: Text('Kelompok ${item.kelompok}', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF7C3AED))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Minggu ${item.minggu}', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                        const SizedBox(height: 2),
                        Text('Tema: ${item.tema}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8)), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── FOOTER ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 11, color: statusColor),
                        const SizedBox(width: 4),
                        Text(item.statusDominan, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Confidence
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFFF0F7FA), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome_rounded, size: 11, color: Color(0xFF0E7490)),
                        const SizedBox(width: 4),
                        Text('${item.avgConfidence}%', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF0E7490))),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Lihat detail
                  Row(
                    children: [
                      Text('Detail', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF7C3AED))),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF7C3AED)),
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