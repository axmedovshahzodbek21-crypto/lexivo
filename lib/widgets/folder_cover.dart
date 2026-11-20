import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_theme.dart';
import '../l10n.dart';
import '../services/supabase_service.dart';

// Folder / unit covers for Library and My Words. One short string, same
// format as web lib/folder-cover.ts and the DB check in
// supabase/migrations/20261120000001_folder_covers.sql:
//   g:3        built-in gradient #3
//   e:🦊|3     emoji on gradient #3
//   img:<url>  uploaded picture in the public folder-covers bucket
//   null / ''  default look
// Keep the gradient list in the same order as web — its index is what's
// stored. The emoji itself is stored, so icon groups can be reordered freely,
// but keep them (and their search words) identical to web.

const coverGradients = <List<Color>>[
  [Color(0xFF6C63FF), Color(0xFF9B8FFF)],
  [Color(0xFF7C3AED), Color(0xFFC084FC)],
  [Color(0xFF4338CA), Color(0xFF6366F1)],
  [Color(0xFFDB2777), Color(0xFFF472B6)],
  [Color(0xFFEA580C), Color(0xFFFB923C)],
  [Color(0xFF059669), Color(0xFF34D399)],
  [Color(0xFF0284C7), Color(0xFF38BDF8)],
  [Color(0xFF334155), Color(0xFF64748B)],
];

class CoverIconGroup {
  final Map<String, String> label; // en / uz / ru
  final List<(String, String)> icons; // (emoji, search words: Uzbek + English)
  const CoverIconGroup(this.label, this.icons);
}

