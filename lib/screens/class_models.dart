class ClassRow {
  final String id, name, joinCode, teacherId;
  final int memberCount;
  const ClassRow({required this.id, required this.name, required this.joinCode, required this.teacherId, this.memberCount = 0});
  factory ClassRow.fromMap(Map<String, dynamic> m) => ClassRow(
    id: m['id'] as String? ?? '', name: m['name'] as String? ?? '',
    joinCode: m['join_code'] as String? ?? '', teacherId: m['teacher_id'] as String? ?? '',
    memberCount: m['member_count'] as int? ?? 0,
  );
}

class ClassWord {
  final String id, classId, word, translation;
  final String? definition, example1, example1Translation, example2, example2Translation;
  const ClassWord({required this.id, required this.classId, required this.word, required this.translation,
    this.definition, this.example1, this.example1Translation, this.example2, this.example2Translation});
  factory ClassWord.fromMap(Map<String, dynamic> m) => ClassWord(
    id: m['id'] as String? ?? '', classId: m['class_id'] as String? ?? '',
    word: m['word'] as String? ?? '', translation: m['translation'] as String? ?? '',
    definition: m['definition'] as String?, example1: m['example1'] as String?,
    example1Translation: m['example1_translation'] as String?,
    example2: m['example2'] as String?, example2Translation: m['example2_translation'] as String?,
  );
}

class ClassNote {
  final String id, classId, message, createdAt;
  final String? readAt;
  const ClassNote({required this.id, required this.classId, required this.message, required this.createdAt, this.readAt});
  factory ClassNote.fromMap(Map<String, dynamic> m) => ClassNote(
    id: m['id'] as String? ?? '', classId: m['class_id'] as String? ?? '',
    message: m['message'] as String? ?? '', createdAt: m['created_at'] as String? ?? '',
    readAt: m['read_at'] as String?,
  );
}

class ClassTarget {
  final String id, classId, title, createdAt;
  final String? dueDate, completedAt;
  const ClassTarget({required this.id, required this.classId, required this.title, required this.createdAt, this.dueDate, this.completedAt});
  factory ClassTarget.fromMap(Map<String, dynamic> m) => ClassTarget(
    id: m['id'] as String? ?? '', classId: m['class_id'] as String? ?? '',
    title: m['title'] as String? ?? '', createdAt: m['created_at'] as String? ?? '',
    dueDate: m['due_date'] as String?, completedAt: m['completed_at'] as String?,
  );
  Map<String, dynamic> toJson() => {
    'id': id, 'class_id': classId, 'title': title, 'created_at': createdAt,
    'due_date': dueDate, 'completed_at': completedAt,
  };
}

class ClassAnnouncement {
  final String id, classId, message, createdAt;
  const ClassAnnouncement({required this.id, required this.classId, required this.message, required this.createdAt});
  factory ClassAnnouncement.fromMap(Map<String, dynamic> m) => ClassAnnouncement(
    id: m['id'] as String? ?? '', classId: m['class_id'] as String? ?? '',
    message: m['message'] as String? ?? '', createdAt: m['created_at'] as String? ?? '',
  );
  Map<String, dynamic> toJson() => {
    'id': id, 'class_id': classId, 'message': message, 'created_at': createdAt,
  };
}

class ClassLeaderboardRow {
  final String studentId, name;
  final int xp, streak;
  const ClassLeaderboardRow({required this.studentId, required this.name, required this.xp, required this.streak});
  factory ClassLeaderboardRow.fromMap(Map<String, dynamic> m) => ClassLeaderboardRow(
    studentId: m['student_id'] as String? ?? '', name: m['name'] as String? ?? '?',
    xp: (m['xp'] as num?)?.toInt() ?? 0, streak: (m['streak'] as num?)?.toInt() ?? 0,
  );
}

class ClassDashboardStudent {
  final String id, name;
  final String? avatarUrl, lastStudyDate;
  final int xp, streak, totalWords;
  const ClassDashboardStudent({required this.id, required this.name, this.avatarUrl, this.lastStudyDate, required this.xp, required this.streak, required this.totalWords});
  factory ClassDashboardStudent.fromMap(Map<String, dynamic> m) => ClassDashboardStudent(
    id: m['student_id'] as String? ?? '', name: m['name'] as String? ?? '?',
    avatarUrl: m['avatar_url'] as String?,
    lastStudyDate: m['last_study_date'] as String?,
    xp: (m['xp'] as num?)?.toInt() ?? 0,
    streak: (m['streak'] as num?)?.toInt() ?? 0,
    totalWords: (m['total_words'] as num?)?.toInt() ?? 0,
  );
}

class ClassHomework {
  final String id, classId, teacherId, title, createdAt;
  final String? dueDate;
  const ClassHomework({required this.id, required this.classId, required this.teacherId, required this.title, required this.createdAt, this.dueDate});
  factory ClassHomework.fromMap(Map<String, dynamic> m) => ClassHomework(
    id: m['id'] as String? ?? '', classId: m['class_id'] as String? ?? '',
    teacherId: m['teacher_id'] as String? ?? '', title: m['title'] as String? ?? '',
    createdAt: m['created_at'] as String? ?? '', dueDate: m['due_date'] as String?,
  );
}
