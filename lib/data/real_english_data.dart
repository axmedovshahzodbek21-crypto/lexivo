class RealEnglishSet {
  final String id;
  final String title;
  final String collectionName;
  final String? duration;
  final String? description;

  const RealEnglishSet({
    required this.id,
    required this.title,
    required this.collectionName,
    this.duration,
    this.description,
  });
}

const List<RealEnglishSet> realEnglishSets = [
  RealEnglishSet(
    id: 'preview-set',
    title: 'How to Sound More Natural in English',
    collectionName: 'Real English: Natural English',
    duration: '11:38',
    description: 'Key phrases and vocabulary from a real interview coaching session.',
  ),
];
