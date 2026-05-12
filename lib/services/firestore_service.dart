import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plate_event.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getHistoryStream({String? plateSearch}) {
    Query q = _db.collection('history').orderBy('timestamp', descending: true);
    if (plateSearch != null && plateSearch.isNotEmpty) {
      final n = plateSearch.toUpperCase().replaceAll(RegExp(r'\s+'), '');
      q = q
          .where('plateNormalized', isGreaterThanOrEqualTo: n)
          .where('plateNormalized', isLessThanOrEqualTo: '$n\uf8ff');
    }
    return q.snapshots();
  }

  Future<void> addPlateEvent(PlateEvent event) async {
    await _db.collection('history').add(event.toMap());
  }

  Future<Map<String, dynamic>> getCurrentSiteStatus() async {
    final entries = await _db
        .collection('history')
        .where('eventType', isEqualTo: 'entry')
        .get();

    final exits = await _db
        .collection('history')
        .where('eventType', isEqualTo: 'exit')
        .get();

    final exitedPlates = <String>{};
    for (var doc in exits.docs) {
      exitedPlates.add(doc.data()['plateNormalized'] as String? ?? '');
    }

    final Map<String, Map<String, dynamic>> latestEntries = {};
    for (var doc in entries.docs) {
      final data = doc.data();
      final plate = data['plateNormalized'] as String? ?? '';
      if (!exitedPlates.contains(plate) && !latestEntries.containsKey(plate)) {
        latestEntries[plate] = data;
      }
    }

    final trucks = latestEntries.entries.map((e) {
      final entryTime = (e.value['timestamp'] as Timestamp?)?.toDate();
      final hours = entryTime != null
          ? DateTime.now().difference(entryTime).inHours
          : 0;
      return {
        'plate': e.value['plateNumber'] ?? e.key,
        'entryTime': entryTime != null
            ? '${entryTime.hour.toString().padLeft(2, '0')}:${entryTime.minute.toString().padLeft(2, '0')}'
            : '--:--',
        'dwellHours': hours,
      };
    }).toList();

    return {'count': trucks.length, 'trucks': trucks};
  }
}