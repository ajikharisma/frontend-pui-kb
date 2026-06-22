import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../core/constants/api_constants.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  List<dynamic> _notifikasi = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchNotifikasi();
    });
  }

  Future<void> _fetchNotifikasi() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final dio = Dio();

      final response = await dio.get(
        '${ApiConstants.baseUrl}/parent/notifikasi',
        options: Options(headers: {
          'Authorization': 'Bearer ${auth.user!.token}',
          'Accept': 'application/json',
        }),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _notifikasi = response.data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Gagal memuat notifikasi';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _bacaNotifikasi(String idNotif, int index) async {
    // Update tampilan langsung (optimistic update)
    setState(() {
      _notifikasi[index]['status_baca'] = true;
    });

    try {
      final auth = context.read<AuthProvider>();
      final dio = Dio();

      await dio.post(
        '${ApiConstants.baseUrl}/parent/notifikasi/$idNotif/baca',
        options: Options(headers: {
          'Authorization': 'Bearer ${auth.user!.token}',
          'Accept': 'application/json',
        }),
      );
    } catch (e) {
      debugPrint('Gagal tandai baca: $e');
    }
  }

  Future<void> _bacaSemua() async {
    try {
      final auth = context.read<AuthProvider>();
      final dio = Dio();

      await dio.post(
        '${ApiConstants.baseUrl}/parent/notifikasi/baca-semua',
        options: Options(headers: {
          'Authorization': 'Bearer ${auth.user!.token}',
          'Accept': 'application/json',
        }),
      );

      setState(() {
        for (var n in _notifikasi) {
          n['status_baca'] = true;
        }
      });
    } catch (e) {
      debugPrint('Gagal tandai semua: $e');
    }
  }

  IconData _getIcon(String jenis) {
    switch (jenis) {
      case 'hasil_analisis':
        return Icons.psychology_rounded;
      case 'penilaian_harian':
        return Icons.edit_note_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getIconColor(String jenis) {
    switch (jenis) {
      case 'hasil_analisis':
        return const Color(0xFF7C3AED);
      case 'penilaian_harian':
        return const Color(0xFF0E7490);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getIconBg(String jenis) {
    switch (jenis) {
      case 'hasil_analisis':
        return const Color(0xFFEDE9FE);
      case 'penilaian_harian':
        return const Color(0xFFE0F2FE);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  String _formatWaktu(String? createdAt) {
    if (createdAt == null) return '-';
    try {
      final dt = DateTime.parse(createdAt);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      if (diff.inDays < 7) return '${diff.inDays} hari lalu';

      return DateFormat('d MMM yyyy, HH:mm').format(dt);
    } catch (e) {
      return createdAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final jumlahBelumDibaca =
        _notifikasi.where((n) => n['status_baca'] == false).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(jumlahBelumDibaca),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF0E7490)))
                  : _error != null
                      ? _buildErrorState()
                      : _notifikasi.isEmpty
                          ? _buildEmptyState()
                          : _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int jumlahBelumDibaca) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 18, color: Color(0xFF475569)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifikasi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                if (jumlahBelumDibaca > 0)
                  Text(
                    '$jumlahBelumDibaca belum dibaca',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ),
          if (jumlahBelumDibaca > 0)
            GestureDetector(
              onTap: _bacaSemua,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Tandai semua',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0E7490),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      color: const Color(0xFF0E7490),
      onRefresh: _fetchNotifikasi,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _notifikasi.length,
        itemBuilder: (context, index) {
          final item = _notifikasi[index];
          final belumDibaca = item['status_baca'] == false;
          final jenis = item['jenis'] ?? '';

          return GestureDetector(
            onTap: () {
              if (belumDibaca) {
                _bacaNotifikasi(item['id_notif'], index);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: belumDibaca ? const Color(0xFFF0F9FF) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: belumDibaca
                      ? const Color(0xFFBAE6FD)
                      : const Color(0xFFF1F5F9),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _getIconBg(jenis),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIcon(jenis),
                      color: _getIconColor(jenis),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item['judul'] ?? '-',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: belumDibaca
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            if (belumDibaca)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 6, top: 2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0EA5E9),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['pesan'] ?? '-',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatWaktu(item['created_at']),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.notifications_off_rounded,
                size: 32, color: Color(0xFF0E7490)),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada notifikasi',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Notifikasi penilaian dan hasil analisis\nakan muncul di sini',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.error_outline_rounded,
                size: 32, color: Color(0xFFDC2626)),
          ),
          const SizedBox(height: 16),
          Text(
            'Gagal memuat notifikasi',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _fetchNotifikasi,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0E7490),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Coba Lagi',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}