const coverIconGroups = <CoverIconGroup>[
  CoverIconGroup({'en': 'Learning', 'uz': "O'qish", 'ru': 'Учёба'}, [
    ('📚', "kitob kitoblar kutubxona book books library"),
    ('📖', "kitob o'qish read reading book"),
    ('✏️', "qalam yozish pencil write"),
    ('📝', "yozish eslatma note notes writing"),
    ('🗣️', "gapirish nutq speaking speak talk"),
    ('💬', "suhbat xabar chat conversation message"),
    ('🔤', "alifbo harf alphabet letters abc"),
    ('💡', "g'oya fikr idea"),
    ('🧠', "miya aql fikrlash brain mind think"),
    ('🎓', "universitet bitiruv talaba university graduation student"),
    ('🏆', "g'alaba mukofot trophy win prize"),
    ('🎯', "maqsad nishon goal target"),
    ('🧩', "jumboq boshqotirma puzzle"),
  ]),
  CoverIconGroup({'en': 'Travel', 'uz': 'Sayohat', 'ru': 'Путешествия'}, [
    ('✈️', "samolyot aeroport uchish plane flight airport"),
    ('🌍', "dunyo yer world earth globe"),
    ('🏖️', "plyaj dengiz dam olish beach sea holiday"),
    ('🏔️', "tog' mountain"),
    ('🗺️', "xarita map"),
    ('🧳', "chamadon yuk suitcase luggage"),
    ('🏙️', "shahar city"),
    ('🕌', "masjid mosque"),
  ]),
  CoverIconGroup({'en': 'Transport', 'uz': 'Transport', 'ru': 'Транспорт'}, [
    ('🚗', "mashina avtomobil car"),
    ('🚆', "poyezd train"),
    ('🚌', "avtobus bus"),
    ('🚲', "velosiped bicycle bike"),
    ('🚢', "kema ship boat"),
    ('🛵', "skuter moped scooter"),
    ('🚁', "vertolyot helicopter"),
    ('🚇', "metro subway underground"),
    ('⛽', "yoqilg'i benzin fuel petrol gas"),
  ]),
  CoverIconGroup({'en': 'Food', 'uz': 'Ovqat', 'ru': 'Еда'}, [
    ('🍎', "olma meva apple fruit"),
    ('🍳', "ovqat pishirish oshxona tuxum cooking kitchen egg"),
    ('🍕', "pitsa pizza"),
    ('🍔', "burger fast food"),
    ('🍰', "tort shirinlik cake dessert"),
    ('☕', "kofe choy ichimlik coffee tea drink"),
    ('🍉', "tarvuz meva watermelon fruit"),
    ('🥗', "salat sabzavot salad vegetables"),
    ('🍞', "non bread bakery"),
    ('🧃', "sharbat ichimlik juice drink"),
  ]),
  CoverIconGroup({'en': 'Nature', 'uz': 'Tabiat', 'ru': 'Природа'}, [
    ('🌿', "tabiat o'simlik barg nature plant leaf"),
    ('🌸', "gul bahor flower spring"),
    ('🌳', "daraxt o'rmon tree forest"),
    ('🌊', "dengiz to'lqin okean sea wave ocean"),
    ('☀️', "quyosh yoz ob-havo sun summer weather"),
    ('🌧️', "yomg'ir ob-havo rain weather"),
    ('❄️', "qor qish snow winter"),
    ('🌙', "oy tun moon night"),
    ('🌈', "kamalak rainbow"),
    ('♻️', "qayta ishlash ekologiya atrof-muhit recycle ecology environment"),
    ('🌱', "nihol o'sish atrof-muhit sprout grow environment"),
    ('🌋', "vulqon volcano"),
    ('🌪️', "bo'ron tornado storm"),
    ('🌡️', "harorat iqlim temperature climate"),
  ]),
  CoverIconGroup({'en': 'Animals', 'uz': 'Hayvonlar', 'ru': 'Животные'}, [
    ('🐾', "hayvon iz uy hayvoni animal paw pet"),
    ('🐶', "it kuchuk dog puppy"),
    ('🐱', "mushuk cat"),
    ('🦁', "sher lion"),
    ('🐘', "fil elephant"),
    ('🦊', "tulki fox"),
    ('🐦', "qush bird"),
    ('🐟', "baliq fish"),
    ('🦋', "kapalak butterfly"),
  ]),
  CoverIconGroup({'en': 'Hobbies', 'uz': 'Sport va hobbi', 'ru': 'Спорт и хобби'}, [
    ('⚽', "futbol to'p sport football soccer ball"),
    ('🏀', "basketbol sport basketball"),
    ('🎾', "tennis sport"),
    ('🏊', "suzish sport swimming swim"),
    ('🚴', "velosport sport cycling"),
    ('🏃', "yugurish sport running run"),
    ('🧘', "yoga meditatsiya meditation"),
    ('🎮', "o'yin video game gaming"),
    ('🎬', "kino film movie cinema"),
    ('📷', "surat foto camera photo"),
    ('🎨', "rasm san'at art painting"),
    ('🎵', "musiqa qo'shiq music song"),
    ('🎸', "gitara musiqa guitar music"),
    ('🎻', "skripka musiqa violin music"),
    ('🥁', "baraban musiqa drum music"),
    ('🎤', "mikrofon qo'shiq singing microphone"),
    ('🎭', "teatr theatre drama"),
    ('🖼️', "rasm muzey picture gallery museum"),
  ]),
  CoverIconGroup({'en': 'Work', 'uz': 'Ish va pul', 'ru': 'Работа и деньги'}, [
    ('💼', "ish biznes work business job"),
    ('💰', "pul money"),
    ('💳', "karta to'lov card payment"),
    ('📈', "o'sish grafik iqtisod growth chart economy"),
    ('🏦', "bank"),
    ('🛠️', "asbob ta'mir tools repair"),
    ('👔', "ofis kiyim office formal"),
    ('👨‍💼', "ofis xodim menejer office worker manager"),
    ('👨‍⚕️', "shifokor doktor kasb doctor job"),
    ('👩‍🏫', "o'qituvchi ustoz kasb teacher job"),
    ('👮', "politsiya kasb police job"),
    ('👨‍🍳', "oshpaz kasb chef cook job"),
    ('👷', "quruvchi qurilish kasb builder construction job"),
    ('👨‍🌾', "dehqon fermer kasb farmer farm job"),
  ]),
  CoverIconGroup({'en': 'Tech & science', 'uz': 'Texnika va fan', 'ru': 'Техника и наука'}, [
    ('💻', "kompyuter computer laptop"),
    ('📱', "telefon mobile phone smartphone"),
    ('🤖', "robot sun'iy intellekt ai"),
    ('🌐', "internet veb web"),
    ('🔒', "xavfsizlik qulf security lock"),
    ('🎧', "quloqchin tinglash headphones listening"),
    ('💾', "ma'lumot saqlash data save"),
    ('✉️', "xat pochta letter mail email"),
    ('📞', "qo'ng'iroq telefon call phone"),
    ('🔬', "fan mikroskop science microscope"),
    ('🔭', "teleskop astronomiya telescope astronomy"),
    ('🪐', "koinot sayyora space planet"),
    ('🚀', "raketa koinot rocket space"),
    ('🧪', "kimyo tajriba chemistry experiment"),
    ('🧬', "biologiya dnk biology dna"),
    ('⚛️', "fizika atom physics"),
    ('🧮', "matematika hisob math maths"),
    ('🔢', "raqam son numbers"),
  ]),
  CoverIconGroup({'en': 'Home & shopping', 'uz': 'Uy va xarid', 'ru': 'Дом и покупки'}, [
    ('🏠', "uy home house"),
    ('🛋️', "mebel divan mehmonxona furniture sofa living room"),
    ('🛏️', "yotoqxona karavot bedroom bed"),
    ('🚿', "hammom dush bathroom shower"),
    ('🧹', "tozalash supurgi cleaning"),
    ('🪴', "gul tuvak o'simlik houseplant"),
    ('🛒', "xarid do'kon bozor shopping store market"),
    ('🛍️', "xarid sumka shopping bags"),
    ('👕', "kiyim futbolka clothes shirt"),
    ('👗', "ko'ylak kiyim dress clothes"),
    ('👟', "poyabzal krossovka shoes"),
    ('👜', "sumka bag"),
    ('🕶️', "ko'zoynak glasses sunglasses"),
  ]),
  CoverIconGroup({'en': 'People & health', 'uz': 'Odamlar va salomatlik', 'ru': 'Люди и здоровье'}, [
    ('👨‍👩‍👧', "oila family"),
    ('👶', "bola chaqaloq baby child"),
    ('😊', "baxt quvonch his-tuyg'u happy emotions feelings"),
    ('😢', "qayg'u yig'i his-tuyg'u sad cry emotions"),
    ('🤝', "do'stlik kelishuv friendship agreement"),
    ('❤️', "sevgi yurak love heart"),
    ('💪', "kuch sport strong fitness"),
    ('🏥', "kasalxona shifoxona salomatlik hospital health"),
    ('💊', "dori salomatlik medicine pill health"),
    ('🩺', "tibbiyot shifokor medical doctor health"),
    ('🦷', "tish stomatolog tooth dentist"),
    ('👁️', "ko'z eye"),
    ('🫀', "yurak tana heart body"),
    ('🦠', "virus mikrob kasallik germ disease"),
  ]),
  CoverIconGroup({'en': 'Society', 'uz': 'Jamiyat', 'ru': 'Общество'}, [
    ('🏛️', "hukumat muzey tarix government museum history"),
    ('🗳️', "saylov ovoz berish election vote"),
    ('📰', "yangiliklar gazeta media news newspaper"),
    ('⚖️', "qonun adolat sud law justice court"),
    ('🚔', "jinoyat politsiya crime police"),
    ('🕊️', "tinchlik peace"),
  ]),
  CoverIconGroup({'en': 'Time & events', 'uz': 'Vaqt va bayram', 'ru': 'Время и праздники'}, [
    ('⏰', "vaqt soat budilnik time clock alarm"),
    ('⌛', "vaqt qum soat time hourglass"),
    ('📅', "kalendar sana jadval calendar date schedule"),
    ('🌅', "tong ertalab morning sunrise"),
    ('🌃', "kecha tun night"),
    ('🎉', "bayram ziyofat party celebration"),
    ('🎁', "sovg'a gift present"),
    ('🎂', "tug'ilgan kun tort birthday cake"),
    ('💍', "to'y uzuk wedding ring"),
    ('🎄', "yangi yil archa new year christmas"),
    ('🎆', "mushak salyut fireworks"),
    ('🔥', "olov issiq fire hot"),
    ('⭐', "yulduz star"),
    ('🌟', "yulduz porlash star shine"),
    ('💎', "olmos qimmatbaho diamond"),
    ('🔑', "kalit key"),
  ]),
];

