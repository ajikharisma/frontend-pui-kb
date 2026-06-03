import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/api_constants.dart';

// =========================================================
// MODEL
// =========================================================
class ProfilData {
  final String namaOrtu, email, noHp, alamat;
  final String? namaAnak, kelompok, tempatLahir, tanggalLahir, jenisKelamin, agama, foto;

  const ProfilData({
    required this.namaOrtu,
    required this.email,
    required this.noHp,
    required this.alamat,
    this.namaAnak,
    this.kelompok,
    this.tempatLahir,
    this.tanggalLahir,
    this.jenisKelamin,
    this.agama,
    this.foto,
  });

  factory ProfilData.fromJson(Map<String, dynamic> json) {
    final ortu = json['ortu'] ?? {};
    final anak = json['anak'] ?? {};
    return ProfilData(
      namaOrtu:     ortu['nama']?.toString() ?? '-',
      email:        ortu['email']?.toString() ?? '-',
      noHp:         ortu['no_hp']?.toString() ?? '-',
      alamat:       ortu['alamat']?.toString() ?? '-',
      namaAnak:     anak['nama_anak']?.toString(),
      kelompok:     anak['kelompok']?.toString(),
      tempatLahir:  anak['tempat_lahir']?.toString(),
      tanggalLahir: anak['tanggal_lahir']?.toString(),
      jenisKelamin: anak['jenis_kelamin']?.toString(),
      agama:        anak['agama']?.toString(),
      foto:         anak['foto']?.toString(),
    );
  }
}

