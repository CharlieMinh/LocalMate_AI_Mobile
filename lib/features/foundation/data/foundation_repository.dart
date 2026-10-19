class FoundationStatus {
  const FoundationStatus({required this.milestone, required this.connected});
  final String milestone;
  final bool connected;

  factory FoundationStatus.fromJson(Map<String, Object?> json) {
    if (json['milestone'] is! String || json['connected'] is! bool) {
      throw const FormatException('Invalid foundation status');
    }
    return FoundationStatus(
      milestone: json['milestone'] as String,
      connected: json['connected'] as bool,
    );
  }
}

/// Local build metadata, not a simulated backend response.
class FoundationRepository {
  const FoundationRepository();
  FoundationStatus get status =>
      const FoundationStatus(milestone: 'M1', connected: false);
}
