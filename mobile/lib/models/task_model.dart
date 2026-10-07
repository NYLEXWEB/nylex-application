class TaskModel {
  final String id;
  final String projectId;
  final String? projectName;
  final String title;
  final String? description;
  final String? assignedTo;
  final String? assignedToName;
  final String priority;
  final String? dueDate;
  final String status; // Todo, In Progress, Completed, Blocked
  final String createdAt;

  TaskModel({
    required this.id,
    required this.projectId,
    this.projectName,
    required this.title,
    this.description,
    this.assignedTo,
    this.assignedToName,
    required this.priority,
    this.dueDate,
    required this.status,
    required this.createdAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? '',
      projectId: json['projectId'] ?? '',
      projectName: json['projectName'],
      title: json['title'] ?? '',
      description: json['description'],
      assignedTo: json['assignedTo'],
      assignedToName: json['assignedToName'],
      priority: json['priority'] ?? 'Medium',
      dueDate: json['dueDate'],
      status: json['status'] ?? 'Todo',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'title': title,
      'description': description,
      'assignedTo': assignedTo,
      'priority': priority,
      'dueDate': dueDate,
      'status': status,
    };
  }
}
