class ReadingQuestion {
  final String question;
  final String explanation;

  const ReadingQuestion({
    required this.question,
    required this.explanation,
  });
}

class ReadingPassage {
  final int id;
  final String title;
  final String topic;
  final String content;
  final List<ReadingQuestion> questions;

  const ReadingPassage({
    required this.id,
    required this.title,
    required this.topic,
    required this.content,
    required this.questions,
  });
}

final List<ReadingPassage> readingPassages = [

  ReadingPassage(
    id: 1,
    title: 'Childhood',
    topic: 'Society & Development',
    content: '''Childhood is the early stage of human life that spans from birth to adolescence. It is a critical period of physical, emotional, cognitive, and social development that lays the foundation for an individual's future well-being and success. Although every child's experience is unique, childhood is universally recognized as a time of learning, growth, and discovery.

From a biological perspective, childhood is marked by rapid growth and development. Infants learn to crawl, walk, and speak, while toddlers begin to explore the world around them through play and interaction. By the time children reach school age, they acquire basic academic skills, emotional regulation, and social behaviors. The quality of care and stimulation received during these years significantly influences brain development and later outcomes in health, education, and relationships.

The concept of childhood has evolved over time and varies across cultures. In traditional societies, children were often viewed as small adults expected to contribute to household or agricultural work from an early age. In contrast, modern industrialized societies tend to regard childhood as a protected period during which children are nurtured and educated, free from the burdens of adult responsibilities.

Family environment plays a key role in shaping childhood. Parents and caregivers provide not only physical care but also emotional support, discipline, and moral guidance. Warm, responsive parenting fosters secure attachment, confidence, and resilience, while neglect or abuse can lead to long-term emotional and psychological issues. Sibling relationships, extended family, and community networks also influence a child's development.

Education is another major influence during childhood. Early childhood education programs help children develop language, motor, and social skills. Formal schooling introduces them to structured learning, discipline, and peer relationships. Access to quality education during childhood is one of the most reliable predictors of future success, including higher earnings, better health, and civic participation.

Play is considered a vital part of childhood. Through play, children develop creativity, problem-solving abilities, and social skills. It allows them to express emotions, practice roles, and learn cooperation. Both structured play, such as games and sports, and unstructured play, such as imaginative storytelling, contribute to a child's cognitive and emotional growth. Unfortunately, in some regions, the pressure of academic achievement has reduced opportunities for free play.

Childhood is also a time when values, beliefs, and identity begin to form. Children learn by observing adults and absorbing cultural norms. Stories, rituals, and traditions help shape a child's sense of belonging and morality. As they grow older, children begin to question authority, develop independence, and form their own opinions about the world.

However, not all children experience a happy or healthy childhood. Millions face challenges such as poverty, malnutrition, violence, and lack of access to education. According to UNICEF, more than 1 in 5 children worldwide live in extreme poverty, and many are forced into child labor or early marriage. These experiences rob children of the chance to learn, grow, and enjoy their early years.

Children affected by conflict and displacement face especially difficult circumstances. Refugee children may lose their homes, family members, and access to basic services. Trauma during childhood can have long-term effects on mental health, academic performance, and social relationships. Supportive environments, trauma-informed care, and consistent routines can help children recover and regain a sense of safety.

In wealthier nations, new challenges have emerged. The widespread use of digital technology has transformed childhood. While smartphones, tablets, and the internet provide access to learning and entertainment, they also raise concerns about screen time, cyberbullying, and social isolation. Parents and educators must find ways to balance digital exposure with real-world interaction and physical activity.

Public policy plays a key role in protecting and promoting healthy childhoods. Governments are responsible for ensuring children's rights to education, healthcare, safety, and protection from exploitation. The United Nations Convention on the Rights of the Child (UNCRC), adopted in 1989, outlines these rights and obligates signatory countries to uphold them. Investment in early childhood development has been shown to yield significant returns in terms of reduced crime, improved productivity, and better social outcomes.

In recent years, there has been a growing emphasis on child participation — giving children a voice in decisions that affect their lives. Whether in the classroom, family, or legal system, listening to children and respecting their perspectives fosters self-esteem and a sense of agency.

In conclusion, childhood is a formative stage of life that shapes the person an individual becomes. It is a time of exploration, learning, and development, deeply influenced by family, culture, education, and environment. Ensuring that every child enjoys a safe, nurturing, and stimulating childhood is not only a moral obligation but also an investment in the future of society.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The author\'s main purpose is to give a broad overview of childhood — what it is, what influences it, and why it matters — arguing that a safe and nurturing childhood is both a moral duty and an investment in society\'s future.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how did traditional societies view children differently from modern industrialized societies?',
        explanation: 'Traditional societies viewed children as small adults expected to work from an early age. Modern industrialized societies, in contrast, treat childhood as a protected period for nurturing and education, free from adult responsibilities.',
      ),
      ReadingQuestion(
        question: 'The word "resilience" in the passage is used in the context of parenting. What does it most likely mean?',
        explanation: 'In context, resilience means the ability to recover from difficulties. The passage states that warm, responsive parenting fosters resilience — meaning children raised in supportive environments are better able to cope with challenges.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the relationship between education and a child\'s future?',
        explanation: 'The passage implies a strong positive relationship: access to quality education during childhood is described as one of the most reliable predictors of future success, including higher earnings, better health, and civic participation.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what new challenges have emerged for children in wealthier nations?',
        explanation: 'The passage identifies digital technology as a new challenge — specifically concerns about excessive screen time, cyberbullying, and social isolation caused by widespread use of smartphones, tablets, and the internet.',
      ),
      ReadingQuestion(
        question: 'What does the author suggest about investing in early childhood development?',
        explanation: 'The author suggests that investing in early childhood yields significant long-term returns for society, including reduced crime rates, improved productivity, and better social outcomes — making it both a moral obligation and a practical benefit.',
      ),
    ],
  ),

  // ── Passage 2 ─────────────────────────────────────────────────────────────
  // ReadingPassage(
  //   id: 2,
  //   title: '',
  //   topic: '',
  //   content: '''''',
  //   questions: [
  //     ReadingQuestion(question: ''),
  //   ],
  // ),

];