// Typed apostrophes vary (o' / oʻ / o’); fold them all to ' before matching.
String _foldSearch(String s) => s.toLowerCase().replaceAll(RegExp('[ʻʼ‘’`]'), "'").trim();

/// Icons whose topic name or search words contain every word of the query.
List<String> searchCoverIcons(String query) {
  final words = _foldSearch(query).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return const [];
  final out = <String>[];
  for (final g in coverIconGroups) {
    final topic = _foldSearch(g.label.values.join(' '));
    for (final (emoji, kw) in g.icons) {
      final hay = '$topic ${_foldSearch(kw)}';
      if (words.every(hay.contains) && !out.contains(emoji)) out.add(emoji);
    }
  }
  return out;
}

const _bucket = 'folder-covers';
const _publicPrefix = 'https://jzozrqbzhagezlwncktf.supabase.co/storage/v1/object/public/$_bucket/';

class CoverSpec {
  final int gradient;
  final String? emoji;
  final String? imageUrl;
  const CoverSpec({this.gradient = 0, this.emoji, this.imageUrl});

  // Null for "no cover" or anything malformed — callers then keep their
  // default look. Image URLs outside our bucket are ignored on purpose.
  static CoverSpec? parse(String? s) {
    if (s == null || s.isEmpty) return null;
    if (s.startsWith('img:')) {
      final url = s.substring(4);
      return url.startsWith(_publicPrefix) ? CoverSpec(imageUrl: url) : null;
    }
    if (s.startsWith('g:')) {
      final g = int.tryParse(s.substring(2));
      return g != null && g >= 0 && g < coverGradients.length ? CoverSpec(gradient: g) : null;
    }
    if (s.startsWith('e:')) {
      final bar = s.lastIndexOf('|');
      if (bar < 3) return null;
      final g = int.tryParse(s.substring(bar + 1));
      if (g == null || g < 0 || g >= coverGradients.length) return null;
      return CoverSpec(gradient: g, emoji: s.substring(2, bar));
    }
    return null;
  }

