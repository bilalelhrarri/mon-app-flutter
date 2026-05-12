import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plate_event.dart';
import '../services/firestore_service.dart';
import '../utils/date_utils.dart';

class TruckDetailScreen extends StatelessWidget {
  final String plateNumber;
  final String entryTime;
  final int dwellHours;

  const TruckDetailScreen({
    super.key,
    required this.plateNumber,
    required this.entryTime,
    required this.dwellHours,
  });

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: Text('تفاصيل: $plateNumber')),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping, size: 48, color: Colors.blueAccent),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plateNumber,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('وقت الدخول: $entryTime'),
                      Text(
                        'مدة المكوث: $dwellHours ساعة',
                        style: TextStyle(
                          color: dwellHours >= 24 ? Colors.red : Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('سجل العمليات',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: fs.getHistoryStream(plateSearch: plateNumber),
              builder: (ctx, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('لا توجد عمليات'));
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final event = PlateEvent.fromMap(
                        docs[i].id, docs[i].data() as Map<String, dynamic>);
                    final isEntry = event.eventType == 'entry';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isEntry ? Colors.green : Colors.red,
                        child: Icon(
                          isEntry ? Icons.login : Icons.logout,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(isEntry ? 'دخول' : 'خروج'),
                      subtitle: Text(
                        '${AppDateUtils.formatDateTime(event.timestamp)}  •  ${event.operatorName}  •  ${event.gateId}',
                      ),
                      trailing: event.manuallyCorrected
                          ? const Icon(Icons.edit, size: 16, color: Colors.orange)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}