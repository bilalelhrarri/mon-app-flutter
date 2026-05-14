import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../models/plate_event.dart';
import '../utils/date_utils.dart';

class HistoryScreen extends StatefulWidget {
  final String? plateFilter;
  const HistoryScreen({super.key, this.plateFilter});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // ── Colors ────────────────────────────────────────────────────────────
  static const Color bgDeep    = Color(0xFF0A1628);
  static const Color bgCard    = Color(0xFF0D1F36);
  static const Color accent    = Color(0xFF1A6FA8);
  static const Color accentLt  = Color(0xFF7AADCC);
  static const Color textPrim  = Color(0xFFE8F4FD);
  static const Color textMuted = Color(0xFF5B8DB8);
  static const Color borderClr = Color(0xFF1E3A5F);
  static const Color colorGreen= Color(0xFF2ECC71);
  static const Color colorRed  = Color(0xFFE74C3C);
  static const Color colorAmber= Color(0xFFF39C12);

  final FirestoreService _fs = FirestoreService();
  final TextEditingController _searchCtrl = TextEditingController();

  String _searchText = '';
  int _selectedFilter = 0; // 0=today 1=yesterday 2=7days 3=month

  final List<String> _filters = ["AUJOURD'HUI", 'HIER', '7 JOURS', 'CE MOIS'];

  @override
  void initState() {
    super.initState();
    if (widget.plateFilter != null) {
      _searchText = widget.plateFilter!;
      _searchCtrl.text = widget.plateFilter!;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDeep,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderClr),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.search_rounded, color: textMuted, size: 18),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: textPrim, fontSize: 13),
                      cursorColor: accent,
                      onChanged: (v) => setState(() => _searchText = v.trim()),
                      decoration: const InputDecoration(
                        hintText: 'Rechercher une plaque...',
                        hintStyle: TextStyle(color: Color(0xFF3A6A8E), fontSize: 12),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (_searchText.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: textMuted, size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchText = '');
                      },
                    ),
                ],
              ),
            ),
          ),

          // ── Date filter chips ─────────────────────────────────
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final active = _selectedFilter == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF0D2E4F) : bgCard,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: active ? accent : borderClr,
                      ),
                    ),
                    child: Text(
                      _filters[i],
                      style: TextStyle(
                        color: active ? accentLt : textMuted,
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),
          Container(height: 1, color: borderClr),

          // ── Events list ───────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _fs.getHistoryStream(
                plateSearch: _searchText.isNotEmpty ? _searchText : null,
              ),
              builder: (ctx, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'خطأ: ${snapshot.error}',
                      style: const TextStyle(color: colorRed),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: accent),
                  );
                }

                final allDocs = snapshot.data!.docs;
                final docs = _applyDateFilter(allDocs);

                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_toggle_off_rounded,
                            size: 48, color: borderClr),
                        SizedBox(height: 12),
                        Text(
                          'لا توجد عمليات مسجلة',
                          style: TextStyle(color: textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: docs.length,
                  separatorBuilder: (_, __) =>
                      Container(height: 1, color: bgCard),
                  itemBuilder: (ctx, i) {
                    final event = PlateEvent.fromMap(
                      docs[i].id,
                      docs[i].data() as Map<String, dynamic>,
                    );
                    return _EventTile(event: event);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<QueryDocumentSnapshot> _applyDateFilter(
      List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = (data['timestamp'] as Timestamp?)?.toDate();
      if (ts == null) return true;

      switch (_selectedFilter) {
        case 0: // today
          return ts.isAfter(today);
        case 1: // yesterday
          final yesterday = today.subtract(const Duration(days: 1));
          return ts.isAfter(yesterday) && ts.isBefore(today);
        case 2: // 7 days
          return ts.isAfter(today.subtract(const Duration(days: 7)));
        case 3: // month
          return ts.isAfter(today.subtract(const Duration(days: 30)));
        default:
          return true;
      }
    }).toList();
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: bgCard,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: textMuted, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.plateFilter != null
                ? 'PLAQUE : ${widget.plateFilter}'
                : 'HISTORIQUE',
            style: const TextStyle(
              color: textPrim,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const Text(
            'TANGER MED · GATE OPS',
            style: TextStyle(
              color: textMuted,
              fontSize: 9,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: borderClr),
      ),
    );
  }
}

// ── Event tile ────────────────────────────────────────────────────────────────
class _EventTile extends StatelessWidget {
  final PlateEvent event;

  const _EventTile({required this.event});

  static const Color bgDeep    = Color(0xFF0A1628);
  static const Color bgCard    = Color(0xFF0D1F36);
  static const Color textPrim  = Color(0xFFE8F4FD);
  static const Color textMuted = Color(0xFF5B8DB8);
  static const Color borderClr = Color(0xFF1E3A5F);
  static const Color colorGreen= Color(0xFF2ECC71);
  static const Color colorRed  = Color(0xFFE74C3C);
  static const Color colorAmber= Color(0xFFF39C12);

  @override
  Widget build(BuildContext context) {
    final isEntry = event.eventType == 'entry';

    final Color dotColor  = isEntry ? colorGreen : colorRed;
    final Color dotBg     = isEntry ? const Color(0xFF0D3320) : const Color(0xFF3D0000);
    final Color dotBorder = isEntry ? const Color(0xFF1A5C38) : const Color(0xFF7A0000);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          // Icon dot
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: dotBg,
              shape: BoxShape.circle,
              border: Border.all(color: dotBorder),
            ),
            child: Icon(
              isEntry ? Icons.login_rounded : Icons.logout_rounded,
              color: dotColor,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      event.plateNumber,
                      style: const TextStyle(
                        color: textPrim,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    if (event.manuallyCorrected) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D1A00),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF7A4500)),
                        ),
                        child: const Text(
                          'CORRIGÉ',
                          style: TextStyle(
                            color: colorAmber,
                            fontSize: 8,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${AppDateUtils.formatDateTime(event.timestamp)}  ·  ${event.operatorName}  ·  ${event.gateId}',
                  style: const TextStyle(color: textMuted, fontSize: 10),
                ),
              ],
            ),
          ),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: dotBg,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: dotBorder),
            ),
            child: Text(
              isEntry ? 'ENTRÉE' : 'SORTIE',
              style: TextStyle(
                color: dotColor,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}