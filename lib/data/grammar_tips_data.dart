import 'package:flutter/material.dart';

/// Port of lexivo-web/lib/grammar-tips.ts — the standalone Grammar Tips
/// reference (20 tips across Grammar / Vocabulary / Writing). Kept in sync
/// with the web copy by hand; there's little churn here.
class GrammarExample {
  final String en;
  final String? note;
  const GrammarExample(this.en, [this.note]);
}

class GrammarTip {
  final String id;
  final String title;
  final String category; // 'Grammar' | 'Vocabulary' | 'Writing'
  final String icon;
  final String explanation;
  final List<GrammarExample> examples;
  final String remember;

  const GrammarTip({
    required this.id,
    required this.title,
    required this.category,
    required this.icon,
    required this.explanation,
    required this.examples,
    required this.remember,
  });

  Color get categoryColor => grammarCategoryColor(category);
}

/// Matches web's ACCENT: Grammar→grammar (#10B981), Vocabulary→learn
/// (#6C63FF), Writing→quiz (#F59E0B).
Color grammarCategoryColor(String category) {
  switch (category) {
    case 'Vocabulary':
      return const Color(0xFF6C63FF);
    case 'Writing':
      return const Color(0xFFF59E0B);
    case 'Grammar':
    default:
      return const Color(0xFF10B981);
  }
}

