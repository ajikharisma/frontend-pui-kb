import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'dart:convert';
import '../../core/constants/api_constants.dart';
import '../perkembangan/detail_perkembangan_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final dataSistem = auth.dashboardData;
    final anak = dataSistem?['anak'];
    final namaAnak = anak?['nama_anak'] ?? '-';
    final kelompok = anak?['kelompok'] ?? '-';
    final fotoAnak = anak?['foto'];

    if (dataSistem == null && !auth.isLoading) {
      Future.microtask(() => context.read<AuthProvider>().fetchDashboardData());
    }

    if (auth.isLoading && dataSistem == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F7FA),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF0E7490),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: Color(0xFF0E7490)),
            ],
          ),
        ),
      );
    }

    final int totalPenilaianReal = dataSistem?['total_penilaian'] ?? 0;
    final int menungguAnalisisReal = dataSistem?['menunggu_analisis'] ?? 0;
    final int sudahDianalisisReal = dataSistem?['sudah_dianalisis'] ?? 0;

    final dynamic rawPerkembangan = dataSistem?['perkembangan_list'];
    List<dynamic> listRaw = [];

    if (rawPerkembangan != null) {
      if (rawPerkembangan is String) {
        try {
          listRaw = jsonDecode(rawPerkembangan) as List<dynamic>;
        } catch (e) {
          listRaw = [];
        }
      } else if (rawPerkembangan is List) {
        listRaw = rawPerkembangan;
      }
    }

    final List<_PerkembanganData> listPerkembanganDinamis = listRaw.map((item) {
      final Map<String, dynamic> dataItem =
          item is String ? jsonDecode(item) : Map<String, dynamic>.from(item);
      final bool isSudah = dataItem['status_analisis'] == true ||
          dataItem['status_analisis'] == 1 ||
          dataItem['status_analisis'] == '1';
      return _PerkembanganData(
        foto: dataSistem?['anak']?['foto']?.toString(),
        namaAnak: (dataItem['nama_anak'] ?? 'Anak').toString(),
        kelompok: (dataItem['kelompok'] ?? '-').toString(),
        minggu: int.tryParse(dataItem['minggu']?.toString() ?? '0') ?? 0,
        tema: (dataItem['tema'] ?? '-').toString(),
        statusAnalisis: isSudah ? 'Sudah Dianalisis' : 'Belum Dianalisis',
        statusColor: isSudah ? const Color(0xFF059669) : const Color(0xFFDC2626),
        statusBg: isSudah ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
      );
    }).toList();

    // Sort by minggu descending, ambil 3 terbaru
    final sortedList = [...listPerkembanganDinamis]
      ..sort((a, b) => b.minggu.compareTo(a.minggu));
    final displayList = sortedList.take(3).toList();
    final hasMore = listPerkembanganDinamis.length > 3;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(context, user?.nama ?? 'Orang Tua', namaAnak, kelompok, fotoAnak),
            ),
            SliverToBoxAdapter(
              child: _buildProfilAnak(anak),
            ),
            SliverToBoxAdapter(
              child: _buildStatCards(
                total: totalPenilaianReal,
                menunggu: menungguAnalisisReal,
                sudah: sudahDianalisisReal,
              ),
            ),
            SliverToBoxAdapter(
              child: _buildSectionTitle('Perkembangan Terkini', Icons.history_edu_rounded),
            ),
            SliverToBoxAdapter(
              child: _buildPerkembanganList(context, displayList, hasMore, listPerkembanganDinamis),
            ),
            SliverToBoxAdapter(
              child: _buildSectionTitle('Menu Utama', Icons.grid_view_rounded),
            ),
            SliverToBoxAdapter(
              child: _buildMenuGrid(context),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ── HEADER ──
  Widget _buildHeader(BuildContext context, String namaUser, String namaAnak,
      String kelompok, String? fotoAnak) {
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
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                "KB Nurul'Ain",
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/notifikasi');
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(
                          Icons.notifications_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),

                      // Badge jumlah notifikasi
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "Selamat Datang,",
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${namaUser.split(' ').first} 👋",
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Pantau perkembangan anak Anda di KB Nurul'Ain",
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── PROFIL ANAK ──
  Widget _buildProfilAnak(dynamic anak) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E7490).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF0E7490).withOpacity(0.2), width: 2),
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFFE0F2FE),
              backgroundImage: anak?['foto'] != null
                  ? NetworkImage(ApiConstants.fotoUrl(anak!['foto']))
                  : null,
              child: anak?['foto'] == null
                  ? const Icon(Icons.child_care, size: 36, color: Color(0xFF0E7490))
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  anak?['nama_anak'] ?? '-',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Kelompok ${anak?['kelompok'] ?? '-'}',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF0E7490),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.child_friendly_rounded, color: Color(0xFF0E7490), size: 20),
          ),
        ],
      ),
    );
  }

  // ── STAT CARDS ──
  Widget _buildStatCards({required int total, required int menunggu, required int sudah}) {
    final stats = [
      _StatData(label: 'Total\nPenilaian', value: total.toString(), icon: Icons.assignment_turned_in_rounded, bgColor: const Color(0xFFE0F2FE), iconColor: const Color(0xFF0E7490)),
      _StatData(label: 'Menunggu\nAnalisis', value: menunggu.toString(), icon: Icons.hourglass_empty_rounded, bgColor: const Color(0xFFFEE2E2), iconColor: const Color(0xFFDC2626)),
      _StatData(label: 'Sudah\nDianalisis', value: sudah.toString(), icon: Icons.fact_check_rounded, bgColor: const Color(0xFFD1FAE5), iconColor: const Color(0xFF059669)),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: stats.asMap().entries.map((e) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: e.key < stats.length - 1 ? 10 : 0),
              child: _StatCard(data: e.value),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── SECTION TITLE ──
  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF0E7490).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF0E7490), size: 17),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  // ── PERKEMBANGAN LIST dengan tombol Lihat Semua ──
  Widget _buildPerkembanganList(BuildContext context, List<_PerkembanganData> displayList,
      bool hasMore, List<_PerkembanganData> allList) {
    if (displayList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Icon(Icons.inbox_rounded, size: 40, color: Colors.grey.shade300),
              const SizedBox(height: 10),
              Text(
                'Belum ada data penilaian dari guru.',
                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // 🔥 SAMBUNGKAN ONTAP SECARA LANGSUNG PADA MAP DI SINI
          ...displayList.map((item) => _PerkembanganCard(
                data: item,
                onTap: () {
                  final bool isSudahFix = item.statusAnalisis == 'Sudah Dianalisis';
                  
                  Navigator.pushNamed(
                    context,
                    '/detail-perkembangan',
                    arguments: DetailPerkembanganArgs(
                      minggu: item.minggu,
                      tema: item.tema,
                      namaAnak: item.namaAnak,
                      kelompok: item.kelompok,
                      isSudah: isSudahFix,
                    ),
                  );
                },
              )),
          if (hasMore) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _showAllPerkembangan(context, allList),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0E7490).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Lihat Semua Perkembangan',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF0E7490),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, color: Color(0xFF0E7490), size: 16),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAllPerkembangan(BuildContext context, List<_PerkembanganData> allList) {
    Navigator.pushNamed(context, '/perkembangan');
  }

  // ── MENU GRID ──
  Widget _buildMenuGrid(BuildContext context) {
    final menus = [
      _MenuData(label: 'Data\nPerkembangan', icon: Icons.bar_chart_rounded, bgColor: const Color(0xFFE0F2FE), iconColor: const Color(0xFF0E7490), route: '/perkembangan'),
      _MenuData(label: 'Hasil\nAnalisis AI', icon: Icons.psychology_rounded, bgColor: const Color(0xFFEDE9FE), iconColor: const Color(0xFF7C3AED), route: '/analisis'),
      _MenuData(label: 'Catatan Anak\nDi Rumah', icon: Icons.assignment_ind_rounded, bgColor: const Color(0xFFD1FAE5), iconColor: const Color(0xFF059669), route: '/catatan-rumah'),
      _MenuData(label: 'Profil\nAkun', icon: Icons.manage_accounts_rounded, bgColor: const Color(0xFFFEF3C7), iconColor: const Color(0xFFD97706), route: '/profile'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: menus.map((m) => _MenuCard(
          data: m,
          onTap: () => Navigator.pushNamed(context, m.route),
        )).toList(),
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
        selectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 11),
        elevation: 0,
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // Sudah di Beranda
              break;
            case 1:
              Navigator.pushNamed(context, '/perkembangan');
              break;
            case 2:
              Navigator.pushNamed(context, '/analisis');
              break;
            case 3:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Data Perkembangan'),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb_rounded), label: 'Hasil Analisis'),
          BottomNavigationBarItem(icon: Icon(Icons.manage_accounts_rounded), label: 'Profil'),
        ],
      ),
    );
  }
}

