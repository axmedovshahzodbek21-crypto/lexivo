import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';

// Page tips: a short card shown the first time an account opens each main
// screen — what it's for and how to use it well. Shown by PageTipButton
// (lib/widgets/page_tip_button.dart), which each screen puts in its header.
//
// Seen ids + the on/off switch are per ACCOUNT (profiles.seen_tips /
// profiles.tips_enabled, shared with the web), cached in SharedPreferences.
// Neither key is in clearAllProgress's keep-list, so sign-out wipes them.
//
// Mirrors lexivo-web/lib/page-tips.ts. The copy below is generated from that
// file by lexivo-web/scripts/page-tips-to-dart.js — edit it there, not here.
class PageTips {
  static const _seenKey = 'seen_tips';
  static const _enabledKey = 'tips_enabled';

  // Pulls the account's seen list + switch into the local copy. Only called
  // when a screen's tip hasn't been seen locally, so seen screens cost nothing.
  static Future<void> _pull(SharedPreferences prefs) async {
    final user = currentUser;
    if (user == null) return;
    try {
      final res = await supabase.from('profiles').select('seen_tips, tips_enabled').eq('id', user.id).maybeSingle();
      if (res == null) return;
      final remote = List<String>.from((res['seen_tips'] as List?) ?? const []);
      await prefs.setStringList(_seenKey, {...?prefs.getStringList(_seenKey), ...remote}.toList());
      await prefs.setBool(_enabledKey, res['tips_enabled'] != false);
    } catch (_) {}
  }

  static Future<bool> shouldShow(String id) async {
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getStringList(_seenKey) ?? const []).contains(id)) return false;
    await _pull(prefs);
    return (prefs.getBool(_enabledKey) ?? true) && !(prefs.getStringList(_seenKey) ?? const []).contains(id);
  }

  static Future<void> markSeen(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList(_seenKey) ?? [];
    if (!seen.contains(id)) await prefs.setStringList(_seenKey, [...seen, id]);
    if (currentUser == null) return;
    try {
      await supabase.rpc('mark_tip_seen', params: {'p_tip': id});
    } catch (_) {}
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    await _pull(prefs);
    return prefs.getBool(_enabledKey) ?? true;
  }

  static Future<void> setEnabled(bool on) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, on);
    final user = currentUser;
    if (user == null) return;
    try {
      await supabase.from('profiles').update({'tips_enabled': on}).eq('id', user.id);
    } catch (_) {}
  }

  // Settings "show all tips again": clears the seen list and turns tips back on.
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seenKey);
    await prefs.setBool(_enabledKey, true);
    final user = currentUser;
    if (user == null) return;
    try {
      await supabase.from('profiles').update({'seen_tips': <String>[], 'tips_enabled': true}).eq('id', user.id);
    } catch (_) {}
  }
}

class PageTipCopy {
  final String title;
  final List<(String icon, String title, String desc)> steps;
  const PageTipCopy(this.title, this.steps);
}

// ── Copy (generated from lexivo-web/lib/page-tips.ts) ──
const pageTipsUi = <String, Map<String, String>>{
  'en': {
    'gotIt': "Got it",
    'turnOff': "Turn off tips",
    'showTip': "About this page",
    'setting': "💡 Page tips",
    'settingHelper': "A short guide the first time you open each page",
    'showAgain': "Show all tips again",
    'shownAgain': "Tips will show again ✓",
  },
  'uz': {
    'gotIt': "Tushunarli",
    'turnOff': "Ko'rsatmalarni o'chirish",
    'showTip': "Sahifa haqida",
    'setting': "💡 Sahifa ko'rsatmalari",
    'settingHelper': "Har bir sahifani birinchi marta ochganingizda qisqa ko'rsatma",
    'showAgain': "Barcha ko'rsatmalarni qayta ko'rsatish",
    'shownAgain': "Ko'rsatmalar yana chiqadi ✓",
  },
  'ru': {
    'gotIt': "Понятно",
    'turnOff': "Отключить подсказки",
    'showTip': "Об этой странице",
    'setting': "💡 Подсказки на страницах",
    'settingHelper': "Короткая подсказка при первом открытии каждой страницы",
    'showAgain': "Показать все подсказки снова",
    'shownAgain': "Подсказки появятся снова ✓",
  },
};