  String encode() => imageUrl != null ? 'img:$imageUrl' : emoji != null ? 'e:$emoji|$gradient' : 'g:$gradient';

  LinearGradient get linear => LinearGradient(
    colors: coverGradients[gradient],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // The cover's main colour, for shadows/borders drawn around it.
  Color get color => coverGradients[gradient][0];
}

/// Fills its box with the cover: gradient (+ big emoji) or the picture with a
/// dark wash so white text on top stays readable. A picture that can't load
/// (offline, deleted) falls back to the default purple gradient.
class CoverFill extends StatelessWidget {
  final CoverSpec cover;
  final double emojiSize;
  const CoverFill({super.key, required this.cover, this.emojiSize = 40});

  @override
  Widget build(BuildContext context) {
    final url = cover.imageUrl;
    if (url != null) {
      return Stack(fit: StackFit.expand, children: [
        DecoratedBox(decoration: BoxDecoration(gradient: cover.linear)),
        Image.network(url, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink()),
        const DecoratedBox(decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x14000000), Color(0x8C000000)],
          ),
        )),
      ]);
    }
    return DecoratedBox(
      decoration: BoxDecoration(gradient: cover.linear),
      child: cover.emoji == null
          ? null
          : Align(
              alignment: const Alignment(0.75, -0.35),
              child: Opacity(opacity: 0.9, child: Text(cover.emoji!, style: TextStyle(fontSize: emojiSize))),
            ),
    );
  }
}

