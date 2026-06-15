class ReportModel {
  final String id;
  final String reporterId;
  final String reporterName;
  final String reportType;
  final String description;
  final double latitude;
  final double longitude;
  final String locationName;
  final String? photoUrl;
  final String status; // 'Menunggu', 'Diproses', 'Selesai', 'Ditolak'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? handledBy;
  final String? notes;

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.reportType,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    this.photoUrl,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.handledBy,
    this.notes,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'] ?? '',
      reporterId: map['reporterId'] ?? '',
      reporterName: map['reporterName'] ?? '',
      reportType: map['reportType'] ?? 'Aktivitas Mencurigakan',
      description: map['description'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      locationName: map['locationName'] ?? '',
      photoUrl: map['photoUrl'],
      status: map['status'] ?? 'Terkirim',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
      handledBy: map['handledBy'],
      notes: map['notes'],
    );
  }

  String displayStatus(bool isStaff) {
    if (status == 'Ditindaklanjuti') {
      return isStaff ? 'Laporan Ditindak Lanjut' : 'Laporan Sudah Ditindaklanjuti';
    }
    return isStaff ? 'Laporan Diterima' : 'Laporan Terkirim';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reportType': reportType,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'photoUrl': photoUrl,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'handledBy': handledBy,
      'notes': notes,
    };
  }

  ReportModel copyWith({
    String? status,
    DateTime? updatedAt,
    String? handledBy,
    String? notes,
  }) {
    return ReportModel(
      id: id,
      reporterId: reporterId,
      reporterName: reporterName,
      reportType: reportType,
      description: description,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      photoUrl: photoUrl,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      handledBy: handledBy ?? this.handledBy,
      notes: notes ?? this.notes,
    );
  }
}
