import 'package:cloud_firestore/cloud_firestore.dart';

class PlateEvent {
  final String id;
  final String plateNumber;
  final String plateNormalized;
  final String eventType;
  final DateTime timestamp;
  final String gateId;
  final String operatorId;
  final String operatorName;
  final String photoUrl;
  final double ocrConfidence;
  final bool manuallyCorrected;

  PlateEvent({
    required this.id,
    required this.plateNumber,
    required this.plateNormalized,
    required this.eventType,
    required this.timestamp,
    required this.gateId,
    required this.operatorId,
    required this.operatorName,
    required this.photoUrl,
    required this.ocrConfidence,
    required this.manuallyCorrected,
  });

  Map<String, dynamic> toMap() => {
        'plateNumber': plateNumber,
        'plateNormalized': plateNormalized,
        'eventType': eventType,
        'timestamp': Timestamp.fromDate(timestamp),
        'gateId': gateId,
        'operatorId': operatorId,
        'operatorName': operatorName,
        'photoUrl': photoUrl,
        'ocrConfidence': ocrConfidence,
        'manuallyCorrected': manuallyCorrected,
      };

  factory PlateEvent.fromMap(String id, Map<String, dynamic> map) => PlateEvent(
        id: id,
        plateNumber: map['plateNumber'] ?? '',
        plateNormalized: map['plateNormalized'] ?? '',
        eventType: map['eventType'] ?? 'entry',
        timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        gateId: map['gateId'] ?? '',
        operatorId: map['operatorId'] ?? '',
        operatorName: map['operatorName'] ?? '',
        photoUrl: map['photoUrl'] ?? '',
        ocrConfidence: (map['ocrConfidence'] ?? 0.0).toDouble(),
        manuallyCorrected: map['manuallyCorrected'] ?? false,
      );
}