/// The raised gradient folder/unit card of Library and My Words, painted with
/// [cover] when set, else the grid's [fallbackColor] gradient as before.
class CoverCard extends StatelessWidget {
  final String? cover;
  final Color fallbackColor;
  final String icon;
  final String title, subtitle;
  const CoverCard({super.key, required this.cover, required this.fallbackColor, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final spec = CoverSpec.parse(cover);
    final color = spec?.color ?? fallbackColor;
    final lighter = Color.lerp(color, Colors.white, 0.25)!;
    final darker = Color.lerp(color, Colors.black, 0.25)!;
    final showIcon = spec == null || (spec.emoji == null && spec.imageUrl == null);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: spec != null ? null : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [lighter, color, darker],
        ),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.55), offset: const Offset(0, 8), blurRadius: 16),
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(0, 12), blurRadius: 24),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border(
          bottom: BorderSide(color: darker, width: 4),
          right: BorderSide(color: darker, width: 2),
        ),
      ),
      child: Stack(fit: StackFit.expand, children: [
        if (spec != null)
          Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(18), child: CoverFill(cover: spec, emojiSize: 34))),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (showIcon) Text(icon, style: const TextStyle(fontSize: 26)),
            const Spacer(),
            Text(title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13,
                    shadows: [Shadow(color: Colors.black38, blurRadius: 4)]),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }
}

const _strings = <String, Map<String, String>>{
  'cover': {'en': 'Cover', 'uz': 'Muqova', 'ru': 'Обложка'},
  'upload': {'en': 'Upload a picture', 'uz': 'Rasm yuklash', 'ru': 'Загрузить фото'},
  'colour': {'en': 'Colour', 'uz': 'Rang', 'ru': 'Цвет'},
  'icon': {'en': 'Icon', 'uz': 'Belgi', 'ru': 'Значок'},
  'save': {'en': 'Save', 'uz': 'Saqlash', 'ru': 'Сохранить'},
  'reset_folder': {'en': 'Default look', 'uz': "Standart ko'rinish", 'ru': 'Обычный вид'},
  'reset_unit': {'en': "Use the folder's cover", 'uz': 'Papka muqovasini ishlatish', 'ru': 'Как у папки'},
  'uploading': {'en': 'Uploading…', 'uz': 'Yuklanmoqda…', 'ru': 'Загрузка…'},
  'upload_failed': {'en': "Couldn't upload the picture", 'uz': "Rasmni yuklab bo'lmadi", 'ru': 'Не удалось загрузить фото'},
  'save_failed': {'en': "Couldn't save the cover", 'uz': "Muqovani saqlab bo'lmadi", 'ru': 'Не удалось сохранить обложку'},
  'search': {'en': 'Search icons (food, doctor…)', 'uz': 'Belgi qidirish (ovqat, shifokor…)', 'ru': 'Поиск значка (еда, врач…)'},
  'no_results': {'en': 'Nothing found', 'uz': 'Hech narsa topilmadi', 'ru': 'Ничего не найдено'},
};

String coverTr(String key) => _strings[key]?[appLangNotifier.value] ?? _strings[key]!['en']!;

