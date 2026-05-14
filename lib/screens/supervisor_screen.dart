import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../providers/app_state.dart';
import 'history_screen.dart';
import 'truck_detail_screen.dart';

class SupervisorScreen extends StatelessWidget {
  SupervisorScreen({super.key});

  final FirestoreService _fs = FirestoreService();

  // ── Colors ────────────────────────────────────────────────────────────
  static const Color bgDeep    = Color(0xFF0A1628);
  static const Color bgCard    = Color(0xFF0D1F36);
  static const Color accent    = Color(0xFF1A6FA8);
  static const Color accentLt  = Color(0xFF7AADCC);
  static const Color textPrim  = Color(0xFFE8F4FD);
  static const Color textMuted = Color(0xFF5B8DB8);
  static const Color borderClr = Color(0xFF1E3A5F);
  static const Color colorGreen= Color(0xFF2ECC71);
  static const Color colorAmber= Color(0xFFF39C12);
  static const Color colorRed  = Color(0xFFE74C3C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDeep,
      appBar: _buildAppBar(context),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fs.getCurrentSiteStatus(),
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

          final int count   = snapshot.data!['count'] as int;
          final List trucks = snapshot.data!['trucks'] as List;
          final int alerts  = trucks.where((t) {
            return ((t as Map<String, dynamic>)['dwellHours'] as int) >= 24;
          }).length;

          // Compute entries/exits if available, fallback to count
          final int entries = snapshot.data!['entries'] as int? ?? count;
          final int exits   = snapshot.data!['exits']   as int? ?? 0;

          return Column(
            children: [
              // ── Stats grid ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.55,
                  children: [
                    _StatCard(
                      label: 'CAMIONS PRÉSENTS',
                      value: '$count',
                      valueColor: colorGreen,
                      icon: Icons.local_shipping_outlined,
                    ),
                    _StatCard(
                      label: "ENTRÉES AUJOURD'HUI",
                      value: '$entries',
                      valueColor: accentLt,
                      icon: Icons.login_rounded,
                    ),
                    _StatCard(
                      label: "SORTIES AUJOURD'HUI",
                      value: '$exits',
                      valueColor: colorAmber,
                      icon: Icons.logout_rounded,
                    ),
                    _StatCard(
                      label: 'ALERTES DURÉE',
                      value: '$alerts',
                      valueColor: alerts > 0 ? colorRed : textMuted,
                      icon: Icons.warning_amber_rounded,
                    ),
                  ],
                ),
              ),

              // ── Section header ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    const Text(
                      'CAMIONS SUR SITE',
                      style: TextStyle(
                        color: accentLt,
                        fontSize: 10,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$count actifs',
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              Container(height: 1, color: borderClr),

              // ── Truck list ──────────────────────────────────────
              Expanded(
                child: trucks.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_shipping_outlined,
                                size: 48, color: borderClr),
                            SizedBox(height: 12),
                            Text(
                              'لا توجد شاحنات داخل الميناء',
                              style: TextStyle(color: textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: trucks.length,
                        separatorBuilder: (_, __) =>
                            Container(height: 1, color: bgCard),
                        itemBuilder: (ctx, i) {
                          final truck = trucks[i] as Map<String, dynamic>;
                          final hours = truck['dwellHours'] as int;
                          return _TruckTile(
                            truck: truck,
                            hours: hours,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TruckDetailScreen(
                                  plateNumber: truck['plate'] as String,
                                  entryTime: truck['entryTime'] as String,
                                  dwellHours: hours,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),

      // ── FAB ──────────────────────────────────────────────────────
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HistoryScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: textPrim,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.history_rounded, size: 18),
            label: const Text(
              'HISTORIQUE COMPLET',
              style: TextStyle(fontSize: 12, letterSpacing: 2),
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: bgCard,
      elevation: 0,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'SUPERVISOR',
            style: TextStyle(
              color: textPrim,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          Text(
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
      actions: [
        IconButton(
          onPressed: () =>
              Provider.of<AppState>(context, listen: false).logout(),
          icon: const Icon(Icons.logout_rounded, color: textMuted, size: 20),
          tooltip: 'تسجيل الخروج',
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ── Stat card widget ──────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SupervisorScreen.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SupervisorScreen.borderClr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: SupervisorScreen.borderClr, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: SupervisorScreen.textMuted,
              fontSize: 9,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Truck tile widget ─────────────────────────────────────────────────────────
class _TruckTile extends StatelessWidget {
  final Map<String, dynamic> truck;
  final int hours;
  final VoidCallback onTap;

  const _TruckTile({
    required this.truck,
    required this.hours,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAlert  = hours >= 24;
    final bool isWarning= hours >= 8 && hours < 24;

    final Color avatarBg = isAlert
        ? const Color(0xFF3D0000)
        : isWarning
            ? const Color(0xFF3D1A00)
            : const Color(0xFF0D3320);

    final Color avatarBorder = isAlert
        ? const Color(0xFF7A0000)
        : isWarning
            ? const Color(0xFF7A3800)
            : const Color(0xFF1A5C38);

    final Color badgeColor = isAlert
        ? SupervisorScreen.colorRed
        : isWarning
            ? SupervisorScreen.colorAmber
            : SupervisorScreen.colorGreen;

    final Color badgeBg = isAlert
        ? const Color(0xFF3D0000)
        : isWarning
            ? const Color(0xFF3D1A00)
            : const Color(0xFF0D3320);

    return InkWell(
      onTap: onTap,
      splashColor: SupervisorScreen.accent.withOpacity(0.1),
      highlightColor: SupervisorScreen.bgCard,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: avatarBg,
                shape: BoxShape.circle,
                border: Border.all(color: avatarBorder),
              ),
              child: Icon(
                isAlert
                    ? Icons.warning_amber_rounded
                    : Icons.local_shipping_outlined,
                color: badgeColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    truck['plate'] as String,
                    style: const TextStyle(
                      color: SupervisorScreen.textPrim,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Entrée ${truck['entryTime']}',
                    style: const TextStyle(
                      color: SupervisorScreen.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: avatarBorder),
              ),
              child: Text(
                '${hours}H${isAlert ? " !" : ""}',
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),

            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: SupervisorScreen.borderClr,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}