// ── MODAL: SEMUA PERKEMBANGAN ──
class _AllPerkembanganSheet extends StatelessWidget {
  final List<_PerkembanganData> allList;
  const _AllPerkembanganSheet({required this.allList});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF0F7FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E7490).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.history_edu_rounded, color: Color(0xFF0E7490), size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'Semua Perkembangan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: allList.length,
              itemBuilder: (context, i) => _PerkembanganCard(
                data: allList[i],
                // 🔥 TAMBAHKAN BLOK ONTAP DI SINI UNTUK MEMPERBAIKI ERROR
                onTap: () {
                  // Tutup bottom sheet terlebih dahulu agar transisi navigasi mulus
                  Navigator.pop(context);
                  
                  final bool isSudahFix = allList[i].statusAnalisis == 'Sudah Dianalisis';

                  Navigator.pushNamed(
                    context,
                    '/detail-perkembangan',
                    arguments: DetailPerkembanganArgs(
                      minggu: allList[i].minggu,
                      tema: allList[i].tema,
                      namaAnak: allList[i].namaAnak,
                      kelompok: allList[i].kelompok,
                      isSudah: isSudahFix,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// DATA MODELS
// =========================================================
class _StatData {
  final String label, value;
  final IconData icon;
  final Color bgColor, iconColor;
  const _StatData({required this.label, required this.value, required this.icon, required this.bgColor, required this.iconColor});
}

class _PerkembanganData {
  final String namaAnak, kelompok, tema, statusAnalisis;
  final int minggu;
  final String? foto;
  final Color statusColor, statusBg;
  const _PerkembanganData({
    required this.namaAnak, required this.kelompok, required this.minggu,
    required this.tema, required this.statusAnalisis, required this.statusColor,
    required this.statusBg, required this.foto,
  });
}

class _MenuData {
  final String label, route;
  final IconData icon;
  final Color bgColor, iconColor;
  const _MenuData({required this.label, required this.icon, required this.bgColor, required this.iconColor, required this.route});
}

// =========================================================
// COMPONENT WIDGETS
// =========================================================
class _StatCard extends StatelessWidget {
  final _StatData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: data.bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.iconColor, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            data.value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PerkembanganCard extends StatelessWidget {
  final _PerkembanganData data;
  final VoidCallback onTap; // 🔥 Tambahkan parameter callback ini

  const _PerkembanganCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // 🔥 Bungkus container dengan penangkap tap aksinya
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFE0F2FE),
              backgroundImage: data.foto != null && data.foto!.isNotEmpty
                  ? NetworkImage(ApiConstants.fotoUrl(data.foto))
                  : null,
              child: (data.foto == null || data.foto!.isEmpty)
                  ? const Icon(Icons.face_6_rounded, color: Color(0xFF0E7490), size: 26)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${data.namaAnak} · Kelompok ${data.kelompok}",
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Minggu ${data.minggu} · ${data.tema}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: data.statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data.statusAnalisis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: data.statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final _MenuData data;
  final VoidCallback onTap;
  const _MenuCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: data.bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, color: data.iconColor, size: 22),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    data.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                      height: 1.3,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}