// GENERATED from lexivo-web/lib/student-summary-sentences.ts by
// lexivo-web/scripts/student-summary-to-dart.js — do not edit by hand.

const summaryWords = <String, Map<String, String>>{
  'uz': {
    'today': "Bugun",
    'yesterday': "Kecha",
    'onDate': "{d} kuni",
    'sinceToday': "bugun",
    'sinceYesterday': "kecha",
    'sinceDays': "{n} kun oldin",
    'and': "va",
    'andMore': "{a}, {b} va yana {n} ta",
    'daysLate': "{n} kun kech",
    'daysLate1': "1 kun kech",
    'aLittleLate': "biroz kech",
    'daysEarly': "{n} kun oldin",
    'daysEarly1': "1 kun oldin",
    'rarely': "kamdan-kam",
    'sometimes': "ba'zan",
    'often': "ko'pincha",
    'learn': "O'rganish",
    'flashcard': "Kartochkalar",
    'quiz': "Test",
    'match': "Moslashtirish",
    'read': "O'qish",
  },
  'en': {
    'today': "Today",
    'yesterday': "Yesterday",
    'onDate': "On {d}",
    'sinceToday': "today",
    'sinceYesterday': "yesterday",
    'sinceDays': "{n} days ago",
    'and': "and",
    'andMore': "{a}, {b} and {n} more",
    'daysLate': "{n} days late",
    'daysLate1': "1 day late",
    'aLittleLate': "a little late",
    'daysEarly': "{n} days",
    'daysEarly1': "1 day",
    'rarely': "rarely",
    'sometimes': "sometimes",
    'often': "often",
    'learn': "Learn",
    'flashcard': "Cards",
    'quiz': "Quiz",
    'match': "Match",
    'read': "Reading",
  },
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
  'ctx_joined_today_active': {
    'uz': [
      "{name} sinfga bugun qo'shildi va [[allaqachon mashq qildi|days]].",
      "{name} bugun sinfga keldi va [[birinchi kuniyoq ishga kirishdi|days]].",
      "Sinfga bugun qo'shilgan {name} [[darhol mashq boshladi|days]].",
    ],
    'en': [
      "{name} joined the class today and [[has already practised|days]].",
      "{name} came to the class today and [[got to work on day one|days]].",
      "Having joined today, {name} [[started practising right away|days]].",
    ],
  },
  'ctx_joined_today': {
    'uz': [
      "{name} sinfga bugun qo'shildi.",
      "{name} bugun sinfga keldi.",
    ],
    'en': [
      "{name} joined the class today.",
      "{name} came to the class today.",
    ],
  },
  'ctx_new_all_active': {
    'uz': [
      "{name} sinfga {since} qo'shilgan va [[har kuni faol bo'ldi|days]].",
      "{since} qo'shilganidan beri {name} [[bir kun ham qoldirmay mashq qildi|days]].",
      "{name} sinfga {since} kelgan va o'shandan beri [[har kuni shug'ullanmoqda|days]].",
      "Sinfga {since} qo'shilgan {name} [[har kuni faol|days]] bo'lib kelmoqda.",
    ],
    'en': [
      "{name} joined the class {since} and [[has been active every day|days]].",
      "Since joining {since}, {name} [[has practised every single day|days]].",
      "{name} came to the class {since} and [[has studied every day since|days]].",
      "Having joined {since}, {name} [[has been active daily|days]].",
    ],
  },
  'ctx_new_some_active': {
    'uz': [
      "{name} sinfga {since} qo'shilgan; o'shandan beri [[{days} kundan {active} kunida faol bo'ldi|days]].",
      "{since} qo'shilganidan beri {name} [[{active} kun mashq qildi|days]].",
      "{name} sinfga {since} kelgan va [[{days} kundan {active} kunida|days]] shug'ullangan.",
    ],
    'en': [
      "{name} joined the class {since} and [[has been active on {active} of {days} days|days]].",
      "Since joining {since}, {name} [[has practised on {active} days|days]].",
      "{name} came to the class {since} and [[studied on {active} of {days} days|days]].",
    ],
  },
  'ctx_new_inactive': {
    'uz': [
      "{name} sinfga {since} qo'shilgan, lekin hali mashq qilmagan.",
      "{name} {since} sinfga kelgan; birinchi mashq hali oldinda.",
    ],
    'en': [
      "{name} joined the class {since} but hasn't practised yet.",
      "{name} came to the class {since}; the first practice is still ahead.",
    ],
  },
  'ctx_week_high': {
    'uz': [
      "So'nggi 7 kunda {name} [[{active} kun faol bo'ldi|days]] — juda muntazam.",
      "{name} bu hafta [[deyarli har kuni mashq qildi|days]].",
      "{name} so'nggi bir haftada [[{active} kun shug'ullandi|days]].",
      "{name} muntazam ishlaydi: [[so'nggi 7 kunning {active} kunida|days]] faol bo'ldi.",
    ],
    'en': [
      "In the last 7 days {name} [[was active on {active} days|days]] — very steady.",
      "{name} [[practised almost every day|days]] this week.",
      "{name} [[studied on {active} days|days]] over the last week.",
      "{name} works regularly: [[active on {active} of the last 7 days|days]].",
    ],
  },
  'ctx_week_mid': {
    'uz': [
      "{name} so'nggi 7 kunda [[{active} kun faol bo'ldi|days]].",
      "Bu hafta {name} [[{active} kun mashq qildi|days]].",
      "{name} so'nggi bir haftada [[{active} kun shug'ullandi|days]].",
    ],
    'en': [
      "{name} [[was active on {active} days|days]] in the last 7 days.",
      "This week {name} [[practised on {active} days|days]].",
      "{name} [[studied on {active} days|days]] over the last week.",
    ],
  },
  'ctx_week_low': {
    'uz': [
      "{name} so'nggi 7 kunda [[{active} kun mashq qildi|days]].",
      "Bu hafta {name} [[{active} kun faol bo'ldi|days]] — odatdagidan kamroq bo'lishi mumkin.",
      "{name} so'nggi bir haftada [[faqat {active} kun|days]] shug'ullandi.",
    ],
    'en': [
      "{name} [[practised on {active} day(s)|days]] in the last 7 days.",
      "This week {name} [[was active on {active} day(s)|days]] — possibly less than usual.",
      "{name} [[studied on only {active} day(s)|days]] over the last week.",
    ],
  },
  'ctx_week_none': {
    'uz': [
      "{name} so'nggi 7 kunda mashq qilmagan; oxirgi marta [[{last}|days]] faol bo'lgan.",
      "Oxirgi mashq [[{last}|days]] bo'lgan — o'shandan beri {name} faol emas.",
    ],
    'en': [
      "{name} hasn't practised in the last 7 days; last active [[{last}|days]].",
      "The last practice was [[{last}|days]] — {name} has not been active since.",
    ],
  },
  'ctx_never': {
    'uz': [
      "{name} hali birorta ham mashq qilmagan.",
      "{name} hali mashq boshlamagan.",
    ],
    'en': [
      "{name} hasn't practised yet.",
      "{name} hasn't started practising yet.",
    ],
  },
  'act_review_cleared': {
    'uz': [
      "{when} [[{n} ta so'zni takrorlab|review]], kutayotgan ro'yxatni to'liq bo'shatdi.",
      "{when} {name} [[{n} ta so'zni takrorladi|review]] — ro'yxatda kutayotgan so'z qolmadi.",
      "{when} takrorlash ro'yxati to'liq yakunlandi: [[{n} ta so'z|review]].",
      "{when} [[{n} ta so'z|review]] takrorlandi va ro'yxat bo'shadi.",
    ],
    'en': [
      "{when} {name} [[reviewed {n} words|review]] and cleared the whole waiting list.",
      "{when} {name} [[reviewed {n} words|review]] — no words are left waiting.",
      "{when} the review list was finished: [[{n} words|review]].",
      "{when} [[{n} words|review]] were reviewed and the list is empty.",
    ],
  },
  'act_review_hw': {
    'uz': [
      "{when} [[{n} ta so'zni takrorladi|review]] va [[{hw}|homework]] vazifasini tugatdi.",
      "{when} {name} [[{n} ta so'z takrorladi|review]], shuningdek [[{hw}|homework]] vazifasini yakunladi.",
      "{when} takrorlashga ham, vazifaga ham vaqt ajratdi: [[{n} ta so'z|review]] va [[{hw}|homework]].",
    ],
    'en': [
      "{when} {name} [[reviewed {n} words|review]] and finished [[{hw}|homework]].",
      "{when} {name} [[reviewed {n} words|review]] and also completed [[{hw}|homework]].",
      "{when} there was time for both: [[{n} words reviewed|review]] and [[{hw}|homework]] finished.",
    ],
  },
  'act_review': {
    'uz': [
      "{when} [[{n} ta so'zni takrorladi|review]].",
      "{when} {name} [[{n} ta so'z|review]] bilan takrorlash qildi.",
      "{when} takrorlashda [[{n} ta so'z|review]] ko'rib chiqildi.",
    ],
    'en': [
      "{when} {name} [[reviewed {n} words|review]].",
      "{when} {name} did a review of [[{n} words|review]].",
      "{when} [[{n} words|review]] were reviewed.",
    ],
  },
  'act_hw': {
    'uz': [
      "{when} [[{hw}|homework]] vazifasini to'liq tugatdi.",
      "{when} {name} [[{hw}|homework]] vazifasini yakunladi.",
      "{when} [[{hw}|homework]] bajarildi — barcha mashqlari bilan.",
    ],
    'en': [
      "{when} {name} fully finished [[{hw}|homework]].",
      "{when} {name} completed [[{hw}|homework]].",
      "{when} [[{hw}|homework]] was done — every activity in it.",
    ],
  },
  'act_hw_partial': {
    'uz': [
      "{when} [[{hw}|homework]] ustida ishladi; [[{left} hali qolgan|timing]].",
      "{when} {name} [[{hw}|homework]] vazifasining bir qismini bajardi — [[{left} qoldi|timing]].",
    ],
    'en': [
      "{when} {name} worked on [[{hw}|homework]]; [[{left} still left|timing]].",
      "{when} {name} did part of [[{hw}|homework]] — [[{left} left|timing]].",
    ],
  },
  'act_other': {
    'uz': [
      "{when} [[sinf mashqlarini bajardi|days]].",
      "{when} {name} [[sinfda shug'ullandi|days]].",
    ],
    'en': [
      "{when} {name} [[did class practice|days]].",
      "{when} {name} [[studied in the class|days]].",
    ],
  },
  'rev_waiting': {
    'uz': [
      "{n} ta so'z takrorlashni kutmoqda.",
      "Takrorlash ro'yxatida {n} ta so'z bor.",
      "Hozir {n} ta so'z takrorlashga tayyor.",
    ],
    'en': [
      "{n} words are waiting for review.",
      "There are {n} words on the review list.",
      "{n} words are ready to review now.",
    ],
  },
  'rev_overdue': {
    'uz': [
      "{n} ta so'z kutmoqda, ulardan {m} tasi muddati o'tgan.",
      "Takrorlash ro'yxatida {n} ta so'z bor; {m} tasi kechikkan.",
      "{m} ta so'zning takrorlash vaqti o'tgan — jami {n} ta so'z kutmoqda.",
    ],
    'en': [
      "{n} words are waiting, {m} of them overdue.",
      "There are {n} words on the review list; {m} are overdue.",
      "{m} words are past their review time — {n} waiting in total.",
    ],
  },
  'rev_stopped': {
    'uz': [
      "Oxirgi takrorlash [[{days} kun oldin|review]] bo'lgan; hozir {n} ta so'z kutmoqda.",
      "{name} [[{days} kundan beri|review]] takrorlamadi — {n} ta so'z kutmoqda.",
      "Takrorlashda [[{days} kunlik tanaffus|review]] bor; ro'yxatda {n} ta so'z.",
    ],
    'en': [
      "The last review was [[{days} days ago|review]]; {n} words are waiting now.",
      "{name} [[hasn't reviewed for {days} days|review]] — {n} words are waiting.",
      "There is a [[{days}-day break|review]] in reviewing; {n} words on the list.",
    ],
  },
  'rev_never': {
    'uz': [
      "{name} hali takrorlashni boshlamagan; {n} ta so'z kutmoqda.",
      "Takrorlash hali boshlanmagan — ro'yxatda {n} ta so'z bor.",
    ],
    'en': [
      "{name} hasn't started reviewing yet; {n} words are waiting.",
      "Reviewing hasn't started yet — {n} words on the list.",
    ],
  },
  'hw_few_early': {
    'uz': [
      "{name} [[{hw}|homework]] vazifasini [[muddatidan {early}|timing]] tugatdi.",
      "[[{hw}|homework]] [[muddatidan {early}|timing]] bajarildi.",
      "{name} [[{hw}|homework]] vazifasiga erta kirishdi va [[muddatidan {early}|timing]] tugatdi.",
    ],
    'en': [
      "{name} finished [[{hw}|homework]] [[{early} before the deadline|timing]].",
      "[[{hw}|homework]] was done [[{early} ahead of time|timing]].",
      "{name} started [[{hw}|homework]] early and finished it [[{early} before the deadline|timing]].",
    ],
  },
  'hw_few_on_time': {
    'uz': [
      "[[{hw}|homework]] [[o'z vaqtida|timing]] bajarildi.",
      "{name} [[{hw}|homework]] vazifasini [[muddatida|timing]] topshirdi.",
      "[[{hw}|homework]] — [[vaqtida bajarilgan|timing]].",
    ],
    'en': [
      "[[{hw}|homework]] was done [[on time|timing]].",
      "{name} handed in [[{hw}|homework]] [[by the deadline|timing]].",
      "[[{hw}|homework]] — [[done on time|timing]].",
    ],
  },
  'hw_few_late': {
    'uz': [
      "[[{hw}|homework]] [[{late}|timing]], lekin to'liq bajarildi.",
      "{name} [[{hw}|homework]] vazifasini [[{late}|timing]] bo'lsa ham, oxirigacha bajardi.",
      "[[{hw}|homework]] muddatdan [[{late}|timing]] topshirildi, ammo to'liq.",
      "{name} [[{hw}|homework]] vazifasini tashlab ketmadi — [[{late}|timing]], lekin tugatdi.",
    ],
    'en': [
      "[[{hw}|homework]] was done [[{late}|timing]], but in full.",
      "{name} finished [[{hw}|homework]] all the way, even if [[{late}|timing]].",
      "[[{hw}|homework]] came in [[{late}|timing]], but complete.",
      "{name} didn't drop [[{hw}|homework]] — [[{late}|timing]], but finished.",
    ],
  },
  'hw_few_open': {
    'uz': [
      "[[{hw}|homework]] hali [[bajarilmagan|timing]] — {left} qolgan.",
      "[[{hw}|homework]] vazifasida [[{left} hali qolgan|timing]].",
      "{name} uchun [[{hw}|homework]] hali [[ochiq|timing]]: {left} qolgan.",
    ],
    'en': [
      "[[{hw}|homework]] is [[not done yet|timing]] — {left} left.",
      "[[{hw}|homework]] still has [[{left} left|timing]].",
      "[[{hw}|homework]] is still [[open|timing]] for {name}: {left} left.",
    ],
  },
  'hw_few_open_many': {
    'uz': [
      "[[{hw}|homework]] hali [[bajarilmagan|timing]].",
      "{name} uchun [[{hw}|homework]] hali [[ochiq|timing]].",
    ],
    'en': [
      "[[{hw}|homework]] are [[not done yet|timing]].",
      "[[{hw}|homework]] are still [[open|timing]] for {name}.",
    ],
  },
  'hw_few_mixed': {
    'uz': [
      "[[{hw}|homework]] vazifalaridan biri bajarilgan, biri [[hali ochiq|timing]].",
      "{name} [[{hw}|homework]] vazifalarining birini tugatgan; [[ikkinchisi kutmoqda|timing]].",
    ],
    'en': [
      "Of [[{hw}|homework]], one is done and one is [[still open|timing]].",
      "{name} has finished one of [[{hw}|homework]]; [[the other is waiting|timing]].",
    ],
  },
  'hw_early': {
    'uz': [
      "{name} [[vazifalarni|homework]] [[odatda muddatidan oldin|timing]] bajaradi.",
      "{name} [[vazifalarga|homework]] erta kirishadi — [[muddatni kutib o'tirmaydi|timing]].",
      "{name} [[uy vazifalarini|homework]] [[ko'pincha vaqtidan ancha oldin|timing]] tugatadi.",
      "[[Vazifalar|homework]] {name} uchun [[oxirgi kunga qolmaydi|timing]] — odatda oldinroq bajariladi.",
    ],
    'en': [
      "{name} usually finishes [[homework|homework]] [[before the deadline|timing]].",
      "{name} starts [[homework|homework]] early and [[doesn't wait for the deadline|timing]].",
      "{name} often finishes [[homework|homework]] [[well ahead of time|timing]].",
      "[[Homework|homework]] [[rarely waits until the last day|timing]] for {name}.",
    ],
  },
  'hw_last_day': {
    'uz': [
      "{name} [[vazifalarni|homework]] [[ko'pincha oxirgi kuni|timing]] bajaradi, lekin hech birini qoldirmaydi.",
      "{name} odatda [[muddatga yaqin|timing]] ishlaydi — baribir [[hammasini|homework]] vaqtida topshiradi.",
      "[[Vazifalar|homework]] [[ko'pincha oxirgi kunga qoladi|timing]], ammo {name} ularni doim tugatadi.",
      "{name} [[oxirgi kunni afzal ko'radi|timing]], lekin [[muddatni|homework]] o'tkazib yubormaydi.",
    ],
    'en': [
      "{name} [[often does homework on the last day|timing]], but never skips [[one|homework]].",
      "{name} usually works [[close to the deadline|timing]], but still hands [[everything|homework]] in on time.",
      "[[Homework|homework]] [[often waits until the last day|timing]], but {name} always finishes it.",
      "{name} [[prefers the last day|timing]], but doesn't miss [[a deadline|homework]].",
    ],
  },
  'hw_on_time': {
    'uz': [
      "{name} [[barcha vazifalarni|homework]] [[o'z vaqtida|timing]] bajargan.",
      "{name} [[hech bir muddatni|timing]] o'tkazib yubormagan.",
      "{name} [[so'nggi {total} ta vazifaning|homework]] [[hammasini vaqtida|timing]] topshirgan.",
    ],
    'en': [
      "{name} has done [[every homework|homework]] [[on time|timing]].",
      "{name} [[hasn't missed a single deadline|timing]].",
      "{name} handed in [[all of the last {total} assignments|homework]] [[on time|timing]].",
    ],
  },
  'hw_same_day': {
    'uz': [
      "{name} [[vazifani|homework]] [[ko'pincha berilgan kuniyoq|timing]] bajaradi.",
      "{name} [[vazifa|homework]] berilishi bilan [[darrov ishga kirishadi|timing]].",
      "[[Vazifa|homework]] berilgan kuni {name} [[odatda uni tugatib qo'yadi|timing]].",
    ],
    'en': [
      "{name} [[often does homework|homework]] [[on the day it is assigned|timing]].",
      "{name} [[gets to work right away|timing]] when [[homework|homework]] is assigned.",
      "{name} [[usually finishes|timing]] [[homework|homework]] on the day it is set.",
    ],
  },
  'hw_late_finishes': {
    'uz': [
      "{name} [[{freq} kechikadi|timing]], lekin [[vazifani|homework]] baribir oxiriga yetkazadi.",
      "{name} [[{freq} muddatdan keyin topshiradi|timing]], ammo [[birorta vazifani|homework]] tashlab ketmaydi.",
      "Muddat {name} uchun [[{freq} qiyin bo'ladi|timing]], lekin [[ish|homework]] doim bajariladi.",
    ],
    'en': [
      "{name} is [[{freq} late|timing]], but always finishes [[the homework|homework]] in the end.",
      "{name} [[{freq} hands in after the deadline|timing]], but never abandons [[an assignment|homework]].",
      "The deadline is [[{freq} hard|timing]] for {name}, but [[the work|homework]] always gets done.",
    ],
  },
  'hw_some_missing': {
    'uz': [
      "{name} [[{total} ta vazifadan|homework]] {done} tasini bajargan; [[{missed} tasi hali ochiq|timing]].",
      "{name} ko'p vazifalarni bajaradi, faqat [[{missed} tasi hali bajarilmagan|timing]].",
      "[[{total} ta vazifadan|homework]] [[{missed} tasi hali kutmoqda|timing]] — qolganlarini {name} bajargan.",
    ],
    'en': [
      "{name} has done {done} of [[{total} assignments|homework]]; [[{missed} still open|timing]].",
      "{name} does most homework — only [[{missed} not done yet|timing]].",
      "[[{missed} of {total} assignments|timing]] are still waiting — {name} has done [[the rest|homework]].",
    ],
  },
  'hw_many_missing': {
    'uz': [
      "{name} {done} ta vazifani bajargan, [[{missed} tasi esa hali ochiq|timing]] — yordam kerak bo'lishi mumkin.",
      "{name} uchun [[bir nechta vazifa ochiq qolgan|timing]]; qisqa suhbat sababini bilishga yordam berishi mumkin.",
      "[[{total} ta vazifadan|homework]] [[{missed} tasi hali bajarilmagan|timing]] — {name} bilan gaplashib ko'rish foydali bo'lishi mumkin.",
    ],
    'en': [
      "{name} has done {done} assignments, but [[{missed} are still open|timing]] — some help may be needed.",
      "[[Several assignments are still open|timing]] for {name}; a short talk could help find out why.",
      "[[{missed} of {total} assignments|timing]] are not done yet — a chat with {name} could help.",
    ],
  },
  'hw_none_done': {
    'uz': [
      "[[So'nggi {total} ta vazifa|timing]] hali bajarilmagan — {name} bilan gaplashib ko'rish foydali bo'lishi mumkin.",
      "{name} [[so'nggi {total} ta vazifani|timing]] hali tugatmagan; qisqa suhbat sababini bilishga yordam berishi mumkin.",
    ],
    'en': [
      "[[The last {total} assignments|timing]] are not done yet — a chat with {name} could help.",
      "{name} hasn't finished [[the last {total} assignments|timing]] yet; a short talk could help find out why.",
    ],
  },
  'hw_improving': {
    'uz': [
      "[[Oxirgi vazifalarda|timing]] yaxshilanish bor.",
      "[[So'nggi vazifalarni|timing]] avvalgidan ko'ra vaqtliroq bajaryapti.",
      "Oxirgi paytlarda [[vazifalar vaqtliroq topshirilyapti|timing]].",
    ],
    'en': [
      "[[Recent homework|timing]] shows improvement.",
      "[[The latest assignments|timing]] are being done more on time than before.",
      "[[Homework has been handed in more on time|timing]] lately.",
    ],
  },
  'hw_slipping': {
    'uz': [
      "[[Oxirgi vazifalarda|timing]] biroz orqaga ketish sezilyapti.",
      "[[So'nggi vazifalar|timing]] avvalgilariga qaraganda kechroq bajarilyapti.",
    ],
    'en': [
      "[[Recent homework|timing]] has slipped a little.",
      "[[The latest assignments|timing]] are being done later than before.",
    ],
  },
  'rem_quick': {
    'uz': [
      "{name} [[eslatmalarga tez javob beradi|reminders]] — odatda bir kun ichida mashq qiladi.",
      "[[Eslatmadan keyin|reminders]] {name} ko'pincha o'sha kuniyoq ishga kirishadi.",
      "{name} uchun [[eslatma yaxshi ishlaydi|reminders]] — javob tez keladi.",
    ],
    'en': [
      "{name} [[responds to reminders quickly|reminders]] — usually practises within a day.",
      "[[After a reminder|reminders]] {name} often gets to work the same day.",
      "[[Reminders work well|reminders]] for {name} — the response comes fast.",
    ],
  },
  'rem_slow': {
    'uz': [
      "{name} [[eslatmalarga biroz kech javob beradi|reminders]], lekin keyin albatta mashq qiladi.",
      "{name} [[eslatmadan keyin|reminders]] darrov emas, lekin bir-ikki kun ichida qaytadi.",
      "[[Eslatmalar|reminders]] {name} uchun ta'sir qiladi — faqat javob uchun biroz vaqt kerak.",
    ],
    'en': [
      "{name} [[responds to reminders a little late|reminders]], but then always practises.",
      "{name} comes back within a day or two [[after a reminder|reminders]], not right away.",
      "[[Reminders|reminders]] do work for {name} — the response just takes a little time.",
    ],
  },
  'rem_mixed': {
    'uz': [
      "{name} [[ba'zan eslatmadan keyin mashq qiladi|reminders]], ba'zan esa yo'q.",
      "[[Eslatmalar|reminders]] {name} uchun har doim ham ta'sir qilmaydi — ba'zan ishlaydi, ba'zan yo'q.",
    ],
    'en': [
      "{name} [[sometimes practises after a reminder|reminders]], sometimes not.",
      "[[Reminders|reminders]] don't always work for {name} — sometimes they do, sometimes not.",
    ],
  },
  'rem_read_no_action': {
    'uz': [
      "{name} [[eslatmalarni o'qiydi|reminders]], lekin ko'pincha mashqqa o'tmaydi — boshqacha yondashuv yordam berishi mumkin.",
      "[[Eslatmalar o'qilgan|reminders]], ammo mashqqa olib kelmagan; jonli suhbat foydaliroq bo'lishi mumkin.",
    ],
    'en': [
      "{name} [[reads reminders|reminders]], but often doesn't start practising — a different approach may help.",
      "[[Reminders were read|reminders]] but didn't lead to practice; talking in person may work better.",
    ],
  },
  'rem_unread': {
    'uz': [
      "{name} [[so'nggi eslatmalarni hali ochmagan|reminders]] — ular yetib bormayotgan bo'lishi mumkin.",
      "[[Eslatmalar o'qilmagan|reminders]]; darsda og'zaki eslatish samaraliroq bo'lishi mumkin.",
    ],
    'en': [
      "{name} [[hasn't opened the recent reminders|reminders]] — they may not be reaching them.",
      "[[Reminders haven't been read|reminders]]; mentioning it in class may work better.",
    ],
  },
  'rem_not_needed': {
    'uz': [
      "{name} eslatmasiz ham [[muntazam mashq qiladi|days]].",
      "{name} uchun eslatma kerak emas — [[o'zi muntazam shug'ullanadi|days]].",
    ],
    'en': [
      "{name} [[practises regularly|days]] without reminders.",
      "{name} doesn't need reminders — [[practises regularly on their own|days]].",
    ],
  },
  'rem_single_responded': {
    'uz': [
      "{name} [[oxirgi eslatmadan|reminders]] keyin {hours} soat ichida mashq qildi.",
      "[[Oxirgi eslatmadan|reminders]] {hours} soat o'tib {name} mashqqa qaytdi.",
    ],
    'en': [
      "{name} practised within {hours} h of [[the last reminder|reminders]].",
      "{name} came back to practise {hours} h after [[the last reminder|reminders]].",
    ],
  },
  'rem_single_read': {
    'uz': [
      "{name} [[oxirgi eslatmani o'qidi|reminders]], lekin hali mashq qilmadi.",
      "[[Oxirgi eslatma o'qilgan|reminders]], ammo mashq hali bo'lmagan.",
    ],
    'en': [
      "{name} [[read the last reminder|reminders]] but hasn't practised yet.",
      "[[The last reminder was read|reminders]], but no practice yet.",
    ],
  },
  'rem_single_unread': {
    'uz': [
      "{name} [[oxirgi eslatmani hali ochmagan|reminders]].",
      "[[Oxirgi eslatma|reminders]] hali o'qilmagan.",
    ],
    'en': [
      "{name} [[hasn't opened the last reminder|reminders]] yet.",
      "[[The last reminder|reminders]] hasn't been read yet.",
    ],
  },
};
