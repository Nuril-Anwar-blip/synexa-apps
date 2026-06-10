class PairingModel {
  final String id;
  final DateTime createdAt;
  final String? userId;
  final String refreshToken;
  final String pairingCode;

  PairingModel({
    required this.id,
    required this.createdAt,
    this.userId,
    required this.refreshToken,
    required this.pairingCode,
  });

  /// Factory untuk mapping dari Supabase/JSON
  factory PairingModel.fromMap(Map<String, dynamic> map) {
    return PairingModel(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      userId: map['user_id'] as String?,
      refreshToken: map['refresh_token'] as String,
      pairingCode: map['pairing_code'] as String,
    );
  }

  /// Konversi ke Map (buat insert/update ke Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
      'refresh_token': refreshToken,
      'pairing_code': pairingCode,
    };
  }

  /// CopyWith untuk update sebagian field
  PairingModel copyWith({
    String? id,
    DateTime? createdAt,
    String? userId,
    String? refreshToken,
    String? pairingCode,
  }) {
    return PairingModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      refreshToken: refreshToken ?? this.refreshToken,
      pairingCode: pairingCode ?? this.pairingCode,
    );
  }
}