const List<GrammarTip> grammarTips = [
  GrammarTip(
    id: 'collocations',
    title: 'Collocations',
    category: 'Vocabulary',
    icon: '🔗',
    explanation:
        'Collocations are words that naturally go together in English. Native speakers use specific combinations even when others seem logical. Learning collocations rather than individual words sounds more natural.',
    examples: [
      GrammarExample('make a decision ✓  /  do a decision ✗', 'make, not do'),
      GrammarExample('heavy rain ✓  /  strong rain ✗', 'heavy, not strong'),
      GrammarExample('take a photo ✓  /  do a photo ✗', 'take, not do'),
    ],
    remember:
        'When you learn a new word, always learn its most common collocations too.',
  ),
  GrammarTip(
    id: 'idioms',
    title: 'Idioms',
    category: 'Vocabulary',
    icon: '🎭',
    explanation:
        "Idioms are fixed phrases whose meaning can't be understood from the individual words. They are very common in spoken and informal English.",
    examples: [
      GrammarExample('"Break a leg!" — means "Good luck!"'),
      GrammarExample('"It\'s raining cats and dogs" — means it\'s raining heavily'),
      GrammarExample('"Hit the books" — means to study'),
    ],
    remember:
        'Never translate idioms word-by-word. Learn them as fixed units with their meaning.',
  ),
  GrammarTip(
    id: 'articles',
    title: 'Articles: a, an, the',
    category: 'Grammar',
    icon: '📌',
    explanation:
        'Use "a/an" for something mentioned for the first time or any one of many. Use "the" for something already known, specific, or unique. Use no article with plural/uncountable nouns in general statements.',
    examples: [
      GrammarExample('I saw a dog. The dog was barking.', 'first mention → a; known → the'),
      GrammarExample('The sun rises in the east.', 'unique things → the'),
      GrammarExample('Dogs are loyal animals.', 'general truth → no article'),
    ],
    remember:
        '"The" = we both know which one. "A/an" = any one, doesn\'t matter which.',
  ),
  GrammarTip(
    id: 'countable',
    title: 'Countable & Uncountable Nouns',
    category: 'Grammar',
    icon: '🔢',
    explanation:
        'Countable nouns have a singular and plural form. Uncountable nouns have no plural and cannot be used with "a/an". Many nouns can be both — with a meaning change.',
    examples: [
      GrammarExample('Much information ✓  /  Many informations ✗', 'information = uncountable'),
      GrammarExample("I'd like a coffee. (= a cup of coffee)", 'contextual countable'),
      GrammarExample('There are few opportunities here.', 'few = countable; little = uncountable'),
    ],
    remember: 'Use much/little with uncountable; many/few with countable.',
  ),
  GrammarTip(
    id: 'present-tenses',
    title: 'Present Simple vs Continuous',
    category: 'Grammar',
    icon: '⏱️',
    explanation:
        'Present Simple is for habits, facts, and routines. Present Continuous is for actions happening right now or temporary situations.',
    examples: [
      GrammarExample('She works at a hospital. (permanent job)', 'simple = permanent'),
      GrammarExample("She's working from home this week.", 'continuous = temporary'),
      GrammarExample('Water boils at 100°C.', 'simple = scientific fact'),
    ],
    remember:
        "State verbs (know, love, believe, own) don't use continuous form.",
  ),
  GrammarTip(
    id: 'past-tenses',
    title: 'Past Simple vs Past Perfect',
    category: 'Grammar',
    icon: '⏪',
    explanation:
        'Past Simple describes completed actions in the past. Past Perfect (had + past participle) describes an action completed before another past action.',
    examples: [
      GrammarExample('I arrived and then she left.', 'two sequential past actions'),
      GrammarExample('She had already left when I arrived.', 'she left first → past perfect'),
      GrammarExample('By 2010, they had built 50 schools.', 'completed before a point in the past'),
    ],
    remember:
        'Past Perfect = the "earlier" of two past events. Use "by the time", "already", "before".',
  ),
  GrammarTip(
    id: 'modal-verbs',
    title: 'Modal Verbs',
    category: 'Grammar',
    icon: '🎛️',
    explanation:
        'Modal verbs (can, could, should, must, might, may, would) add meaning like ability, possibility, obligation, or permission. They are followed by the base form of the verb.',
    examples: [
      GrammarExample('You must wear a seatbelt. (obligation)', 'must = strong obligation'),
      GrammarExample('You should eat more vegetables.', 'should = advice'),
      GrammarExample('It might rain tomorrow.', 'might = weak possibility'),
    ],
    remember:
        '"Must" = obligation from the speaker. "Have to" = obligation from rules/outside.',
  ),
  GrammarTip(
    id: 'passive',
    title: 'Passive Voice',
    category: 'Grammar',
    icon: '🔄',
    explanation:
        'The passive voice is formed with be + past participle. Use it when the action is more important than who does it, or when the agent is unknown.',
    examples: [
      GrammarExample('The report was written by the team.', 'active: The team wrote the report'),
      GrammarExample('Mistakes were made.', 'agent unknown/unimportant'),
      GrammarExample('The new law will be introduced next year.', 'future passive'),
    ],
    remember: 'Passive is common in formal, scientific, and news writing.',
  ),
  GrammarTip(
    id: 'conditionals',
    title: 'Conditionals',
    category: 'Grammar',
    icon: '🔀',
    explanation:
        'English has four main conditionals. Zero = always true. First = real/likely future. Second = unreal/hypothetical present. Third = impossible past.',
    examples: [
      GrammarExample('If you heat ice, it melts. (zero)', 'general truth'),
      GrammarExample("If it rains, I'll stay home. (first)", 'likely future'),
      GrammarExample("If I were rich, I'd travel. (second)", 'unreal present'),
    ],
    remember:
        'Second conditional: always "were" (not "was") in formal writing — "If I were you…"',
  ),
  GrammarTip(
    id: 'gerunds-infinitives',
    title: 'Gerunds vs Infinitives',
    category: 'Grammar',
    icon: '⚖️',
    explanation:
        'Some verbs are followed by gerund (-ing), some by infinitive (to + verb), and some by either with a meaning change.',
    examples: [
      GrammarExample('She enjoys swimming. (enjoy + gerund)', 'enjoy always takes gerund'),
      GrammarExample('He decided to leave. (decide + infinitive)', 'decide always takes infinitive'),
      GrammarExample('I stopped to rest. / I stopped resting.', 'stop changes meaning!'),
    ],
    remember:
        'Stop/remember/try/forget change meaning with gerund vs infinitive.',
  ),
  GrammarTip(
    id: 'relative-clauses',
    title: 'Relative Clauses',
    category: 'Grammar',
    icon: '🔍',
    explanation:
        'Defining relative clauses identify which person/thing you mean (no commas). Non-defining clauses add extra info about something already identified (use commas).',
    examples: [
      GrammarExample('The man who called was my uncle.', 'defining — tells us which man'),
      GrammarExample('My uncle, who lives in London, called.', 'non-defining — extra info'),
      GrammarExample('The book that I bought was excellent.', 'that = defining only'),
    ],
    remember:
        '"That" can only be used in defining clauses, never non-defining.',
  ),
  GrammarTip(
    id: 'word-formation',
    title: 'Word Formation',
    category: 'Vocabulary',
    icon: '🏗️',
    explanation:
        'English builds new words using prefixes (before the root) and suffixes (after the root). Knowing common affixes dramatically expands your vocabulary.',
    examples: [
      GrammarExample('un- + happy = unhappy (negative prefix)', 'un-, dis-, in-, im-, ir-'),
      GrammarExample('employ + -ment = employment (noun suffix)', '-ment, -tion, -ness, -ity'),
      GrammarExample('beauty + -ful = beautiful (adjective suffix)', '-ful, -less, -ous, -able'),
    ],
    remember:
        'Learn word families: employ → employee, employer, employment, unemployed.',
  ),
  GrammarTip(
    id: 'prepositions-time',
    title: 'Prepositions of Time',
    category: 'Grammar',
    icon: '🕐',
    explanation:
        'AT is for precise times and fixed expressions. ON is for days and dates. IN is for longer periods like months, years, and seasons.',
    examples: [
      GrammarExample('at 3pm · at midnight · at Christmas', 'at = precise point'),
      GrammarExample('on Monday · on 15 June · on my birthday', 'on = specific day/date'),
      GrammarExample('in July · in 2024 · in the morning', 'in = longer period'),
    ],
    remember:
        'No preposition before "last", "next", "this", "every": "I\'ll see you next Friday."',
  ),
  GrammarTip(
    id: 'prepositions-place',
    title: 'Prepositions of Place',
    category: 'Grammar',
    icon: '📍',
    explanation:
        'AT indicates a general location or point. IN indicates being inside/enclosed. ON indicates a surface or position.',
    examples: [
      GrammarExample('at the station · at school · at home', 'at = general point'),
      GrammarExample('in the car · in London · in my pocket', 'in = enclosed/inside'),
      GrammarExample('on the table · on the wall · on the bus', 'on = surface/transport'),
    ],
    remember: 'We say "in" a car/taxi but "on" a bus/train/plane.',
  ),
  GrammarTip(
    id: 'phrasal-verbs',
    title: 'Phrasal Verbs',
    category: 'Vocabulary',
    icon: '🔧',
    explanation:
        'Phrasal verbs combine a verb + particle(s) to create a new meaning. They are extremely common in informal English and often have surprising meanings.',
    examples: [
      GrammarExample('give up = quit/stop trying', 'not "give" + "up" literally'),
      GrammarExample('run into = meet unexpectedly', '"into" changes the meaning'),
      GrammarExample('look up to = admire', 'completely different from "look up"'),
    ],
    remember:
        'Some phrasal verbs are separable ("turn it off") and some are not ("run into him").',
  ),
  GrammarTip(
    id: 'adjective-order',
    title: 'Adjective Order',
    category: 'Grammar',
    icon: '📐',
    explanation:
        'When using multiple adjectives before a noun, English follows a strict order: Opinion → Size → Age → Shape → Color → Origin → Material → Purpose.',
    examples: [
      GrammarExample('a lovely little old rectangular green French silver whittling knife', 'all 8 categories'),
      GrammarExample('a beautiful young Italian woman ✓', 'opinion before origin'),
      GrammarExample('a wooden large table ✗  →  a large wooden table ✓', 'size before material'),
    ],
    remember:
        'In practice, 2-3 adjectives maximum. The order feels natural once you memorize it.',
  ),
  GrammarTip(
    id: 'reported-speech',
    title: 'Reported Speech',
    category: 'Grammar',
    icon: '💬',
    explanation:
        'When reporting what someone said, verbs shift back one tense (backshift). Present → Past, Past → Past Perfect. Time expressions also change.',
    examples: [
      GrammarExample('"I am tired." → She said she was tired.', 'am → was (backshift)'),
      GrammarExample('"I will call." → He said he would call.', 'will → would'),
      GrammarExample('"I\'ve finished." → She said she had finished.', 'present perfect → past perfect'),
    ],
    remember:
        'No backshift needed if reporting immediately after or if the fact is still true.',
  ),
  GrammarTip(
    id: 'quantifiers',
    title: 'Quantifiers',
    category: 'Grammar',
    icon: '🔢',
    explanation:
        'Quantifiers express amounts. Some work only with countable, some only with uncountable, and some with both.',
    examples: [
      GrammarExample('many students / much time', 'many=countable, much=uncountable'),
      GrammarExample('few friends (= not many) / a few friends (= some)', 'few vs a few'),
      GrammarExample('a lot of + both · some/any + both', 'neutral quantifiers'),
    ],
    remember:
        '"Few/little" = negative (not enough). "A few/a little" = positive (some, enough).',
  ),
  GrammarTip(
    id: 'comparatives',
    title: 'Comparatives & Superlatives',
    category: 'Grammar',
    icon: '📊',
    explanation:
        'Short adjectives add -er/-est. Long adjectives (2+ syllables) use more/most. Irregular forms must be memorized.',
    examples: [
      GrammarExample('fast → faster → fastest', 'one syllable: add -er/-est'),
      GrammarExample('expensive → more expensive → most expensive', 'long adjective: more/most'),
      GrammarExample('good → better → best · bad → worse → worst', 'irregular forms'),
    ],
    remember:
        'Double the final consonant: big → bigger, hot → hotter, thin → thinner.',
  ),
  GrammarTip(
    id: 'cohesive-devices',
    title: 'Cohesive Devices',
    category: 'Writing',
    icon: '🔗',
    explanation:
        'Linking words connect ideas and make your writing flow. They show relationship: addition, contrast, cause/effect, sequence, or concession.',
    examples: [
      GrammarExample('Furthermore / Moreover / In addition — adding ideas', 'addition'),
      GrammarExample('However / Nevertheless / Although — contrast', 'contrast'),
      GrammarExample('Therefore / As a result / Consequently — cause/effect', 'result'),
    ],
    remember:
        'Don\'t overuse "and", "but", "so". Replace with formal connectors in academic writing.',
  ),
];

final List<String> grammarTipCategories =
    grammarTips.map((t) => t.category).toSet().toList();