const pageTips = <String, Map<String, PageTipCopy>>{
  'home': {
    'en': PageTipCopy("Home", [
      ("🔥", "Daily goal & streak", "Study a little every day to keep your streak going."),
      ("🔁", "Reviews first", "If words are due for review, do them before learning new ones."),
      ("▶️", "One tap to study", "Each card here opens an activity straight away."),
    ]),
    'uz': PageTipCopy("Bosh sahifa", [
      ("🔥", "Kunlik maqsad va streak", "Streakni yo'qotmaslik uchun har kuni ozgina bo'lsa ham o'qing."),
      ("🔁", "Avval takrorlash", "Takrorlanadigan so'zlar bo'lsa, yangilaridan oldin ularni bajaring."),
      ("▶️", "Bir bosishda mashq", "Bu yerdagi har bir karta mashqni darhol ochadi."),
    ]),
    'ru': PageTipCopy("Главная", [
      ("🔥", "Цель и серия", "Занимайтесь понемногу каждый день, чтобы не прерывать серию."),
      ("🔁", "Сначала повторение", "Если есть слова на повторение, сделайте их до новых слов."),
      ("▶️", "Учёба в одно касание", "Каждая карточка здесь сразу открывает занятие."),
    ]),
  },
  'srs': {
    'en': PageTipCopy("Review (SRS)", [
      ("🧠", "What it is", "Words you've learned come back right before you'd forget them."),
      ("📅", "When", "Each word returns after 1, 5, 7, 14 and 30 days. Come back whenever words are due."),
      ("⚠️", "Don't skip", "Miss 3 reviews of a word in a row and it goes back to learning."),
    ]),
    'uz': PageTipCopy("Takrorlash (SRS)", [
      ("🧠", "Bu nima", "O'rgangan so'zlaringiz aynan unutay deganingizda qaytib keladi."),
      ("📅", "Qachon", "Har bir so'z 1, 5, 7, 14 va 30 kundan keyin qaytadi. So'zlar kelganda kiring."),
      ("⚠️", "O'tkazib yubormang", "So'zni ketma-ket 3 marta takrorlamasangiz, u qayta o'rganishga qaytadi."),
    ]),
    'ru': PageTipCopy("Повторение (SRS)", [
      ("🧠", "Что это", "Выученные слова возвращаются как раз перед тем, как вы бы их забыли."),
      ("📅", "Когда", "Каждое слово возвращается через 1, 5, 7, 14 и 30 дней. Заходите, когда есть слова."),
      ("⚠️", "Не пропускайте", "Пропустите 3 повторения слова подряд — и оно вернётся в изучение."),
    ]),
  },
  'learn': {
    'en': PageTipCopy("Learn", [
      ("📖", "New words", "See each word with its translation, pronunciation and examples."),
      ("🔊", "Say it out loud", "Tap the speaker and repeat the word — it sticks much better."),
      ("🔁", "Then review", "Learned words go into Review automatically, so you won't forget them."),
    ]),
    'uz': PageTipCopy("O'rganish", [
      ("📖", "Yangi so'zlar", "Har bir so'z tarjimasi, talaffuzi va misollari bilan."),
      ("🔊", "Ovoz chiqarib ayting", "Karnayni bosing va so'zni takrorlang — shunda yaxshi eslab qolasiz."),
      ("🔁", "Keyin takrorlash", "O'rganilgan so'zlar unutilmasligi uchun avtomatik Takrorlashga tushadi."),
    ]),
    'ru': PageTipCopy("Изучение", [
      ("📖", "Новые слова", "Каждое слово с переводом, произношением и примерами."),
      ("🔊", "Говорите вслух", "Нажмите на динамик и повторите слово — так оно лучше запомнится."),
      ("🔁", "Потом повторение", "Выученные слова сами попадают в Повторение, чтобы вы их не забыли."),
    ]),
  },
  'flashcards': {
    'en': PageTipCopy("Flashcards", [
      ("🤔", "Remember first", "Try to recall the meaning before you flip the card."),
      ("🃏", "Easy or hard", "Mark each card honestly so you see which words need more work."),
      ("⚡", "Quick practice", "Good for a few minutes of revision between other activities."),
    ]),
    'uz': PageTipCopy("Kartochkalar", [
      ("🤔", "Avval eslang", "Kartani aylantirishdan oldin ma'nosini eslashga harakat qiling."),
      ("🃏", "Oson yoki qiyin", "Qaysi so'zlar ustida ko'proq ishlash kerakligini bilish uchun halol belgilang."),
      ("⚡", "Tezkor mashq", "Boshqa mashqlar orasida bir necha daqiqalik takrorlash uchun qulay."),
    ]),
    'ru': PageTipCopy("Карточки", [
      ("🤔", "Сначала вспомните", "Попробуйте вспомнить значение, прежде чем перевернуть карточку."),
      ("🃏", "Легко или трудно", "Отмечайте честно, чтобы видеть, какие слова требуют работы."),
      ("⚡", "Быстрая практика", "Подходит для нескольких минут повторения между занятиями."),
    ]),
  },
  'quiz': {
    'en': PageTipCopy("Quiz", [
      ("❓", "Pick the answer", "Choose the right meaning out of four options."),
      ("🎯", "Don't guess", "The quiz shows which words you really know — and which you only think you know."),
      ("⭐", "Bonus XP", "A perfect score gives extra XP."),
    ]),
    'uz': PageTipCopy("Test", [
      ("❓", "Javobni tanlang", "To'rtta variantdan to'g'ri ma'noni tanlang."),
      ("🎯", "Taxmin qilmang", "Test qaysi so'zlarni haqiqatan bilishingizni ko'rsatadi."),
      ("⭐", "Bonus XP", "Hammasi to'g'ri bo'lsa, qo'shimcha XP olasiz."),
    ]),
    'ru': PageTipCopy("Тест", [
      ("❓", "Выберите ответ", "Выберите правильное значение из четырёх вариантов."),
      ("🎯", "Не угадывайте", "Тест показывает, какие слова вы действительно знаете."),
      ("⭐", "Бонус XP", "За результат без ошибок — дополнительный XP."),
    ]),
  },
  'matching': {
    'en': PageTipCopy("Match", [
      ("🔗", "Make pairs", "Tap a word, then tap its meaning."),
      ("🎯", "Few mistakes", "Try to clear the board with as few wrong taps as you can."),
      ("💡", "Best for", "A quick, fun check of words you've already learned."),
    ]),
    'uz': PageTipCopy("Moslashtirish", [
      ("🔗", "Juftlang", "So'zni bosing, keyin uning ma'nosini bosing."),
      ("🎯", "Kam xato", "Hamma juftlarni iloji boricha kam xato bilan toping."),
      ("💡", "Nima uchun", "O'rgangan so'zlaringizni tez va qiziqarli tekshirish uchun."),
    ]),
    'ru': PageTipCopy("Сопоставление", [
      ("🔗", "Составьте пары", "Нажмите на слово, затем на его значение."),
      ("🎯", "Меньше ошибок", "Постарайтесь собрать все пары с минимумом ошибок."),
      ("💡", "Для чего", "Быстрая и весёлая проверка уже выученных слов."),
    ]),
  },
  'my_words': {
    'en': PageTipCopy("My Words", [
      ("📁", "Your own words", "Words you add yourself live here, in folders and units."),
      ("➕", "Add words", "Type them in or use AI import to get translations and examples."),
      ("📚", "Study them", "Open a unit to Learn, Flashcards, Quiz or Match on your own words."),
    ]),
    'uz': PageTipCopy("Mening so'zlarim", [
      ("📁", "O'z so'zlaringiz", "O'zingiz qo'shgan so'zlar shu yerda, papka va bo'limlarda saqlanadi."),
      ("➕", "So'z qo'shish", "Qo'lda yozing yoki tarjima va misollar uchun AI importdan foydalaning."),
      ("📚", "O'rganing", "Bo'limni oching va o'z so'zlaringiz bilan O'rganish, Kartochka, Test yoki Moslashtirishni bajaring."),
    ]),
    'ru': PageTipCopy("Мои слова", [
      ("📁", "Ваши слова", "Слова, которые вы добавили сами, хранятся здесь в папках и разделах."),
      ("➕", "Добавление", "Введите их вручную или через AI-импорт с переводом и примерами."),
      ("📚", "Учите их", "Откройте раздел: Изучение, Карточки, Тест или Сопоставление."),
    ]),
  },
  'library': {
    'en': PageTipCopy("Library", [
      ("📚", "Teaching library", "Build folders and units of words to use with your classes."),
      ("➕", "Add words", "Add words to a unit by hand or with AI import."),
      ("🏫", "Use in class", "Give units to your students as homework."),
    ]),
    'uz': PageTipCopy("Kutubxona", [
      ("📚", "O'qituvchi kutubxonasi", "Sinflaringiz uchun so'zlardan papka va bo'limlar tuzing."),
      ("➕", "So'z qo'shish", "Bo'limga so'zlarni qo'lda yoki AI import orqali qo'shing."),
      ("🏫", "Sinfda foydalaning", "Bo'limlarni o'quvchilarga uy vazifasi qilib bering."),
    ]),
    'ru': PageTipCopy("Библиотека", [
      ("📚", "Библиотека учителя", "Создавайте папки и разделы со словами для своих классов."),
      ("➕", "Добавление слов", "Добавляйте слова в раздел вручную или через AI-импорт."),
      ("🏫", "В классе", "Задавайте разделы ученикам как домашнее задание."),
    ]),
  },
  'import': {
    'en': PageTipCopy("How to Import Words", [
      ("🌐", "Choose languages", "Select the language of your words and the language you want translations in."),
      ("🤖", "Copy a prompt", "Copy a prompt below, open Claude or ChatGPT, paste it with your words and send."),
      ("📋", "Paste the response", "Copy the AI's reply and paste it into the box below. Your words appear instantly."),
    ]),
    'uz': PageTipCopy("So'zlarni qanday import qilish", [
      ("🌐", "Tillarni tanlang", "So'zlaringiz tilini va tarjima tilini tanlang."),
      ("🤖", "Promptni nusxalang", "Promptni nusxalang, Claude yoki ChatGPT ga so'zlaringiz bilan joylashtiring va yuboring."),
      ("📋", "Javobni joylashtiring", "Sun'iy intellekt javobini quyidagi maydonga joylashtiring. So'zlaringiz darhol ko'rinadi."),
    ]),
    'ru': PageTipCopy("Как импортировать слова", [
      ("🌐", "Выберите языки", "Выберите язык ваших слов и язык перевода."),
      ("🤖", "Скопируйте запрос", "Скопируйте запрос, откройте Claude или ChatGPT, вставьте вместе со словами и отправьте."),
      ("📋", "Вставьте ответ", "Вставьте ответ AI в поле ниже. Слова появятся сразу."),
    ]),
  },
  'reading': {
    'en': PageTipCopy("Ideas — Reading", [
      ("📰", "Short reads", "Stories and articles at B1–B2 level, full of useful words."),
      ("✋", "Collect words", "Select any word or phrase while reading to collect it."),
      ("💬", "Check yourself", "Answer the questions at the end to see if you understood."),
    ]),
    'uz': PageTipCopy("G'oyalar — O'qish", [
      ("📰", "Qisqa matnlar", "B1–B2 darajadagi foydali so'zlarga boy hikoya va maqolalar."),
      ("✋", "So'z yig'ing", "O'qiyotganda istalgan so'z yoki iborani belgilab, yig'ib oling."),
      ("💬", "O'zingizni tekshiring", "Tushunganingizni bilish uchun oxiridagi savollarga javob bering."),
    ]),
    'ru': PageTipCopy("Идеи — Чтение", [
      ("📰", "Короткие тексты", "Истории и статьи уровня B1–B2 с полезными словами."),
      ("✋", "Собирайте слова", "Выделите любое слово или фразу во время чтения, чтобы сохранить."),
      ("💬", "Проверьте себя", "Ответьте на вопросы в конце, чтобы проверить понимание."),
    ]),
  },
  'ielts_reading': {
    'en': PageTipCopy("IELTS Reading", [
      ("📝", "Exam style", "Three passages with 30 practice tests each, using real IELTS question types."),
      ("⏱️", "Time yourself", "Give yourself about 20 minutes per passage, like in the exam."),
      ("🔍", "Learn from mistakes", "After checking, find the sentence in the text that holds the answer."),
    ]),
    'uz': PageTipCopy("IELTS Reading", [
      ("📝", "Imtihon uslubi", "Uchta passage, har birida 30 ta test — haqiqiy IELTS savol turlari."),
      ("⏱️", "Vaqtni belgilang", "Imtihondagidek har bir passage uchun taxminan 20 daqiqa ajrating."),
      ("🔍", "Xatodan o'rganing", "Tekshirgandan keyin matnda javob turgan gapni toping."),
    ]),
    'ru': PageTipCopy("IELTS Reading", [
      ("📝", "Как на экзамене", "Три пассажа по 30 тестов, настоящие типы вопросов IELTS."),
      ("⏱️", "Засекайте время", "Около 20 минут на пассаж, как на экзамене."),
      ("🔍", "Учитесь на ошибках", "После проверки найдите в тексте предложение с ответом."),
    ]),
  },
  'structures': {
    'en': PageTipCopy("Structures", [
      ("🧩", "Sentence patterns", "Ready-made English structures you can use in speaking and writing."),
      ("📆", "Unit by unit", "Each unit is split into days: Learn first, then Flashcards and Translate."),
      ("🔁", "Keep them", "Use Review and Detective to practise everything you've learned."),
    ]),
    'uz': PageTipCopy("Strukturalar", [
      ("🧩", "Gap qoliplari", "Gapirish va yozishda ishlatsa bo'ladigan tayyor ingliz strukturalari."),
      ("📆", "Bo'limma-bo'lim", "Har bir bo'lim kunlarga bo'lingan: avval O'rganish, keyin Kartochka va Tarjima."),
      ("🔁", "Mustahkamlang", "O'rganganlaringizni Takrorlash va Detective bilan mashq qiling."),
    ]),
    'ru': PageTipCopy("Структуры", [
      ("🧩", "Шаблоны фраз", "Готовые английские структуры для речи и письма."),
      ("📆", "По разделам", "Каждый раздел разбит на дни: сначала Изучение, потом Карточки и Перевод."),
      ("🔁", "Закрепляйте", "Повторение и Detective помогут закрепить всё выученное."),
    ]),
  },
  'battle_ready': {
    'en': PageTipCopy("Battle-Ready", [
      ("⚔️", "Topic prep", "Pick a topic and a side to get arguments, idioms, phrases and vocabulary."),
      ("🗣️", "For speaking", "Great before IELTS Speaking, an essay or a class debate."),
      ("🃏", "Practise the words", "Each side has Learn, Flashcards, Match and Quiz for its vocabulary."),
    ]),
    'uz': PageTipCopy("Battle-Ready", [
      ("⚔️", "Mavzuga tayyorgarlik", "Mavzu va tomonni tanlang: dalillar, idiomalar, iboralar va so'zlar."),
      ("🗣️", "Gapirish uchun", "IELTS Speaking, insho yoki sinfdagi bahsdan oldin juda foydali."),
      ("🃏", "So'zlarni mashq qiling", "Har bir tomonda so'zlar uchun O'rganish, Kartochka, Moslashtirish va Test bor."),
    ]),
    'ru': PageTipCopy("Battle-Ready", [
      ("⚔️", "Подготовка к теме", "Выберите тему и сторону: аргументы, идиомы, фразы и слова."),
      ("🗣️", "Для говорения", "Отлично перед IELTS Speaking, эссе или дебатами в классе."),
      ("🃏", "Тренируйте слова", "У каждой стороны есть Изучение, Карточки, Сопоставление и Тест."),
    ]),
  },
  'debate': {
    'en': PageTipCopy("Debate Arena", [
      ("🎤", "Both sides", "Learn to argue for and against any topic."),
      ("🛠️", "Core skills first", "Start with openings, signposting and rebuttal phrases."),
      ("🔥", "Then drill", "Pick a topic and go through its steps one by one."),
    ]),
    'uz': PageTipCopy("Debate Arena", [
      ("🎤", "Ikkala tomon", "Istalgan mavzu bo'yicha tarafdor va qarshi fikr bildirishni o'rganing."),
      ("🛠️", "Avval asosiy ko'nikmalar", "Kirish, bog'lovchi va raddiya iboralaridan boshlang."),
      ("🔥", "Keyin mashq", "Mavzuni tanlang va bosqichlarini birma-bir bajaring."),
    ]),
    'ru': PageTipCopy("Debate Arena", [
      ("🎤", "Обе стороны", "Учитесь аргументировать за и против любой темы."),
      ("🛠️", "Сначала основы", "Начните со вступлений, связок и фраз для опровержения."),
      ("🔥", "Потом практика", "Выберите тему и пройдите её шаги по порядку."),
    ]),
  },
  'phrases': {
    'en': PageTipCopy("Phrases", [
      ("💬", "Ready-made phrases", "Natural expressions from A1 to C2, each with examples."),
      ("🎚️", "Pick your level", "Start at your level and move up when it feels easy."),
      ("🗣️", "Use them", "Try to use one new phrase in your own sentence today."),
    ]),
    'uz': PageTipCopy("Iboralar", [
      ("💬", "Tayyor iboralar", "A1 dan C2 gacha tabiiy iboralar, har biri misollar bilan."),
      ("🎚️", "Darajangizni tanlang", "O'z darajangizdan boshlang, oson bo'lib qolsa, yuqoriga o'ting."),
      ("🗣️", "Ishlating", "Bugun bitta yangi iborani o'z gapingizda ishlatib ko'ring."),
    ]),
    'ru': PageTipCopy("Фразы", [
      ("💬", "Готовые фразы", "Естественные выражения от A1 до C2, каждое с примерами."),
      ("🎚️", "Выберите уровень", "Начните со своего уровня и переходите выше, когда станет легко."),
      ("🗣️", "Используйте", "Попробуйте сегодня использовать одну новую фразу в своём предложении."),
    ]),
  },
  'real_english': {
    'en': PageTipCopy("Real English", [
      ("🎬", "Real videos", "Each set teaches the words from a real English video."),
      ("🔁", "Review them", "Review the words with SRS for about 11 days."),
      ("🔓", "Unlock", "After the +7-day review the video unlocks — and you understand it."),
    ]),
    'uz': PageTipCopy("Real English", [
      ("🎬", "Haqiqiy videolar", "Har bir to'plam haqiqiy ingliz tilidagi videodagi so'zlarni o'rgatadi."),
      ("🔁", "Takrorlang", "So'zlarni taxminan 11 kun davomida SRS bilan takrorlang."),
      ("🔓", "Oching", "+7 kunlik takrorlashdan keyin video ochiladi — va siz uni tushunasiz."),
    ]),
    'ru': PageTipCopy("Real English", [
      ("🎬", "Настоящие видео", "Каждый набор учит слова из настоящего английского видео."),
      ("🔁", "Повторяйте", "Повторяйте слова через SRS около 11 дней."),
      ("🔓", "Откройте", "После повторения на +7 день видео откроется — и вы его поймёте."),
    ]),
  },
  'speaking': {
    'en': PageTipCopy("Speaking Practice", [
      ("🎙️", "Real questions", "Every question has appeared in a real IELTS Speaking exam."),
      ("🗣️", "Answer out loud", "Pick a part, get a question and answer it out loud."),
      ("😌", "No pressure", "No score and no right answers — just speaking practice."),
    ]),
    'uz': PageTipCopy("Gapirish mashqi", [
      ("🎙️", "Haqiqiy savollar", "Har bir savol haqiqiy IELTS Speaking imtihonida berilgan."),
      ("🗣️", "Ovoz chiqarib javob bering", "Qismni tanlang, savol oling va ovoz chiqarib javob bering."),
      ("😌", "Bosimsiz", "Ball ham, to'g'ri javob ham yo'q — faqat gapirish mashqi."),
    ]),
    'ru': PageTipCopy("Практика говорения", [
      ("🎙️", "Настоящие вопросы", "Каждый вопрос был на реальном экзамене IELTS Speaking."),
      ("🗣️", "Отвечайте вслух", "Выберите часть, получите вопрос и ответьте вслух."),
      ("😌", "Без давления", "Без баллов и правильных ответов — просто практика."),
    ]),
  },
  'pomodoro': {
    'en': PageTipCopy("Pomodoro", [
      ("⏱️", "Focus timer", "Study for a set time, then take a short break."),
      ("🎯", "One task", "Decide what you will study before you start the timer."),
      ("📊", "See your time", "Your focus sessions are saved in Pomodoro stats."),
    ]),
    'uz': PageTipCopy("Pomodoro", [
      ("⏱️", "Diqqat taymeri", "Belgilangan vaqt o'qing, keyin qisqa tanaffus qiling."),
      ("🎯", "Bitta vazifa", "Taymerni yoqishdan oldin nimani o'qishingizni hal qiling."),
      ("📊", "Vaqtingizni ko'ring", "Diqqat seanslaringiz Pomodoro statistikasida saqlanadi."),
    ]),
    'ru': PageTipCopy("Помодоро", [
      ("⏱️", "Таймер фокуса", "Занимайтесь заданное время, затем короткий перерыв."),
      ("🎯", "Одна задача", "Решите, что будете учить, до запуска таймера."),
      ("📊", "Ваше время", "Сессии фокуса сохраняются в статистике Помодоро."),
    ]),
  },
  'progress': {
    'en': PageTipCopy("Progress", [
      ("📈", "Your stats", "Your XP, streak and how many words you've learned."),
      ("📅", "Calendar", "The calendar shows which days you studied."),
      ("💪", "Look back", "Check it once a week to see how far you have come."),
    ]),
    'uz': PageTipCopy("Natijalar", [
      ("📈", "Statistikangiz", "XP, streak va qancha so'z o'rganganingiz."),
      ("📅", "Kalendar", "Kalendar qaysi kunlari o'qiganingizni ko'rsatadi."),
      ("💪", "Ortga qarang", "Qanchalik o'sganingizni ko'rish uchun haftada bir marta tekshiring."),
    ]),
    'ru': PageTipCopy("Прогресс", [
      ("📈", "Ваша статистика", "XP, серия и сколько слов вы выучили."),
      ("📅", "Календарь", "Календарь показывает, в какие дни вы занимались."),
      ("💪", "Оглянитесь", "Заглядывайте раз в неделю, чтобы увидеть свой рост."),
    ]),
  },
  'leaderboard': {
    'en': PageTipCopy("Leaderboard", [
      ("🏆", "Ranking", "See how your XP compares with other learners."),
      ("⚡", "Climb up", "Every activity gives XP — studying every day is the fastest way up."),
      ("🙈", "Privacy", "You can hide yourself from the leaderboard in Settings."),
    ]),
    'uz': PageTipCopy("Reyting", [
      ("🏆", "Reyting", "XP'ingizni boshqa o'quvchilar bilan solishtiring."),
      ("⚡", "Yuqoriga ko'tariling", "Har bir mashq XP beradi — har kuni o'qish eng tez yo'l."),
      ("🙈", "Maxfiylik", "Sozlamalarda o'zingizni reytingdan yashirishingiz mumkin."),
    ]),
    'ru': PageTipCopy("Рейтинг", [
      ("🏆", "Рейтинг", "Сравните свой XP с другими учениками."),
      ("⚡", "Поднимайтесь", "Каждое занятие даёт XP — ежедневная учёба быстрее всего ведёт вверх."),
      ("🙈", "Приватность", "Скрыть себя из рейтинга можно в Настройках."),
    ]),
  },
  'classes': {
    'en': PageTipCopy("Classes", [
      ("🏫", "Learn with a teacher", "Join your teacher's class with a code or link."),
      ("👩‍🏫", "Or teach", "Create your own class and invite students."),
      ("🔒", "Kept separate", "Class XP and streak are separate from your personal ones."),
    ]),
    'uz': PageTipCopy("Sinflar", [
      ("🏫", "O'qituvchi bilan", "O'qituvchingiz sinfiga kod yoki havola orqali qo'shiling."),
      ("👩‍🏫", "Yoki o'qiting", "O'z sinfingizni yarating va o'quvchilarni taklif qiling."),
      ("🔒", "Alohida", "Sinf XP va streaki shaxsiy XP va streakingizdan alohida."),
    ]),
    'ru': PageTipCopy("Классы", [
      ("🏫", "С учителем", "Вступите в класс учителя по коду или ссылке."),
      ("👩‍🏫", "Или учите сами", "Создайте свой класс и пригласите учеников."),
      ("🔒", "Отдельно", "XP и серия класса отдельно от личных."),
    ]),
  },
  'classes_joined': {
    'en': PageTipCopy("Joined Classes", [
      ("📋", "Homework", "Your teacher's homework and announcements show up here."),
      ("⏰", "On time", "Finish homework before its due date."),
      ("💬", "Ask your teacher", "Open a class to message your teacher."),
    ]),
    'uz': PageTipCopy("Qo'shilgan sinflar", [
      ("📋", "Uy vazifasi", "O'qituvchingizning uy vazifalari va e'lonlari shu yerda chiqadi."),
      ("⏰", "O'z vaqtida", "Uy vazifasini muddatidan oldin bajaring."),
      ("💬", "O'qituvchiga yozing", "O'qituvchingizga yozish uchun sinfni oching."),
    ]),
    'ru': PageTipCopy("Мои классы (ученик)", [
      ("📋", "Домашние задания", "Здесь появляются задания и объявления учителя."),
      ("⏰", "Вовремя", "Выполняйте задания до срока."),
      ("💬", "Напишите учителю", "Откройте класс, чтобы написать учителю."),
    ]),
  },
  'classes_created': {
    'en': PageTipCopy("My Classes", [
      ("➕", "Create a class", "Create a class and share its code with your students."),
      ("📚", "Give homework", "Assign words from your Library as homework."),
      ("📊", "Follow students", "See each student's progress and the daily insights."),
    ]),
    'uz': PageTipCopy("Mening sinflarim", [
      ("➕", "Sinf yarating", "Sinf yarating va kodini o'quvchilaringizga yuboring."),
      ("📚", "Uy vazifasi bering", "Kutubxonangizdagi so'zlarni uy vazifasi qilib bering."),
      ("📊", "O'quvchilarni kuzating", "Har bir o'quvchining natijasi va kunlik Xulosalarni ko'ring."),
    ]),
    'ru': PageTipCopy("Мои классы (учитель)", [
      ("➕", "Создайте класс", "Создайте класс и отправьте код ученикам."),
      ("📚", "Задавайте ДЗ", "Задавайте слова из Библиотеки как домашнее задание."),
      ("📊", "Следите за учениками", "Смотрите прогресс каждого ученика и ежедневные выводы."),
    ]),
  },
};
