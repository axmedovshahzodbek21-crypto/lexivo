class RealEnglishVideo {
  final String id;
  final String title;
  final String duration; // ← WRITE VIDEO DURATION HERE, e.g. '11:38'
  final String collectionName;

  const RealEnglishVideo({
    required this.id,
    required this.title,
    required this.duration,
    required this.collectionName,
  });
}

class RealEnglishSet {
  final String id;
  final String title;
  final List<RealEnglishVideo> videos;

  const RealEnglishSet({
    required this.id,
    required this.title,
    required this.videos,
  });
}

const List<RealEnglishSet> realEnglishSets = [
  RealEnglishSet(
    id: 'preview-set',
    title: 'How to Sound More Natural in English',
    videos: [
      RealEnglishVideo(id: 'preview-set-v1',  title: 'Video 1',  duration: '', collectionName: 'Natural English V1'),
      RealEnglishVideo(id: 'preview-set-v2',  title: 'Video 2',  duration: '', collectionName: 'Natural English V2'),
      RealEnglishVideo(id: 'preview-set-v3',  title: 'Video 3',  duration: '', collectionName: 'Natural English V3'),
      RealEnglishVideo(id: 'preview-set-v4',  title: 'Video 4',  duration: '', collectionName: 'Natural English V4'),
      RealEnglishVideo(id: 'preview-set-v5',  title: 'Video 5',  duration: '', collectionName: 'Natural English V5'),
      RealEnglishVideo(id: 'preview-set-v6',  title: 'Video 6',  duration: '', collectionName: 'Natural English V6'),
      RealEnglishVideo(id: 'preview-set-v7',  title: 'Video 7',  duration: '', collectionName: 'Natural English V7'),
      RealEnglishVideo(id: 'preview-set-v8',  title: 'Video 8',  duration: '', collectionName: 'Natural English V8'),
      RealEnglishVideo(id: 'preview-set-v9',  title: 'Video 9',  duration: '', collectionName: 'Natural English V9'),
      RealEnglishVideo(id: 'preview-set-v10', title: 'Video 10', duration: '', collectionName: 'Natural English V10'),
    ],
  ),
];
