class TaskEvent {
  int? id;
  String taskName;
  String description;
  String isCompleted;

  TaskEvent({
    this.id,
    required this.taskName,
    required this.description,
    this.isCompleted = 'NO', // Default value is "NO"
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_name': taskName,
      'description': description,
      'is_completed': isCompleted,
    };
  }

  // Constructor to create a ClassEvent object from a Map
  factory TaskEvent.fromMap(Map<String, dynamic> map) {
    return TaskEvent(
      id: map['id'],
          taskName: map['task_name'],
          description: map['description'],
      isCompleted: map['is_completed'],
    );
  }
}
