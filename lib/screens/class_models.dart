import '../data/word_data.dart';
import '../data/a1_collection.dart';
import '../data/a2_collection.dart';
import '../data/b1_collection.dart';

/// Looks up one of the six built-in word collections by its exact display
/// name, as stored in class_homework.collection_name. Previously
/// reimplemented identically in 3 Flutter files (class_curriculum_tab.dart,
/// class_homework_tab.dart, library_unit_study_screen.dart) — renaming a
/// collection required updating every copy in lockstep, or homework
/// silently fell back to whatever the caller did on a null return.
WordCollection? collectionByName(String name) {
  switch (name) {
    case '30 Days of Powerful Words': return thirtyDaysCollection;
    case '24 Vocabulary Challenge':   return vocabularyChallengeCollection;
    case 'Word Mastery':              return wordMasteryCollection;
    case 'A1':                        return a1Collection;
    case 'A2':                        return a2Collection;
    case 'B1':                        return b1Collection;
    default: return null;
  }
}

// "Fully done" for a homework assignment: every assigned mode has a
// matching entry in the student's completed-modes set. Previously
// reimplemented independently 9+ times across class_homework_tab.dart,
// class_curriculum_tab.dart, and class_home_screen.dart — consistent today
// (every real assignment has at least one mode; `modes` is never actually
// empty via the assign-homework UI, which always requires 'learn'), but with
// no single place to fix if that definition ever changes.
bool isHomeworkFullyDone(List<String> modes, Set<String> completedModes) =>
    modes.isNotEmpty && modes.every(completedModes.contains);

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
