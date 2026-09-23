import '../l10n.dart';

class RealEnglishVideo {
  final String id;
  final String title;
  final String? titleUz;
  final String? titleRu;
  final String duration; // ← WRITE VIDEO DURATION HERE, e.g. '11:38'
  final String collectionName;

  const RealEnglishVideo({
    required this.id,
    required this.title,
    this.titleUz,
    this.titleRu,
    required this.duration,
    required this.collectionName,
  });
}

class RealEnglishSet {
  final String id;
  final String title;
  final String? titleUz;
  final String? titleRu;
  final List<RealEnglishVideo> videos;

  const RealEnglishSet({
    required this.id,
    required this.title,
    this.titleUz,
    this.titleRu,
    required this.videos,
  });
}

// Falls back to the English title for any set/video that hasn't had a
// titleUz/titleRu added yet, so new content doesn't need translating before
// it can ship.
String localizedTitle(String title, String? titleUz, String? titleRu) {
  final lang = appLangNotifier.value;
  if (lang == 'uz') return titleUz ?? title;
  if (lang == 'ru') return titleRu ?? title;
  return title;
}

const List<RealEnglishSet> realEnglishSets = [
  RealEnglishSet(
    id: 'preview-set',
    title: 'How to Sound More Natural in English',
    titleUz: "Ingliz tilida tabiiyroq gapirish yo'llari",
    titleRu: 'Как звучать более естественно на английском',
    videos: [
      RealEnglishVideo(id: 'preview-set-v1',  title: 'Video 1',  titleUz: '1-video',  titleRu: 'Видео 1',  duration: '03:42', collectionName: 'Natural English V1'),
      RealEnglishVideo(id: 'preview-set-v2',  title: 'Video 2',  titleUz: '2-video',  titleRu: 'Видео 2',  duration: '', collectionName: 'Natural English V2'),
      RealEnglishVideo(id: 'preview-set-v3',  title: 'Video 3',  titleUz: '3-video',  titleRu: 'Видео 3',  duration: '', collectionName: 'Natural English V3'),
      RealEnglishVideo(id: 'preview-set-v4',  title: 'Video 4',  titleUz: '4-video',  titleRu: 'Видео 4',  duration: '', collectionName: 'Natural English V4'),
      RealEnglishVideo(id: 'preview-set-v5',  title: 'Video 5',  titleUz: '5-video',  titleRu: 'Видео 5',  duration: '', collectionName: 'Natural English V5'),
      RealEnglishVideo(id: 'preview-set-v6',  title: 'Video 6',  titleUz: '6-video',  titleRu: 'Видео 6',  duration: '', collectionName: 'Natural English V6'),
      RealEnglishVideo(id: 'preview-set-v7',  title: 'Video 7',  titleUz: '7-video',  titleRu: 'Видео 7',  duration: '', collectionName: 'Natural English V7'),
      RealEnglishVideo(id: 'preview-set-v8',  title: 'Video 8',  titleUz: '8-video',  titleRu: 'Видео 8',  duration: '', collectionName: 'Natural English V8'),
      RealEnglishVideo(id: 'preview-set-v9',  title: 'Video 9',  titleUz: '9-video',  titleRu: 'Видео 9',  duration: '', collectionName: 'Natural English V9'),
      RealEnglishVideo(id: 'preview-set-v10', title: 'Video 10', titleUz: '10-video', titleRu: 'Видео 10', duration: '', collectionName: 'Natural English V10'),
      RealEnglishVideo(id: 'preview-set-v11', title: 'Video 11', titleUz: '11-video', titleRu: 'Видео 11', duration: '', collectionName: 'Natural English V11'),
      RealEnglishVideo(id: 'preview-set-v12', title: 'Video 12', titleUz: '12-video', titleRu: 'Видео 12', duration: '', collectionName: 'Natural English V12'),
    ],
  ),
];