/// Bottom sheet to choose a cover. Returns null if cancelled, '' to remove
/// the cover (default look / inherit the folder's), else the new cover string.
/// [isUnit] only changes the remove button's wording.
Future<String?> showCoverPicker(BuildContext context, {String? current, bool isUnit = false}) {
  final start = CoverSpec.parse(current);
  var gradient = start?.gradient ?? 0;
  String? emoji = start?.emoji;
  var uploading = false;
  final searchCtrl = TextEditingController();
  // Open on the tab holding the current icon, else the first.
  var group = coverIconGroups.indexWhere((g) => g.icons.any((i) => i.$1 == emoji));
  if (group < 0) group = 0;

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
      Future<void> upload() async {
        final user = currentUser;
        if (user == null) return;
        final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 75);
        if (picked == null) return;
        setSheet(() => uploading = true);
        try {
          final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
          await supabase.storage.from(_bucket).uploadBinary(path, await picked.readAsBytes(),
              fileOptions: const FileOptions(contentType: 'image/jpeg'));
          final url = supabase.storage.from(_bucket).getPublicUrl(path);
          if (ctx.mounted) Navigator.pop(ctx, 'img:$url');
        } catch (e) {
          debugPrint('[showCoverPicker] upload failed: $e');
          if (ctx.mounted) {
            setSheet(() => uploading = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(coverTr('upload_failed'))));
          }
        }
      }

      final preview = CoverSpec(gradient: gradient, emoji: emoji);
      final searching = searchCtrl.text.trim().isNotEmpty;
      final shown = searching
          ? searchCoverIcons(searchCtrl.text)
          : [for (final (e, _) in coverIconGroups[group].icons) e];
      Widget label(String k) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 8),
        child: Text(coverTr(k), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textMuted, letterSpacing: 0.5)),
      );

      return SafeArea(child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: ctx.surface2, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 12),
          Text(coverTr('cover'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ctx.appText)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(height: 90, width: double.infinity, child: CoverFill(cover: preview, emojiSize: 44)),
          ),
          const SizedBox(height: 12),
          if (currentUser != null)
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: uploading ? null : upload,
              icon: uploading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.photo_library_outlined),
              label: Text(coverTr(uploading ? 'uploading' : 'upload')),
              style: OutlinedButton.styleFrom(foregroundColor: ctx.primary, side: BorderSide(color: ctx.primary.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            )),
          label('colour'),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (var i = 0; i < coverGradients.length; i++)
              GestureDetector(
                onTap: () => setSheet(() => gradient = i),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: coverGradients[i]),
                    border: Border.all(color: gradient == i ? ctx.appText : Colors.transparent, width: 3),
                  ),
                ),
              ),
          ]),
          label('icon'),
          TextField(
            controller: searchCtrl,
            onChanged: (_) => setSheet(() {}),
            style: TextStyle(color: ctx.appText, fontSize: 14),
            decoration: InputDecoration(
              hintText: coverTr('search'),
              hintStyle: TextStyle(color: ctx.textMuted, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: ctx.textMuted, size: 20),
              isDense: true,
              filled: true,
              fillColor: ctx.surface2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),
          if (!searching)
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: coverIconGroups.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final g = coverIconGroups[i];
                  final on = group == i;
                  return GestureDetector(
                    onTap: () => setSheet(() => group = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: on ? ctx.primary : ctx.surface2, borderRadius: BorderRadius.circular(20)),
                      child: Text('${g.icons.first.$1} ${g.label[appLangNotifier.value] ?? g.label['en']}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: on ? Colors.white : ctx.textMuted)),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 10),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(child: Text(coverTr('no_results'), style: TextStyle(color: ctx.textMuted, fontSize: 12))),
            ),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final e in shown)
              GestureDetector(
                onTap: () => setSheet(() => emoji = emoji == e ? null : e),
                child: Container(
                  width: 40, height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: emoji == e ? ctx.primary.withValues(alpha: 0.18) : ctx.surface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: emoji == e ? ctx.primary : Colors.transparent, width: 2),
                  ),
                  child: Text(e, style: const TextStyle(fontSize: 20)),
                ),
              ),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            if (current != null && current.isNotEmpty) ...[
              Expanded(child: TextButton(
                onPressed: uploading ? null : () => Navigator.pop(ctx, ''),
                child: Text(coverTr(isUnit ? 'reset_unit' : 'reset_folder'), textAlign: TextAlign.center, style: TextStyle(color: ctx.textMuted)),
              )),
              const SizedBox(width: 8),
            ],
            Expanded(child: ElevatedButton(
              onPressed: uploading ? null : () => Navigator.pop(ctx, preview.encode()),
              style: ElevatedButton.styleFrom(backgroundColor: ctx.primary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(coverTr('save'), style: const TextStyle(fontWeight: FontWeight.bold)),
            )),
          ]),
        ]),
      ));
    }),
  ).whenComplete(searchCtrl.dispose);
}

/// Best-effort: delete an uploaded picture that's no longer used. Only our
/// own files (folder = user id) — RLS would refuse anything else anyway.
Future<void> deleteCoverImage(String? cover) async {
  final url = CoverSpec.parse(cover)?.imageUrl;
  final user = currentUser;
  if (url == null || user == null) return;
  final path = url.substring(_publicPrefix.length);
  if (!path.startsWith('${user.id}/')) return;
  try {
    await supabase.storage.from(_bucket).remove([path]);
  } catch (e) {
    debugPrint('[deleteCoverImage] $e');
  }
}
