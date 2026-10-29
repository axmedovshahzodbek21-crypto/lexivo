// GENERATED from lexivo-web/lib/student-summary-sentences.ts by
// lexivo-web/scripts/student-summary-to-dart.js — do not edit by hand.

const summaryFreq = <String, Map<String, String>>{
  'uz': {'rarely': "kamdan-kam", 'sometimes': "ba'zan", 'often': "ko'pincha"},
  'en': {'rarely': "rarely", 'sometimes': "sometimes", 'often': "often"},
};

const summarySentences = <String, Map<String, List<String>>>{
  'not_enough_data': {
    'uz': [
      "Batafsil xulosa uchun hali ma'lumot kam — vazifalar bajarilgani yoki muddati o'tgani sari paydo bo'ladi.",
    ],
    'en': [
      "Not enough data yet for a fuller summary — it grows as homework gets done or passes its deadline.",
    ],
  },
  'hw_early': {
    'uz': [
      "{name} vazifalarni odatda muddatidan oldin bajaradi.",
      "{name} vazifalarga erta kirishadi — muddatni kutib o'tirmaydi.",
      "{name} uy vazifalarini ko'pincha vaqtidan ancha oldin tugatadi.",
      "Vazifalar {name} uchun oxirgi kunga qolmaydi — odatda oldinroq bajariladi.",
    ],
    'en': [
      "{name} usually finishes homework before the deadline.",
      "{name} starts homework early and doesn't wait for the deadline.",
      "{name} often finishes homework well ahead of time.",
      "Homework rarely waits until the last day for {name}.",
    ],
  },
  'hw_last_day': {
    'uz': [
      "{name} vazifalarni ko'pincha oxirgi kuni bajaradi, lekin hech birini qoldirmaydi.",
      "{name} odatda muddatga yaqin ishlaydi — baribir hammasini vaqtida topshiradi.",
      "Vazifalar ko'pincha oxirgi kunga qoladi, ammo {name} ularni doim tugatadi.",
      "{name} oxirgi kunni afzal ko'radi, lekin muddatni o'tkazib yubormaydi.",
    ],
    'en': [
      "{name} often does homework on the last day, but never skips one.",
      "{name} usually works close to the deadline, but still hands everything in on time.",
      "Homework often waits until the last day, but {name} always finishes it.",
      "{name} prefers the last day, but doesn't miss the deadline.",
    ],
  },
  'hw_on_time': {
    'uz': [
      "{name} barcha vazifalarni o'z vaqtida bajargan.",
      "{name} hech bir muddatni o'tkazib yubormagan.",
      "{name} so'nggi {total} ta vazifaning hammasini vaqtida topshirgan.",
    ],
    'en': [
      "{name} has done every homework on time.",
      "{name} hasn't missed a single deadline.",
      "{name} handed in all of the last {total} assignments on time.",
    ],
  },
  'hw_same_day': {
    'uz': [
      "{name} vazifani ko'pincha berilgan kuniyoq bajaradi.",
      "{name} vazifa berilishi bilan darrov ishga kirishadi.",
      "Vazifa berilgan kuni {name} odatda uni tugatib qo'yadi.",
    ],
    'en': [
      "{name} often does homework on the day it is assigned.",
      "{name} gets to work as soon as homework is assigned.",
      "{name} usually finishes homework on the day it is set.",
    ],
  },
  'hw_late_finishes': {
    'uz': [
      "{name} {freq} kechikadi, lekin vazifani baribir oxiriga yetkazadi.",
      "{name} {freq} muddatdan keyin topshiradi, ammo birorta vazifani tashlab ketmaydi.",
      "Muddat {name} uchun {freq} qiyin bo'ladi, lekin ish doim bajariladi.",
    ],
    'en': [
      "{name} is {freq} late, but always finishes the homework in the end.",
      "{name} {freq} hands in after the deadline, but never abandons an assignment.",
      "The deadline is {freq} hard for {name}, but the work always gets done.",
    ],
  },
  'hw_some_missing': {
    'uz': [
      "{name} {total} ta vazifadan {done} tasini bajargan; {missed} tasi hali ochiq.",
      "{name} ko'p vazifalarni bajaradi, faqat {missed} tasi hali bajarilmagan.",
      "{total} ta vazifadan {missed} tasi hali kutmoqda — qolganlarini {name} bajargan.",
    ],
    'en': [
      "{name} has done {done} of {total} assignments; {missed} still open.",
      "{name} does most homework — only {missed} not done yet.",
      "{missed} of {total} assignments are still waiting — {name} has done the rest.",
    ],
  },
  'hw_many_missing': {
    'uz': [
      "{name} {done} ta vazifani bajargan, {missed} tasi esa hali ochiq — yordam kerak bo'lishi mumkin.",
      "{name} uchun bir nechta vazifa ochiq qolgan; qisqa suhbat sababini bilishga yordam berishi mumkin.",
      "{total} ta vazifadan {missed} tasi hali bajarilmagan — {name} bilan gaplashib ko'rish foydali bo'lishi mumkin.",
    ],
    'en': [
      "{name} has done {done} assignments, but {missed} are still open — some help may be needed.",
      "Several assignments are still open for {name}; a short talk could help find out why.",
      "{missed} of {total} assignments are not done yet — a chat with {name} could help.",
    ],
  },
  'hw_none_done': {
    'uz': [
      "So'nggi {total} ta vazifa hali bajarilmagan — {name} bilan gaplashib ko'rish foydali bo'lishi mumkin.",
      "{name} so'nggi {total} ta vazifani hali tugatmagan; qisqa suhbat sababini bilishga yordam berishi mumkin.",
    ],
    'en': [
      "The last {total} assignments are not done yet — a chat with {name} could help.",
      "{name} hasn't finished the last {total} assignments yet; a short talk could help find out why.",
    ],
  },
  'hw_improving': {
    'uz': [
      "Oxirgi vazifalarda yaxshilanish bor.",
      "So'nggi vazifalarni avvalgidan ko'ra vaqtliroq bajaryapti.",
      "Oxirgi paytlarda vazifalar vaqtliroq topshirilyapti.",
    ],
    'en': [
      "Recent homework shows improvement.",
      "The latest assignments are being done more on time than before.",
      "Homework has been handed in more on time lately.",
    ],
  },
  'hw_slipping': {
    'uz': [
      "Oxirgi vazifalarda biroz orqaga ketish sezilyapti.",
      "So'nggi vazifalar avvalgilariga qaraganda kechroq bajarilyapti.",
    ],
    'en': [
      "Recent homework has slipped a little.",
      "The latest assignments are being done later than before.",
    ],
  },
  'hw_few_on_time': {
    'uz': [
      "{name} hozircha vazifalarni o'z vaqtida bajarib kelmoqda.",
      "Hozircha {name} vazifalarni vaqtida topshirgan.",
    ],
    'en': [
      "{name} has done homework on time so far.",
      "So far {name} has handed homework in on time.",
    ],
  },
  'hw_few_late': {
    'uz': [
      "{name} hozircha vazifalarni biroz kech, lekin bajargan.",
      "Hozircha vazifalar biroz kechikib, ammo bajarilgan.",
    ],
    'en': [
      "{name} has done homework so far, if a little late.",
      "So far homework has been a little late, but always done.",
    ],
  },
  'hw_few_open': {
    'uz': [
      "{name} uchun {missed} ta vazifa hali bajarilmagan.",
      "Hozircha {missed} ta vazifa hali ochiq.",
    ],
    'en': [
      "{missed} assignment(s) not done yet for {name}.",
      "So far {missed} assignment(s) are still open.",
    ],
  },
  'rem_quick': {
    'uz': [
      "Eslatmalarga tez javob beradi — odatda bir kun ichida mashq qiladi.",
      "Eslatmadan keyin {name} ko'pincha o'sha kuniyoq ishga kirishadi.",
      "{name} uchun eslatma yaxshi ishlaydi — javob tez keladi.",
    ],
    'en': [
      "Responds to reminders quickly — usually practises within a day.",
      "{name} often gets to work the same day after a reminder.",
      "Reminders work well for {name} — the response comes fast.",
    ],
  },
  'rem_slow': {
    'uz': [
      "{name} eslatmalarga biroz kech javob beradi, lekin keyin albatta mashq qiladi.",
      "{name} eslatmadan keyin darrov emas, lekin bir-ikki kun ichida qaytadi.",
      "Eslatmalar {name} uchun ta'sir qiladi — faqat javob uchun biroz vaqt kerak.",
    ],
    'en': [
      "{name} responds to reminders a little late, but then always practises.",
      "{name} comes back within a day or two after a reminder, not right away.",
      "Reminders do work for {name} — the response just takes a little time.",
    ],
  },
  'rem_mixed': {
    'uz': [
      "{name} ba'zan eslatmadan keyin mashq qiladi, ba'zan esa yo'q.",
      "Eslatmalar {name} uchun har doim ham ta'sir qilmaydi — ba'zan ishlaydi, ba'zan yo'q.",
    ],
    'en': [
      "{name} sometimes practises after a reminder, sometimes not.",
      "Reminders don't always work for {name} — sometimes they do, sometimes not.",
    ],
  },
  'rem_read_no_action': {
    'uz': [
      "{name} eslatmalarni o'qiydi, lekin ko'pincha mashqqa o'tmaydi — boshqacha yondashuv yordam berishi mumkin.",
      "Eslatmalar o'qilgan, ammo mashqqa olib kelmagan; jonli suhbat foydaliroq bo'lishi mumkin.",
    ],
    'en': [
      "{name} reads reminders, but often doesn't start practising — a different approach may help.",
      "Reminders were read but didn't lead to practice; talking in person may work better.",
    ],
  },
  'rem_unread': {
    'uz': [
      "{name} so'nggi eslatmalarni hali ochmagan — ular yetib bormayotgan bo'lishi mumkin.",
      "Eslatmalar o'qilmagan; darsda og'zaki eslatish samaraliroq bo'lishi mumkin.",
    ],
    'en': [
      "{name} hasn't opened the recent reminders — they may not be reaching them.",
      "Reminders haven't been read; mentioning it in class may work better.",
    ],
  },
  'rem_not_needed': {
    'uz': [
      "{name} eslatmasiz ham muntazam mashq qiladi.",
      "{name} uchun eslatma kerak emas — o'zi muntazam shug'ullanadi.",
    ],
    'en': [
      "{name} practises regularly without reminders.",
      "{name} doesn't need reminders — practises regularly on their own.",
    ],
  },
  'rem_single_responded': {
    'uz': [
      "{name} oxirgi eslatmadan keyin {hours} soat ichida mashq qildi.",
      "Oxirgi eslatmadan {hours} soat o'tib {name} mashqqa qaytdi.",
    ],
    'en': [
      "{name} practised within {hours} h of the last reminder.",
      "{name} came back to practise {hours} h after the last reminder.",
    ],
  },
  'rem_single_read': {
    'uz': [
      "{name} oxirgi eslatmani o'qidi, lekin hali mashq qilmadi.",
      "Oxirgi eslatma o'qilgan, ammo mashq hali bo'lmagan.",
    ],
    'en': [
      "{name} read the last reminder but hasn't practised yet.",
      "The last reminder was read, but no practice yet.",
    ],
  },
  'rem_single_unread': {
    'uz': [
      "{name} oxirgi eslatmani hali ochmagan.",
      "Oxirgi eslatma hali o'qilmagan.",
    ],
    'en': [
      "{name} hasn't opened the last reminder yet.",
      "The last reminder hasn't been read yet.",
    ],
  },
};
