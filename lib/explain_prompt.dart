// "Explain with AI" — the prompt a student copies from a Learn card and pastes
// into any AI chat to get a spoken-style explanation: action → feeling → what
// the person does next. Uzbek-UI users get the Uzbek version, everyone else the
// English one. Same text as lexivo-web lib/explain-prompt.ts — keep in sync.

const _enPrompt = r'''Explain the English phrase/word: "{WORD}"{MEANING}

Write in a natural, conversational style (like you're talking to a student). Use simple B1-level English, so the explanation is easier than the phrase itself.

Start with a simple definition.

Then explain the real feeling or effect it creates.

After that, give several concrete, everyday situations. Use phrases like "Just imagine…", "Take this example…", "Picture this…". In every situation:
- clearly show the action
- show how the person feels
- show what they usually do next or how it changes their behavior

Make the examples feel real and personal (phone, work, friends, travel, online, relationships, etc.).

At the end, add 2–3 more short real-life examples that reinforce the meaning.

Do not use numbered lists or formal structure. Write in flowing paragraphs so it feels like a spoken explanation.

———

Here's an example of the exact style I want (for the phrase "come to grips with"):

To come to grips with something means to face and start dealing with a difficult problem, reality, or emotion. It's about moving from denial or avoidance to acceptance and action. You stop running away from the issue and begin handling it, even if it's uncomfortable or painful.

You were upset with your friend, but it's been a while and you're not feeling the way you felt before. Your friend lied to you and you broke up with them, and after a while you recognize that it was actually okay to do so — which means you have come to grips with your friend's lie.

Or you are afraid of speaking publicly, then you watch people talk in public just the way they talk to you and you think "it's not a big deal" — that means you have come to grips with public speaking.

You came to grips with the fact that your job wasn't fulfilling. You started applying for new positions and eventually changed careers. She finally came to grips with living alone after her roommate moved out, and started cooking proper dinners for herself instead of ordering takeout.''';

const _uzPrompt = r'''Explain the English phrase/word: "{WORD}"{MEANING}

Write the entire explanation in natural, conversational Uzbek (as if you're talking to a student).

Start with a simple definition in Uzbek.

Then explain the real feeling or effect it creates.

After that, give several concrete, everyday situations. Use natural Uzbek phrases like "Tasavvur qiling…", "Masalan…", "Ko'z oldingizga keltiring…". In every situation:
- clearly show the action
- show how the person feels
- show what they usually do next or how it changes their behavior
- end it with one short, simple English sentence (B1 level) that uses the phrase the way a native speaker would, starting with "Inglizcha:"

Make the examples feel real and personal (phone, work, friends, travel, online, relationships, etc.).

At the end, add 2–3 more short real-life examples that reinforce the meaning.

Do not use numbered lists or formal structure. Write in flowing paragraphs so it feels like a spoken explanation.

———

Here's an example of the exact style I want (for the phrase "come to grips with"):

"Come to grips with" degani qiyin muammo, haqiqat yoki his-tuyg‘uni yuzma-yuz ko‘rib, uni qabul qilib, yechishni boshlash demakdir. Bu inkor qilish yoki qochishdan voz kechib, qabul qilish va harakatga o‘tishni anglatadi. Siz muammodan qochishni to‘xtatib, hatto noqulay yoki og‘riqli bo‘lsa ham, uni hal qilishni boshlaysiz.

Tasavvur qiling, siz do‘stingizga xafa bo‘lgandingiz, lekin biroz vaqt o‘tdi va endi avvalgidek his qilmayapsiz. Do‘stingiz yolg‘on gapirgan edi, siz undan ayrildingiz, keyin esa "aslida shunday qilish to‘g‘ri ekan" deb tushundingiz — bu siz do‘stingizning yolg‘onini "come to grips with" qilganingizni bildiradi. Inglizcha: "I've finally come to grips with my friend's lie."

Yoki siz omma oldida gapirishdan qo‘rqasiz, keyin odamlarning oddiy suhbatlashgandek gapirayotganini ko‘rasiz va "aslida unchalik katta narsa emas ekan" deb o‘ylaysiz — bu siz omma oldida gapirish qo‘rquvingizni "come to grips with" qilganingizni anglatadi. Inglizcha: "I've come to grips with my fear of public speaking."

Siz ishingiz sizni qoniqtirmasligini "come to grips with" qildingiz. Yangi ishlarga ariza topshirishni boshladingiz va oxir-oqibat kasbingizni o‘zgartirdingiz. Inglizcha: "I came to grips with the fact that my job wasn't fulfilling."''';

String buildExplainPrompt(String word, String definition, String lang) {
  final meaning = definition.trim().isNotEmpty ? '\nIn this meaning: ${definition.trim()}' : '';
  return (lang == 'uz' ? _uzPrompt : _enPrompt)
      .replaceFirst('{WORD}', word)
      .replaceFirst('{MEANING}', meaning);
}
