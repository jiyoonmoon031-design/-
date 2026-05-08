class DiagnosisResult {
  final int id;
  final int? imageId;
  final String diseaseName;
  final double confidence;
  final String severityLevel;
  final String? recommendation;
  final String actionStatus;
  final String createdAt;

  DiagnosisResult({
    required this.id,
    required this.imageId,
    required this.diseaseName,
    required this.confidence,
    required this.severityLevel,
    required this.recommendation,
    required this.actionStatus,
    required this.createdAt,
  });

  factory DiagnosisResult.fromJson(Map<String, dynamic> json) {
    return DiagnosisResult(
      id: json['id'],
      imageId: json['image_id'],
      imagePath: json['image_path'],
      diseaseName: json['disease_name'],
      confidence: (json['confidence'] as num).toDouble(),
      severityLevel: json['severity_level'],
      recommendation: json['recommendation'],
      actionStatus: json['action_status'],
      createdAt: json['created_at'],
    );
  }
}