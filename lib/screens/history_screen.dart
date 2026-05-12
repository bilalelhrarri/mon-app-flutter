import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../models/plate_event.dart';
import '../utils/date_utils.dart';

class HistoryScreen extends StatelessWidget {
  final String? plateFilter;

  HistoryScreen({super.key, this.plateFilter});

  final FirestoreService _fs = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(plateFilter != null ? 'سجل: $plateFilter' : 'سجل العمليات'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fs.getHistoryStream(plateSearch: plateFilter),
        builder: (ctx, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('لا توجد عمليات مسجلة'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final event = PlateEvent.fromMap(
                docs[i].id,
                docs[i].data() as Map<String, dynamic>,
              );
              final isEntry = event.eventType == 'entry';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isEntry ? Colors.green : Colors.red,
                  child: Icon(
                    isEntry ? Icons.login : Icons.logout,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  event.plateNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${AppDateUtils.formatDateTime(event.timestamp)}  •  ${event.operatorName}  •  ${event.gateId}',
                ),
                trailing: event.manuallyCorrected
                    ? const Tooltip(
                        message: 'تم التصحيح يدوياً',
                        child: Icon(Icons.edit, size: 16, color: Colors.orange),
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}