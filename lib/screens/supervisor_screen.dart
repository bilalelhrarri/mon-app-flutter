import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../providers/app_state.dart';
import 'history_screen.dart';
import 'truck_detail_screen.dart';

class SupervisorScreen extends StatelessWidget {
  SupervisorScreen({super.key});

  final FirestoreService _fs = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة المشرف'),
        actions: [
          IconButton(
            onPressed: () =>
                Provider.of<AppState>(context, listen: false).logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fs.getCurrentSiteStatus(),
        builder: (ctx, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final int count = snapshot.data!['count'] as int;
          final List trucks = snapshot.data!['trucks'] as List;

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '$count',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent,
                            ),
                          ),
                          const Text('شاحنة داخل الميناء'),
                        ],
                      ),
                      const Icon(Icons.local_shipping, size: 60, color: Colors.white30),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: trucks.isEmpty
                    ? const Center(child: Text('لا توجد شاحنات داخل الميناء حالياً'))
                    : ListView.builder(
                        itemCount: trucks.length,
                        itemBuilder: (ctx, i) {
                          final truck = trucks[i] as Map<String, dynamic>;
                          final hours = truck['dwellHours'] as int;
                          final isAlert = hours >= 24;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isAlert ? Colors.red : Colors.green,
                              child: const Icon(Icons.local_shipping, color: Colors.white),
                            ),
                            title: Text(
                              truck['plate'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'دخل: ${truck['entryTime']}  •  مكث: ${hours}س',
                            ),
                            trailing: isAlert
                                ? const Icon(Icons.warning, color: Colors.red)
                                : null,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HistoryScreen()),
        ),
        label: const Text('كل العمليات'),
        icon: const Icon(Icons.history),
      ),
    );
  }
}