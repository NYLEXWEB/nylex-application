class DailyUpdateModel {
  final String id;
  final String projectId;
  final String? projectName;
  final String userId;
  final String? userName;
  final String updateText;
  final String? completedSection;
  final String? nextSection;
  final String? blockerSection;
  final String date;
  final String createdAt;

  DailyUpdateModel({
    required this.id,
    required this.projectId,
    this.projectName,
    required this.userId,
    this.userName,
    required this.updateText,
    this.completedSection,
    this.nextSection,
    this.blockerSection,
    required this.date,
    required this.createdAt,
  });

  factory DailyUpdateModel.fromJson(Map<String, dynamic> json) {
    return DailyUpdateModel(
      id: json['id'] ?? '',
      projectId: json['projectId'] ?? '',
      projectName: json['projectName'],
      userId: json['userId'] ?? '',
      userName: json['userName'],
      updateText: json['updateText'] ?? '',
      completedSection: json['completedSection'],
      nextSection: json['nextSection'],
      blockerSection: json['blockerSection'],
      date: json['date'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'updateText': updateText,
      'completedSection': completedSection,
      'nextSection': nextSection,
      'blockerSection': blockerSection,
      'date': date,
    };
  }
}