// =========================================================
// SCREEN
// =========================================================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfilData? _profil;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      if (auth.user == null) await auth.loadSession();
      if (!mounted) return;
      _fetchProfil();
    });
  }

  Future<void> _fetchProfil() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final auth = context.read<AuthProvider>();
      final dio  = Dio();
      final response = await dio.get(
        '${ApiConstants.baseUrl}/parent/profil',
        options: Options(headers: {
          'Authorization': 'Bearer ${auth.user!.token}',
          'Accept': 'application/json',
        }),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _profil   = ProfilData.fromJson(response.data);
          _isLoading = false;
        });
      } else {
        setState(() { _error = 'Gagal memuat profil'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
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
                ? _buildError()
                : _buildContent(),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator(color: Color(0xFF0E7490)));
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 64, height: 64,
              decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.error_outline_rounded, size: 32, color: Color(0xFFDC2626))),
          const SizedBox(height: 16),
          Text('Gagal memuat profil',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF1E293B))),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _fetchProfil,
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

  Widget _buildContent() {
    final p = _profil!;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(p)),
        SliverToBoxAdapter(child: _buildSectionTitle('Informasi Anak', Icons.child_care_rounded)),
        SliverToBoxAdapter(child: _buildAnakCard(p)),
        SliverToBoxAdapter(child: _buildSectionTitle('Informasi Orang Tua', Icons.person_rounded)),
        SliverToBoxAdapter(child: _buildOrtuCard(p)),
        SliverToBoxAdapter(child: _buildLogoutButton()),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  // ── HEADER ──
  Widget _buildHeader(ProfilData p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
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
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.school, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Text("KB Nurul'Ain",
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              GestureDetector(
                onTap: _fetchProfil,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 3),
            ),
            child: CircleAvatar(
              radius: 42,
              backgroundColor: Colors.white.withOpacity(0.2),
              backgroundImage: p.foto != null && p.foto!.isNotEmpty
                  ? NetworkImage(ApiConstants.fotoUrl(p.foto))
                  : null,
              child: (p.foto == null || p.foto!.isEmpty)
                  ? const Icon(Icons.child_care_rounded, color: Colors.white, size: 42)
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          Text(p.namaAnak ?? '-',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text('Kelompok ${p.kelompok ?? '-'}',
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
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

  // ── ANAK CARD ──
  Widget _buildAnakCard(ProfilData p) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _infoRow('Nama Lengkap',    p.namaAnak     ?? '-', Icons.badge_rounded),
          _divider(),
          _infoRow('Kelompok',        p.kelompok     ?? '-', Icons.group_rounded),
          _divider(),
          _infoRow('Tempat Lahir',    p.tempatLahir  ?? '-', Icons.location_city_rounded),
          _divider(),
          _infoRow('Tanggal Lahir',   _formatDate(p.tanggalLahir), Icons.cake_rounded),
          _divider(),
          _infoRow('Jenis Kelamin',   p.jenisKelamin ?? '-', Icons.wc_rounded),
          _divider(),
          _infoRow('Agama',           p.agama        ?? '-', Icons.auto_awesome_rounded),
          _divider(),
          _editButton('Edit Data Anak', () => _showEditAnak(p)),
        ],
      ),
    );
  }

  // ── ORTU CARD ──
  Widget _buildOrtuCard(ProfilData p) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _infoRow('Nama Orang Tua', p.namaOrtu, Icons.person_rounded),
          _divider(),
          _infoRow('Email',          p.email,    Icons.email_rounded),
          _divider(),
          _infoRow('No. HP',         p.noHp,     Icons.phone_rounded),
          _divider(),
          _infoRow('Alamat',         p.alamat,   Icons.home_rounded),
          _divider(),
          _editButton('Edit Data Orang Tua', () => _showEditOrtu(p)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF0E7490).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF0E7490), size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 16, endIndent: 16);

  Widget _editButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0E7490).withOpacity(0.05),
          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.edit_rounded, color: Color(0xFF0E7490), size: 16),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF0E7490), fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ── LOGOUT ──
  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: GestureDetector(
        onTap: _showLogoutDialog,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFEE2E2)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
              const SizedBox(width: 8),
              Text('Keluar', style: GoogleFonts.plusJakartaSans(color: const Color(0xFFDC2626), fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }

  // ── DIALOG LOGOUT ──
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Keluar', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        content: Text('Apakah Anda yakin ingin keluar?', style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text('Keluar', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── EDIT ANAK BOTTOM SHEET ──
  void _showEditAnak(ProfilData p) {
    final namaC    = TextEditingController(text: p.namaAnak);
    final tempatC  = TextEditingController(text: p.tempatLahir);
    final tglC     = TextEditingController(text: p.tanggalLahir);
    String? jenisKelamin = p.jenisKelamin;
    String? agama        = p.agama;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Color(0xFFF0F7FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Text('Edit Data Anak', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(width: 32, height: 32,
                          decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B))),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _formField('Nama Lengkap', namaC, Icons.badge_rounded),
                      const SizedBox(height: 14),
                      _formField('Tempat Lahir', tempatC, Icons.location_city_rounded),
                      const SizedBox(height: 14),
                      _formField('Tanggal Lahir', tglC, Icons.cake_rounded, hint: 'YYYY-MM-DD',
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.tryParse(tglC.text) ?? DateTime(2020),
                            firstDate: DateTime(2010),
                            lastDate: DateTime.now(),
                            builder: (ctx, child) => Theme(
                              data: Theme.of(ctx).copyWith(
                                colorScheme: const ColorScheme.light(primary: Color(0xFF0E7490)),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            tglC.text = picked.toIso8601String().split('T').first;
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      _dropdownField('Jenis Kelamin', jenisKelamin, ['Laki-laki', 'Perempuan'], Icons.wc_rounded,
                        (val) => setModalState(() => jenisKelamin = val)),
                      const SizedBox(height: 14),
                      _dropdownField('Agama', agama,
                        ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Buddha', 'Konghucu'],
                        Icons.auto_awesome_rounded,
                        (val) => setModalState(() => agama = val)),
                      const SizedBox(height: 24),
                      _saveButton('Simpan Data Anak', () async {
                        await _submitAnak(ctx, {
                          'nama_anak':     namaC.text.trim(),
                          'tempat_lahir':  tempatC.text.trim(),
                          'tanggal_lahir': tglC.text.trim(),
                          'jenis_kelamin': jenisKelamin,
                          'agama':         agama,
                        });
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── EDIT ORTU BOTTOM SHEET ──
  void _showEditOrtu(ProfilData p) {
    final namaC   = TextEditingController(text: p.namaOrtu);
    final emailC  = TextEditingController(text: p.email);
    final hpC     = TextEditingController(text: p.noHp);
    final alamatC = TextEditingController(text: p.alamat);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFF0F7FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text('Edit Data Orang Tua', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(width: 32, height: 32,
                        decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
                child: Column(
                  children: [
                    _formField('Nama Orang Tua', namaC,   Icons.person_rounded),
                    const SizedBox(height: 14),
                    _formField('Email',          emailC,  Icons.email_rounded, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 14),
                    _formField('No. HP',         hpC,     Icons.phone_rounded, keyboardType: TextInputType.phone),
                    const SizedBox(height: 14),
                    _formField('Alamat Lengkap', alamatC, Icons.home_rounded, maxLines: 3),
                    const SizedBox(height: 24),
                    _saveButton('Simpan Data Orang Tua', () async {
                      await _submitOrtu(ctx, {
                        'nama':   namaC.text.trim(),
                        'email':  emailC.text.trim(),
                        'no_hp':  hpC.text.trim(),
                        'alamat': alamatC.text.trim(),
                      });
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SUBMIT ANAK ──
  Future<void> _submitAnak(BuildContext sheetCtx, Map<String, dynamic> data) async {
    try {
      final auth = context.read<AuthProvider>();
      final dio  = Dio();
      final response = await dio.post(
        '${ApiConstants.baseUrl}/parent/profil/anak',
        data: data,
        options: Options(headers: {
          'Authorization': 'Bearer ${auth.user!.token}',
          'Accept': 'application/json',
        }),
      );
      if (response.data['success'] == true) {
        Navigator.pop(sheetCtx);
        _fetchProfil();
        _showSnackbar('Data anak berhasil diperbarui', success: true);
      } else {
        _showSnackbar(response.data['message'] ?? 'Gagal menyimpan', success: false);
      }
    } catch (e) {
      _showSnackbar('Terjadi kesalahan', success: false);
    }
  }

  // ── SUBMIT ORTU ──
  Future<void> _submitOrtu(BuildContext sheetCtx, Map<String, dynamic> data) async {
    try {
      final auth = context.read<AuthProvider>();
      final dio  = Dio();
      final response = await dio.post(
        '${ApiConstants.baseUrl}/parent/profil/ortu',
        data: data,
        options: Options(headers: {
          'Authorization': 'Bearer ${auth.user!.token}',
          'Accept': 'application/json',
        }),
      );
      if (response.data['success'] == true) {
        Navigator.pop(sheetCtx);
        _fetchProfil();
        _showSnackbar('Data orang tua berhasil diperbarui', success: true);
      } else {
        _showSnackbar(response.data['message'] ?? 'Gagal menyimpan', success: false);
      }
    } catch (e) {
      _showSnackbar('Terjadi kesalahan', success: false);
    }
  }

  void _showSnackbar(String msg, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: success ? const Color(0xFF059669) : const Color(0xFFDC2626),
      content: Text(msg, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600)),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── FORM HELPERS ──
  Widget _formField(String label, TextEditingController controller, IconData icon, {
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF374151))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: onTap != null,
          onTap: onTap,
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint ?? 'Masukkan $label',
            hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 13),
            prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0E7490), width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _dropdownField(String label, String? value, List<String> items, IconData icon, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF374151))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : null,
              hint: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text('Pilih $label', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 13)),
              ),
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              borderRadius: BorderRadius.circular(12),
              items: items.map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: GoogleFonts.plusJakartaSans(fontSize: 14)),
              )).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _saveButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0E7490),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(width: 8),
            const Icon(Icons.check_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty || raw == '-') return '-';
    try {
      final dt = DateTime.parse(raw);
      const bulan = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
          'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
      return '${dt.day} ${bulan[dt.month]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  // ── BOTTOM NAV ──
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, -4))]),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: const Color(0xFF0E7490),
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11),
        elevation: 0,
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0: Navigator.pushReplacementNamed(context, '/dashboard'); break;
            case 1: Navigator.pushReplacementNamed(context, '/perkembangan'); break;
            case 2: Navigator.pushReplacementNamed(context, '/analisis'); break;
            case 3: break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Data Perkembangan'),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb_rounded), label: 'Hasil Analisis'),
          BottomNavigationBarItem(icon: Icon(Icons.badge_rounded), label: 'Profil'),
        ],
      ),
    );
  }
}