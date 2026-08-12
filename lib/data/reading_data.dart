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

  ReadingPassage(
    id: 2,
    title: 'Child Care',
    topic: 'Society & Culture',
    content: '''Child care refers to the supervision and nurturing of children, typically from infancy to early school age, by individuals other than the child's parents. It plays a vital role in child development, family life, and modern economies. As more parents engage in full-time work or education, the need for reliable, affordable, and high-quality child care continues to grow. 
There are several types of child care arrangements. The most common include daycare centers, home-based care, nannies, and relatives providing informal care. 
Each option varies in terms of cost, flexibility, quality, and accessibility. For many families, choosing the right child care involves balancing financial limitations with the desire to ensure a safe and stimulating environment for their children. 
High-quality child care provides more than just supervision—it contributes significantly to a child‘s social, emotional, cognitive, and physical development. In structured child care settings, children engage in activities that promote language skills, early literacy, and social interaction. Exposure to diverse environments and caregivers can also enhance adaptability and emotional intelligence. 
Governments and researchers recognize the importance of early childhood development, which begins well before formal schooling. Studies consistently show that children who attend quality child care programs are more likely to succeed academically, enjoy better health, and display stronger social skills later in life. As a result, many countries have implemented policies and subsidies to support child care services. 
However, access to quality child care is uneven, particularly in low-income communities or rural areas. In many countries, child care remains expensive and out of reach for families with limited resources. The cost of full-time child care often rivals or exceeds the average rent or mortgage payment, placing a significant financial burden on working parents—especially single mothers. 
Child care workers are essential but often underpaid. Despite their responsibility in shaping young minds, many early childhood educators receive low wages and limited benefits. This can lead to high staff turnover, which negatively affects consistency and attachment between children and caregivers. Improving the status and training of child care professionals is a priority for advocates of early childhood education. 
Health and safety are fundamental components of child care. Facilities must meet strict standards regarding hygiene, nutrition, emergency preparedness, and staff-tochild ratios. Licensing, inspections, and background checks are mechanisms used to ensure compliance. During public health crises, such as the COVID-19 pandemic, child care centers had to adapt quickly to minimize risks while continuing to serve essential workers and families. 
Child care policies vary widely across countries. In Scandinavian nations, child care is often publicly funded and considered a universal right. Countries like Sweden and Norway offer generous parental leave followed by affordable, highquality early education programs. In contrast, countries such as the United States and United Kingdom rely more heavily on private providers, with limited public subsidies. 
Parental leave is closely related to child care. The availability and duration of paid leave affect when and how parents return to work, and whether they rely on child care services. In some cases, grandparents or extended family step in to help, especially in cultures where multigenerational living is common. 
Technology is changing the landscape of child care. Apps and digital platforms allow parents to monitor their child‘s daily activities, communicate with caregivers, and access resources on child development. Some startups offer flexible or on-demand care options, which can be particularly useful for shift workers or freelancers. 
Yet, not all parents have the same needs or preferences. Some choose to care for their children at home due to cultural, religious, or personal beliefs. Others worry about the emotional impact of long hours in institutional settings. Quality homebased care or co-operative arrangements between families are often seen as alternatives that provide both nurturing and structure. 
In addition to regular child care, after-school programs, summer camps, and early intervention services provide support for working parents and children with special needs. These programs can offer tutoring, sports, arts, and enrichment activities, reducing the risks associated with unsupervised time after school. 
The debate about who should bear the cost of child care continues. Some argue that governments should fund universal child care as a public good—just like primary education—because of its long-term benefits to society. Others believe that families should be responsible for making their own arrangements without relying on taxpayer support. This debate influences national budgets, election platforms, and labor policies. 
In conclusion, child care is a crucial aspect of modern life that affects children‘s development, gender equality, and economic productivity. While challenges remain—particularly regarding affordability, accessibility, and quality—investing in child care pays dividends for individuals and society. As the world changes, flexible, inclusive, and well-regulated child care systems will be essential for supporting families and shaping the next generation.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of this passage is to discuss the importance of child care for child development, family life, and economies, while covering types of arrangements, benefits of high-quality care, challenges of access and affordability, the conditions of workers, varying national policies, related issues like parental leave and technology, and the debate over funding, concluding that investment in flexible, inclusive, and well-regulated systems is essential.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what benefits does high-quality child care provide beyond supervision?',
        explanation: 'High-quality child care contributes significantly to a child\'s social, emotional, cognitive, and physical development. Children engage in activities that promote language skills, early literacy, and social interaction, and exposure to diverse environments and caregivers can enhance adaptability and emotional intelligence. Studies show that children who attend quality programs are more likely to succeed academically, enjoy better health, and display stronger social skills later in life.',
      ),
      ReadingQuestion(
        question: 'The word \'uneven\' in paragraph 6 most likely means?',
        explanation: 'It most likely means unequal or inconsistent in distribution or availability, as the passage states that access to quality child care is uneven, particularly in low-income communities or rural areas, and remains expensive and out of reach for many families with limited resources.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about child care policies in Scandinavian nations compared to those in the United States and United Kingdom?',
        explanation: 'It can be inferred that Scandinavian nations view child care as a publicly funded universal right, offering generous parental leave followed by affordable, high-quality early education programs, whereas the United States and United Kingdom rely more heavily on private providers with limited public subsidies.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does high staff turnover affect child care?',
        explanation: 'High staff turnover negatively affects consistency and attachment between children and caregivers, which is a problem because many early childhood educators receive low wages and limited benefits despite their essential role in shaping young minds.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the financial impact of child care on working parents?',
        explanation: 'It can be inferred that the cost of full-time child care places a significant financial burden on working parents, especially single mothers, because it often rivals or exceeds the average rent or mortgage payment and remains expensive and out of reach for families with limited resources, particularly in low-income communities or rural areas.',
      ),
    ],
  ),

  ReadingPassage(
    id: 3,
    title: 'Children\'s Education',
    topic: 'Education & Society',
    content: '''Children‘s education refers to the formal and informal learning processes that take place during the early years of life, typically from preschool through primary and secondary school. It is considered one of the most important foundations for individual success and national development. A well-educated child is more likely to grow into a responsible, healthy, and productive adult.
Education during childhood serves multiple purposes. Academically, it introduces children to basic skills such as reading, writing, and arithmetic. Socially, it helps them develop cooperation, discipline, and communication. Emotionally, it builds self-esteem, resilience, and curiosity. In many countries, primary education is compulsory, reflecting its vital role in personal and societal progress.
Early childhood education, which begins before formal schooling, is especially important. Studies show that children who attend preschool perform better later in life. These programs focus on language development, motor skills, and emotional regulation. In supportive learning environments, young children are better prepared for the structure and expectations of primary school.
As children progress through school, the curriculum becomes more complex. In primary and secondary education, students learn a broad range of subjects, including science, mathematics, literature, history, and the arts. Education systems vary across countries, but the goal is usually to equip children with the knowledge and skills necessary to participate in the economy and society.
Teachers play a central role in shaping children‘s education. A skilled, motivated, and well-trained teacher can inspire a lifelong love of learning. Teachers must not only understand the subject matter but also know how to engage young learners, manage behavior, and support diverse needs. Unfortunately, in many countries, there is a shortage of qualified teachers, especially in rural or low-income areas.
Access to education remains a challenge for millions of children around the world. Barriers include poverty, distance to school, gender discrimination, conflict, and disabilities. According to UNESCO, more than 250 million children of primary and secondary school age are not in school. In some cases, children are forced to work or marry early, preventing them from completing their studies.
Gender inequality is another issue. In many societies, girls are less likely to attend school due to cultural norms, safety concerns, or household responsibilities. Educating girls has been shown to reduce poverty, improve health outcomes, and promote gender equality. Programs that provide scholarships, safe transportation, or menstrual hygiene support can help close the education gap between boys and girls.
Technology is transforming children‘s education. Digital tools such as tablets, educational software, and online learning platforms make it easier to access information and tailor instruction to individual needs. During the COVID-19 pandemic, many schools adopted remote learning, highlighting both the potential and the limitations of technology in education. While digital education offers flexibility, it also exposes inequalities in internet access and device availability.
Assessment and testing are central components of most education systems. Standardized exams are used to measure student performance and school effectiveness. However, excessive testing can create stress and discourage creativity. Many educators advocate for a more balanced approach that values critical thinking, collaboration, and emotional intelligence alongside academic achievement.
Parental involvement is a key factor in children‘s educational success. Children whose parents are engaged in their schooling—through reading at home, attending parent-teacher meetings, or helping with homework—tend to perform better academically. Strong partnerships between schools and families can support a child‘s learning and address problems early.
Inclusive education is also gaining attention. This approach emphasizes accommodating all learners, including those with disabilities, different languages, or special learning needs. Inclusive classrooms promote diversity, tolerance, and equal opportunity. However, implementing inclusive education requires training, resources, and systemic change. In many countries, governments have made children‘s education a policy priority. Public spending on schools, teacher salaries, infrastructure, and textbooks is essential to improving quality and access. International organizations such as UNICEF and the World Bank support education programs in developing countries, helping build schools, train teachers, and provide materials.
Despite these efforts, challenges remain. In some regions, schools are overcrowded, underfunded, or unsafe. Children may face bullying, discrimination, or violence at school. Climate change and armed conflict have displaced millions of children, interrupting their education. Addressing these challenges requires coordination between governments, communities, and global institutions.
In conclusion, children‘s education is a fundamental right and a critical investment in the future. It supports personal development, social inclusion, and economic growth. Ensuring that every child has access to quality education, regardless of background, is not only a matter of fairness but also a foundation for building a more just and prosperous world.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to explain the importance of children\'s education as a foundation for individual and societal progress, describe its academic, social, and emotional benefits, discuss challenges such as access barriers and teacher shortages, and emphasize the need for quality education for every child.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what multiple purposes does education during childhood serve?',
        explanation: 'Academically it introduces basic skills such as reading, writing, and arithmetic; socially it helps develop cooperation, discipline, and communication; emotionally it builds self-esteem, resilience, and curiosity.',
      ),
      ReadingQuestion(
        question: 'The word \'compulsory\' in the second paragraph most likely means...',
        explanation: 'Required by law or rules. The passage states that in many countries primary education is compulsory, reflecting its vital role in personal and societal progress.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the importance of early childhood education?',
        explanation: 'It is especially important because studies show that children who attend preschool perform better later in life, and such programs prepare young children for the structure and expectations of primary school by focusing on language development, motor skills, and emotional regulation.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how many children of primary and secondary school age are not in school according to UNESCO?',
        explanation: 'More than 250 million children of primary and secondary school age are not in school.',
      ),
      ReadingQuestion(
        question: 'The word \'resilience\' in the second paragraph most likely means...',
        explanation: 'The ability to recover from difficulties or adapt well to challenges. The passage lists resilience as one of the emotional qualities that education during childhood builds, along with self-esteem and curiosity.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the effects of educating girls?',
        explanation: 'Educating girls has been shown to reduce poverty, improve health outcomes, and promote gender equality, and targeted programs such as scholarships or safe transportation can help close the education gap between boys and girls.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is a key factor in children\'s educational success?',
        explanation: 'Parental involvement. Children whose parents are engaged in their schooling—through reading at home, attending parent-teacher meetings, or helping with homework—tend to perform better academically.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of technology in children\'s education?',
        explanation: 'Technology transforms education by making information more accessible and allowing tailored instruction, yet the COVID-19 shift to remote learning also revealed limitations and inequalities in internet access and device availability.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what does inclusive education emphasize?',
        explanation: 'Inclusive education emphasizes accommodating all learners, including those with disabilities, different languages, or special learning needs, and promotes diversity, tolerance, and equal opportunity, though it requires training, resources, and systemic change.',
      ),
    ],
  ),

  ReadingPassage(
    id: 4,
    title: 'Family',
    topic: 'Society & Culture',
    content: '''The family is often described as the basic unit of society. It plays a vital role in shaping an individual's identity, values, and behavior. Families provide emotional support, financial stability, and social connections. While the concept of family may differ across cultures and historical periods, its influence on personal development and societal structure remains universal and profound.
Traditionally, a family was defined as a group consisting of two parents and their children living together under one roof. However, in today‘s world, family structures have become more diverse. Modern families include single-parent families, blended families (formed after remarriage), child-free couples, extended families living together, and same-sex parent families. These changes reflect shifting social norms, economic conditions, and legal frameworks.
The family plays several key roles in a child‘s early development. Parents and caregivers are the first teachers, providing children with language, manners, moral values, and basic life skills. Through interaction with family members, children learn how to communicate, form relationships, solve problems, and manage emotions. A stable and loving home environment contributes to healthy emotional and psychological growth.
In addition to emotional support, families provide for the material needs of their members. Food, shelter, clothing, and access to education and healthcare are typically ensured through the collective efforts of the family unit. In many cultures, older family members support younger generations financially and in return receive care during old age.
Family relationships also influence identity and self-esteem. Positive relationships within a family foster a sense of security, belonging, and confidence. On the other hand, dysfunctional family environments—marked by neglect, conflict, or abuse— can lead to long-term emotional damage, affecting academic performance, social behavior, and mental health.
Family dynamics vary across cultures. In many Western societies, there is an emphasis on independence and nuclear family living. Parents encourage children to make their own choices and pursue individual goals. In contrast, collectivist cultures, such as those in Asia, Africa, and Latin America, often emphasize family loyalty, shared responsibilities, and respect for elders. In such cultures, extended families—grandparents, aunts, uncles—play a larger role in raising children.
Modern families face numerous challenges. Work-life balance is a major concern, especially in dual-income households. Parents often struggle to spend enough time with their children due to long working hours or job-related stress. This can affect family bonding and children‘s emotional development. Many families also deal with financial pressure, which can lead to tension and conflict.
Divorce, separation, and remarriage have become more common in many parts of the world. While these changes reflect greater personal freedom, they also bring new challenges. Children of divorced parents may experience emotional stress, confusion, or changes in living arrangements. However, many families adapt successfully, and children can thrive in stepfamilies or co-parenting arrangements when supported with love and stability.
Technology has had a profound impact on family life. On the one hand, digital communication tools allow family members to stay connected across distances. Video calls, messaging apps, and social media make it easier to share everyday moments and maintain relationships. On the other hand, excessive screen time and smartphone use can reduce face-to-face interaction, especially during meals or family time. Parents must model healthy tech habits and encourage offline bonding.
Family life is also influenced by broader social and economic trends. Urbanization, migration, and globalization have led to families being more geographically dispersed. In many countries, young adults move away from their hometowns for education or work, reducing daily contact with their parents and relatives. This has increased the importance of community support systems, schools, and peer networks in providing the care traditionally offered by the extended family. Government policies and social services can either support or strain family life. For example, access to parental leave, affordable childcare, and housing assistance helps families thrive. Countries with strong social safety nets tend to have lower rates of child poverty and better work-life balance. In contrast, a lack of support can increase stress and limit opportunities for parents and children alike. Despite the diversity of modern family arrangements, the emotional core of the family remains the same—love, trust, responsibility, and connection. Whether biological or chosen, families provide a sense of identity and continuity. They are the first place where people experience love, care, and mutual support.
In conclusion, the family is a fundamental part of human life, shaping values, identity, and behavior. Though its structure and roles have changed over time, its importance remains constant. Supporting families through social policy, education, and community engagement is essential for building a healthy and inclusive society.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to explain the importance of the family as a fundamental social unit, describe how its structures and roles have evolved, outline its functions in emotional, material, and cultural development, discuss modern challenges, and emphasize the need to support families for a healthy society.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how was a family traditionally defined?',
        explanation: 'Traditionally, a family was defined as a group consisting of two parents and their children living together under one roof.',
      ),
      ReadingQuestion(
        question: 'The word "blended" in the second paragraph most likely means',
        explanation: 'In the context of "blended families (formed after remarriage)", the word means families created by combining members from previous relationships or marriages, typically after remarriage.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about collectivist cultures from the passage?',
        explanation: 'It can be inferred that collectivist cultures (such as those in Asia, Africa, and Latin America) place greater value on family loyalty, shared responsibilities, respect for elders, and the involvement of extended family members in raising children, in contrast to the emphasis on independence found in many Western societies.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are some of the key roles the family plays in a child\'s early development?',
        explanation: 'Parents and caregivers act as the first teachers, providing language, manners, moral values, and basic life skills; through family interaction, children learn to communicate, form relationships, solve problems, and manage emotions; a stable, loving home supports healthy emotional and psychological growth.',
      ),
      ReadingQuestion(
        question: 'The word "dysfunctional" in the fifth paragraph most likely means',
        explanation: 'In the context of "dysfunctional family environments—marked by neglect, conflict, or abuse", the word means not operating properly or healthily, characterized by serious problems that harm family members.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the impact of technology on family life?',
        explanation: 'Technology has a dual impact: it helps family members stay connected across distances through tools like video calls and messaging, but excessive screen time can reduce face-to-face interaction and weaken bonding, so parents need to model healthy habits.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how do families typically provide for the material needs of their members?',
        explanation: 'Families ensure food, shelter, clothing, and access to education and healthcare through the collective efforts of the family unit; in many cultures, older members also support younger generations financially and later receive care in old age.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the effects of divorce and remarriage on children?',
        explanation: 'While divorce and remarriage can cause emotional stress, confusion, or changes in living arrangements for children, many children adapt successfully and can thrive in stepfamilies or co-parenting situations when they receive love and stability.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what remains the emotional core of the family despite changes in structure?',
        explanation: 'Despite the diversity of modern family arrangements, the emotional core remains the same: love, trust, responsibility, and connection. Families, whether biological or chosen, provide a sense of identity, continuity, care, and mutual support.',
      ),
    ],
  ),

  ReadingPassage(
    id: 5,
    title: 'Family Ties',
    topic: 'Society & Culture',
    content: '''Family ties refer to the emotional, social, and legal bonds that connect individuals within a family. These ties often represent the deepest and most lasting relationships in a person's life. They influence how people grow, interact with others, and face life's challenges. In every culture, family connections are seen as a vital part of personal identity, social structure, and community life.
There are different types of family ties, including those between parents and children, siblings, spouses, and extended relatives such as grandparents, aunts, uncles, and cousins. These relationships are not only defined by blood or marriage but also by emotional attachment, mutual care, and shared experiences.
One of the strongest and earliest family bonds is that between parents and children. This tie begins at birth and often lasts a lifetime. Parents provide physical care, emotional support, and guidance as children grow and mature. In return, children may later support their parents emotionally and financially, especially in old age. This sense of responsibility and reciprocity strengthens the intergenerational link. Sibling relationships also play an important role in shaping personality and behavior. Brothers and sisters often serve as companions, role models, and rivals. These relationships can be characterized by deep affection and occasional conflict. Siblings often share memories, traditions, and family history, creating a unique connection that continues into adulthood.
In many cultures, extended family ties are just as important as immediate ones. Grandparents, for example, may help raise children, pass down cultural knowledge, or provide moral support. In collectivist societies, family loyalty and shared decision-making extend across generations and household boundaries. Relatives are expected to assist one another, particularly during illness, financial hardship, or celebrations such as weddings and religious festivals.
Strong family ties offer many benefits. Emotional support is one of the most valuable aspects. Family members often provide comfort during difficult times, such as illness, loss, or personal failure. This support can reduce stress, promote mental health, and improve overall well-being. People with strong family connections tend to have higher life satisfaction and a greater sense of purpose.
Economic security is another advantage of close family ties. Families often pool resources to pay for education, housing, or emergencies. In times of crisis, relatives may offer temporary housing, childcare, or financial help. In some societies, family businesses or shared property represent long-term cooperation between relatives.
However, family ties are not always positive. Tensions may arise from personality differences, competition, jealousy, or unmet expectations. Some family relationships are strained due to past conflicts, emotional neglect, or differing values. In extreme cases, unresolved issues can lead to estrangement or even abuse. Maintaining healthy family ties requires communication, forgiveness, and respect for personal boundaries.
Modern lifestyles have changed the nature of family ties. In today‘s world, many families are more dispersed due to migration, education, or employment. Young adults may move to cities or abroad, limiting daily contact with parents or siblings. While technology helps maintain communication through video calls and messaging apps, it cannot fully replace physical presence and shared activities.
At the same time, some people are choosing non-traditional family arrangements, including single-parent households, same-sex couples, or chosen families composed of close friends. In these cases, family ties are built on trust and emotional connection rather than legal or biological links. These new forms of family reflect changing social attitudes and a broader understanding of what defines meaningful relationships.
Cultural attitudes strongly influence how family ties are valued and maintained. In many Asian, African, and Latin American societies, respecting elders and prioritizing family obligations are seen as moral duties. Children are often expected to care for their parents in old age. In contrast, individualistic cultures such as those in Western Europe or North America may emphasize personal freedom and independence, sometimes at the expense of close family bonds.
Legal and governmental policies also affect family ties. Laws related to marriage, inheritance, parental rights, and elder care influence how families function and interact. For instance, tax benefits, parental leave, and housing support can encourage family stability. On the other hand, legal disputes over custody or inheritance may create long-lasting divisions within families.
Efforts to strengthen family ties can include regular communication, shared meals, celebrating traditions, and spending quality time together. Counseling services or support groups can help families navigate conflict or reconnect after periods of separation. Schools and community centers may also offer programs that teach parenting skills, conflict resolution, or intergenerational understanding.
In conclusion, family ties form the emotional and social framework of human life. They provide love, support, and stability, while also presenting challenges that require effort and understanding. Whether defined by blood, marriage, or emotional connection, strong family relationships contribute to personal happiness and a more caring, cohesive society.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage explains the nature, types, benefits, challenges, and cultural variations of family ties, concluding that they form a fundamental framework of human life that contributes to happiness and social cohesion.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what defines family relationships beyond blood or marriage?',
        explanation: 'The passage states that these relationships are also defined by emotional attachment, mutual care, and shared experiences.',
      ),
      ReadingQuestion(
        question: 'The word "reciprocity" in the third paragraph most likely means',
        explanation: 'In context, reciprocity refers to the mutual exchange of support, where children later provide emotional and financial help to parents who previously cared for them.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about sibling relationships from the passage?',
        explanation: 'Sibling relationships involve both deep affection and occasional conflict, and they help shape personality while creating lasting connections through shared memories and history.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how do collectivist societies view extended family ties?',
        explanation: 'In collectivist societies, family loyalty and shared decision-making extend across generations, and relatives are expected to assist one another during hardship or celebrations.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the impact of strong family ties on well-being?',
        explanation: 'People with strong family connections tend to experience reduced stress, better mental health, higher life satisfaction, and a greater sense of purpose due to emotional support.',
      ),
      ReadingQuestion(
        question: 'The word "estrangement" in the seventh paragraph most likely means',
        explanation: 'In context, estrangement refers to a state of emotional or physical separation or alienation that can result from unresolved family conflicts.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what limitation does technology have in modern family life?',
        explanation: 'While technology enables communication through video calls and messaging apps, it cannot fully replace physical presence and shared activities.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about non-traditional family arrangements?',
        explanation: 'These arrangements, such as chosen families of close friends, are based on trust and emotional connection rather than legal or biological links, reflecting broader social changes in defining meaningful relationships.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how do cultural attitudes differ regarding family obligations?',
        explanation: 'Many Asian, African, and Latin American societies treat respecting elders and family duties as moral obligations, whereas individualistic Western cultures often prioritize personal freedom and independence.',
      ),
    ],
  ),

  ReadingPassage(
    id: 6,
    title: 'Parenting',
    topic: 'Society & Culture',
    content: '''Parenting refers to the process of raising and nurturing children from infancy through adulthood. It involves providing for a child‘s physical needs, supporting emotional development, teaching values and discipline, and preparing the child for independent life. Good parenting is essential for healthy childhood development and plays a major role in shaping an individual‘s character, confidence, and behavior.
There are many different styles of parenting, and each has a unique impact on children. The most widely discussed models include authoritative, authoritarian, permissive, and neglectful parenting.
•        Authoritative parents set clear rules but are also supportive and responsive. They encourage independence while maintaining boundaries. Research suggests that this style is associated with the most positive outcomes, including high self-esteem, good academic performance, and strong social skills.
•        Authoritarian parents demand strict obedience and often rely on punishment. While their children may follow rules, they are more likely to develop low self-confidence and social anxiety.
•        Permissive parents are loving but offer little discipline or structure. Their children may struggle with self-control and responsibility.
•        Neglectful parents, who are uninvolved or indifferent, often raise children who lack emotional support and structure, which can lead to behavioral and academic difficulties.
Effective parenting is not about applying a rigid formula—it‘s about adapting to a child‘s unique needs and personality while maintaining a balance between guidance and freedom. Children thrive when they feel loved, heard, and respected, and when they are given opportunities to learn from both successes and failures. Communication is a core component of successful parenting. Open, honest, and age-appropriate conversations help build trust between parents and children. When children feel safe expressing themselves, they are more likely to seek advice, share problems, and develop emotional intelligence. Active listening—where parents pay full attention and respond thoughtfully—is especially important in building these bonds.
Discipline is another important aspect of parenting. It teaches children about consequences, boundaries, and responsibility. However, discipline should be constructive, not punitive. Positive discipline focuses on correcting behavior through explanation, redirection, and consistent consequences rather than fear or physical punishment. Studies have shown that harsh discipline, especially corporal punishment, can lead to aggression, resentment, and lower academic achievement. Parenting roles vary across cultures and societies. In many traditional cultures, parenting is a shared responsibility among extended family members, including grandparents, uncles, and aunts. In more individualistic societies, parenting is often carried out by one or two caregivers, sometimes with limited community support.
Gender roles also influence parenting. While mothers have traditionally taken on most child-rearing responsibilities, more fathers today are actively involved in their children‘s lives, contributing to more balanced parenting.
Modern parenting is also shaped by economic and social changes. Dual-income families, single-parent households, and blended families have become increasingly common. Parents often face time constraints and work-related stress, which can impact their ability to engage fully with their children. Access to parental leave, affordable childcare, and flexible work arrangements can help reduce these pressures and support family well-being.
The rise of digital technology has introduced new challenges and opportunities for parenting. On one hand, educational apps and online resources can support learning. On the other hand, excessive screen time, social media exposure, and cyberbullying can harm mental health. Parents must guide their children in developing healthy digital habits, set screen time limits, and monitor online activities without invading their privacy.
Parental involvement in education is another key factor in a child‘s development. When parents engage with schools, attend parent-teacher conferences, and support learning at home, children tend to perform better academically and develop stronger motivation. Reading with children, discussing schoolwork, and encouraging curiosity all contribute to a positive learning environment.
It is also important to recognize the emotional side of parenting. Raising a child can be deeply rewarding but also stressful, frustrating, and overwhelming at times. Parents may experience guilt, anxiety, or self-doubt, especially when faced with behavioral problems or social pressure. Seeking support from friends, family, or professionals can make a significant difference. Parenting classes, books, and support groups provide strategies and reassurance, helping parents feel more confident and capable.
Every child is different, and there is no single ―right‖ way to parent. What works for one child may not work for another. Flexibility, patience, and self-reflection are essential. Successful parents are not perfect; they learn from mistakes, adapt to changing circumstances, and remain committed to their child‘s well-being.
Government and community support can strengthen parenting. Policies such as paid parental leave, access to quality healthcare, parenting education programs, and child protection services create an environment where parents can succeed. In turn, strong families contribute to healthier, more stable societies.
In conclusion, parenting is one of the most important and challenging responsibilities a person can undertake. It shapes the next generation and influences every aspect of a child‘s life—from academic achievement to emotional well-being. While parenting styles and strategies may differ, love, consistency, communication, and support remain the core ingredients of raising happy and healthy children.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage explains the nature of parenting, describes different parenting styles and their effects, discusses key elements such as communication and discipline, and examines cultural, social, technological, and emotional aspects of raising children, concluding that love, consistency, communication, and support are essential.',
      ),
      ReadingQuestion(
        question: 'According to the passage, which parenting style is associated with the most positive outcomes?',
        explanation: 'The passage states that research suggests the authoritative style is associated with the most positive outcomes, including high self-esteem, good academic performance, and strong social skills.',
      ),
      ReadingQuestion(
        question: 'The word "authoritarian" in the passage most likely means',
        explanation: 'In the context of the passage, "authoritarian" describes parents who demand strict obedience and often rely on punishment, contrasting with more supportive styles.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about children raised by permissive parents?',
        explanation: 'The passage states that permissive parents offer little discipline or structure, and their children may struggle with self-control and responsibility, implying potential difficulties in managing behavior and duties independently.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is a core component of successful parenting?',
        explanation: 'The passage explicitly identifies communication as a core component of successful parenting, noting that open, honest, and age-appropriate conversations help build trust.',
      ),
      ReadingQuestion(
        question: 'The word "constructive" in the discussion of discipline most likely means',
        explanation: 'The passage contrasts constructive discipline with punitive approaches, explaining that positive discipline focuses on correcting behavior through explanation, redirection, and consistent consequences rather than fear or physical punishment.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the impact of harsh discipline according to the passage?',
        explanation: 'The passage notes that studies have shown harsh discipline, especially corporal punishment, can lead to aggression, resentment, and lower academic achievement, implying negative long-term effects on children\'s behavior and performance.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how do parenting roles differ between traditional and individualistic societies?',
        explanation: 'The passage states that in many traditional cultures, parenting is a shared responsibility among extended family members, while in more individualistic societies, it is often carried out by one or two caregivers, sometimes with limited community support.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about modern challenges related to digital technology in parenting?',
        explanation: 'The passage describes both opportunities (educational apps and online resources) and risks (excessive screen time, social media exposure, and cyberbullying), indicating that parents must actively guide children toward healthy digital habits while balancing monitoring and privacy.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is parental involvement in education important?',
        explanation: 'The passage explains that when parents engage with schools, attend parent-teacher conferences, and support learning at home, children tend to perform better academically and develop stronger motivation.',
      ),
    ],
  ),

  ReadingPassage(
    id: 7,
    title: 'Friendship',
    topic: 'Society & Culture',
    content: '''Friendship is a close and voluntary relationship between individuals based on mutual affection, trust, and shared experiences. Unlike family ties, friendships are chosen, making them one of the most personal and meaningful forms of human connection. From early childhood through adulthood, friendships play a critical role in emotional development, mental well-being, and social life.
Friendships begin in early childhood, often formed through shared play, school activities, or common interests. Young children develop basic social skills through their first friendships—learning how to share, resolve conflicts, and cooperate. As children grow older, friendships become more emotionally complex and stable, involving loyalty, empathy, and support. By adolescence, friends often become central to one‘s identity and decision-making process.
In adulthood, friendships may take different forms. Some people maintain large social circles with casual friends, while others develop a few deep, long-lasting relationships. Adult friendships are often based on shared values, hobbies, or life experiences. Unlike in childhood, adult friendships must be actively maintained, as time constraints, work, and family responsibilities can limit opportunities for connection.
Friendship offers numerous emotional benefits. A good friend provides companionship, listens during difficult times, and celebrates successes. Having someone to talk to reduces feelings of loneliness, anxiety, and depression. Studies show that people with strong friendships tend to have better mental health, greater life satisfaction, and even longer lifespans.
Beyond emotional support, friends can also influence personal behavior and decision-making. Positive friendships can encourage healthy habits, motivate personal growth, and provide constructive feedback. For example, friends may help each other stay active, avoid harmful behaviors, or pursue new opportunities. On the other hand, toxic friendships—marked by manipulation, jealousy, or dishonesty—can lead to stress, low self-esteem, or poor choices.
Trust and communication are the foundations of lasting friendships. Being honest, reliable, and respectful helps build trust, while open and empathetic communication deepens the bond. Conflicts may arise, but healthy friendships can survive disagreements through mutual understanding and compromise.
Apologizing, listening, and setting boundaries are essential skills in maintaining a balanced and respectful relationship.
Cultural values shape how friendships are formed and maintained. In some cultures, friendships are highly expressive, with frequent communication and emotional sharing. In others, friendships may be more reserved but equally deep. Expectations about loyalty, personal space, and time commitment can vary widely. For instance, in collectivist societies, friendship may involve greater obligations and long-term commitment, while individualistic cultures may emphasize independence and flexibility.
The rise of technology and social media has transformed the nature of friendship. Online platforms make it easier to stay in touch with old friends or meet new ones across the globe. For some, virtual friendships offer a sense of belonging, especially when face-to-face interaction is difficult. However, digital communication can also lead to superficial interactions, miscommunication, or social comparison. While social media connects people, it does not always replace the emotional depth of in-person relationships.
Maintaining adult friendships can be challenging. Busy schedules, geographic distance, and life changes such as marriage or parenthood often shift social priorities. Friendships may fade over time if not actively nurtured. Setting aside time to meet, call, or write can help preserve these valuable connections. Even brief, meaningful interactions can strengthen bonds.
Friendships can form in many settings—schools, workplaces, neighborhoods, or shared interest groups. Work friendships are especially important, as many adults spend a large portion of their time at their jobs. A friendly work environment improves morale, productivity, and job satisfaction. However, workplace friendships may be complicated by power dynamics, competition, or professionalism.
Another important form of friendship is cross-generational friendship, where individuals of different ages connect as equals. These friendships can offer fresh perspectives, mentorship, or emotional support outside of family structures. Similarly, friendships that cross cultural or religious boundaries can enrich understanding and promote tolerance in diverse societies.
Friendship also plays a vital role during life transitions. Whether moving to a new city, starting a new job, or dealing with illness or loss, friends provide emotional grounding and practical help. In times of crisis, strong social networks are linked to better coping strategies and quicker recovery.
It is worth noting that not all friendships are lifelong. Some friends drift apart due to changing interests, values, or circumstances. Letting go of a friendship can be painful but sometimes necessary for personal growth. Ending a toxic or one-sided friendship may lead to greater emotional freedom and well-being.
In conclusion, friendship is a key part of a fulfilling life. It provides emotional support, encourages personal growth, and enhances social connection. Though friendships may evolve or end, their value remains constant. In a world where isolation and stress are increasingly common, building and maintaining genuine friendships is more important than ever—for both individual happiness and the health of society.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to explain the nature of friendship, its development across life stages, its emotional and social benefits, the challenges of maintaining it, and its importance for individual well-being and society.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how do friendships typically begin in early childhood?',
        explanation: 'Friendships begin in early childhood often formed through shared play, school activities, or common interests, helping young children develop basic social skills such as sharing, resolving conflicts, and cooperating.',
      ),
      ReadingQuestion(
        question: 'The word "voluntary" in the first paragraph most likely means...',
        explanation: 'In the context of the passage, "voluntary" means chosen freely by the individuals involved, as opposed to family ties which are not selected.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about adult friendships compared to those in childhood?',
        explanation: 'It can be inferred that adult friendships require more active effort to maintain because of time constraints, work, and family responsibilities, whereas childhood friendships form more naturally through shared activities.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are the foundations of lasting friendships?',
        explanation: 'Trust and communication are the foundations of lasting friendships. Being honest, reliable, and respectful builds trust, while open and empathetic communication deepens the bond.',
      ),
      ReadingQuestion(
        question: 'The word "toxic" in the fifth paragraph most likely means...',
        explanation: 'In the context of the passage, "toxic" describes friendships marked by manipulation, jealousy, or dishonesty that can cause stress, low self-esteem, or poor choices.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the impact of social media on friendship?',
        explanation: 'It can be inferred that while social media makes it easier to stay connected and form virtual friendships, it can lead to superficial interactions and does not fully replace the emotional depth of in-person relationships.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how do cultural values influence friendships?',
        explanation: 'Cultural values shape how friendships are formed and maintained; some cultures favor expressive and frequent emotional sharing, while others are more reserved, and collectivist societies may involve greater obligations compared to individualistic ones that emphasize independence.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about ending a friendship?',
        explanation: 'It can be inferred that not all friendships last forever, and ending a toxic or one-sided friendship, though painful, can sometimes be necessary for personal growth and lead to greater emotional freedom and well-being.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what role do friends play during life transitions?',
        explanation: 'Friends provide emotional grounding and practical help during life transitions such as moving, starting a new job, or dealing with illness or loss, and strong social networks are linked to better coping strategies and quicker recovery in times of crisis.',
      ),
    ],
  ),

  ReadingPassage(
    id: 8,
    title: 'Marriage',
    topic: 'Society & Culture',
    content: '''Marriage is a socially and legally recognized union between two individuals that establishes rights and obligations between them. It is one of the oldest human institutions and exists in almost every culture, though customs, meanings, and laws surrounding marriage vary widely. While traditionally seen as a lifelong commitment involving emotional support, reproduction, and economic cooperation, the concept of marriage has evolved significantly in the modern world.
In many societies, marriage has historically been viewed as a social contract between families, often arranged to strengthen alliances, secure property, or maintain social status. Love and personal compatibility were not always the main factors in choosing a spouse. In contrast, modern Western societies generally emphasize romantic love, personal choice, and emotional connection as the foundation for marriage.
Marriage plays multiple roles in society. It provides a stable structure for raising children, sharing financial responsibilities, and supporting one another through life‘s challenges. Married couples often benefit from legal protections such as tax benefits, inheritance rights, and health insurance coverage. In many cultures, marriage is also a marker of adulthood and social respectability.
However, attitudes toward marriage are changing. In many parts of the world, marriage rates are declining, and people are marrying later than previous generations. Greater access to education, economic independence—particularly among women—and changing social norms have made marriage a less immediate priority. In some countries, cohabitation (living together without marriage) has become a widely accepted alternative.
Same-sex marriage has become a major legal and cultural issue in recent decades. While many countries have legalized it, granting equal rights to LGBTQ+ couples, others still prohibit it or do not recognize it legally. The legalization of same-sex marriage is often seen as a milestone in the fight for equal rights and social acceptance.
Religious and cultural traditions continue to shape marriage practices. In some cultures, arranged marriages are still common, where families select partners for their children based on compatibility, caste, religion, or economic background. Although critics argue that arranged marriages can limit personal freedom, supporters claim they often lead to stable and lasting unions, especially when both parties consent.
Interfaith and intercultural marriages are increasing as societies become more diverse and globalized. While these relationships can bring rich cultural exchange, they may also face challenges related to differing values, family expectations, and religious practices. Mutual respect and open communication are essential for success in such marriages.
A significant concern in many marriages is the division of household labor and childcare. While traditional roles assigned men as breadwinners and women as homemakers, these roles are shifting. Dual-income households are common, and more men are taking on active parenting roles. Still, surveys show that women often carry a heavier burden of domestic duties, even when working full-time.
Communication, trust, and mutual respect are widely recognized as the keys to a healthy marriage. When couples work as partners—sharing goals, solving problems together, and supporting each other emotionally—their relationships tend to be more stable and fulfilling. Counseling and education programs can help couples develop these skills, especially during times of stress or transition. Despite efforts to strengthen marriages, divorce rates have risen in many countries. The reasons for divorce are varied, including incompatibility, financial problems, infidelity, and lack of communication. While divorce is often seen as a failure, it can also be a necessary step toward personal growth and well-being, particularly in cases of abuse or chronic unhappiness.
Children of divorced parents may experience emotional or behavioral difficulties, but many adapt well over time, especially when both parents remain involved in their lives. Co-parenting arrangements, family counseling, and stable routines can help minimize the impact of divorce on children.
Economic conditions also influence marriage patterns. In uncertain financial times, people may delay marriage or forgo it altogether. In some societies, high dowry demands or expensive wedding traditions act as barriers to marriage, particularly for poorer families. Governments can support marriage and family stability by offering affordable housing, parental leave, and child support services.
Legal frameworks around marriage vary. In some countries, civil marriage is the only legally recognized form, while in others, religious ceremonies also carry legal weight. Laws regarding age of consent, property rights, and marital responsibilities differ significantly and continue to evolve.
In conclusion, marriage remains a deeply significant institution, both personally and socially. While its form and meaning have changed over time, its core purpose—providing a structure for companionship, cooperation, and family life— remains largely intact. In a rapidly changing world, the challenge is to make marriage inclusive, flexible, and supportive of diverse relationships and individual needs.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to examine marriage as a social and legal institution, describing its historical roles, modern changes, challenges, and enduring significance across cultures.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how was marriage historically viewed in many societies?',
        explanation: 'According to the passage, marriage was historically viewed as a social contract between families, often arranged to strengthen alliances, secure property, or maintain social status, rather than being based primarily on love or personal compatibility.',
      ),
      ReadingQuestion(
        question: 'The word "evolved" in the first paragraph most likely means',
        explanation: 'In the context of the first paragraph, "evolved" means gradually changed or developed over time, referring to how the concept of marriage has shifted significantly in the modern world from traditional views.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about romantic love in traditional versus modern Western marriages?',
        explanation: 'It can be inferred that romantic love was not always a primary factor in traditional marriages, which focused on family alliances and social status, whereas modern Western societies generally emphasize romantic love, personal choice, and emotional connection as the foundation.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what factors have contributed to declining marriage rates in many parts of the world?',
        explanation: 'According to the passage, greater access to education, economic independence—particularly among women—and changing social norms have made marriage a less immediate priority, leading to declining rates and later marriages.',
      ),
      ReadingQuestion(
        question: 'The word "cohabitation" in the fourth paragraph most likely means',
        explanation: 'In the context of the fourth paragraph, "cohabitation" means living together without being married, presented as a widely accepted alternative to marriage in some countries.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the legalization of same-sex marriage?',
        explanation: 'It can be inferred that the legalization of same-sex marriage is viewed as a significant step toward equal rights and social acceptance for LGBTQ+ couples, even though not all countries recognize or permit it.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are widely recognized as the keys to a healthy marriage?',
        explanation: 'According to the passage, communication, trust, and mutual respect are widely recognized as the keys to a healthy marriage, with couples who work as partners tending to have more stable and fulfilling relationships.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the impact of divorce on children?',
        explanation: 'It can be inferred that while children of divorced parents may face emotional or behavioral difficulties, many adapt well over time when both parents remain involved, and measures like co-parenting, counseling, and stable routines can reduce negative effects.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how do economic conditions influence marriage patterns?',
        explanation: 'According to the passage, in uncertain financial times people may delay or forgo marriage, and high dowry demands or expensive wedding traditions can act as barriers, especially for poorer families.',
      ),
    ],
  ),

  ReadingPassage(
    id: 9,
    title: 'Divorce',
    topic: 'Society & Culture',
    content: '''Divorce is the legal dissolution of a marriage by a court or other competent authority. Once considered rare or socially unacceptable in many cultures, divorce has become increasingly common in recent decades. Changing social norms, increased gender equality, and evolving legal systems have contributed to rising divorce rates in many parts of the world.
Historically, marriage was often seen as a lifelong commitment, regardless of personal happiness or compatibility. In many societies, religious and legal restrictions made divorce difficult or impossible. However, as views on marriage and individual rights have changed, so too has the acceptance of divorce as a personal choice.
There are many reasons why couples choose to divorce. Common factors include poor communication, financial stress, infidelity, lack of emotional support, and differing values or life goals. In some cases, abuse or addiction creates an environment where ending the marriage becomes necessary for personal safety and well-being. While every situation is unique, the decision to divorce is often complex and painful.
The process of divorce can vary greatly depending on the legal system, cultural context, and the presence of children or shared assets. In some countries, couples must undergo a separation period or counseling before a divorce is granted. Others offer no-fault divorce, allowing either spouse to end the marriage without proving wrongdoing. When divorce involves disputes over custody, property, or financial support, the process can be lengthy and emotionally taxing.
The impact of divorce on children is one of the most widely discussed aspects of marital breakdown. Children may experience confusion, sadness, or anxiety during and after their parents' separation. However, research shows that the effects of divorce depend largely on how the process is handled. When parents cooperate, communicate respectfully, and prioritize the child‘s well-being, children are more likely to adapt and maintain strong relationships with both parents.
In contrast, high-conflict divorces—marked by fighting, blame, or lack of cooperation—can harm children emotionally and academically. Stability, routine, and reassurance are essential during this time. Joint custody arrangements and clear parenting plans can help minimize disruption and ensure that children continue to receive love and support from both parents.
Economic consequences are another major concern in divorce. In many cases, one spouse—often the woman—may face financial hardship, particularly if they were not working outside the home during the marriage. Legal fees, relocation, and the cost of raising children as a single parent can create long-term financial strain. Child support and alimony laws are designed to address these issues, but enforcement and adequacy vary by region.
Divorce also affects mental health. Adults going through divorce often report feelings of loneliness, depression, and anxiety. The breakdown of a long-term relationship can challenge one‘s identity, disrupt social connections, and lead to stress-related health problems. Support networks—such as friends, family, or counseling services—play a critical role in helping individuals recover and rebuild their lives.
Despite these challenges, many people find that divorce ultimately leads to personal growth and renewed happiness. For those leaving abusive or unfulfilling relationships, divorce offers freedom and a chance to start over. Studies suggest that individuals who exit high-conflict marriages often experience improved wellbeing in the long term.
Social attitudes toward divorce have shifted significantly over time. In the past, divorced individuals—especially women—often faced social stigma and limited remarriage opportunities. Today, divorce is widely accepted in many societies, and blended families (formed after remarriage) are increasingly common. However, in more conservative cultures, divorce may still carry shame or be discouraged by religious or community leaders.
The rise in divorce rates is influenced by several factors. Higher expectations of marriage, greater gender equality, and increased financial independence among women have all contributed. In some cases, couples rush into marriage without fully understanding their compatibility, leading to disappointment and separation. In others, the legal system has simply made it easier to exit an unhappy relationship.
In response, many governments and organizations promote marriage education and counseling to support couples before and during marriage. These programs teach communication skills, conflict resolution, and realistic expectations. While not a cure-all, they can help prevent divorce or ensure that separation happens in a respectful and constructive manner.
At the same time, legal reforms have aimed to make divorce more efficient and less adversarial. Mediation and collaborative divorce processes allow couples to resolve issues outside of court, reducing cost and emotional damage. These approaches focus on cooperation rather than blame, which can be particularly beneficial when children are involved.
In conclusion, divorce is a complex and emotionally charged process that affects individuals, families, and societies. While it can bring pain and disruption, it also offers an opportunity for change and growth. As social attitudes and legal systems continue to evolve, the goal should be to support individuals through the process with dignity, fairness, and compassion—especially when children‘s lives are at stake.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to explain the nature of divorce, its causes, processes, effects on individuals and children, economic and mental health consequences, changing social attitudes, and efforts to support couples and make divorce less adversarial, concluding that it is a complex process that can also lead to growth and should be handled with dignity and compassion.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what factors have contributed to rising divorce rates in many parts of the world?',
        explanation: 'According to the passage, changing social norms, increased gender equality, and evolving legal systems have contributed to rising divorce rates in many parts of the world.',
      ),
      ReadingQuestion(
        question: 'The word "dissolution" in the first paragraph most likely means',
        explanation: 'In the first paragraph, "dissolution" refers to the legal ending or termination of a marriage by a court or other competent authority, as the sentence defines divorce as the legal dissolution of a marriage.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the effects of divorce on children?',
        explanation: 'It can be inferred that the effects of divorce on children depend largely on how the process is handled: when parents cooperate, communicate respectfully, and prioritize the child’s well-being, children adapt better and maintain strong relationships with both parents, whereas high-conflict divorces can harm them emotionally and academically.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is no-fault divorce?',
        explanation: 'According to the passage, no-fault divorce allows either spouse to end the marriage without proving wrongdoing.',
      ),
      ReadingQuestion(
        question: 'The phrase "high-conflict divorces" in the passage most likely refers to',
        explanation: 'The phrase "high-conflict divorces" refers to divorces marked by fighting, blame, or lack of cooperation, which the passage states can harm children emotionally and academically.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about economic consequences of divorce?',
        explanation: 'It can be inferred that economic consequences are a major concern, as one spouse—often the woman—may face financial hardship especially if not working outside the home, and legal fees, relocation, and raising children as a single parent can create long-term strain, even though child support and alimony laws aim to address these issues with varying enforcement and adequacy.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how have social attitudes toward divorce changed?',
        explanation: 'According to the passage, social attitudes have shifted significantly: in the past, divorced individuals—especially women—faced social stigma and limited remarriage opportunities, while today divorce is widely accepted in many societies and blended families are increasingly common, though it may still carry shame in more conservative cultures.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about individuals who exit high-conflict marriages?',
        explanation: 'It can be inferred that individuals who exit high-conflict marriages often experience improved wellbeing in the long term, as studies suggest this and the passage notes that many people find divorce ultimately leads to personal growth and renewed happiness, especially when leaving abusive or unfulfilling relationships.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what do mediation and collaborative divorce processes aim to achieve?',
        explanation: 'According to the passage, mediation and collaborative divorce processes allow couples to resolve issues outside of court, reducing cost and emotional damage, and focus on cooperation rather than blame, which can be particularly beneficial when children are involved.',
      ),
    ],
  ),

  ReadingPassage(
    id: 10,
    title: 'Personality',
    topic: 'Psychology & Behavior',
    content: '''Personality refers to the unique combination of characteristics, traits, and behaviors that define how an individual thinks, feels, and interacts with others. It influences how people respond to different situations, make decisions, and build relationships. While some aspects of personality are inherited, others are shaped by life experiences, culture, and environment.
Psychologists have long studied personality to understand human behavior. One of the most widely accepted theories is the Five-Factor Model, which identifies five core dimensions of personality:
•        Openness to experience: curiosity, imagination, and willingness to try new things
•        Conscientiousness: self-discipline, organization, and dependability
•        Extraversion: sociability, energy, and assertiveness
•        Agreeableness: kindness, empathy, and cooperation
•        Neuroticism: emotional instability, anxiety, and moodiness
Each person scores differently on these traits, and no single combination is considered ―better‖ or ―worse.‖ For example, someone high in extraversion may enjoy social gatherings and team projects, while an introverted person may prefer quiet environments and individual tasks.
Personality begins forming in early childhood, influenced by temperament, parenting style, and social environment. As individuals grow, their personalities continue to develop, shaped by education, culture, friendships, and life experiences. While core traits tend to remain stable over time, people can and do change aspects of their behavior through self-awareness and personal growth.
Culture plays a key role in shaping personality. In individualistic societies (like the United States or Australia), traits such as independence, assertiveness, and selfexpression are often valued. In collectivist cultures (like Japan or India), traits such as harmony, respect, and group loyalty may be emphasized. These cultural values influence not only how people see themselves but also how they interact with others.
Personality testing is used in many fields, from psychology and education to business and healthcare. Common tools include the Myers-Briggs Type Indicator (MBTI), the Big Five Inventory, and emotional intelligence assessments.
Employers may use personality tests during recruitment to predict job performance or team compatibility. While helpful, these tests are not always accurate and should be interpreted with caution.
Personality affects many areas of life. For instance, career choice is often influenced by personality. Creative individuals may be drawn to the arts, while conscientious people may prefer structured roles like accounting or engineering. Extraverts may excel in sales or customer service, while introverts might thrive in research or writing. Understanding one‘s strengths and preferences can help individuals make informed career decisions.
Relationships are also shaped by personality. People with high agreeableness tend to build strong friendships and avoid conflict, while those high in neuroticism may struggle with emotional regulation. Compatibility in romantic relationships often depends on shared values and complementary traits. However, communication, empathy, and mutual respect are ultimately more important than personality similarities.
Mental health is another area where personality plays a role. Certain traits, such as high neuroticism, are linked to higher risks of anxiety or depression. Conversely, people with high levels of conscientiousness and emotional stability are more likely to manage stress effectively. Developing self-awareness and emotional intelligence can improve mental well-being and coping skills.
In education, understanding personality can enhance teaching and learning. For example, extraverted students may enjoy group discussions, while introverted students may prefer written assignments. Teachers who recognize diverse personality traits can create more inclusive and effective learning environments.
Despite its stability, personality is not fixed. Life events such as trauma, success, or parenthood can alter how people behave or view themselves. Therapy, personal reflection, and goal setting can also lead to intentional personality change. For example, someone who is naturally disorganized can learn to become more structured with effort and support.
Modern research suggests that genetics and environment both contribute to personality. Twin studies show that identical twins raised apart often share similar traits, suggesting a strong genetic component. At the same time, experiences such as parenting, education, and social relationships clearly influence personality development.
The rise of social media has introduced new dimensions to personality expression. Online platforms allow people to curate their image and connect with others, but they also raise questions about authenticity. Some individuals may behave differently online than in real life, leading to misunderstandings or identity confusion.
In conclusion, personality is a complex and essential aspect of human identity. It influences every area of life, from relationships and careers to health and happiness. While personality traits are relatively stable, people have the capacity to grow, adapt, and change. By understanding personality—our own and others‘—we can improve communication, build stronger connections, and lead more fulfilling lives.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to explain the nature of personality, including its definition, the Five-Factor Model, how it develops and is influenced by genetics, environment, and culture, its effects on careers, relationships, mental health, and education, and the fact that while relatively stable it can still change through self-awareness and effort.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are the five core dimensions identified by the Five-Factor Model?',
        explanation: 'According to the passage, the five core dimensions are Openness to experience (curiosity, imagination, and willingness to try new things), Conscientiousness (self-discipline, organization, and dependability), Extraversion (sociability, energy, and assertiveness), Agreeableness (kindness, empathy, and cooperation), and Neuroticism (emotional instability, anxiety, and moodiness).',
      ),
      ReadingQuestion(
        question: 'The word "curate" in the paragraph about social media most likely means',
        explanation: 'In the context of the passage, "curate" most likely means to carefully select, organize, and present one\'s image or online presence, as the text states that online platforms allow people to curate their image and connect with others while raising questions about authenticity.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about personality tests from the passage?',
        explanation: 'It can be inferred that personality tests, while useful in fields such as psychology, education, business, and healthcare for predicting job performance or team compatibility, are not always accurate and therefore should be interpreted with caution.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does culture influence personality?',
        explanation: 'According to the passage, culture plays a key role in shaping personality. In individualistic societies such as the United States or Australia, traits like independence, assertiveness, and self-expression are often valued, whereas in collectivist cultures such as Japan or India, traits such as harmony, respect, and group loyalty may be emphasized. These cultural values influence how people see themselves and how they interact with others.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about people high in neuroticism based on the passage?',
        explanation: 'It can be inferred that people high in neuroticism may struggle with emotional regulation in relationships and are linked to higher risks of anxiety or depression, in contrast to those with high conscientiousness and emotional stability who manage stress more effectively.',
      ),
      ReadingQuestion(
        question: 'The word "temperament" in the paragraph describing early childhood most likely means',
        explanation: 'In the context of the passage, "temperament" most likely refers to an individual\'s innate or natural disposition and behavioral tendencies that influence personality formation in early childhood, along with parenting style and social environment.',
      ),
      ReadingQuestion(
        question: 'According to the passage, which personality traits are associated with better stress management?',
        explanation: 'According to the passage, people with high levels of conscientiousness and emotional stability are more likely to manage stress effectively, in contrast to those with high neuroticism who face higher risks of anxiety or depression.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the stability of personality from the passage?',
        explanation: 'It can be inferred that although core personality traits tend to remain relatively stable over time, personality is not fixed; life events, therapy, personal reflection, goal setting, and effort can lead to changes in behavior and self-view.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why might employers use personality tests during recruitment?',
        explanation: 'According to the passage, employers may use personality tests during recruitment to predict job performance or team compatibility, although the tests are not always accurate and should be interpreted with caution.',
      ),
    ],
  ),

  ReadingPassage(
    id: 11,
    title: 'Fear',
    topic: 'Psychology & Emotion',
    content: '''Fear is a basic human emotion triggered by perceived threats or danger. It plays a critical role in survival by alerting the body and mind to potential harm. Whether it‘s a fear of physical injury, social rejection, or failure, this emotion influences how people think, act, and make decisions. While fear can be protective, excessive or irrational fear may become a source of anxiety and limit personal growth.
From a biological perspective, fear is part of the body's "fight or flight" response. When a person senses danger, the brain's amygdala signals the release of stress hormones like adrenaline and cortisol. This prepares the body to respond quickly— by fleeing, hiding, or defending itself. Physical reactions may include increased heart rate, rapid breathing, muscle tension, and heightened alertness. These reactions are automatic and help humans survive immediate threats.
Fear can be rational or irrational. Rational fears are based on real, immediate dangers—such as the fear of a car crash or being bitten by a wild animal. Irrational fears, often called phobias, are disproportionate or unrelated to actual risk. Examples include fear of harmless insects, elevators, or public speaking. While the object may pose little danger, the fear response can be intense and disruptive.
Psychologists categorize fear into different types. Acute fear is a short-term reaction to a specific event, like hearing a loud noise. Chronic fear persists over time and may lead to anxiety disorders. Social fear involves worry about being judged or rejected by others, while existential fear deals with larger concerns, such as death or the meaning of life.
Fear is shaped by both biology and experience. Children may be born with certain fear responses, such as the fear of falling or loud noises. However, most fears are learned. A traumatic event, repeated warnings from adults, or exposure to frightening stories can teach individuals to associate certain situations with danger. Over time, these associations can strengthen and become difficult to unlearn.
Culture also influences fear. In some societies, fear of supernatural forces, shame, or dishonor may be more powerful than physical threats. In others, political instability or economic hardship may heighten fear of violence or poverty. What people fear, and how they express that fear, depends greatly on cultural beliefs, traditions, and historical context.
Despite its negative reputation, fear is not always harmful. In small doses, it can be motivating and constructive. Fear of failure, for example, may push students to study harder or athletes to train more intensely. In dangerous environments, fear helps people avoid risky behavior. It also plays a role in creativity and problemsolving, as individuals seek ways to reduce uncertainty and build confidence.
However, excessive fear can be debilitating. Anxiety disorders, such as generalized anxiety, panic disorder, and phobias, can interfere with daily life. People may avoid certain places, situations, or tasks due to fear, limiting their opportunities and well-being. Post-traumatic stress disorder (PTSD) is another condition where past fear-inducing experiences cause ongoing psychological distress.
Managing fear is a central goal in both psychology and personal development. Techniques include deep breathing, mindfulness, exposure therapy, and cognitivebehavioral therapy (CBT). These methods aim to help individuals recognize, confront, and reframe their fears rather than avoiding them. Facing fear in a controlled and gradual way often leads to reduced anxiety and greater resilience.
Education and information can also reduce fear. People tend to fear the unknown, so understanding how something works—like how airplanes stay in the air or how vaccines function—can make it less frightening. Rational thinking and accurate risk assessment are important tools in distinguishing real danger from imagined threats.
In the media and politics, fear is often used as a tool for influence. Sensational news stories, horror films, and political campaigns may trigger fear to attract attention or persuade people. While fear-based messages can raise awareness or encourage safety measures, they may also spread misinformation, promote stereotypes, or cause unnecessary panic.
Children are especially sensitive to fear. They may develop fears about the dark, monsters, or being separated from parents. While many of these fears are a normal part of development, it is important for caregivers to provide reassurance, maintain routines, and avoid exposing children to disturbing content. Supportive parenting helps children build confidence and emotional control.
Collective fears, such as fear of terrorism, disease, or climate change, can shape public behavior and policy. During global crises like the COVID-19 pandemic, fear led people to change habits, follow health guidelines, and support emergency measures. At the same time, fear can lead to scapegoating, discrimination, or irrational behavior, such as hoarding supplies or rejecting scientific advice. In conclusion, fear is a complex and deeply rooted human emotion. While it serves essential protective functions, it can also limit freedom and happiness when left unmanaged. Understanding the causes, types, and consequences of fear is the first step toward overcoming it. With the right knowledge and support, individuals and societies can learn not just to cope with fear, but to grow stronger because of it.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage explains the nature of fear as a basic human emotion, covering its biological basis, types, cultural influences, potential benefits and harms, and strategies for managing it, ultimately arguing that understanding fear helps individuals and societies overcome and grow from it.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what role does the amygdala play in the fear response?',
        explanation: 'When a person senses danger, the brain\'s amygdala signals the release of stress hormones like adrenaline and cortisol, preparing the body for a quick response such as fleeing, hiding, or defending itself.',
      ),
      ReadingQuestion(
        question: 'The word "disproportionate" in the paragraph discussing rational and irrational fears most likely means',
        explanation: 'It means excessive or out of proportion relative to the actual risk, as irrational fears (phobias) are described as disproportionate or unrelated to real danger.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the relationship between fear and learning?',
        explanation: 'Most fears are learned through experiences such as traumatic events, repeated warnings from adults, or exposure to frightening stories, and these learned associations can strengthen over time and become difficult to unlearn.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does culture influence fear?',
        explanation: 'Culture shapes what people fear and how they express it; in some societies, fears of supernatural forces, shame, or dishonor may outweigh physical threats, while in others, political instability or economic hardship heightens fears of violence or poverty, depending on cultural beliefs, traditions, and historical context.',
      ),
      ReadingQuestion(
        question: 'The word "debilitating" in the paragraph about excessive fear most likely means',
        explanation: 'It means weakening or impairing, as excessive fear is described as debilitating because anxiety disorders and related conditions can interfere with daily life and limit opportunities and well-being.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the positive aspects of fear?',
        explanation: 'In small doses, fear can be motivating and constructive, such as pushing students to study harder or athletes to train more intensely due to fear of failure, helping people avoid risky behavior, and contributing to creativity and problem-solving by reducing uncertainty.',
      ),
      ReadingQuestion(
        question: 'According to the passage, which techniques are used to manage fear?',
        explanation: 'Techniques include deep breathing, mindfulness, exposure therapy, and cognitivebehavioral therapy (CBT), which help individuals recognize, confront, and reframe their fears rather than avoid them, leading to reduced anxiety and greater resilience.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the use of fear in media and politics?',
        explanation: 'Fear is often used as a tool for influence through sensational news, horror films, and political campaigns to attract attention or persuade people; while it can raise awareness or encourage safety, it may also spread misinformation, promote stereotypes, or cause unnecessary panic.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how should caregivers respond to children\'s fears?',
        explanation: 'Caregivers should provide reassurance, maintain routines, and avoid exposing children to disturbing content, as supportive parenting helps children build confidence and emotional control, even though many childhood fears are a normal part of development.',
      ),
    ],
  ),

  ReadingPassage(
    id: 12,
    title: 'Happiness',
    topic: 'Psychology & Well-being',
    content: '''Happiness is a state of emotional well-being characterized by feelings of joy, satisfaction, and contentment. While the concept of happiness is universal, its meaning, causes, and measurement vary greatly across individuals and cultures. Some view happiness as a fleeting emotional response, while others see it as a long-term condition related to life satisfaction and purpose.
Psychologists often distinguish between two types of happiness: hedonic and eudaimonic. Hedonic happiness focuses on pleasure and the absence of pain. It involves short-term gratification, such as enjoying good food, entertainment, or relaxation. Eudaimonic happiness, by contrast, relates to meaning, personal growth, and fulfillment. People who pursue long-term goals, contribute to others, or develop their talents often report higher levels of eudaimonic happiness.
Many factors influence happiness, including genetics, environment, personality, and life circumstances. Research suggests that a portion of individual happiness is inherited, but much of it is shaped by intentional behavior and outlook. For example, people who are optimistic, grateful, and socially connected tend to report higher levels of happiness.
Relationships are one of the strongest predictors of happiness. Supportive family, friendships, and community connections provide emotional support, reduce stress, and create a sense of belonging. Studies consistently show that people with strong social bonds are happier and healthier than those who are socially isolated. Quality of relationships often matters more than quantity.
Work and achievement also contribute to happiness. People who find meaning in their work, feel competent, and receive recognition are more satisfied with life. However, job stress, unemployment, or a lack of autonomy can decrease happiness significantly. A balance between challenge and control is crucial for well-being in the workplace.
Money and material wealth play a complex role in happiness. To a certain extent, financial stability increases happiness by reducing stress and enabling access to basic needs like food, shelter, and healthcare. However, beyond a certain income level, additional wealth has a limited effect on happiness. In fact, people who focus heavily on material success may experience anxiety, comparison, or dissatisfaction, especially in consumer-driven societies.
Health is another key component. Physical and mental health significantly impact how people feel on a daily basis. Chronic illness, pain, or mental health conditions can reduce life satisfaction, while regular exercise, adequate sleep, and a nutritious diet contribute to positive mood and energy. Mental health support and stress management strategies are essential for maintaining emotional well-being.
Culture influences how people define and pursue happiness. In individualistic cultures, such as those in North America or Western Europe, happiness is often linked to personal achievement and self-expression. In collectivist cultures, such as those in East Asia or Africa, happiness may be more closely tied to family harmony, social responsibility, and group belonging. These cultural differences affect how people report their happiness and what they value most in life.
Spirituality and religion can also contribute to happiness. Many people find comfort, meaning, and hope through religious beliefs or spiritual practices. Participation in religious communities provides social support and a sense of purpose, which are linked to higher life satisfaction. However, this effect depends on individual beliefs and cultural context.
In recent years, the study of happiness has gained attention in public policy. Governments are increasingly recognizing that economic indicators alone do not reflect the quality of life. Countries like Bhutan have introduced the concept of Gross National Happiness (GNH) to guide decision-making. Others use happiness surveys to measure well-being alongside GDP. This shift reflects a broader understanding of what makes life meaningful.
Technology and social media have changed how people experience and evaluate happiness. On one hand, digital tools allow people to connect, share experiences, and access entertainment. On the other hand, constant exposure to others' curated lives can lead to unrealistic expectations, envy, and reduced self-esteem. Managing digital habits and focusing on real-life connections are important for emotional balance.
People often overestimate the impact of life events on long-term happiness. This phenomenon, known as hedonic adaptation, suggests that individuals quickly return to a baseline level of happiness after major changes, whether positive or negative. For example, people may feel happier immediately after winning the lottery or getting a promotion, but the emotional boost often fades as they adjust to the new situation.
To increase happiness, psychologists recommend practices such as gratitude, mindfulness, acts of kindness, and goal setting. Keeping a gratitude journal, meditating, helping others, or pursuing meaningful personal projects can significantly improve mood and life satisfaction. These activities promote positive emotions and a sense of purpose.
In conclusion, happiness is a complex and deeply personal experience influenced by internal and external factors. While genetics and circumstances play a role, much of our happiness depends on how we think, relate to others, and live our daily lives. By focusing on relationships, health, purpose, and gratitude, individuals and societies can build a more satisfying and fulfilling life.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to explain the nature of happiness, distinguish between hedonic and eudaimonic types, examine the various factors that influence it, and suggest practices that can increase happiness for individuals and societies.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is the difference between hedonic and eudaimonic happiness?',
        explanation: 'Hedonic happiness focuses on pleasure and the absence of pain through short-term gratification, while eudaimonic happiness relates to meaning, personal growth, and fulfillment from pursuing long-term goals, contributing to others, or developing talents.',
      ),
      ReadingQuestion(
        question: 'The word \'hedonic\' in the second paragraph most likely means...',
        explanation: 'Related to pleasure or short-term gratification. The passage defines hedonic happiness as focusing on pleasure and the absence of pain, involving experiences such as enjoying good food, entertainment, or relaxation.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of relationships in happiness?',
        explanation: 'Relationships are one of the strongest predictors of happiness because supportive connections provide emotional support, reduce stress, and create belonging; people with strong social bonds are happier and healthier than those who are isolated, and quality matters more than quantity.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does money affect happiness?',
        explanation: 'Financial stability increases happiness up to a point by reducing stress and meeting basic needs, but beyond a certain income level additional wealth has a limited effect, and a heavy focus on material success may lead to anxiety, comparison, or dissatisfaction.',
      ),
      ReadingQuestion(
        question: 'The phrase \'hedonic adaptation\' in the twelfth paragraph most likely means...',
        explanation: 'The tendency for people to quickly return to a baseline level of happiness after major positive or negative life changes, so that the emotional impact of events such as winning the lottery or getting a promotion often fades over time.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about cultural differences in happiness?',
        explanation: 'In individualistic cultures happiness is often linked to personal achievement and self-expression, whereas in collectivist cultures it is more closely tied to family harmony, social responsibility, and group belonging, affecting how people report and value happiness.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what practices do psychologists recommend to increase happiness?',
        explanation: 'Psychologists recommend practices such as gratitude, mindfulness, acts of kindness, and goal setting, including keeping a gratitude journal, meditating, helping others, or pursuing meaningful personal projects.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the relationship between health and happiness?',
        explanation: 'Physical and mental health significantly affect daily feelings and life satisfaction; chronic illness or mental health conditions can reduce happiness, while exercise, sleep, nutritious diet, mental health support, and stress management contribute to positive mood and well-being.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why have some governments begun to measure happiness?',
        explanation: 'Governments recognize that economic indicators alone do not fully reflect quality of life, so concepts such as Bhutan\'s Gross National Happiness and happiness surveys used alongside GDP reflect a broader understanding of what makes life meaningful.',
      ),
    ],
  ),

  ReadingPassage(
    id: 13,
    title: 'Success',
    topic: 'Personal Development',
    content: '''Success is the achievement of a desired goal or outcome, and it holds different meanings for different people. For some, success may be measured by wealth, status, or career accomplishments. For others, it might be defined by personal happiness, strong relationships, or a meaningful life. Regardless of the definition, success is often the result of effort, planning, and persistence.
Traditional views of success are often linked to education, employment, and income. In many societies, individuals are considered successful if they attend prestigious universities, obtain high-paying jobs, and accumulate material wealth. Media and advertising frequently reinforce these ideas by portraying success as luxury, fame, and power. While these external indicators can reflect achievement, they do not necessarily guarantee personal fulfillment.
Increasingly, people are redefining success in more personal and holistic terms. Emotional well-being, work-life balance, and a sense of purpose are now considered essential components. A person who earns less but finds joy and meaning in their work, or someone who prioritizes family and health over career advancement, may be seen as equally successful as a corporate executive or celebrity.
Success is influenced by a range of factors, including talent, opportunity, environment, and mindset. Natural ability can provide an advantage, but it is rarely sufficient on its own. Successful individuals often combine skills with hard work, resilience, and adaptability. They set goals, overcome setbacks, and continue improving themselves over time.
Mindset plays a critical role in achieving success. Psychologist Carol Dweck introduced the concept of the ―growth mindset‖—the belief that abilities and intelligence can be developed through effort and learning. People with a growth mindset are more likely to take on challenges, persist after failure, and view effort as a path to mastery. In contrast, a ―fixed mindset‖ assumes abilities are unchangeable, which may discourage risk-taking or personal growth.
Failure is often part of the journey to success. Many well-known figures—such as inventors, athletes, and entrepreneurs—experienced repeated failures before achieving their goals. Learning from mistakes and adjusting strategies is essential. In some cultures, however, failure is heavily stigmatized, making individuals afraid to try new things. Creating a supportive environment that encourages experimentation and accepts setbacks can foster long-term success.
Cultural background shapes how people define and pursue success. In individualistic cultures, success is often associated with personal achievement, independence, and self-promotion. In collectivist cultures, success may be viewed in terms of family honor, group harmony, and contribution to the community. These cultural values influence educational systems, parenting styles, and workplace expectations.
Education is commonly regarded as a key to success. It provides knowledge, skills, and credentials that open doors to job opportunities and social mobility. However, formal education is not the only path. Many successful individuals achieve their goals through apprenticeships, self-learning, or unconventional careers. In today‘s digital age, access to information and skill-building has become more democratized through online platforms.
Networking and social connections are also important. Knowing the right people can provide mentorship, open doors, and build support systems. Success is rarely achieved in isolation; collaboration, communication, and teamwork are vital in most professional and personal pursuits.
Technology and globalization have expanded the ways people can succeed. Remote work, online businesses, and digital platforms have created opportunities for individuals to build careers and reputations from almost anywhere. At the same time, increased competition and rapidly changing industries mean that adaptability and lifelong learning are more important than ever.
Health and well-being are often overlooked in discussions of success. Physical fitness, mental stability, and emotional resilience allow people to perform at their best. Burnout, anxiety, and poor health can undermine even the most impressive achievements. As a result, many people now seek success that includes not only professional goals but also a healthy and balanced lifestyle.
Measuring success can be challenging. External metrics—such as salary, awards, or job titles—are visible and easy to compare. However, internal satisfaction, peace of mind, and personal growth are harder to quantify but often more meaningful. Self-reflection and goal-setting can help individuals define success on their own terms.
Governments and institutions also promote success at a societal level. Public policies that support education, healthcare, and equal opportunity allow more individuals to reach their potential. Inequality, discrimination, or lack of access can prevent people from succeeding despite their talent and effort. Promoting fairness and inclusion is essential for creating a society where everyone has a chance to succeed.
In conclusion, success is a deeply personal and evolving concept. It involves not only achieving external goals but also finding meaning, balance, and satisfaction in life. While hard work, education, and connections all contribute, the most lasting success often comes from within—through purpose, resilience, and the ability to grow. By redefining success in broader, more inclusive terms, individuals and societies can create healthier, more fulfilling paths forward.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to explore the concept of success as a personal and evolving idea, contrasting traditional external measures with more holistic definitions, examining factors that influence success such as mindset, culture, education, and health, and emphasizing the value of internal fulfillment and inclusive opportunities.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how do traditional views often define success?',
        explanation: 'Traditional views link success to education, employment, and income; individuals are considered successful if they attend prestigious universities, obtain high-paying jobs, and accumulate material wealth, with media and advertising reinforcing images of luxury, fame, and power.',
      ),
      ReadingQuestion(
        question: 'The term "growth mindset" in the fifth paragraph most likely means',
        explanation: 'According to the passage, a growth mindset is the belief that abilities and intelligence can be developed through effort and learning; people with this mindset take on challenges, persist after failure, and view effort as a path to mastery.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of failure in achieving success?',
        explanation: 'It can be inferred that failure is a common and often necessary part of the path to success; many accomplished people experienced repeated failures, and learning from mistakes while adjusting strategies is essential, though cultural stigma around failure can discourage risk-taking.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how do individualistic and collectivist cultures differ in their views of success?',
        explanation: 'In individualistic cultures, success is associated with personal achievement, independence, and self-promotion, while in collectivist cultures it is viewed in terms of family honor, group harmony, and contribution to the community; these values affect education, parenting, and workplaces.',
      ),
      ReadingQuestion(
        question: 'The word "stigmatized" in the sixth paragraph most likely means',
        explanation: 'In the context of failure being "heavily stigmatized", the word means strongly disapproved of or marked by social disgrace, which makes people afraid to try new things.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the importance of health and well-being in relation to success?',
        explanation: 'It can be inferred that health and well-being are essential yet often overlooked elements of success; physical fitness, mental stability, and emotional resilience enable peak performance, while burnout and poor health can undermine achievements, leading many to seek a balanced lifestyle alongside professional goals.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is formal education not the only path to success?',
        explanation: 'While education provides knowledge, skills, and credentials that open doors, many successful people achieve goals through apprenticeships, self-learning, or unconventional careers, and digital platforms have further democratized access to information and skill-building.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about measuring success from the passage?',
        explanation: 'External metrics like salary, awards, or job titles are visible and easy to compare, but internal factors such as satisfaction, peace of mind, and personal growth are harder to quantify yet often more meaningful; self-reflection helps people define success on their own terms.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what role do governments and institutions play in promoting success?',
        explanation: 'They promote success at a societal level through public policies supporting education, healthcare, and equal opportunity, which help more people reach their potential; inequality or lack of access can block success despite talent, so fairness and inclusion are essential.',
      ),
    ],
  ),

  ReadingPassage(
    id: 14,
    title: 'Memory',
    topic: 'Health & Science',
    content: '''Memory is the mental ability to store, retain, and recall information. It plays a central role in everyday life, allowing humans to learn from experience, make decisions, and maintain relationships. Without memory, individuals would struggle to function, as even simple tasks like recognizing faces or finding one‘s way home rely on recalling past events or knowledge.
Psychologists generally divide memory into three main stages: encoding, storage, and retrieval. Encoding is the process of taking in information through the senses. Storage refers to maintaining that information over time. Retrieval is the act of accessing the stored information when needed. Problems in any of these stages can lead to forgetting or distorted memories.
Memory can also be categorized into different types. One of the most widely accepted models identifies sensory memory, short-term memory, and long-term memory. Sensory memory holds information for just a few seconds, like the brief image of a street sign seen while driving. Short-term memory, sometimes called working memory, allows individuals to hold and manipulate information temporarily—for example, remembering a phone number just long enough to dial it. Long-term memory stores information over extended periods and includes everything from childhood memories to the names of world capitals.
Long-term memory is further divided into explicit and implicit memory. Explicit memory involves conscious recall and includes two subtypes: episodic memory (personal experiences) and semantic memory (general knowledge and facts). Implicit memory, by contrast, refers to unconscious memories, such as riding a bicycle or typing on a keyboard—skills that become automatic over time. The brain structures involved in memory include the hippocampus, amygdala, and cerebral cortex. The hippocampus is essential for forming new long-term memories, while the amygdala plays a role in emotional memories. The cortex is involved in storing and retrieving information, especially in long-term storage. Damage to these areas, through injury or disease, can result in memory loss or impairment.
Aging affects memory, but not all aspects decline equally. While older adults may take longer to recall names or learn new tasks, many retain strong long-term memories and life experiences. Memory decline becomes more concerning when it interferes with daily activities, as seen in conditions like Alzheimer‘s disease or dementia, which are characterized by progressive memory loss and cognitive decline.
Stress, lack of sleep, and poor nutrition can also affect memory. Stress hormones like cortisol can interfere with the brain‘s ability to form and retrieve memories.
Sleep is critical for memory consolidation, a process in which newly learned information is stabilized in the brain. A healthy diet that supports brain function— rich in omega-3 fatty acids, antioxidants, and vitamins—is also beneficial for memory.
To improve memory, individuals can use various techniques. Mnemonics, such as acronyms or visual imagery, help encode information more effectively. Repetition and review strengthen neural connections, making retrieval easier. Chunking, or grouping related items together, allows the brain to process larger amounts of information. For example, breaking a long number into smaller parts makes it easier to remember.
Technology has influenced how people use memory. With smartphones, calendars, and search engines, people rely less on remembering facts and more on accessing information when needed. While these tools improve efficiency, some experts worry they may reduce mental effort and weaken memory skills over time. Cultural differences influence how people remember and value certain experiences. In Western cultures, memory is often personal and focused on individual experiences. In contrast, many Asian cultures emphasize collective memory and social context, focusing more on group events or shared narratives. These cultural frameworks affect how people recall and interpret the past. Memory is not always accurate. False memories—memories of events that never happened or that are distorted—can occur due to suggestion, imagination, or emotional influence. Research shows that memory is reconstructive, meaning that the brain fills in gaps based on expectations or related knowledge. This has important implications in areas like eyewitness testimony, where inaccurate memories can have serious consequences.
Memory also plays a key role in identity and learning. Personal memories give individuals a sense of self and continuity. Academic learning relies heavily on the ability to memorize facts and procedures. The ability to reflect on past experiences also supports personal growth and decision-making.
Emerging research in neuroscience and artificial intelligence seeks to understand and replicate memory. Scientists are exploring how memories are formed, stored, and retrieved at the molecular level, with the aim of developing treatments for memory disorders. Meanwhile, AI systems are being designed to mimic human memory processes, potentially enhancing learning tools or supporting people with cognitive impairments.
In conclusion, memory is a fundamental cognitive function that shapes how we live, learn, and relate to others. While it can be fragile and fallible, it is also adaptable and trainable. By understanding how memory works and what influences it, individuals can take steps to improve it, protect it, and use it more effectively in daily life.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage explains the stages, types, brain mechanisms, influences, improvement techniques, cultural aspects, and limitations of memory, concluding that it is a fundamental yet adaptable cognitive function.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are the three main stages of memory?',
        explanation: 'Psychologists divide memory into encoding (taking in information through the senses), storage (maintaining information over time), and retrieval (accessing stored information when needed).',
      ),
      ReadingQuestion(
        question: 'The word "consolidation" in the seventh paragraph most likely means',
        explanation: 'In context, consolidation refers to the process by which newly learned information is stabilized in the brain during sleep.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about implicit memory from the passage?',
        explanation: 'Implicit memory involves unconscious skills that become automatic over time, such as riding a bicycle or typing, and does not require conscious recall.',
      ),
      ReadingQuestion(
        question: 'According to the passage, which brain structure is essential for forming new long-term memories?',
        explanation: 'The hippocampus is essential for forming new long-term memories, while the amygdala handles emotional memories and the cortex stores and retrieves information.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the effects of aging on memory?',
        explanation: 'Aging does not affect all aspects of memory equally; older adults may recall names or learn new tasks more slowly but often retain strong long-term memories, with serious decline linked to conditions like Alzheimer\'s disease.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how can stress affect memory?',
        explanation: 'Stress hormones such as cortisol can interfere with the brain\'s ability to form and retrieve memories.',
      ),
      ReadingQuestion(
        question: 'The word "reconstructive" in the tenth paragraph most likely means',
        explanation: 'In context, reconstructive means that memory is not a perfect recording but involves the brain filling in gaps based on expectations or related knowledge, which can lead to false or distorted memories.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the impact of technology on memory skills?',
        explanation: 'Although smartphones and search engines improve efficiency by reducing the need to remember facts, some experts worry that reliance on them may decrease mental effort and weaken memory skills over time.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how do cultural differences influence memory?',
        explanation: 'Western cultures tend to focus on personal and individual experiences, whereas many Asian cultures emphasize collective memory, social context, group events, and shared narratives.',
      ),
    ],
  ),

  ReadingPassage(
    id: 15,
    title: 'Life Expectancy',
    topic: 'Health & Science',
    content: '''Life expectancy refers to the average number of years a person is expected to live, based on statistical analysis of current mortality rates. It is often used as a key indicator of a population‘s overall health and well-being. Life expectancy varies greatly across countries, regions, and social groups, influenced by a range of biological, social, economic, and environmental factors.
In recent centuries, global life expectancy has increased significantly. In the early 20th century, many countries had average life expectancies below 50 years. Thanks to improvements in sanitation, nutrition, medical care, and public health measures, people now live much longer. According to the World Health Organization (WHO), the global average life expectancy reached over 73 years in recent years, though the figure varies widely depending on location and income level.
Healthcare access is one of the most important factors influencing life expectancy. Populations with access to affordable and high-quality medical services—such as vaccinations, emergency care, and treatments for chronic diseases—tend to live longer. Countries with universal healthcare systems often have higher life expectancy, as preventive care and early diagnosis reduce the risk of fatal illnesses. Nutrition and clean water also play a critical role. Malnutrition weakens the immune system and increases vulnerability to disease, especially among children. Contaminated water sources can lead to deadly illnesses such as cholera and typhoid. Investments in clean water infrastructure and food security have helped reduce mortality rates in many developing countries.
Lifestyle choices significantly affect how long people live. Smoking, excessive alcohol consumption, poor diet, and lack of physical activity are associated with increased risks of heart disease, diabetes, cancer, and other non-communicable diseases. On the other hand, individuals who maintain a healthy weight, exercise regularly, and avoid harmful substances tend to live longer and enjoy better quality of life.
Education and income are strong predictors of life expectancy. More educated individuals are generally better informed about health practices, more likely to seek medical help, and more capable of navigating healthcare systems. Higher income provides access to nutritious food, safe housing, and healthcare. In contrast, poverty and low education are linked to shorter lifespans due to limited resources and opportunities.
Gender differences in life expectancy are notable. In almost every country, women tend to live longer than men. This is partly due to biological differences—such as hormonal and genetic factors—as well as behavioral patterns. Men are more likely to engage in risky behavior, work in dangerous occupations, and avoid medical checkups. However, women are more prone to certain chronic illnesses, and the gap in life expectancy may narrow in future generations.
Mental health and social connection also impact longevity. People with strong social networks and a sense of purpose are less likely to suffer from depression and anxiety, which can lead to poor physical health. Loneliness and social isolation, particularly among the elderly, are linked to higher rates of illness and early death.
Supportive communities, mental health care, and active lifestyles help mitigate these risks.
Infant and maternal mortality rates are closely tied to national life expectancy.
High rates of child mortality lower average life expectancy significantly. Improving maternal healthcare, prenatal services, and nutrition can dramatically increase survival rates and overall life expectancy in a population.
Environmental factors such as air pollution, climate change, and exposure to toxic substances also influence life expectancy. People living in polluted areas are at greater risk of respiratory diseases and other health problems. Climate-related disasters—such as heatwaves, floods, and droughts—can disrupt healthcare services and access to food and water, particularly in vulnerable communities.
Technological and medical advances continue to push the boundaries of human lifespan. New treatments, early disease detection, and personalized medicine offer promising avenues for extending life. Some researchers are exploring anti-aging therapies and genetic modifications aimed at slowing or reversing the aging process. However, ethical, social, and economic implications must be considered alongside scientific progress.
Despite the progress, life expectancy is not evenly distributed. People in lowincome or conflict-affected regions still face high mortality rates due to preventable diseases, violence, or lack of healthcare. The COVID-19 pandemic, for instance, temporarily reduced life expectancy in many countries by overwhelming health systems and causing millions of premature deaths.
Public policy plays a crucial role in determining life expectancy. Governments can promote longer, healthier lives by investing in healthcare, education, social welfare, and environmental protection. Policies that reduce inequality, ensure food and water security, and promote healthy behaviors contribute to better public health outcomes.
In conclusion, life expectancy is a valuable measure of societal health and progress. While it has increased significantly over time, achieving higher and more equitable life expectancy for all requires continued investment in healthcare, education, infrastructure, and social support. As science and society evolve, the challenge is not only to extend life, but to ensure that those added years are healthy, meaningful, and accessible to everyone.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage defines life expectancy, explains the factors that influence it (healthcare, nutrition, lifestyle, education, gender, mental health, environment, and policy), describes historical increases and ongoing disparities, and concludes that equitable gains require continued investment in health and social systems.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what was the global average life expectancy in recent years according to the WHO?',
        explanation: 'The passage states that according to the World Health Organization (WHO), the global average life expectancy reached over 73 years in recent years.',
      ),
      ReadingQuestion(
        question: 'The word "predictors" in the sentence about education and income most likely means',
        explanation: 'In context, "predictors" refers to factors that strongly indicate or forecast differences in life expectancy, as education and income are described as strong predictors linked to longer or shorter lifespans.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the relationship between gender and life expectancy?',
        explanation: 'The passage notes that women tend to live longer than men in almost every country due to biological and behavioral differences, but also states that women are more prone to certain chronic illnesses and that the gap may narrow in future generations.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how do lifestyle choices affect life expectancy?',
        explanation: 'The passage explains that smoking, excessive alcohol consumption, poor diet, and lack of physical activity increase risks of heart disease, diabetes, cancer, and other diseases, while healthy weight, regular exercise, and avoiding harmful substances are linked to longer life and better quality of life.',
      ),
      ReadingQuestion(
        question: 'The word "mitigate" in the discussion of mental health most likely means',
        explanation: 'In context, "mitigate" means to reduce or lessen the risks associated with loneliness and social isolation through supportive communities, mental health care, and active lifestyles.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the impact of infant and maternal mortality on national life expectancy?',
        explanation: 'The passage states that high rates of child mortality lower average life expectancy significantly, and that improving maternal healthcare, prenatal services, and nutrition can dramatically increase survival rates and overall life expectancy.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what role does public policy play in life expectancy?',
        explanation: 'The passage states that public policy plays a crucial role and that governments can promote longer, healthier lives by investing in healthcare, education, social welfare, and environmental protection, as well as by reducing inequality and ensuring food and water security.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the uneven distribution of life expectancy?',
        explanation: 'The passage notes that despite overall progress, people in low-income or conflict-affected regions still face high mortality rates due to preventable diseases, violence, or lack of healthcare, and that events like the COVID-19 pandemic temporarily reduced life expectancy in many countries.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is healthcare access important for life expectancy?',
        explanation: 'The passage explains that populations with access to affordable and high-quality medical services tend to live longer, and that countries with universal healthcare systems often have higher life expectancy because preventive care and early diagnosis reduce the risk of fatal illnesses.',
      ),
    ],
  ),

  ReadingPassage(
    id: 16,
    title: 'Hobbies',
    topic: 'Lifestyle & Well-being',
    content: '''Hobbies are activities that people engage in during their free time for enjoyment, relaxation, or personal development. They range widely—from physical activities like sports or gardening to creative pursuits such as painting, music, or writing. In today‘s fast-paced world, hobbies provide an important outlet for stress relief, selfexpression, and social connection.
The concept of hobbies is not new. Throughout history, people have spent their leisure time practicing crafts, playing musical instruments, or participating in local games. However, the modern idea of hobbies as structured, personal interests became popular during the industrial era, when shorter working hours allowed people more time for recreation. Today, hobbies are an essential part of a balanced lifestyle.
Hobbies contribute to mental and physical well-being. Engaging in a hobby helps individuals focus on something enjoyable, which can reduce anxiety, combat depression, and improve mood. For example, reading can stimulate the mind and expand knowledge, while playing an instrument may enhance concentration and emotional expression. Physical hobbies like swimming, hiking, or dancing also promote cardiovascular health and physical fitness.
Hobbies are also important for personal growth and skill development. Learning a new language, building models, or mastering photography can increase confidence and self-esteem. Hobbies encourage problem-solving, creativity, and patience— qualities that are transferable to academic or professional settings. In fact, many employers view hobbies as indicators of a well-rounded, motivated individual.
Social hobbies—such as joining a club, participating in team sports, or attending workshops—promote interaction and friendship. They offer a sense of community and belonging, particularly for people who may feel isolated. Shared interests often lead to meaningful conversations and lasting relationships. Even solitary hobbies, such as writing or painting, can be shared online, allowing individuals to connect with like-minded people across the globe.
Technology has expanded the possibilities for hobbies. With access to the internet, people can learn almost any skill through online tutorials, courses, or forums. Digital hobbies like blogging, video editing, coding, or gaming have become increasingly popular. These activities not only entertain but can also evolve into professional skills or sources of income. For instance, some people turn their photography or content creation hobbies into freelance careers or small businesses. Despite their benefits, hobbies are often overlooked due to busy schedules or academic pressure. In many societies, people prioritize work and productivity, leaving little time for leisure activities. Students, in particular, may face pressure to focus solely on grades and exams, neglecting hobbies that could reduce stress and support overall development. Encouraging time for hobbies is essential for maintaining mental balance and preventing burnout.
Children and teenagers benefit greatly from hobbies. Activities like drawing, puzzles, team sports, or music lessons support cognitive and emotional development. They help young people discover their interests and talents, develop discipline, and build self-confidence. Schools and parents can play a role in introducing children to a variety of activities, allowing them to explore different paths before choosing what suits them best.
Retired individuals also find great value in hobbies. As people age and leave the workforce, hobbies provide purpose and routine. They combat loneliness, maintain mental sharpness, and keep older adults engaged in meaningful ways. Gardening, knitting, volunteering, or participating in community groups are popular pastimes among the elderly.
In some cases, hobbies cross the line between leisure and livelihood. What begins as a simple interest can develop into a part-time job or full-time career. Writers, musicians, designers, or even gamers may start with a passion and eventually earn income from it. While turning a hobby into a profession can be rewarding, it also changes the nature of the activity, potentially introducing stress and deadlines that reduce enjoyment.
Cultural factors influence the types of hobbies people pursue. In colder climates, indoor hobbies like board games, crafts, or cooking are more common. In warmer regions, people may prefer outdoor activities such as cycling or surfing. In some cultures, traditional arts or group activities play a significant role, while in others, individual hobbies are more popular. Socioeconomic status also affects access to certain hobbies, especially those requiring expensive equipment or training.
Environmental awareness has led to a rise in sustainable hobbies. Activities like upcycling, eco-gardening, and crafting with recycled materials allow people to enjoy leisure time while contributing to environmental conservation. These hobbies align personal enjoyment with social responsibility, creating a deeper sense of fulfillment.
In conclusion, hobbies are more than just a way to pass time—they are a valuable part of a healthy, fulfilling life. They support emotional well-being, skill development, and social interaction across all age groups. Despite busy lifestyles, making time for hobbies can enhance happiness, reduce stress, and improve overall quality of life. In a world full of demands and distractions, hobbies offer a unique space for creativity, relaxation, and personal enrichment.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to explain the value of hobbies for enjoyment, well-being, personal growth, and social connection across different ages and cultures, while noting challenges in finding time for them and their potential to become careers.',
      ),
      ReadingQuestion(
        question: 'According to the passage, when did the modern idea of hobbies as structured personal interests become popular?',
        explanation: 'The modern idea of hobbies as structured, personal interests became popular during the industrial era, when shorter working hours allowed people more time for recreation.',
      ),
      ReadingQuestion(
        question: 'The word "outlet" in the first paragraph most likely means...',
        explanation: 'In the context of the passage, "outlet" means a means of release or expression for stress, self-expression, and social connection.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the relationship between hobbies and employment?',
        explanation: 'It can be inferred that hobbies can indicate a well-rounded and motivated individual to employers, and that some hobbies may evolve into professional skills, freelance careers, or small businesses.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how do social hobbies benefit people?',
        explanation: 'Social hobbies promote interaction and friendship, offer a sense of community and belonging, particularly for those who feel isolated, and can lead to meaningful conversations and lasting relationships.',
      ),
      ReadingQuestion(
        question: 'The word "burnout" in the sixth paragraph most likely means...',
        explanation: 'In the context of the passage, "burnout" refers to a state of physical or mental exhaustion caused by prolonged stress, which can be prevented by making time for hobbies.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about hobbies for retired individuals?',
        explanation: 'It can be inferred that hobbies help retired people maintain purpose, routine, mental sharpness, and social engagement after leaving the workforce, combating loneliness in older age.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is a potential downside of turning a hobby into a profession?',
        explanation: 'Turning a hobby into a profession can introduce stress and deadlines that reduce the original enjoyment of the activity.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the influence of culture and climate on hobbies?',
        explanation: 'It can be inferred that climate affects preferred activities (indoor in colder regions, outdoor in warmer ones) and that cultural values shape whether traditional group arts or individual hobbies are more common.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how have environmental concerns affected hobbies?',
        explanation: 'Environmental awareness has led to a rise in sustainable hobbies such as upcycling, eco-gardening, and crafting with recycled materials, which combine personal enjoyment with contributions to conservation.',
      ),
    ],
  ),

  ReadingPassage(
    id: 17,
    title: 'Music',
    topic: 'Arts & Culture',
    content: '''Music is a universal form of human expression that exists in every culture around the world. It can communicate emotions, tell stories, and bring people together, regardless of language or background. From ancient tribal rhythms to modern digital production, music has evolved over time but continues to play a vital role in society.
The origins of music date back thousands of years. Archaeologists have discovered ancient instruments made from bones, wood, and animal skins, suggesting that early humans used music in rituals, celebrations, and daily life. Over time, music developed into more complex forms, influenced by geography, religion, and social structure. In many cultures, music was closely connected to storytelling, dance, and spiritual practices.
One of the most powerful features of music is its emotional impact. Music can express joy, sadness, fear, hope, or nostalgia. A slow melody in a minor key may evoke sorrow, while a fast, upbeat rhythm can generate excitement. Because music engages multiple parts of the brain—memory, emotion, motor skills—it has the unique ability to influence mood and behavior. It is often used in therapy to help people manage stress, recover from trauma, or improve mental health.
Cultural identity is closely linked to music. Each society has its own musical traditions, instruments, and styles that reflect its values and history. For example, traditional Chinese music uses instruments like the guzheng and erhu, while African drumming emphasizes rhythm and community participation. Music also plays an important role in religious ceremonies, national celebrations, and rites of passage such as weddings or funerals.
With globalization and technology, music has become more diverse and accessible than ever. The rise of the internet and streaming platforms allows people to explore a wide variety of genres—from classical and jazz to hip-hop, pop, and electronic music. Musicians can now reach global audiences without needing a major record label, and listeners can discover artists from different countries with just a few clicks.
Despite this diversity, some critics argue that commercial music has become repetitive and formulaic, focusing more on profit than creativity. Pop music, in particular, is often produced to appeal to mass audiences, sometimes at the cost of originality or cultural depth. However, independent artists and niche genres continue to push boundaries and explore new sounds, keeping the music world vibrant and dynamic.
Learning music has cognitive and emotional benefits, especially for children. Studies show that playing an instrument improves memory, attention, and problem-solving skills. It also enhances coordination and discipline, as regular practice is essential to improvement. Music education encourages self-expression and collaboration, whether through solo performance or group ensembles like orchestras or choirs.
Schools that include music programs often report better academic performance and higher student engagement. Yet, in many countries, arts education—including music—is underfunded or overlooked. Advocates argue that music is not a luxury, but a vital part of a well-rounded education. Access to music instruction can inspire creativity and build confidence in young people.
Technology has transformed how music is created and consumed. Digital audio workstations, synthesizers, and mobile apps make it possible for anyone to compose, mix, and publish music from home. Sampling, remixing, and electronic production have given rise to new genres like EDM (electronic dance music) and lo-fi hip hop. While traditional music skills are still important, today‘s musicians must also understand software, social media, and digital marketing to succeed. Live performances remain a key part of music culture. Concerts, festivals, and street performances provide opportunities for shared experience and cultural exchange. The energy of a live show—complete with sound, visuals, and audience participation—creates a connection between performer and listener that digital music often lacks. During the COVID-19 pandemic, virtual concerts and livestreams became popular alternatives, showing the music industry‘s ability to adapt.
Music also plays a significant role in social and political movements. Protest songs, national anthems, and freedom chants have united people and expressed collective hopes or frustrations. From civil rights marches in the United States to anti-apartheid rallies in South Africa, music has helped mobilize communities and give voice to the oppressed. It continues to serve as a form of resistance and empowerment.
The business of music is a massive global industry, generating billions in revenue each year. While streaming services have made music more accessible, they have also changed how artists earn income. Album sales have declined, and musicians now rely more on live shows, merchandise, sponsorships, and online platforms to support their careers. Intellectual property and copyright issues remain hot topics in the digital age, as artists strive to protect their work in a rapidly changing market.
In conclusion, music is an essential aspect of human life, offering entertainment, emotional expression, cultural identity, and social unity. It adapts across time and technology, bridging generations and geographies. Whether enjoyed in solitude or shared in a crowd, music has the power to inspire, heal, and connect. As technology and society continue to evolve, so too will the role of music in shaping how we experience the world.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to explore music as a universal form of human expression, covering its origins, emotional and cultural roles, benefits, technological changes, social impact, and ongoing significance in society.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what evidence suggests that early humans used music?',
        explanation: 'According to the passage, archaeologists have discovered ancient instruments made from bones, wood, and animal skins, suggesting that early humans used music in rituals, celebrations, and daily life.',
      ),
      ReadingQuestion(
        question: 'The word "evoke" in the third paragraph most likely means',
        explanation: 'In the context of the third paragraph, "evoke" means to bring forth or produce a feeling or response, as a slow melody in a minor key may evoke sorrow.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the relationship between music and the brain?',
        explanation: 'It can be inferred that music has a unique ability to influence mood and behavior because it engages multiple parts of the brain, including those responsible for memory, emotion, and motor skills.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how has technology affected access to music?',
        explanation: 'According to the passage, the rise of the internet and streaming platforms has made music more diverse and accessible, allowing people to explore many genres and enabling musicians to reach global audiences without a major record label.',
      ),
      ReadingQuestion(
        question: 'The word "formulaic" in the sixth paragraph most likely means',
        explanation: 'In the context of the sixth paragraph, "formulaic" means following a set pattern or formula in a repetitive way, referring to commercial music that focuses more on profit than originality or creativity.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the value of music education in schools?',
        explanation: 'It can be inferred that music education is considered vital rather than a luxury, as schools with music programs often report better academic performance and higher student engagement, and access to instruction can inspire creativity and build confidence.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what additional skills must today‘s musicians understand to succeed?',
        explanation: 'According to the passage, while traditional music skills remain important, today‘s musicians must also understand software, social media, and digital marketing to succeed.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of music in social and political movements?',
        explanation: 'It can be inferred that music serves as a powerful tool for uniting people, expressing collective hopes or frustrations, mobilizing communities, and giving voice to the oppressed, acting as a form of resistance and empowerment.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how have streaming services changed the way artists earn income?',
        explanation: 'According to the passage, while streaming services have made music more accessible, album sales have declined, and musicians now rely more on live shows, merchandise, sponsorships, and online platforms to support their careers.',
      ),
    ],
  ),

  ReadingPassage(
    id: 18,
    title: 'Sport',
    topic: 'Sports & Society',
    content: '''Sport refers to physical activities that involve skill, competition, and often teamwork. It plays a significant role in societies across the world, offering benefits that go beyond physical fitness. From local community matches to global tournaments like the Olympics or the World Cup, sport brings people together, promotes national pride, and influences culture, economy, and education.
One of the primary benefits of sport is its positive effect on physical health. Regular participation in sports improves cardiovascular function, strengthens muscles and bones, and helps maintain a healthy weight. It also lowers the risk of chronic diseases such as diabetes, heart disease, and certain types of cancer. Children and teenagers who are active in sports often grow up with better physical coordination, flexibility, and overall health.
In addition to physical benefits, sport contributes greatly to mental and emotional well-being. Exercise releases chemicals in the brain like endorphins and serotonin, which help reduce stress, anxiety, and depression. Team sports also teach important life skills, such as communication, leadership, resilience, and discipline. For many people, sport offers a productive outlet for emotional energy and a structured way to develop confidence.
Sport also plays a crucial role in education. Many schools include sports as part of the curriculum, not just for health purposes but also to encourage teamwork and time management. Student athletes often perform better academically because they learn to balance practice with study. In some countries, scholarships allow talented students to access higher education through sport, giving them new opportunities for advancement.
At the professional level, sport is a global industry. Athletes, coaches, advertisers, and media companies generate billions in revenue through events, sponsorships, broadcasting rights, and merchandise. Football, basketball, cricket, tennis, and other popular sports attract massive audiences both in stadiums and online. With the rise of digital platforms, fans can now follow their favorite teams and players from anywhere in the world.
National and international sporting events promote unity and diplomacy. The Olympics, for instance, bring together athletes from diverse backgrounds to compete in a spirit of fairness and cooperation. Such events often foster a sense of national pride and shared identity. Governments may invest heavily in hosting tournaments to boost tourism, create jobs, and showcase their country's image on the world stage.
However, sport is not without challenges. One of the major issues is inequality and lack of access. In many regions, girls and women have fewer opportunities to participate in sports due to cultural norms, lack of funding, or safety concerns. People with disabilities also face barriers, despite progress made through events like the Paralympics. Addressing these gaps requires inclusive policies, investment in facilities, and changing societal attitudes.
Doping and corruption are additional concerns in professional sports. The use of performance-enhancing drugs undermines the fairness of competition and can damage the reputation of entire sports. Despite strict regulations, some athletes and teams still engage in unethical practices to gain an advantage. Anti-doping agencies and international sporting bodies work to detect violations and maintain integrity in competitions.
Injury risk is another drawback of sport, especially in contact sports like rugby or boxing. Athletes face the possibility of long-term damage to joints, muscles, or even the brain. Proper training, safety gear, and medical supervision are essential to minimize risks. In recent years, growing attention has been paid to the long-term health of retired athletes and the need for better aftercare.
Commercialization has also raised ethical questions about the role of money in sport. Top athletes earn millions, and some competitions are driven more by profit than by the spirit of the game. Critics argue that excessive sponsorship and advertising may overshadow the values of fair play and sportsmanship. Balancing business interests with integrity remains a challenge for the sports industry.
Despite these issues, sport continues to be a powerful tool for social change. Programs that use sport to engage youth, promote gender equality, or support refugees have been successful in many parts of the world. Sport can bridge differences, teach conflict resolution, and provide a positive path for individuals at risk of violence or exclusion.
The rise of technology in sport has changed how games are played, watched, and analyzed. Instant replays, goal-line technology, and wearable fitness trackers have improved fairness and performance. Data analysis helps coaches make informed decisions, while fans enjoy interactive experiences through virtual reality and social media. However, some argue that too much technology may reduce the human element of the game.
In conclusion, sport is much more than physical activity. It is a global phenomenon that affects health, education, culture, and the economy. While challenges such as inequality, doping, and commercialization persist, the benefits of sport are undeniable. It promotes discipline, unity, and personal growth, making it an essential part of both individual lives and societies. Supporting inclusive, fair, and ethical sports systems is key to ensuring that the positive impact of sport continues into the future.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to describe the wide-ranging benefits of sport for physical health, mental well-being, education, the economy, and social unity, while also examining challenges such as inequality, doping, injury risk, and commercialization, and concluding that sport is a powerful global phenomenon whose positive impact depends on inclusive, fair, and ethical systems.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are some physical health benefits of regular participation in sports?',
        explanation: 'According to the passage, regular participation in sports improves cardiovascular function, strengthens muscles and bones, helps maintain a healthy weight, and lowers the risk of chronic diseases such as diabetes, heart disease, and certain types of cancer. Children and teenagers who are active in sports often grow up with better physical coordination, flexibility, and overall health.',
      ),
      ReadingQuestion(
        question: 'The word "endorphins" in the third paragraph most likely refers to',
        explanation: 'In the third paragraph, "endorphins" refers to chemicals released in the brain by exercise that help reduce stress, anxiety, and depression, alongside serotonin.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about student athletes from the passage?',
        explanation: 'It can be inferred that student athletes often perform better academically because they learn to balance practice with study, and that sports in schools encourage teamwork and time management in addition to health benefits; in some countries, scholarships also allow talented students to access higher education through sport.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how do national and international sporting events promote unity and diplomacy?',
        explanation: 'According to the passage, national and international sporting events such as the Olympics bring together athletes from diverse backgrounds to compete in a spirit of fairness and cooperation, foster a sense of national pride and shared identity, and may lead governments to invest in hosting tournaments to boost tourism, create jobs, and showcase their country\'s image.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about inequality in sport?',
        explanation: 'It can be inferred that inequality and lack of access remain major issues, as girls and women in many regions have fewer opportunities due to cultural norms, lack of funding, or safety concerns, and people with disabilities also face barriers despite progress through events like the Paralympics; addressing these gaps requires inclusive policies, investment in facilities, and changing societal attitudes.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what undermines the fairness of competition in professional sports?',
        explanation: 'According to the passage, the use of performance-enhancing drugs undermines the fairness of competition and can damage the reputation of entire sports, even though anti-doping agencies and international sporting bodies work to detect violations and maintain integrity.',
      ),
      ReadingQuestion(
        question: 'The phrase "commercialization" in the passage most likely refers to',
        explanation: 'In the context of the passage, "commercialization" refers to the increasing role of money in sport, where top athletes earn millions, some competitions are driven more by profit than by the spirit of the game, and excessive sponsorship and advertising may overshadow the values of fair play and sportsmanship.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of technology in sport?',
        explanation: 'It can be inferred that technology has improved fairness and performance through tools like instant replays, goal-line technology, and wearable fitness trackers, helps coaches make informed decisions via data analysis, and gives fans interactive experiences, though some argue that too much technology may reduce the human element of the game.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is supporting inclusive, fair, and ethical sports systems important?',
        explanation: 'According to the passage, supporting inclusive, fair, and ethical sports systems is key to ensuring that the positive impact of sport—on health, education, culture, the economy, discipline, unity, and personal growth—continues into the future, despite ongoing challenges such as inequality, doping, and commercialization.',
      ),
    ],
  ),

  ReadingPassage(
    id: 19,
    title: 'Sportsmanship',
    topic: 'Sports & Ethics',
    content: '''Sportsmanship refers to the ethical and respectful behavior expected of individuals involved in sports, whether they are athletes, coaches, officials, or spectators. It involves fair play, respect for opponents, graciousness in winning or losing, and a commitment to the values that sport is meant to promote. Good sportsmanship not only enhances the experience of competition but also teaches lessons that extend far beyond the playing field.
At its core, sportsmanship is about respect—respect for the rules, for teammates and opponents, for referees, and for the game itself. It emphasizes honesty, selfcontrol, and humility. A player who admits a fault, congratulates an opponent, or helps someone who is injured demonstrates sportsmanship. Such actions show character and maturity and are widely admired both in amateur and professional sports.
Sportsmanship is often tested in moments of high emotion—particularly in defeat or controversy. True sportsmanship is seen when individuals maintain dignity during loss, avoid blaming others, and continue to behave with integrity even when the outcome is unfavorable. Conversely, poor sportsmanship may involve cheating, arguing with officials, taunting opponents, or reacting aggressively. These behaviors not only damage the spirit of competition but can also negatively influence younger audiences.
Youth sports play a crucial role in teaching sportsmanship. Children and teenagers are at a stage where they are forming habits and values. Coaches and parents have a responsibility to model respectful behavior and encourage fair play over winning at all costs. In environments where winning is excessively emphasized, young athletes may feel pressured to cheat or act aggressively. Instead, emphasizing effort, improvement, and teamwork helps build positive character traits.
In professional sports, where high stakes and public attention are involved, examples of both good and bad sportsmanship are frequently on display. When well-known athletes demonstrate humility and generosity—such as helping an injured opponent or acknowledging a competitor‘s skills—it inspires millions. On the other hand, scandals involving doping, match-fixing, or unsportsmanlike conduct can tarnish a sport‘s reputation and undermine public trust.
The concept of sportsmanship is also closely linked to ethics in competition. Playing by the rules is not only a matter of legality but of fairness. Cheating may bring short-term success, but it undermines the value of sport and can lead to serious consequences, including disqualification, loss of sponsorships, and damage to an athlete‘s legacy. Upholding ethical standards protects the credibility and integrity of sports.
Cultural perspectives on sportsmanship may vary. In some countries, showing emotion or strong competitive spirit is valued, while in others, modesty and restraint are emphasized. Nevertheless, the core idea of treating others with fairness and respect remains universal. International sporting events, such as the Olympics, promote these shared values by highlighting unity, respect, and peaceful competition.
Sportsmanship among spectators is also important. Fans who cheer positively, accept decisions, and show respect for both teams contribute to a healthy and enjoyable environment. Unfortunately, poor fan behavior—such as booing, insulting players, or inciting violence—can ruin the experience for everyone and even escalate into dangerous situations. Organizers, clubs, and communities must work together to promote respectful behavior among fans.
The media has a powerful role in shaping public attitudes toward sportsmanship. When acts of respect and kindness are celebrated, they set a positive example for audiences. When unethical behavior is glorified or excused, it sends the wrong message—especially to young viewers. Broadcasters, journalists, and influencers should highlight values like honesty, humility, and teamwork alongside athletic achievement.
Sportsmanship is not limited to the playing field. The values it promotes—respect, integrity, and fairness—are essential in everyday life. People who practice sportsmanship in sports often carry these values into their studies, workplaces, and relationships. For example, learning to accept failure, work with others, and show empathy are all traits that contribute to personal and professional success.
Promoting sportsmanship requires effort from multiple stakeholders:
•                  Coaches and educators must teach and model respectful behavior.
•                  Parents should emphasize enjoyment and effort over results.
•                  Sports organizations must enforce rules and promote ethical conduct.
•                  Athletes must take personal responsibility for their actions and attitudes. Some countries and schools have introduced awards for sportsmanship, recognizing players who demonstrate outstanding character, regardless of performance or results. These awards help shift focus away from winning alone and towards how the game is played.
In the digital era, social media has become a platform where sportsmanship is both praised and criticized. A single act of generosity or misconduct can go viral, influencing public opinion and shaping athletes‘ reputations. This online visibility increases the responsibility of athletes and teams to act thoughtfully and ethically at all times.
In conclusion, sportsmanship is a fundamental aspect of sport that promotes fairness, respect, and ethical behavior. It enhances the spirit of competition and helps build character in athletes and fans alike. In a world often focused on winning, sportsmanship reminds us that how we play the game is just as important as the result. By nurturing these values at every level—from schoolyards to stadiums—sports can continue to be a positive force in individual lives and global society.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to define sportsmanship as ethical and respectful behavior in sports, explain its importance for athletes, coaches, spectators, and society, discuss how it is taught and tested, and emphasize that how the game is played matters as much as the result.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what does sportsmanship involve at its core?',
        explanation: 'According to the passage, at its core sportsmanship is about respect—for the rules, teammates and opponents, referees, and the game itself—and it emphasizes honesty, self-control, and humility.',
      ),
      ReadingQuestion(
        question: 'The word "graciousness" in the first paragraph most likely means',
        explanation: 'In the context of the passage, "graciousness" most likely means showing kindness, courtesy, and good manners when winning or losing, as the text links it to respectful behavior and fair play in sports.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of coaches and parents in youth sports?',
        explanation: 'It can be inferred that coaches and parents have a responsibility to model respectful behavior and prioritize fair play, effort, improvement, and teamwork over winning at all costs, because excessive emphasis on winning can pressure young athletes to cheat or act aggressively.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are some examples of poor sportsmanship?',
        explanation: 'According to the passage, poor sportsmanship may involve cheating, arguing with officials, taunting opponents, or reacting aggressively, and these behaviors damage the spirit of competition and can negatively influence younger audiences.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the consequences of cheating in sports?',
        explanation: 'It can be inferred that while cheating may bring short-term success, it undermines the value of sport and can lead to serious long-term consequences such as disqualification, loss of sponsorships, and damage to an athlete\'s legacy.',
      ),
      ReadingQuestion(
        question: 'The word "tarnish" in the paragraph about professional sports most likely means',
        explanation: 'In the context of the passage, "tarnish" most likely means to damage or harm the reputation of a sport, as the text states that scandals involving doping, match-fixing, or unsportsmanlike conduct can tarnish a sport\'s reputation and undermine public trust.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does the media influence attitudes toward sportsmanship?',
        explanation: 'According to the passage, the media has a powerful role: celebrating acts of respect and kindness sets a positive example, while glorifying or excusing unethical behavior sends the wrong message, especially to young viewers. Broadcasters, journalists, and influencers should highlight honesty, humility, and teamwork.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about sportsmanship beyond the playing field?',
        explanation: 'It can be inferred that the values of respect, integrity, and fairness promoted by sportsmanship are useful in everyday life, as people who practice them in sports often carry these traits into their studies, workplaces, and relationships, aiding personal and professional success.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why have some countries and schools introduced awards for sportsmanship?',
        explanation: 'According to the passage, some countries and schools have introduced awards for sportsmanship to recognize players who demonstrate outstanding character regardless of performance or results, helping to shift focus away from winning alone and toward how the game is played.',
      ),
    ],
  ),

  ReadingPassage(
    id: 20,
    title: 'Sporting Events',
    topic: 'Sports & Society',
    content: '''Sporting events are organized competitions where athletes or teams compete in various disciplines, often in front of live audiences or broadcast to millions. These events range from local school tournaments to global spectacles like the Olympic Games, the FIFA World Cup, and the Super Bowl. They are not only about athletic performance but also about entertainment, national pride, economic impact, and cultural exchange.
Large-scale sporting events serve multiple purposes. Firstly, they showcase talent and human achievement. Athletes from around the world train for years to compete at the highest levels. These events offer them a platform to test their abilities, break records, and represent their countries. Moments of victory or defeat often become part of national memory, inspiring future generations.
Secondly, major sporting events promote unity and cultural exchange. International competitions bring people from different countries and backgrounds together. Spectators cheer for their teams, celebrate national identity, and often learn about other cultures in the process. The Olympic Games, for example, emphasize peace and cooperation, as athletes compete under shared values and mutual respect.
Sporting events also have significant economic impact. Hosting a major event can boost local economies through tourism, job creation, and infrastructure development. Hotels, restaurants, transport systems, and entertainment venues all benefit from the influx of visitors. However, these benefits depend on careful planning and management. Poorly managed events may lead to debt and underused facilities once the games are over.
Media and broadcasting play a central role in the reach and popularity of sporting events. Millions of viewers tune in to watch matches live, while highlights, interviews, and analysis are shared across television, radio, and social media. This global exposure attracts sponsors and advertisers who invest heavily in branding and promotion. Top events generate billions in revenue from broadcasting rights and commercial partnerships.
In addition to professional competitions, community-level sporting events also play a vital role. Local school sports days, amateur leagues, and charity tournaments bring neighbors together and encourage grassroots participation. These events help promote fitness, teamwork, and community pride. They often serve as stepping stones for future professional athletes.
Despite their many advantages, sporting events also face challenges and criticisms. One issue is the cost of hosting, especially for developing countries. Building stadiums, improving infrastructure, and meeting international standards can strain national budgets. In some cases, money spent on sports could arguably be better used for health, education, or social programs.
Corruption and mismanagement are other concerns. There have been cases where bidding processes for hosting rights were influenced by bribery or political pressure. Organizers may also face criticism for poor planning, safety issues, or lack of transparency. These problems damage the reputation of international sports and discourage public trust.
Another controversy relates to the environmental impact of large-scale events. Constructing facilities, flying in participants and fans, and producing large amounts of waste can harm ecosystems and increase carbon emissions. To address these concerns, some event organizers now implement sustainable practices, such as using renewable energy, encouraging public transport, and recycling materials. Security and crowd management are crucial for the success of any large sporting event. With massive gatherings of people, the risk of accidents, violence, or terrorism must be taken seriously. Organizers work closely with law enforcement to ensure safety through surveillance, emergency planning, and strict access control. Although necessary, heavy security can also raise concerns about privacy and civil liberties.
Another significant issue is fairness and inclusion. Discrimination based on gender, disability, or nationality has historically excluded certain groups from full participation. Over time, progress has been made. Events like the Paralympic Games and the Women‘s World Cup have expanded opportunities for marginalized athletes. Nonetheless, ongoing efforts are needed to ensure equal representation and respect for all participants.
Technology is reshaping the experience of sporting events. High-definition cameras, instant replay, and virtual reality provide fans with immersive experiences. Online ticketing, apps, and live statistics enhance engagement. For athletes, data analytics and wearable tech improve performance and reduce injury risk. However, technology also raises questions—such as whether video refereeing disrupts the flow of a game or replaces human judgment.
Spectator behavior is another important factor. While most fans support their teams positively, some events have been marred by racism, violence, or offensive chants.
Promoting respectful behavior through education, strict rules, and social campaigns is essential to maintaining the spirit of sportsmanship.
In recent years, eSports (electronic sports) have emerged as a new kind of sporting event. Competitions in video games like Dota 2 or League of Legends attract huge audiences, with professional players and large cash prizes. While some debate whether eSports count as "real" sports, there is no doubt they share many features with traditional competitions: skill, training, strategy, and fan engagement.
In conclusion, sporting events are much more than games—they are cultural, economic, and social phenomena. When well-managed, they inspire excellence, foster unity, and boost development. At the same time, challenges related to cost, fairness, and sustainability must be addressed. As the world changes, sporting events will continue to evolve, offering opportunities not only for athletes but for entire communities and nations to come together.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage examines sporting events as cultural, economic, and social phenomena, discussing their benefits in showcasing talent, promoting unity, and boosting economies, while also addressing challenges such as costs, corruption, environmental impact, fairness, and the rise of eSports.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what economic benefits can hosting a major sporting event provide?',
        explanation: 'Hosting can boost local economies through tourism, job creation, and infrastructure development, benefiting hotels, restaurants, transport systems, and entertainment venues from the influx of visitors, though benefits depend on careful planning and management.',
      ),
      ReadingQuestion(
        question: 'The word "grassroots" in the paragraph about community-level events most likely means',
        explanation: 'It refers to basic or local-level participation starting from ordinary community members, as community sporting events encourage grassroots participation that promotes fitness, teamwork, and community pride and can lead to future professional athletes.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the potential drawbacks of hosting major sporting events in developing countries?',
        explanation: 'The high costs of building stadiums, improving infrastructure, and meeting international standards can strain national budgets, and money spent on sports might arguably be better used for health, education, or social programs, sometimes leading to debt and underused facilities.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how do major sporting events promote cultural exchange?',
        explanation: 'International competitions bring people from different countries and backgrounds together; spectators celebrate national identity while learning about other cultures, and events like the Olympic Games emphasize peace, cooperation, shared values, and mutual respect.',
      ),
      ReadingQuestion(
        question: 'The word "immersive" in the paragraph about technology most likely means',
        explanation: 'It means deeply engaging or providing a sense of being fully involved in the experience, as high-definition cameras, instant replay, and virtual reality are said to provide fans with immersive experiences.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of media in sporting events?',
        explanation: 'Media and broadcasting greatly expand the reach and popularity of events by allowing millions to watch live and share highlights, interviews, and analysis across platforms, which attracts sponsors and advertisers and generates billions in revenue from broadcasting rights and commercial partnerships.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what progress has been made regarding fairness and inclusion in sporting events?',
        explanation: 'Although discrimination based on gender, disability, or nationality historically excluded certain groups, progress includes events like the Paralympic Games and the Women\'s World Cup that have expanded opportunities for marginalized athletes, though ongoing efforts are still needed for equal representation and respect.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about eSports from the passage?',
        explanation: 'eSports have emerged as a new form of sporting event with professional players, large cash prizes, and huge audiences for games like Dota 2 or League of Legends; despite debate over whether they count as "real" sports, they share key features with traditional competitions such as skill, training, strategy, and fan engagement.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is security important at large sporting events, and what concern does it raise?',
        explanation: 'With massive gatherings, the risks of accidents, violence, or terrorism require organizers to work with law enforcement on surveillance, emergency planning, and strict access control; however, heavy security can also raise concerns about privacy and civil liberties.',
      ),
    ],
  ),

  ReadingPassage(
    id: 21,
    title: 'Fashion and Clothing',
    topic: 'Society & Culture',
    content: '''Fashion is not just about what people wear. It is a dynamic cultural and economic force that reflects identity, values, and social trends. Clothing choices can express personality, group belonging, and even political views. From high-end designer brands to fast fashion outlets, what people wear often says more about them than words ever could.
Throughout history, fashion has played a central role in defining eras and societies. In ancient civilizations, clothing indicated status and function. Royalty wore elaborate garments made from expensive materials, while commoners had simple, practical attire. During the Renaissance, fashion in Europe was driven by nobility and used to display wealth and taste. Today, although class distinctions remain, the fashion industry has become more democratized, with trends spreading quickly through media and online platforms.
One reason people care so much about fashion is that clothing helps construct personal identity. Teenagers, for example, often choose styles that reflect their subcultures—whether that‘s punk, skater, minimalist, or vintage. Adults may use clothing to appear professional, confident, or creative. Even subtle changes—like wearing glasses, a watch, or a certain color—can shape how others perceive someone.
The influence of globalization has created a fashion landscape that blends styles from around the world. Traditional clothing like the Japanese kimono or the Indian sari is now worn with modern twists, and Western trends influence streetwear in Asia, Africa, and Latin America. However, this has also led to the problem of cultural appropriation, where fashion brands borrow elements of other cultures without understanding their meaning, often for commercial gain.
The rise of fast fashion has completely transformed how people consume clothing. Brands such as Zara, H&M, and Shein produce low-cost, trendy items at lightning speed, releasing new collections weekly. This makes fashionable clothing accessible to the average consumer. However, the environmental and ethical costs are severe. Fast fashion encourages overconsumption, and millions of garments end up in landfills each year. Factories often exploit workers in developing countries, paying extremely low wages and operating in unsafe conditions. In response, sustainable fashion is becoming more popular. Consumers are increasingly aware of how their buying habits affect the environment. Many now prefer to buy second-hand clothes, choose eco-friendly brands, or wear garments made from organic or recycled materials. Social media influencers and activists encourage the ―slow fashion‖ movement, which promotes buying fewer, higherquality pieces and keeping them longer.
Technology is also redefining the fashion industry. 3D printing, virtual fashion shows, and AI-generated designs are changing how clothes are made and sold. Online shopping, once a novelty, is now the norm. Some retailers offer virtual tryons using augmented reality. Digital fashion—clothes that only exist online—is becoming popular among gamers and metaverse users who want to dress their avatars.
Fashion is often criticized for promoting unrealistic beauty standards.
Advertisements and runways have historically featured thin, tall models, excluding people with different body types, races, or disabilities. Fortunately, recent years have seen a push for greater inclusivity. Brands now include diverse models in their campaigns and create clothing lines for all sizes. While progress is slow, fashion is beginning to reflect the real-world diversity of its customers.
Gender norms in fashion are also shifting. Unisex clothing and gender-fluid fashion are growing in popularity, challenging the traditional divide between ―men‘s‖ and ―women‘s‖ styles. Many young people see fashion as a way to express themselves freely, without being limited by outdated labels or expectations.
School uniforms are another area where fashion meets social debate. Some argue that uniforms promote equality and reduce bullying. Others believe they restrict self-expression and make students feel controlled. While many schools in the UK, Japan, and other countries require uniforms, others take a more relaxed approach, letting students wear what they want within limits.
In the workplace, dress codes still matter, though they are becoming more flexible. While formal suits were once the standard, many companies now allow smartcasual or even fully casual dress, especially in creative or tech industries. Some argue that how someone dresses should not affect how they are judged at work. Others believe clothing still influences professionalism and respect.
Fashion also plays a role in protest and activism. From the black outfits of feminist movements to climate protestors wearing recycled materials, clothes can be a powerful symbol. What someone wears in public can send a message louder than words—especially in today‘s media-heavy world.
Despite all these changes, fashion remains personal. It can bring joy, boost confidence, and help people belong. Yet it can also pressure people to conform, overspend, or feel insecure. Whether a person follows trends or ignores them, the fact remains: we all make fashion choices every day, and those choices matter more than we might think.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of this passage is to explore fashion as a cultural and economic force that reflects identity, values, and social trends, while examining its historical role, the impact of globalization and fast fashion, technological changes, issues of inclusivity and gender norms, debates around uniforms and dress codes, its use in activism, and its personal significance in everyday life.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are some negative consequences of fast fashion?',
        explanation: 'Fast fashion encourages overconsumption, with millions of garments ending up in landfills each year. Factories often exploit workers in developing countries by paying extremely low wages and operating in unsafe conditions. The environmental and ethical costs are described as severe.',
      ),
      ReadingQuestion(
        question: 'The word \'democratized\' in paragraph 2 most likely means?',
        explanation: 'It most likely means made more accessible or available to a wider range of people, as the passage states that although class distinctions remain, the fashion industry has become more democratized, with trends spreading quickly through media and online platforms.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the slow fashion movement?',
        explanation: 'It can be inferred that the slow fashion movement is a response to the problems of fast fashion, as it promotes buying fewer, higher-quality pieces and keeping them longer, and is encouraged by social media influencers and activists concerned about environmental and ethical impacts.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how has fashion historically reflected social status?',
        explanation: 'In ancient civilizations, clothing indicated status and function, with royalty wearing elaborate garments made from expensive materials while commoners had simple, practical attire. During the Renaissance, fashion in Europe was driven by nobility and used to display wealth and taste.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about current trends in gender and fashion?',
        explanation: 'It can be inferred that traditional gender divides in clothing are being challenged, as unisex clothing and gender-fluid fashion are growing in popularity, and many young people use fashion to express themselves freely without being limited by outdated labels or expectations.',
      ),
    ],
  ),

  ReadingPassage(
    id: 22,
    title: 'Diet',
    topic: 'Health & Nutrition',
    content: '''A person‘s diet refers to the types and quantities of food they consume on a regular basis. While individual diets vary widely around the world, the choices people make about what they eat have major consequences for health, culture, the environment, and the economy.
In recent decades, diets have changed dramatically, especially in urban and industrialized areas. Traditional meals, once based on local grains, fruits, and vegetables, have been replaced by processed foods, sugary snacks, and fast food. These new eating habits are often convenient and affordable—but they also contribute to rising rates of obesity, diabetes, heart disease, and other lifestylerelated illnesses.
A healthy diet typically includes a balance of carbohydrates, proteins, fats, vitamins, and minerals. Nutritionists emphasize the importance of variety and moderation. For example, fruits and vegetables provide essential vitamins, while whole grains offer fiber and slow-release energy. Proteins—whether from meat, fish, beans, or tofu—support growth and repair. Fats are needed too, but in small amounts and ideally from sources like nuts, seeds, or olive oil.
Despite this knowledge, many people struggle to maintain a nutritious diet. One reason is marketing. Food companies invest billions in advertising unhealthy products, especially to children. Supermarkets place sweets and snacks near checkouts to increase impulse buying. Meanwhile, healthy foods like fresh produce are often more expensive and less accessible, especially in low-income areas. Cultural habits and social pressures also shape diet. In some cultures, large portions or meat-heavy meals are associated with hospitality or wealth. Religious rules may forbid certain foods. In others, slimness is idealized, leading to restrictive dieting or eating disorders. Because food is so closely tied to identity, changing diet can be difficult—even when people know it would benefit their health.
Another growing concern is the environmental cost of modern diets. Livestock farming produces large amounts of greenhouse gases, especially methane. Forests are cut down to grow animal feed. Overfishing threatens marine life. As a result, many environmentalists and scientists support plant-based diets. Reducing meat and dairy consumption, even slightly, can lower one‘s carbon footprint significantly.
Governments and public health agencies have tried to improve national diets through various strategies. These include:
•        Food labeling laws that show sugar, salt, and fat content
•        Public awareness campaigns encouraging five portions of fruits and vegetables a day
•        School lunch reforms to promote healthier eating habits from a young age
•        Taxation on sugary drinks or junk food to discourage overconsumption Some countries, like Japan and the Mediterranean nations, still maintain diets linked to longer life expectancy. These diets tend to be rich in vegetables, fish, rice or grains, and relatively low in red meat and sugar. Studies suggest that diet may be the single most important lifestyle factor in predicting long-term health—more so than exercise, sleep, or even genetics.
Technology has also affected the way people eat. Online food delivery apps allow people to order meals in minutes. While this is convenient, it often promotes fast food over home cooking. Meanwhile, social media is filled with influencers promoting extreme diets, detox plans, or supplements without scientific support. This makes it harder for the public to know what to trust.
Intermittent fasting, keto, paleo, veganism—these are just a few of the popular diets that have gained attention in recent years. While some people report benefits, such diets are not suitable for everyone. Experts generally recommend a balanced, flexible approach rather than strict rules, unless there is a medical reason.
Another trend is the rise of functional foods—items with added health benefits, like probiotic yogurt or fortified cereal. These are marketed as improving digestion, boosting immunity, or enhancing brain power. While some claims are backed by science, others are exaggerated or misleading.
For athletes or people with special conditions (e.g. diabetes, allergies, pregnancy), dietary needs become even more specific. Sports nutrition, for example, focuses on timing meals around performance, while diabetic patients must control blood sugar through careful meal planning.
Education plays a vital role in changing dietary behavior. People who understand the long-term effects of their choices are more likely to cook at home, read labels, and choose healthier options. Yet in many countries, basic nutrition is not taught in schools, leaving young people unprepared to make informed decisions about food. Finally, there is a social side to diet. Sharing meals with family or friends has emotional and psychological benefits. People tend to eat more slowly and healthily when they dine together. In contrast, eating alone, while watching screens, can lead to mindless overeating and poor digestion.
In conclusion, diet is not simply about calories or nutrients—it is connected to almost every aspect of human life: culture, health, the planet, and even how we feel day to day. While no single diet is perfect for everyone, one truth remains: what we eat shapes who we are, and the better we eat, the better we live.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to explain what diet is, how modern diets have changed and their health and environmental consequences, the challenges of maintaining a healthy diet, and the cultural, social, and policy factors that influence what people eat.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what has replaced traditional meals in many urban and industrialized areas?',
        explanation: 'Traditional meals based on local grains, fruits, and vegetables have been replaced by processed foods, sugary snacks, and fast food.',
      ),
      ReadingQuestion(
        question: 'The word \'moderation\' in the third paragraph most likely means...',
        explanation: 'Avoiding extremes and consuming foods in reasonable amounts. Nutritionists emphasize variety and moderation as key principles of a healthy diet that balances carbohydrates, proteins, fats, vitamins, and minerals.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the environmental impact of modern diets?',
        explanation: 'Modern diets, especially those high in meat and dairy, contribute significantly to greenhouse gas emissions, deforestation for animal feed, and overfishing, so reducing meat and dairy consumption can lower one\'s carbon footprint.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what strategies have governments used to improve national diets?',
        explanation: 'Strategies include food labeling laws showing sugar, salt, and fat content; public awareness campaigns encouraging five portions of fruits and vegetables a day; school lunch reforms; and taxation on sugary drinks or junk food.',
      ),
      ReadingQuestion(
        question: 'The phrase \'functional foods\' in the tenth paragraph most likely means...',
        explanation: 'Foods that have been enhanced with additional health benefits, such as probiotic yogurt or fortified cereal, which are marketed as improving digestion, immunity, or brain function.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about popular diets such as intermittent fasting, keto, or veganism?',
        explanation: 'While some people report benefits, these diets are not suitable for everyone, and experts generally recommend a balanced, flexible approach rather than strict rules unless there is a medical reason.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why do many people struggle to maintain a nutritious diet?',
        explanation: 'Reasons include heavy marketing of unhealthy products, placement of sweets near checkouts, higher cost and lower accessibility of healthy foods in low-income areas, and cultural habits or social pressures tied to food and identity.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of education in dietary behavior?',
        explanation: 'People who understand the long-term effects of their food choices are more likely to cook at home, read labels, and choose healthier options, yet basic nutrition is often not taught in schools, leaving young people unprepared.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does sharing meals with others affect eating habits?',
        explanation: 'Sharing meals with family or friends has emotional and psychological benefits; people tend to eat more slowly and healthily when they dine together, whereas eating alone while watching screens can lead to mindless overeating and poor digestion.',
      ),
    ],
  ),

  ReadingPassage(
    id: 23,
    title: 'Obesity',
    topic: 'Health & Science',
    content: '''Obesity is a growing global health crisis. It is defined as having excessive body fat that may impair health, usually measured using the Body Mass Index (BMI). A BMI over 30 is considered obese. Although once common only in wealthier countries, obesity is now rising sharply in both developed and developing nations. The causes of obesity are complex. While genetics may influence body shape or metabolism, the main drivers are poor diet and lack of physical activity. Many people consume far more calories than they burn. Highly processed foods—rich in sugar, fat, and salt—are cheap, convenient, and heavily marketed. At the same time, daily routines have become more sedentary. Desk jobs, screen time, and carbased lifestyles have drastically reduced physical movement.
Obesity increases the risk of serious diseases. These include type 2 diabetes, heart disease, high blood pressure, stroke, and even some cancers. In fact, obesity is now one of the leading preventable causes of death worldwide. Children who are obese are also more likely to suffer from joint problems, low self-esteem, and bullying at school.
What makes obesity particularly challenging is that it is often linked to social, economic, and environmental factors. In low-income communities, healthy food is often more expensive and harder to access. Fast food chains, meanwhile, are easily available and affordable. Public spaces may lack safe areas for walking, biking, or exercising. In this way, obesity is not simply a personal issue but a public one.
Governments have taken a variety of steps to address the obesity epidemic. Some countries have introduced a sugar tax on soft drinks to discourage overconsumption. Others have banned junk food advertising targeted at children. In schools, healthier meals are being promoted and physical education is being strengthened. Yet despite these efforts, obesity rates continue to climb in many areas.
Experts suggest that public education must be combined with structural changes. Teaching people about calories and nutrition is useful—but not enough. People also need access to healthy, affordable food and safe spaces for exercise. Urban planning, workplace wellness programs, and food labeling laws all play a role.
There is also disagreement about how obesity should be discussed. Some health campaigns use fear-based messages, showing graphic images of disease. Critics argue that this approach promotes fat-shaming and increases stigma. They point out that mental health and emotional eating are often overlooked in obesity discussions. Instead of blame, they call for compassion-based health promotion that supports people in making long-term lifestyle changes.
Another controversy surrounds the body positivity movement, which promotes acceptance of all body types. Supporters say it helps reduce shame and encourages self-confidence, especially among young people. However, some argue that it may also normalize unhealthy weight and distract from the real medical risks linked to obesity.
Technology has created both problems and solutions. On one hand, screen-based entertainment keeps people inactive for long hours. Food delivery apps increase the convenience of fast food. On the other hand, fitness trackers, health apps, and online coaching can help people monitor their diet and activity. When used wisely, technology can support healthier lifestyles.
The food industry also plays a key role. Many companies now offer ―lighter‖ menu options or publish calorie information. However, some critics accuse the industry of greenwashing—pretending to care about health while continuing to push unhealthy products. Without strong regulations, profit often outweighs public health.
In the case of children, parents have a major responsibility. Family habits around meals, snacks, screen time, and physical activity strongly influence a child‘s weight. Experts advise parents to lead by example—cooking at home, limiting junk food, and encouraging outdoor play. Schools can also help by integrating food education and regular exercise into the curriculum.
Obesity is not only a health problem—it is an economic burden. Countries spend billions every year treating obesity-related illnesses. Productivity is reduced when people are too unwell to work. Insurance systems, hospitals, and employers all face rising costs. Long-term, preventing obesity could save far more money than treating it.
One key question remains: is obesity a personal failure, or a result of a broken system? While individuals are responsible for their choices, those choices are shaped by environment, culture, and policy. It is increasingly clear that solving obesity requires a collective effort—from individuals, families, businesses, governments, and healthcare providers.
In conclusion, obesity is not caused by laziness or lack of willpower. It is a complex, multi-layered problem driven by modern food systems, inactive lifestyles, and social inequalities. Addressing it will require more than just diet advice—it demands a serious, coordinated response across all levels of society. Until that happens, obesity will remain one of the most urgent health threats of our time.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to examine obesity as a complex global health crisis, outlining its definition, causes, health and economic consequences, social and environmental factors, government and industry responses, related controversies, and the need for a coordinated societal effort rather than individual blame.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how is obesity usually measured and defined?',
        explanation: 'Obesity is defined as having excessive body fat that may impair health and is usually measured using the Body Mass Index (BMI); a BMI over 30 is considered obese.',
      ),
      ReadingQuestion(
        question: 'The word "sedentary" in the first paragraph most likely means',
        explanation: 'In the context of daily routines becoming more sedentary due to desk jobs, screen time, and car-based lifestyles that reduce physical movement, the word means involving little physical activity or characterized by sitting and inactivity.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the causes of obesity from the passage?',
        explanation: 'While genetics may play a role, the main drivers are poor diet (especially highly processed foods) and lack of physical activity; social, economic, and environmental factors such as limited access to healthy food and safe exercise spaces also contribute, making obesity more than just a personal issue.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are some health risks associated with obesity?',
        explanation: 'Obesity increases the risk of type 2 diabetes, heart disease, high blood pressure, stroke, and some cancers; it is one of the leading preventable causes of death worldwide, and obese children are more likely to face joint problems, low self-esteem, and bullying.',
      ),
      ReadingQuestion(
        question: 'The term "greenwashing" in the ninth paragraph most likely means',
        explanation: 'In the context of critics accusing the food industry of greenwashing by pretending to care about health while continuing to push unhealthy products, the term means making misleading or false claims about being environmentally or health-conscious to improve public image.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the body positivity movement from the passage?',
        explanation: 'Supporters believe it reduces shame and builds self-confidence, especially for young people, by promoting acceptance of all body types; however, critics argue it may normalize unhealthy weight and divert attention from the medical risks of obesity.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what steps have governments taken to address obesity?',
        explanation: 'Some countries have introduced a sugar tax on soft drinks, banned junk food advertising aimed at children, promoted healthier school meals, and strengthened physical education; experts also stress the need for structural changes like better access to healthy food and safe exercise spaces.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of technology in relation to obesity?',
        explanation: 'Technology contributes to the problem through screen-based inactivity and food delivery apps that increase fast-food convenience, but it can also help via fitness trackers, health apps, and online coaching that support monitoring diet and activity when used wisely.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is obesity described as an economic burden?',
        explanation: 'Countries spend billions treating obesity-related illnesses, productivity falls when people are too unwell to work, and insurance systems, hospitals, and employers face rising costs; preventing obesity could save far more money in the long term than treating it.',
      ),
    ],
  ),

  ReadingPassage(
    id: 24,
    title: 'Aging',
    topic: 'Society & Culture',
    content: '''Aging is a natural biological process that affects all living organisms. For humans, it involves a gradual decline in physical and sometimes mental function over time. While many associate aging with wrinkles, gray hair, or frailty, the truth is that aging has far deeper social, economic, and medical implications, especially as global life expectancy continues to rise.
Thanks to modern healthcare, improved nutrition, and safer working conditions, people now live much longer than in the past. In many countries, the average life expectancy exceeds 80 years. However, living longer does not always mean living healthier. Aging is often accompanied by chronic diseases such as arthritis, diabetes, dementia, or heart conditions, which require ongoing care and support.
This shift in demographics has led to what experts call an ―aging population‖—a situation where a growing percentage of a country‘s people are over the age of 65. Japan, Italy, and Germany are notable examples. In such societies, the workforce shrinks while the number of retired people grows. This creates challenges for pension systems, healthcare services, and economic productivity.
Governments are under pressure to adapt. In many countries, retirement ages are being raised to reduce pressure on pension funds. Some countries also offer incentives for older adults to stay in the labor force longer. Meanwhile, healthcare systems must prepare for a surge in age-related diseases. Elderly care, both at home and in institutions, requires trained professionals, accessible housing, and social support systems.
Aging is not only a burden—it also offers opportunities. Older adults bring experience, wisdom, and emotional stability. Many contribute to society by volunteering, mentoring, or helping raise grandchildren. In fact, research shows that intergenerational contact—when young and old people interact regularly—can reduce loneliness and increase empathy across age groups.
Despite this, ageism remains a serious issue. Older people are often seen as slow, outdated, or incapable, particularly in technology-driven workplaces. Age-based discrimination can prevent capable individuals from finding work or being promoted. This not only harms individuals but also wastes valuable skills in the labor market.
In the field of science, researchers are exploring how and why we age. Some theories focus on genetic programming, while others highlight damage from free radicals or the shortening of telomeres (protective caps at the ends of DNA strands). Anti-aging research has become a booming industry, with companies offering supplements, gene therapies, and even cryopreservation in the hope of extending human lifespan.
However, critics warn that this obsession with staying young may ignore deeper questions. Instead of asking how to avoid aging, perhaps society should focus on how to age with dignity, purpose, and support. Mental health in older adults is one key area often overlooked. Depression, anxiety, and isolation are common but underdiagnosed, especially among those who live alone or have lost a spouse.
One concept gaining popularity is ―active aging‖, which promotes staying physically, mentally, and socially active in later life. Activities like walking, learning new skills, socializing, or volunteering can improve quality of life. Governments and communities are now investing in age-friendly programs and infrastructure—like public benches, elevator access, and adult learning courses—to support active lifestyles.
Technology, too, can help. From telemedicine to smart home devices, innovations are enabling older adults to live independently for longer. Simple tools—like pill reminders, fall detectors, or video calls—can bridge the gap between independence and care. However, digital literacy remains a barrier, as many elderly people struggle to use smartphones or apps without proper training.
Family remains the main source of elderly care in many cultures. In countries like India or Uzbekistan, it is common for multiple generations to live under one roof. While this strengthens family ties, it can also put financial and emotional stress on caregivers. In Western societies, by contrast, many elderly people live alone or in care facilities, which may result in social isolation.
Economically, the aging population has both negative and positive effects. On one hand, healthcare and pensions become more expensive. On the other, the so-called ―silver economy‖—goods and services aimed at older consumers—is booming.
Travel, healthcare, insurance, wellness, and entertainment tailored to older adults are fast-growing markets.
Culturally, aging is viewed very differently around the world. In East Asia, older people are traditionally respected and cared for by younger generations. In contrast, Western culture often celebrates youth and views aging as something to hide. Media representation plays a major role in shaping these attitudes. Portraying elderly people as active, intelligent, and capable can change how society views the aging process.
In conclusion, aging is inevitable—but how we handle it is not. As the world‘s population grows older, societies must rethink healthcare, employment, housing, and social values. By embracing aging rather than fearing it, we can build a world where people live not just longer lives, but better ones. After all, growing old is a privilege many never reach—and it deserves to be treated with care and respect.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage examines the biological, social, economic, and cultural aspects of aging, highlighting both challenges and opportunities while arguing that societies should focus on aging with dignity and support rather than merely avoiding it.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is an "aging population"?',
        explanation: 'An aging population is a demographic situation in which a growing percentage of a country\'s people are over the age of 65, as seen in countries like Japan, Italy, and Germany.',
      ),
      ReadingQuestion(
        question: 'The word "ageism" in the sixth paragraph most likely means',
        explanation: 'In context, ageism refers to discrimination or prejudice against older people based on stereotypes that they are slow, outdated, or incapable.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the economic impact of an aging population?',
        explanation: 'While an aging population increases costs for healthcare and pensions, it also creates opportunities through the growing "silver economy" of goods and services targeted at older consumers.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is "active aging"?',
        explanation: 'Active aging is a concept that promotes remaining physically, mentally, and socially active in later life through activities such as walking, learning new skills, socializing, or volunteering to improve quality of life.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about intergenerational contact from the passage?',
        explanation: 'Regular interaction between young and old people can reduce loneliness among the elderly and increase empathy across age groups.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how do cultural views of aging differ?',
        explanation: 'In East Asia, older people are traditionally respected and cared for by younger generations, whereas Western culture often celebrates youth and treats aging as something to hide.',
      ),
      ReadingQuestion(
        question: 'The word "telomeres" in the seventh paragraph most likely refers to',
        explanation: 'Telomeres are described as protective caps at the ends of DNA strands whose shortening is one theory related to the aging process.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about technology\'s role in elderly care?',
        explanation: 'Innovations such as telemedicine, smart home devices, pill reminders, and fall detectors can help older adults live independently longer, though limited digital literacy remains a barrier for many.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is mental health in older adults often overlooked?',
        explanation: 'Depression, anxiety, and isolation are common among older adults, especially those living alone or who have lost a spouse, yet these issues are frequently underdiagnosed.',
      ),
    ],
  ),

  ReadingPassage(
    id: 25,
    title: 'Stress',
    topic: 'Health & Science',
    content: '''Stress is a natural physical and emotional response to challenging or threatening situations. While it can sometimes be helpful—motivating people to focus, act quickly, or meet deadlines—chronic stress can have serious consequences for both mental and physical health. In today‘s fast-paced world, stress has become a widespread issue across all age groups.
Stress is often caused by external pressures such as work, school, relationships, financial difficulties, or health problems. It can also result from internal factors, such as perfectionism, fear of failure, or negative self-talk. Each person responds to stress differently. What feels overwhelming to one person might seem manageable to another.
When the brain perceives a threat, it activates the ―fight-or-flight‖ response, releasing hormones like adrenaline and cortisol. These chemicals increase heart rate, sharpen focus, and prepare the body to react. This response was useful for early humans facing danger in the wild. However, when the body remains in a state of alert for too long, it leads to exhaustion, anxiety, depression, sleep problems, and weakened immunity.
One major source of stress today is work. Employees face long hours, tight deadlines, constant emails, and fear of losing their jobs. In competitive industries, the pressure to perform can lead to burnout—a condition marked by emotional exhaustion, detachment, and reduced effectiveness. Some companies now offer wellness programs or mental health support to reduce workplace stress, but not all employers recognize its seriousness.
Academic stress is also on the rise. Students worry about grades, exams, future careers, and social acceptance. In some countries, pressure from parents or teachers can be intense, especially when education is linked to social status. High-stakes testing environments often prioritize results over well-being, leaving little room for rest, creativity, or emotional growth.
Technology plays a complex role in stress. On one hand, it improves convenience and access to information. On the other, it can create constant distractions and pressure to stay connected. Many people check work messages late at night, struggle to disconnect from social media, or compare themselves to unrealistic online images. This digital overload contributes to mental fatigue, low self-esteem, and a feeling of never being ―enough.‖
There are also societal factors. In fast-moving economies, people often link selfworth to productivity. Taking breaks, resting, or asking for help is sometimes seen as weakness. This toxic culture of overachievement encourages people to ignore early warning signs of stress until it turns into a crisis.
Physical health suffers too. Chronic stress has been linked to heart disease, obesity, diabetes, and digestive issues. It affects sleep patterns and appetite. Many people cope by smoking, drinking, or overeating—behaviors that provide short-term relief but worsen health long-term. The mind and body are deeply connected; treating one without the other is rarely effective.
Fortunately, stress can be managed. Experts recommend a combination of strategies, including:
•        Regular physical activity, which reduces stress hormones and boosts mood
•        Mindfulness and meditation, which help calm the mind and increase awareness
•        Healthy eating, which supports brain function and energy levels
•        Social support, whether through friends, family, or counseling
•        Time management skills, such as prioritizing tasks and setting boundaries Small daily habits—like getting enough sleep, spending time in nature, or keeping a gratitude journal—can also reduce stress levels. For severe stress or trauma, professional help may be necessary. Cognitive-behavioral therapy (CBT) is one evidence-based method that helps people reframe negative thought patterns and develop healthier coping mechanisms.
Schools and workplaces are beginning to recognize the need for mental health education and emotional resilience training. Teaching young people how to handle failure, regulate emotions, and ask for help is key to long-term well-being. Meanwhile, companies that support mental health often see better productivity, lower turnover, and stronger employee satisfaction.
Another growing concept is ―stress resilience‖—the ability to adapt and recover from adversity. Some people are naturally more resilient, but resilience can also be developed. Having a purpose, staying flexible, and learning from failure are important traits that help people bounce back under pressure.
In many cultures, talking about stress or mental health is still taboo. This makes it harder for individuals to seek help or admit they are struggling. Changing these attitudes requires open conversation, public education, and media representation that breaks down stereotypes and normalizes vulnerability.
It‘s also important to note that not all stress is bad. Short-term or ―acute‖ stress can sharpen focus and improve performance in situations like interviews, sports, or public speaking. The goal is not to eliminate all stress, but to manage it so it doesn‘t become harmful.
In conclusion, stress is a normal part of life—but when unmanaged, it can damage our health, relationships, and happiness. As modern life grows more demanding, learning how to handle stress is no longer optional—it‘s a survival skill. By understanding its causes and practicing healthy coping strategies, individuals and societies can build greater emotional strength, balance, and peace of mind.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage explains what stress is, its causes and effects on mental and physical health, the roles of work, academics, technology, and society, and outlines management strategies and the concept of resilience, concluding that managing stress is essential in modern life.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what happens when the brain perceives a threat?',
        explanation: 'The passage states that the brain activates the ―fight-or-flight‖ response, releasing hormones like adrenaline and cortisol that increase heart rate, sharpen focus, and prepare the body to react.',
      ),
      ReadingQuestion(
        question: 'The word "burnout" in the passage most likely means',
        explanation: 'In context, "burnout" is described as a condition marked by emotional exhaustion, detachment, and reduced effectiveness resulting from prolonged workplace pressure.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of technology in stress?',
        explanation: 'The passage indicates that while technology improves convenience, it also creates constant distractions, pressure to stay connected, and digital overload that contributes to mental fatigue, low self-esteem, and feelings of inadequacy.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does chronic stress affect physical health?',
        explanation: 'The passage links chronic stress to heart disease, obesity, diabetes, and digestive issues, and notes that it affects sleep patterns and appetite.',
      ),
      ReadingQuestion(
        question: 'The word "resilience" in the phrase "stress resilience" most likely means',
        explanation: 'The passage defines "stress resilience" as the ability to adapt and recover from adversity, noting that it can be developed through purpose, flexibility, and learning from failure.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about societal attitudes toward stress and mental health?',
        explanation: 'The passage states that in many cultures talking about stress or mental health is still taboo, which makes it harder for individuals to seek help, and that changing these attitudes requires open conversation, public education, and media representation.',
      ),
      ReadingQuestion(
        question: 'According to the passage, which strategies do experts recommend for managing stress?',
        explanation: 'The passage lists regular physical activity, mindfulness and meditation, healthy eating, social support, and time management skills, along with small daily habits and professional help such as CBT when needed.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about short-term or acute stress?',
        explanation: 'The passage notes that not all stress is bad and that short-term or "acute" stress can sharpen focus and improve performance in situations like interviews, sports, or public speaking, so the goal is management rather than elimination.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is learning to handle stress considered a survival skill?',
        explanation: 'The passage concludes that as modern life grows more demanding, unmanaged stress can damage health, relationships, and happiness, making the ability to handle stress essential rather than optional.',
      ),
    ],
  ),

  ReadingPassage(
    id: 26,
    title: 'Smoking',
    topic: 'Health & Science',
    content: '''Smoking, particularly tobacco use, is one of the leading causes of preventable death worldwide. It is responsible for millions of deaths each year and contributes to a wide range of serious health problems. Despite decades of public health campaigns, smoking remains a major global issue, especially in low- and middleincome countries.
Tobacco contains nicotine, a highly addictive chemical that stimulates the brain and creates a temporary feeling of pleasure or relaxation. Because of its addictive nature, quitting smoking can be extremely difficult—even when people are aware of its dangers. Once a person becomes dependent on nicotine, both physical cravings and psychological habits make quitting a challenge.
Cigarettes are the most common form of tobacco consumption, but other products like cigars, pipes, chewing tobacco, and, more recently, e-cigarettes (or vapes) are also widely used. All of these products contain harmful substances. Cigarette smoke, for example, contains over 7,000 chemicals—many of them toxic, and at least 70 known to cause cancer.
The health consequences of smoking are severe. It increases the risk of lung cancer, heart disease, stroke, chronic bronchitis, and many other conditions. Smoking also affects reproductive health, weakens the immune system, and accelerates aging. Secondhand smoke, which occurs when non-smokers inhale smoke from nearby smokers, also poses significant risks—especially to children and pregnant women.
Despite these facts, smoking remains popular for several reasons. In many societies, smoking is linked to social identity, rebellion, or relaxation.
Advertising—especially in the past—portrayed smoking as glamorous, masculine, or sophisticated. Although tobacco advertising is now banned in many countries, its historical influence still lingers. Peer pressure, stress, and curiosity also play a role in getting people started.
Governments and health organizations have implemented a wide range of measures to reduce smoking rates. These include:
•        Raising tobacco taxes, which makes cigarettes more expensive and less accessible
•        Banning smoking in public places, such as restaurants, offices, and public transport
•        Requiring graphic health warnings on cigarette packages
•        Running public awareness campaigns that highlight the dangers of smoking
•        Offering support programs for people who want to quit, such as counseling or nicotine replacement therapy
These strategies have proven effective in many countries. For example, in the UK and Australia, smoking rates have declined significantly over the last two decades. However, in some developing countries, tobacco use continues to rise—partly due to weak regulations and aggressive marketing by tobacco companies.
A more recent development is the rise of electronic cigarettes, or vaping devices. These are often marketed as safer alternatives to smoking. While vaping does not involve burning tobacco, the health risks are still being studied. Some experts argue that vaping may help smokers quit. Others worry that e-cigarettes could become a gateway to nicotine addiction among young people, especially since many products come in sweet flavors and colorful packaging.
One of the major challenges in combating smoking is the influence of the tobacco industry, which is extremely powerful and profitable. Tobacco companies often lobby against stricter laws and fund misleading research. In some cases, they sponsor events, sports, or charities to improve their public image. Critics argue that these strategies distract attention from the true health impact of their products. Smoking is not only a personal health issue—it also has economic and environmental consequences. Treating smoking-related diseases costs healthcare systems billions of dollars each year. Lost productivity due to illness or early death adds to this burden. Environmentally, cigarette production and consumption contribute to deforestation, pollution, and littering. Cigarette butts are one of the most common forms of plastic waste in the world.
Another concern is youth smoking. Studies show that most adult smokers began before the age of 18. Preventing young people from starting is key to reducing long-term smoking rates. Many experts recommend education programs in schools, stricter age restrictions, and removing flavored tobacco products from the market.
Some people argue that smoking is a personal choice and that governments should not interfere. However, because smoking harms not only the smoker but also the wider public, most countries treat it as a public health issue. Just as laws exist to ensure food safety or clean water, restrictions on tobacco aim to protect society as a whole.
In conclusion, smoking remains one of the most dangerous yet preventable threats to global health. While progress has been made through legislation, education, and public campaigns, challenges persist—especially with new products like e-cigarettes and the ongoing influence of the tobacco industry. To create a smokefree future, society must combine strict policies, support for quitting, and a cultural shift away from nicotine dependence.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to describe the health risks of smoking, the reasons it persists, government measures to reduce it, challenges from the tobacco industry and e-cigarettes, and the need for continued efforts toward a smoke-free future.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is quitting smoking extremely difficult?',
        explanation: 'Quitting is extremely difficult because nicotine is highly addictive, creating physical cravings and psychological habits even when people know the dangers.',
      ),
      ReadingQuestion(
        question: 'The word "gateway" in the paragraph about e-cigarettes most likely means...',
        explanation: 'In the context of the passage, "gateway" means something that can lead or open the way to nicotine addiction among young people.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about secondhand smoke?',
        explanation: 'It can be inferred that secondhand smoke is harmful to non-smokers, particularly children and pregnant women, because it exposes them to the same toxic chemicals present in cigarette smoke.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what measures have governments used to reduce smoking rates?',
        explanation: 'Governments have raised tobacco taxes, banned smoking in public places, required graphic health warnings on packages, run public awareness campaigns, and offered support programs such as counseling or nicotine replacement therapy.',
      ),
      ReadingQuestion(
        question: 'The word "lingers" in the fifth paragraph most likely means...',
        explanation: 'In the context of the passage, "lingers" means continues to remain or have an effect, referring to the lasting historical influence of tobacco advertising.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the tobacco industry\'s role in the smoking problem?',
        explanation: 'It can be inferred that the tobacco industry actively works against stricter regulations through lobbying, funding misleading research, and improving its public image, which hinders efforts to reduce smoking.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is preventing youth smoking especially important?',
        explanation: 'Preventing youth smoking is key because studies show that most adult smokers began before the age of 18, so stopping young people from starting helps reduce long-term smoking rates.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the economic impact of smoking?',
        explanation: 'It can be inferred that smoking places a heavy financial burden on society through high healthcare costs for treating related diseases and lost productivity from illness or early death.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how do most countries view smoking in terms of policy?',
        explanation: 'Most countries treat smoking as a public health issue rather than purely a personal choice, because it harms both the smoker and the wider public, justifying restrictions similar to those for food safety or clean water.',
      ),
    ],
  ),

  ReadingPassage(
    id: 27,
    title: 'Addiction',
    topic: 'Health & Society',
    content: '''Addiction is a condition in which a person is unable to stop engaging in a behavior or using a substance, despite harmful consequences. It affects the brain‘s reward system, making the person feel temporary pleasure or relief, followed by a cycle of craving, use, and withdrawal. While addiction was once seen mainly as a moral weakness, it is now recognized as a complex medical and psychological disorder. There are two main categories of addiction: substance addiction and behavioral addiction. Substance addiction includes drugs, alcohol, and nicotine. Behavioral addictions involve activities such as gambling, gaming, shopping, or even internet use. Although these may seem less dangerous, they can still lead to serious consequences—financial ruin, broken relationships, depression, and even suicide. Addiction often begins with curiosity or social influence. A teenager may start smoking to fit in, or a stressed worker may drink alcohol to relax. Over time, the brain adapts, and the person needs more of the substance or activity to feel the same effect. This tolerance leads to dependence, and eventually, the person feels unable to function without it.
The causes of addiction are both biological and environmental. Genetics play a role—some people are more vulnerable due to their brain chemistry. Childhood trauma, neglect, or growing up in an environment where addiction is common can also increase the risk. Mental health conditions, such as anxiety, depression, or PTSD, often occur alongside addiction, making recovery even more difficult.
One of the most harmful forms of addiction is opioid dependence. Opioids are powerful painkillers, including morphine, heroin, and fentanyl. In countries like the United States, overprescription of these drugs has led to a major health crisis. Thousands of people have died from overdoses. Families, communities, and entire healthcare systems have been deeply affected.
The rise of technology addiction is another growing concern. Many people, especially young adults, spend hours each day on social media, video games, or streaming platforms. While not physically harmful, these behaviors can lead to social isolation, poor sleep, and a decline in academic or work performance. In some countries, digital detox centers have been created to help people disconnect. Addiction not only affects the individual—it also impacts families, workplaces, and society at large. Family members often suffer emotional distress, financial problems, or abuse. Employers face lost productivity and higher medical costs. Healthcare systems struggle with rising demand for treatment, especially in areas with limited resources.
Treating addiction is a long and complex process. Detoxification (removing the substance from the body) is often the first step, followed by therapy or medication. Cognitive-behavioral therapy (CBT) helps individuals recognize and change harmful thought patterns. Support groups, such as Alcoholics Anonymous (AA), provide a sense of community and shared understanding.
In some cases, medication is used to reduce cravings or block the effects of drugs. For example, methadone is often prescribed for heroin addicts. However, treatment must be long-term and holistic. Without addressing the root causes—such as trauma, poverty, or mental illness—relapse is likely. Recovery is rarely a straight line; it requires patience, support, and access to ongoing care.
Stigma remains a major barrier. Many people still view addiction as a choice or a failure of willpower. This attitude discourages people from seeking help and increases feelings of shame. Changing public opinion is key—addiction should be treated like any other health condition, with compassion and medical care.
Governments have responded to addiction in different ways. Some follow a punitive approach, focusing on criminal punishment. Others emphasize harm reduction, which includes clean needle programs, safe injection sites, and access to therapy. Portugal, for example, decriminalized drug use in 2001 and invested heavily in treatment. Since then, drug-related deaths and HIV infections have dropped sharply.
Prevention is just as important as treatment. Schools can provide education on the risks of substance abuse. Parents can model healthy coping skills and monitor their children‘s behavior. Media can play a role too—responsible portrayal of addiction can reduce stigma and promote understanding.
Addiction is a deeply human problem. It reveals how people deal with pain, stress, and disconnection. As society becomes faster, more pressured, and more digital, the risk of addiction grows. The question is not whether we will face it—but how we will respond.
In conclusion, addiction is not limited to drugs or alcohol. It can take many forms and affect anyone, regardless of age, background, or wealth. Tackling addiction requires more than just willpower—it demands social support, medical care, education, and a shift in mindset. To truly overcome it, society must stop blaming and start helping.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to explain addiction as a complex medical and psychological disorder, covering its types, causes, effects, treatment approaches, stigma, prevention, and the need for a compassionate societal response.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are the two main categories of addiction?',
        explanation: 'According to the passage, the two main categories of addiction are substance addiction, which includes drugs, alcohol, and nicotine, and behavioral addiction, which involves activities such as gambling, gaming, shopping, or internet use.',
      ),
      ReadingQuestion(
        question: 'The word "tolerance" in the first paragraph most likely means',
        explanation: 'In the context of the first paragraph, "tolerance" refers to the process by which the brain adapts so that a person needs more of the substance or activity to feel the same effect, leading to dependence.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the relationship between mental health and addiction?',
        explanation: 'It can be inferred that mental health conditions such as anxiety, depression, or PTSD often occur alongside addiction and make recovery more difficult, indicating a complex interplay between the two.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what has contributed to the opioid crisis in the United States?',
        explanation: 'According to the passage, overprescription of powerful painkillers such as morphine, heroin, and fentanyl has led to a major health crisis involving thousands of overdose deaths and widespread effects on families, communities, and healthcare systems.',
      ),
      ReadingQuestion(
        question: 'The word "stigma" in the seventh paragraph most likely means',
        explanation: 'In the context of the seventh paragraph, "stigma" means a mark of shame or negative social attitude that views addiction as a choice or failure of willpower, discouraging people from seeking help.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about Portugal‘s approach to drug use?',
        explanation: 'It can be inferred that Portugal‘s shift to decriminalization and investment in treatment since 2001 has been effective, as evidenced by sharp drops in drug-related deaths and HIV infections, supporting a harm-reduction model over purely punitive measures.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why must addiction treatment be long-term and holistic?',
        explanation: 'According to the passage, treatment must be long-term and holistic because without addressing root causes such as trauma, poverty, or mental illness, relapse is likely, and recovery requires patience, support, and ongoing care.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the impact of technology addiction?',
        explanation: 'It can be inferred that although technology addiction is not physically harmful like substance abuse, it can still cause serious problems including social isolation, poor sleep, and declines in academic or work performance, prompting the creation of digital detox centers in some countries.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what roles can schools, parents, and media play in preventing addiction?',
        explanation: 'According to the passage, schools can educate on the risks of substance abuse, parents can model healthy coping skills and monitor behavior, and media can responsibly portray addiction to reduce stigma and promote understanding.',
      ),
    ],
  ),

  ReadingPassage(
    id: 28,
    title: 'Television',
    topic: 'Media & Culture',
    content: '''Television has been one of the most influential inventions of the 20th century. Since its rise in popularity during the 1950s, TV has shaped culture, politics, education, and entertainment across the world. Even today, despite competition from the internet, television continues to play a central role in many people‘s daily lives.
The impact of TV on society is complex. On the one hand, television has served as a powerful educational tool. Documentaries, science programs, and historical series have helped millions learn about topics they might never study in school. Educational TV for children—such as ―Sesame Street‖ or ―Dora the Explorer‖— has been shown to improve language skills, cognitive development, and social awareness.
TV also acts as a window to the world. People can follow global news, discover different cultures, or witness live events without leaving their homes. During major events like elections, sporting tournaments, or natural disasters, television brings people together, creating a shared sense of experience. In this way, TV contributes to national identity and global connection.
However, not all content is positive. Critics argue that much of modern television promotes violence, materialism, and unhealthy lifestyles. Reality shows, soap operas, and crime dramas often exaggerate conflict and reward shallow behavior. Children who watch violent programs may become desensitized or more aggressive. Adults who consume too much TV may suffer from reduced attention span, poor physical health, or even depression.
Another concern is the passive nature of watching TV. Unlike reading, which activates imagination and critical thinking, television delivers images and sound directly to the viewer, requiring little mental effort. Long hours in front of the screen can lead to a sedentary lifestyle. This has been linked to obesity, back pain, and heart disease, especially when combined with unhealthy snacking habits.
Advertising is another powerful influence. Commercials on TV shape consumer behavior by promoting products, lifestyles, and beauty standards. Children are especially vulnerable to persuasive marketing, which can affect their food choices, body image, and spending habits. Although some countries have introduced regulations, advertising remains a core part of the TV industry‘s business model.
The rise of streaming platforms, such as Netflix, Amazon Prime, and Disney+, has changed how people watch TV. Viewers are no longer limited to scheduled broadcasts. Instead, they can choose what to watch, when to watch, and how much to watch. This flexibility has increased viewer satisfaction, but also raised concerns about binge-watching—a habit where people watch multiple episodes or even entire seasons in one sitting. Binge-watching can disrupt sleep, reduce productivity, and harm mental health.
TV has also influenced politics and public opinion. Debates, interviews, and campaign ads are broadcast to millions, helping voters form opinions. In some cases, television has been used to spread propaganda or misinformation, especially in countries with limited press freedom. At the same time, investigative journalism and documentaries can expose corruption, raise awareness, and promote social change.
Despite these issues, many people still view television as an essential part of life.
Families often gather around the TV in the evening, sharing time and conversation. Watching favorite shows can be relaxing, comforting, or emotionally engaging. Well-produced series and films can explore deep human themes, build empathy, and spark global discussion.
There is also growing diversity in TV content. Series now feature more characters from different backgrounds, genders, and identities. Storylines address important topics like mental health, racism, and climate change. While this representation is still not perfect, television is slowly becoming more inclusive and reflective of real society.
The quality of TV production has improved as well. Advances in technology, writing, and acting have turned television into an art form. Shows like ―Breaking Bad,‖ ―Chernobyl,‖ or ―The Crown‖ are praised not only for entertainment but for cinematic excellence and storytelling. In many ways, television has closed the gap between small screens and big cinema.
In education, schools and universities have begun using TV programs and documentaries as teaching tools. Platforms like YouTube and educational channels offer content that supports learning in subjects like geography, history, and biology. When used correctly, television can make learning more visual, engaging, and memorable.
In conclusion, television is neither entirely good nor entirely bad. It has educated, entertained, informed, and influenced billions of people. At the same time, it has promoted harmful ideas, distracted minds, and encouraged passivity. Like any tool, its impact depends on how it is used. For individuals and families, the key is balance—choosing quality content, limiting screen time, and being mindful of what we watch.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to examine the complex impact of television on society, covering its educational value, role as a window to the world, influence on politics and culture, negative effects such as promoting violence or passivity, the rise of streaming and binge-watching, improvements in diversity and production quality, and the conclusion that its effects depend on balanced, mindful use.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how has educational television benefited children?',
        explanation: 'According to the passage, educational TV for children—such as ―Sesame Street‖ or ―Dora the Explorer‖—has been shown to improve language skills, cognitive development, and social awareness.',
      ),
      ReadingQuestion(
        question: 'The word "desensitized" in the fourth paragraph most likely means',
        explanation: 'In the fourth paragraph, "desensitized" most likely means becoming less sensitive or less responsive to violence, as the passage states that children who watch violent programs may become desensitized or more aggressive.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the passive nature of watching TV?',
        explanation: 'It can be inferred that watching TV is more passive than reading because it delivers images and sound directly and requires little mental effort, whereas reading activates imagination and critical thinking; long hours of TV viewing can lead to a sedentary lifestyle linked to obesity, back pain, and heart disease.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what concerns have been raised by the rise of streaming platforms?',
        explanation: 'According to the passage, while streaming platforms increase viewer satisfaction through flexibility in choosing what, when, and how much to watch, they have also raised concerns about binge-watching, which can disrupt sleep, reduce productivity, and harm mental health.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about television\'s influence on politics?',
        explanation: 'It can be inferred that television influences politics and public opinion by broadcasting debates, interviews, and campaign ads that help voters form opinions, and that it can be used either to spread propaganda or misinformation in countries with limited press freedom or, through investigative journalism and documentaries, to expose corruption, raise awareness, and promote social change.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how has diversity in TV content changed?',
        explanation: 'According to the passage, there is growing diversity in TV content as series now feature more characters from different backgrounds, genders, and identities, and storylines address important topics like mental health, racism, and climate change, though representation is still not perfect.',
      ),
      ReadingQuestion(
        question: 'The phrase "binge-watching" in the passage most likely refers to',
        explanation: 'In the passage, "binge-watching" refers to a habit where people watch multiple episodes or even entire seasons in one sitting, a practice made more common by streaming platforms and linked to disrupted sleep, reduced productivity, and harm to mental health.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the quality of modern television production?',
        explanation: 'It can be inferred that the quality of TV production has improved significantly through advances in technology, writing, and acting, turning television into an art form; shows like ―Breaking Bad,‖ ―Chernobyl,‖ or ―The Crown‖ are praised for cinematic excellence and storytelling, closing the gap between small screens and big cinema.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is the key to managing television\'s impact?',
        explanation: 'According to the passage, television is neither entirely good nor entirely bad and its impact depends on how it is used; for individuals and families, the key is balance—choosing quality content, limiting screen time, and being mindful of what we watch.',
      ),
    ],
  ),

  ReadingPassage(
    id: 29,
    title: 'Education',
    topic: 'Education & Society',
    content: '''Education is one of the most powerful tools for personal growth, social mobility, and national development. From early childhood to higher education, schools and
universities play a critical role in shaping the skills, values, and future opportunities of individuals. Without access to quality education, entire generations may remain trapped in cycles of poverty and inequality.
The purpose of education goes beyond academic knowledge. While learning maths, science, or history is essential, students also develop critical thinking, creativity, discipline, and communication skills. In modern societies, education prepares individuals not only for employment but also for civic life, helping them make informed decisions and participate actively in their communities.
There are various models of education around the world. In some countries, strict discipline, uniforms, and high-stakes exams define the school experience. In others, student-centered learning, group projects, and creativity are prioritized. Regardless of the approach, the ultimate goal is to equip young people with the tools they need to thrive in a rapidly changing world.
One major debate in education is whether schools should focus more on academic subjects or life skills. Some argue that students spend too much time memorizing facts and not enough time learning practical things—like how to manage money, resolve conflicts, or cook healthy meals. As societies evolve, so too must their education systems.
Technology has brought major changes to education. Online courses, digital textbooks, and interactive learning platforms have made education more flexible and accessible. During the COVID-19 pandemic, millions of students around the world attended classes from home. While this shift allowed learning to continue, it also highlighted the digital divide—not all students have internet access or devices at home.
Another issue is the gap in educational quality between rich and poor areas. In many countries, students in wealthy neighborhoods attend well-funded schools with experienced teachers, modern facilities, and a wide range of extracurricular activities. Meanwhile, those in poorer areas may face overcrowded classrooms, outdated materials, and underpaid staff. Educational inequality reinforces existing social and economic divisions.
Higher education presents both opportunities and challenges. A university degree can open doors to better jobs, higher income, and greater status. However, in many countries, tuition fees have become unaffordable. Student debt is a growing problem, especially in places like the United States. Some experts question whether university is still worth the cost, especially when skilled trades and online certifications offer cheaper, faster paths to employment.
Standardized testing is another controversial topic. Supporters say it allows fair comparison across schools and students. Critics argue that exams create pressure, limit creativity, and encourage rote learning. In response, some countries are moving toward continuous assessment or project-based learning models that evaluate real-world skills.
Teachers are central to the education system, yet their role is often undervalued. In many places, they work long hours for low pay and face constant pressure to improve results. Without investing in teacher training and well-being, no education reform can succeed. Respecting and supporting teachers is crucial to improving outcomes for students.
The classroom is not the only place where education happens. Parents, communities, media, and even peer groups all influence how children learn and grow. Values like honesty, cooperation, and responsibility are often learned outside formal schooling. This is why a holistic view of education—one that includes both academic and emotional development—is essential.
Another global challenge is ensuring equal access to education for all, including girls, refugees, children with disabilities, and those living in conflict zones. Around the world, millions of children are still out of school. Some are forced to work, others are kept at home due to cultural norms or safety concerns. International organizations, such as UNESCO, work to promote universal education, but progress remains slow in some regions.
Education also plays a major role in shaping future economies. Countries with strong education systems tend to have more innovation, higher productivity, and greater social stability. Investing in education is not just a moral decision—it is also a smart economic strategy. The more educated a population is, the more capable it becomes of solving complex problems and adapting to new technologies.
However, education must also keep pace with the changing world. The jobs of tomorrow will likely require creativity, emotional intelligence, and digital literacy. Memorizing facts will no longer be enough. Lifelong learning—the idea that people must continue to learn throughout their careers—is becoming essential in the 21st century.
In conclusion, education is far more than schooling. It shapes who we are, how we think, and what kind of societies we build. While challenges like inequality, outdated methods, and underfunding remain, the potential of education to transform lives is undeniable. If we want a better future, we must start by rethinking how we teach, what we value, and who we empower to learn.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to explain the importance of education for personal growth, social mobility, and national development, discuss its purposes beyond academics, examine challenges such as inequality, technology gaps, and costs, and argue that education systems must evolve to prepare people for a changing world.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what skills does education help students develop beyond academic knowledge?',
        explanation: 'According to the passage, beyond academic subjects like maths, science, or history, students also develop critical thinking, creativity, discipline, and communication skills, and education prepares them for employment as well as civic life.',
      ),
      ReadingQuestion(
        question: 'The phrase "digital divide" in the paragraph about technology most likely means',
        explanation: 'In the context of the passage, "digital divide" most likely refers to the gap between students who have internet access and devices at home and those who do not, as the text notes that the shift to online learning during the COVID-19 pandemic highlighted this inequality.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about educational inequality from the passage?',
        explanation: 'It can be inferred that educational inequality between wealthy and poorer areas reinforces existing social and economic divisions, because students in rich neighborhoods often have better-funded schools, experienced teachers, and modern facilities, while those in poorer areas face overcrowded classrooms and outdated materials.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why do some experts question the value of university education?',
        explanation: 'According to the passage, some experts question whether university is still worth the cost because tuition fees have become unaffordable in many countries, student debt is a growing problem (especially in the United States), and skilled trades and online certifications offer cheaper, faster paths to employment.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of teachers from the passage?',
        explanation: 'It can be inferred that teachers are essential to the education system and that reforms cannot succeed without investing in their training and well-being, since they are often undervalued, work long hours for low pay, and face constant pressure to improve results.',
      ),
      ReadingQuestion(
        question: 'The word "holistic" in the paragraph about education outside the classroom most likely means',
        explanation: 'In the context of the passage, "holistic" most likely means comprehensive or complete, referring to a view of education that includes both academic and emotional development and recognizes influences from parents, communities, media, and peers beyond formal schooling.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is becoming essential in the 21st century regarding learning?',
        explanation: 'According to the passage, lifelong learning—the idea that people must continue to learn throughout their careers—is becoming essential in the 21st century, because future jobs will require creativity, emotional intelligence, and digital literacy rather than just memorizing facts.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the economic impact of education from the passage?',
        explanation: 'It can be inferred that investing in education is both a moral decision and a smart economic strategy, since countries with strong education systems tend to have more innovation, higher productivity, and greater social stability, and educated populations are better at solving complex problems and adapting to new technologies.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what global challenge remains in ensuring access to education?',
        explanation: 'According to the passage, a major global challenge is ensuring equal access for all, including girls, refugees, children with disabilities, and those in conflict zones; millions of children are still out of school due to work, cultural norms, or safety concerns, and progress by organizations like UNESCO remains slow in some regions.',
      ),
    ],
  ),

  ReadingPassage(
    id: 30,
    title: 'School Discipline',
    topic: 'Education & Society',
    content: '''Discipline is a key part of any successful education system. It helps create a safe, focused, and respectful environment where learning can take place. Without discipline, classrooms can become chaotic, and both students and teachers may struggle to meet their goals. However, how discipline should be enforced in schools remains a highly debated topic.
Traditionally, discipline in schools relied on strict rules, punishment, and authority. Teachers were expected to control the classroom firmly. Misbehavior was met with detentions, suspensions, or even physical punishment. While these methods were once common, many have been criticized for being too harsh or damaging to students‘ mental health.
In recent years, there has been a shift toward more student-centered approaches to discipline. Instead of punishment, these methods focus on understanding the reasons behind bad behavior and helping students learn from their mistakes. This is often referred to as ―restorative discipline‖, where the goal is to repair harm, build responsibility, and restore relationships.
Supporters of this approach argue that strict punishment often fails to change behavior. A student who is suspended may fall behind in class, feel rejected, or become more rebellious. In contrast, involving students in conversations about their actions and consequences can lead to deeper understanding and long-term change.
However, not everyone agrees. Some educators believe that lenient discipline creates more problems than it solves. If students are not held accountable, they may continue to disrupt the classroom. A lack of clear consequences may also send the message that rules don‘t matter. Striking the right balance between fairness and firmness is one of the biggest challenges schools face.
One of the most controversial forms of school discipline is corporal punishment— physical punishment such as hitting, slapping, or paddling. This practice is banned in many countries but still allowed in some regions. Human rights groups and child psychologists have strongly opposed it, arguing that it causes fear, trauma, and long-term harm. Research shows that corporal punishment does not improve behavior but instead increases aggression and anxiety.
Another key issue is disproportionate discipline. Studies in countries like the US and UK have found that students from minority backgrounds, particularly Black or low-income students, are more likely to be suspended or expelled than their peers. These patterns raise serious concerns about bias, discrimination, and equality in school discipline systems.
Modern schools are experimenting with new ways to manage behavior. These include:
•        Positive Behavior Support (PBS) – where schools reward good behavior instead of just punishing bad behavior
•        Peer mediation programs – where students help resolve conflicts through dialogue
•        Counseling and mental health support – to address the root causes of misbehavior
•        Classroom management training for teachers – helping them respond calmly and effectively
Technology is also changing the way discipline is tracked. Digital systems allow schools to monitor attendance, behavior, and performance more accurately. Parents can be informed in real time about incidents or progress. While this increases transparency, it also raises questions about student privacy and data misuse.
Parental involvement is another important factor. Students are more likely to behave well when parents are engaged in their education and support school rules at home. However, some parents defend their children unconditionally, even when they are clearly at fault. Effective discipline often depends on a partnership between school and family.
Cultural values influence how discipline is viewed. In some Asian cultures, for example, respect for teachers and obedience are highly emphasized. In Scandinavian countries, discipline tends to be more relaxed, focusing on cooperation and emotional intelligence. There is no one-size-fits-all model, and discipline policies must consider local norms, values, and student needs.
One promising approach is teaching emotional regulation and conflict resolution as part of the curriculum. If students are taught how to handle anger, stress, and disagreement from a young age, they may be less likely to act out. Programs like
―social-emotional learning‖ (SEL) aim to build self-awareness, empathy, and decision-making skills.
At the same time, schools must support teachers. Managing student behavior requires patience, training, and support from school leadership. When teachers feel overwhelmed, they may rely on discipline out of frustration rather than strategy. Investing in teacher development is critical to creating respectful, well-managed classrooms.
In conclusion, discipline in schools is essential—but the way it is enforced matters. While punishment alone may offer quick results, it rarely produces lasting change. A balanced approach that promotes fairness, emotional growth, and accountability is more effective in the long run. Discipline should not be about control—it should be about helping students become responsible, respectful members of society.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage discusses the importance of discipline in schools, contrasts traditional punitive methods with modern student-centered and restorative approaches, examines controversies such as corporal punishment and disproportionate discipline, and advocates for a balanced approach that promotes fairness, emotional growth, and accountability.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is the goal of restorative discipline?',
        explanation: 'Restorative discipline focuses on understanding the reasons behind bad behavior and helping students learn from their mistakes, with the specific goals of repairing harm, building responsibility, and restoring relationships.',
      ),
      ReadingQuestion(
        question: 'The word "disproportionate" in the paragraph about discipline patterns most likely means',
        explanation: 'It means unequal or excessive relative to the situation, as studies show that students from minority backgrounds, particularly Black or low-income students, are more likely to be suspended or expelled than their peers, raising concerns about bias and discrimination.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the effects of corporal punishment according to the passage?',
        explanation: 'Research shows that corporal punishment does not improve behavior but instead increases aggression and anxiety; human rights groups and child psychologists oppose it because it causes fear, trauma, and long-term harm.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why do some educators oppose lenient discipline?',
        explanation: 'Some educators believe that lenient discipline creates more problems than it solves because if students are not held accountable, they may continue to disrupt the classroom, and a lack of clear consequences may send the message that rules do not matter.',
      ),
      ReadingQuestion(
        question: 'The phrase "one-size-fits-all" in the paragraph about cultural values most likely means',
        explanation: 'It means a single approach or model that works equally well for everyone, as the passage states there is no such model for discipline and that policies must consider local norms, values, and student needs.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of technology in school discipline?',
        explanation: 'Digital systems allow schools to monitor attendance, behavior, and performance more accurately and inform parents in real time, increasing transparency, but this also raises questions about student privacy and potential data misuse.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how do cultural values influence views on discipline?',
        explanation: 'In some Asian cultures, respect for teachers and obedience are highly emphasized, while in Scandinavian countries discipline tends to be more relaxed and focused on cooperation and emotional intelligence; thus, discipline policies must consider local norms and values.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the importance of supporting teachers in managing discipline?',
        explanation: 'Managing student behavior requires patience, training, and support from school leadership; when teachers feel overwhelmed, they may rely on discipline out of frustration rather than strategy, so investing in teacher development is critical for creating respectful, well-managed classrooms.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is the long-term goal of school discipline?',
        explanation: 'Discipline should not be about control but about helping students become responsible, respectful members of society through a balanced approach that promotes fairness, emotional growth, and accountability rather than relying solely on punishment.',
      ),
    ],
  ),

  ReadingPassage(
    id: 31,
    title: 'Distance Learning',
    topic: 'Education & Technology',
    content: '''Distance learning—also known as online education or remote learning—has transformed how people access knowledge. With the rise of the internet and digital platforms, millions of students around the world can now study from home. Whether through university programs, language apps, or online courses, distance learning has opened the door to flexible, affordable, and global education.
Traditionally, education required physical presence in classrooms. Students and teachers met face to face, following fixed schedules in a shared space. However, modern technology has challenged this model. Today, learners can access lectures, assignments, and discussions using just a laptop or smartphone. This flexibility is especially valuable for working adults, parents, or people in remote areas.
The growth of distance learning accelerated sharply during the COVID-19 pandemic. With schools and universities closed, millions of learners shifted online almost overnight. While this change allowed education to continue, it also exposed deep inequalities in digital access. Not all students had internet connections, devices, or quiet environments at home. As a result, some fell behind or dropped out entirely.
Despite these challenges, distance learning offers many advantages. First, it allows students to learn at their own pace. Some platforms offer recorded lessons, so learners can pause, rewind, or review difficult topics. This benefits people with different learning styles or schedules. Second, online education is often more affordable. Without the cost of transport, housing, or printed materials, more people can afford to continue their studies.
Third, distance learning encourages digital literacy. Students must learn how to navigate software, submit assignments online, and communicate through email or video calls. These are essential skills in the modern workplace. In this sense, online learning prepares students not just academically, but professionally.
However, distance learning also comes with significant drawbacks. One of the most common problems is lack of motivation and discipline. Without a teacher or classmates nearby, some students find it hard to focus, stay organized, or complete tasks on time. Isolation is another concern. Traditional schools provide social interaction, friendships, and emotional support. Online education, in contrast, can feel lonely and impersonal.
Another issue is reduced engagement and communication. In physical classrooms, teachers can read students‘ body language, ask spontaneous questions, or hold group discussions. These natural interactions are harder to replicate online. Even with live video classes, some students stay silent or keep their cameras off. This makes it difficult for teachers to assess understanding or build relationships. Technical problems can also interrupt learning. Slow internet, outdated devices, or unfamiliar software can frustrate both students and teachers. Technical support is essential, but often unavailable, especially in underfunded schools or rural areas. In some cases, students must share one device with siblings or parents working from home.
There is also debate about the quality and credibility of online education. While many online courses are excellent, some are poorly designed, outdated, or even fraudulent. Employers may view online degrees with skepticism, especially if the institution lacks accreditation. To maintain trust, online programs must meet high academic standards and ensure fairness in assessment.
Despite these concerns, distance learning is expected to grow. Universities and companies are investing in more interactive, personalized, and user-friendly platforms. Artificial intelligence, gamification, and virtual reality are being explored to make online learning more immersive. Blended learning—which combines online and face-to-face education—is becoming increasingly popular.
Teachers must also adapt. Online teaching requires different skills than traditional classroom instruction. Teachers need training in digital tools, student engagement, and online classroom management. Without proper support, they may feel overwhelmed or ineffective. Professional development is key to successful distance education.
Parents play a larger role in remote learning, especially for young children. They may need to supervise lessons, provide feedback, or troubleshoot technical issues. This puts extra pressure on families, especially those with limited time, education, or resources. Policymakers must recognize that distance learning is not just about technology—it‘s about the whole learning environment.
Cultural attitudes toward distance learning are also evolving. In the past, online education was seen as second-rate. Today, some of the world‘s top universities, like Harvard and MIT, offer online courses. Platforms like Coursera, edX, and Khan Academy reach millions of learners globally. As more people succeed through online education, its reputation continues to improve.
In conclusion, distance learning is a powerful tool—but not a perfect one. It increases access, flexibility, and independence, but it also creates new challenges related to motivation, connection, and equity. As technology continues to develop, and as educators adapt to this new reality, the future of education will likely be a hybrid of online and in-person learning—combining the best of both worlds.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of this passage is to examine how distance learning has transformed access to education, outlining its advantages such as flexibility, affordability, and digital skill development, its drawbacks including motivation issues, isolation, and technical barriers, the inequalities exposed during the COVID-19 pandemic, and the expected future growth of hybrid models that combine online and in-person learning.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what advantages does distance learning offer to students?',
        explanation: 'Distance learning allows students to learn at their own pace with recorded lessons that can be paused, rewound, or reviewed. It is often more affordable by eliminating costs of transport, housing, or printed materials. It also encourages digital literacy through navigating software, submitting assignments online, and communicating via email or video calls, preparing students both academically and professionally.',
      ),
      ReadingQuestion(
        question: 'The word \'accelerated\' in paragraph 3 most likely means?',
        explanation: 'It most likely means increased or sped up rapidly, as the passage states that the growth of distance learning accelerated sharply during the COVID-19 pandemic when schools and universities closed and millions of learners shifted online almost overnight.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the impact of the COVID-19 pandemic on distance learning?',
        explanation: 'It can be inferred that while the pandemic forced a rapid shift to online education that allowed learning to continue, it also revealed deep inequalities in digital access, as not all students had internet connections, devices, or quiet environments, causing some to fall behind or drop out entirely.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why can distance learning feel lonely and impersonal?',
        explanation: 'Traditional schools provide social interaction, friendships, and emotional support, whereas online education lacks a teacher or classmates nearby, making it hard for some students to focus and leading to isolation as a significant concern.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the future of education based on the passage?',
        explanation: 'It can be inferred that the future of education will likely be a hybrid model combining online and in-person learning, as distance learning is expected to grow with investments in interactive platforms, AI, gamification, and virtual reality, while blended learning becomes increasingly popular and educators adapt to new skills.',
      ),
    ],
  ),

  ReadingPassage(
    id: 32,
    title: 'Home Schooling',
    topic: 'Education & Society',
    content: '''Home schooling, or home education, refers to the practice of educating children outside the formal school system, usually by parents or private tutors. While traditional schools remain the most common form of education worldwide, home schooling has grown significantly in popularity, particularly in countries like the United States, Canada, and the UK.
Families choose home schooling for many reasons. Some parents are dissatisfied with the quality of public education or disagree with the national curriculum. Others want to provide religious or moral instruction not offered in mainstream schools. In certain cases, children with special needs, chronic illnesses, or bullying experiences may find home schooling a safer and more supportive environment. The key appeal is flexibility and control over what and how children learn.
One of the main advantages of home schooling is customized learning. Unlike large classrooms with 20 or 30 students, home schooling allows education to be tailored to a child‘s pace, interests, and abilities. A student who struggles in mathematics but excels in science can receive more time and attention in the areas where they need it. Lessons can also be built around real-life experiences—field trips, experiments, or family discussions—rather than textbooks alone.
Supporters argue that home schooling promotes independent thinking and deeper learning. Without constant testing or peer pressure, students may become more curious, motivated, and confident. Additionally, home-schooled children often have more time for hobbies, sports, and community involvement, which may contribute to a well-rounded personality.
However, home schooling also presents major challenges. One major concern is socialization. Critics argue that children educated at home may miss out on opportunities to interact with peers, develop communication skills, or learn how to handle conflict. Schools are not just about academics—they also teach teamwork, discipline, and emotional intelligence.
Another issue is the academic standard and quality of instruction. Not all parents have the time, knowledge, or teaching ability to provide a well-rounded education.
Some may lack expertise in subjects like math, science, or foreign languages. Without access to labs, libraries, or sports facilities, students might also miss out on resources that traditional schools provide.
Moreover, monitoring and regulation of home schooling varies greatly by country. In some places, there are strict guidelines, regular testing, and inspections. In others, parents can educate their children with minimal oversight. This raises concerns about educational inequality, neglect, or even ideological isolation. Governments must balance the right to educate with the need to protect children‘s interests.
Technology has improved the experience of home schooling. Online platforms, video lessons, and virtual tutors have made it easier for parents to deliver structured lessons. Students can now connect with others around the world, join virtual classes, or access global resources. Digital learning has made home education more efficient, but also more dependent on internet access and digital literacy.
Another consideration is the role of parents. Home schooling requires a high level of commitment, patience, and planning. One parent often must reduce working hours or leave their job altogether. This can create financial pressure on the family. In single-parent homes or low-income households, home schooling may be unrealistic, even if the parents are willing.
The long-term outcomes of home schooling are mixed. Some studies show that home-schooled students perform as well or better on standardized tests and in university admissions. Others point out that academic success depends heavily on the parent‘s education level, resources, and teaching style. Social outcomes also vary widely—some home-schooled students are highly social and confident, while others may struggle with group dynamics or public speaking.
During the COVID-19 pandemic, millions of families were forced to try a form of home schooling. This experience gave many parents a deeper appreciation of teachers' roles and the complexity of education. Some discovered that their children thrived at home, while others found it stressful and ineffective. As a result, interest in hybrid models of education has grown, combining elements of both home and school learning.
Governments and education systems now face important questions. Should home schooling be encouraged as a valid alternative? How can we ensure educational standards and protect children's rights? What support should be offered to parents who choose this path? These issues are particularly urgent in societies where educational access is uneven or where school systems are underfunded.
In conclusion, home schooling offers flexibility, personalized learning, and a safe environment for some families. However, it also raises questions about quality, social development, and equal opportunity. It is neither clearly better nor worse than traditional schooling—its success depends on the context, the child's needs, and the parent's ability to teach. For some, it's a life-changing solution. For others, it's an impractical dream. What's essential is that every child, no matter where they study, receives a rich, balanced, and meaningful education.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to explain what home schooling is, why families choose it, its advantages and challenges, the role of technology and parents, and the broader questions it raises about educational quality, socialization, and equal opportunity.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are some reasons families choose home schooling?',
        explanation: 'Families may be dissatisfied with public education quality or the national curriculum, want to provide religious or moral instruction, or seek a safer environment for children with special needs, chronic illnesses, or bullying experiences; the key appeal is flexibility and control over learning.',
      ),
      ReadingQuestion(
        question: 'The word \'customized\' in the third paragraph most likely means...',
        explanation: 'Tailored or adapted to the individual. The passage explains that home schooling allows education to be tailored to a child\'s pace, interests, and abilities, unlike large classrooms.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about socialization concerns regarding home schooling?',
        explanation: 'Critics argue that home-schooled children may miss opportunities to interact with peers, develop communication skills, handle conflict, and learn teamwork, discipline, and emotional intelligence that schools provide beyond academics.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how has technology affected home schooling?',
        explanation: 'Online platforms, video lessons, and virtual tutors make structured lessons easier; students can connect globally, join virtual classes, and access resources, making home education more efficient but more dependent on internet access and digital literacy.',
      ),
      ReadingQuestion(
        question: 'The word \'oversight\' in the seventh paragraph most likely means...',
        explanation: 'Supervision or monitoring. The passage notes that in some places parents educate with minimal oversight, raising concerns about inequality, neglect, or ideological isolation.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the long-term outcomes of home schooling?',
        explanation: 'Outcomes are mixed: some studies show home-schooled students perform as well or better on tests and university admissions, but success depends heavily on the parent\'s education, resources, and teaching style, and social outcomes also vary widely.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what impact did the COVID-19 pandemic have on views of home schooling?',
        explanation: 'Millions of families tried a form of home schooling, which gave parents a deeper appreciation of teachers\' roles; some children thrived while others found it stressful, leading to greater interest in hybrid models combining home and school learning.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the demands home schooling places on parents?',
        explanation: 'It requires high commitment, patience, and planning; one parent often reduces work hours or leaves a job, creating financial pressure, and it may be unrealistic for single-parent or low-income households even if parents are willing.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is essential regardless of where a child studies?',
        explanation: 'Every child, no matter where they study, should receive a rich, balanced, and meaningful education; home schooling is neither clearly better nor worse than traditional schooling, as its success depends on context, the child\'s needs, and the parent\'s ability to teach.',
      ),
    ],
  ),

  ReadingPassage(
    id: 33,
    title: 'Field Trips',
    topic: 'Education & Learning',
    content: '''Field trips—educational visits to locations outside the classroom—have long been part of school culture. Whether it‘s a museum, factory, historical site, or nature reserve, these trips aim to enhance learning by offering real-world experiences. While some educators view field trips as optional extras, others see them as vital to holistic education.
The main goal of a field trip is to make learning more engaging. Instead of reading about fossils in a textbook, students can observe them in a natural history museum. Instead of discussing farming techniques in theory, they can witness them on a working farm. These direct experiences help students connect classroom concepts to the real world, making lessons more meaningful and memorable.
Another advantage is the development of soft skills. Field trips require planning, time management, teamwork, and curiosity. Students must follow instructions, behave responsibly in public, and interact with people outside their school. Such experiences build confidence, independence, and social awareness—qualities that can‘t always be taught in a classroom.
Field trips also promote cross-disciplinary learning. A single trip to an art museum might include history, culture, creativity, and even marketing. In a science center, students might explore physics, biology, and environmental issues all at once. These rich environments encourage students to ask questions, think critically, and see how different subjects are connected.
Teachers often note that students who struggle in academic settings may thrive on field trips. Some children are visual or hands-on learners, and they understand concepts better through observation or interaction. Others become more engaged outside the rigid classroom structure. This shift can improve motivation and even lead to better academic performance.
Despite these benefits, field trips are not without drawbacks. One concern is cost. Transport, entry fees, and meals can add up, especially for schools with limited budgets. Parents may struggle to afford extra expenses, and some students may feel excluded if they cannot participate. This raises issues of equity and access.
Safety is another concern. Taking a group of students off-campus requires risk assessments, extra supervision, and clear emergency plans. Even well-organized trips can face unexpected problems—bad weather, lost items, or injuries. As a result, some schools avoid field trips entirely, fearing legal responsibility or logistical stress.
Time constraints also matter. With growing academic pressure and strict syllabi, teachers may feel that field trips take away from ―serious learning.‖ Planning a trip requires effort, paperwork, and classroom time. If the trip is not directly tied to the curriculum, it may be viewed as a distraction.
Technology has changed the way some schools approach field trips. Virtual field trips—online tours of museums, landmarks, or factories—are now available through websites and apps. These experiences are cheaper and easier to arrange but lack the sensory richness of physical visits. No video can fully replace the feeling of standing in an ancient ruin or touching a historical artifact.
Field trips can also support community connections. Visits to local businesses, hospitals, or government offices show students how their society functions. Such experiences build civic understanding and help young people see their place in the wider world. They may even inspire future careers or volunteer work.
Some countries make field trips a regular part of the curriculum. In Finland, for example, outdoor learning and excursions are seen as essential. In Japan, group discipline and cultural experiences are emphasized during school trips. Cultural attitudes play a major role in how field trips are valued and implemented.
To be effective, field trips must be well-planned. Educators should set clear goals, link the trip to classroom content, and prepare students in advance. After returning, teachers can assign follow-up activities—presentations, reports, or discussions—to reinforce what was learned. Reflection is key to turning a fun outing into a deep learning experience.
Environmental education is one area where field trips are especially valuable. Visiting a forest, recycling center, or wildlife park helps students understand environmental issues firsthand. Seeing the effects of pollution or conservation efforts in real life often has a stronger impact than reading statistics in a book.
In conclusion, field trips are more than just breaks from routine—they are powerful tools for experiential learning. While they come with costs and risks, their potential to spark curiosity, strengthen learning, and broaden horizons is immense. To create well-rounded learners, schools should make room for both theory and experience—inside and outside the classroom.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to discuss the educational value of field trips, outlining their benefits for engagement, soft skills, cross-disciplinary learning, and motivation, while also addressing drawbacks such as cost, safety, and time constraints, and concluding that they are powerful tools for experiential learning when well-planned.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is the main goal of a field trip?',
        explanation: 'The main goal is to make learning more engaging by offering real-world experiences that help students connect classroom concepts to the real world, making lessons more meaningful and memorable.',
      ),
      ReadingQuestion(
        question: 'The phrase "soft skills" in the third paragraph most likely refers to',
        explanation: 'In the context of field trips requiring planning, time management, teamwork, and curiosity, and building confidence, independence, and social awareness, soft skills refer to personal and interpersonal abilities that are not strictly academic or technical.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about students who struggle in traditional academic settings?',
        explanation: 'It can be inferred that some of these students, particularly visual or hands-on learners, may thrive on field trips because they understand concepts better through observation or interaction and become more engaged outside the rigid classroom structure, which can improve motivation and academic performance.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are some drawbacks of field trips?',
        explanation: 'Drawbacks include high costs for transport, entry fees, and meals that raise equity issues; safety concerns requiring risk assessments and supervision; and time constraints that may conflict with academic pressure and strict syllabi, leading some schools to avoid them.',
      ),
      ReadingQuestion(
        question: 'The word "equity" in the sixth paragraph most likely means',
        explanation: 'In the context of parents struggling to afford expenses and some students feeling excluded if they cannot participate, equity refers to fairness and equal access or opportunity for all students.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about virtual field trips compared to physical ones?',
        explanation: 'Virtual field trips are cheaper and easier to arrange but lack the sensory richness of physical visits; no video can fully replace the experience of standing in an ancient ruin or touching a historical artifact.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how can field trips support community connections?',
        explanation: 'Visits to local businesses, hospitals, or government offices show students how society functions, build civic understanding, help young people see their place in the wider world, and may inspire future careers or volunteer work.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the importance of planning for effective field trips?',
        explanation: 'Effective field trips require clear goals, links to classroom content, advance preparation of students, and follow-up activities such as presentations or discussions; reflection is essential to turn a fun outing into deep learning.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why are field trips especially valuable for environmental education?',
        explanation: 'Visiting places like a forest, recycling center, or wildlife park allows students to understand environmental issues firsthand; seeing the effects of pollution or conservation in real life often has a stronger impact than reading statistics in a book.',
      ),
    ],
  ),

  ReadingPassage(
    id: 34,
    title: 'Illiteracy',
    topic: 'Society & Education',
    content: '''Illiteracy—the inability to read and write—remains one of the most urgent global challenges in the 21st century. Although tremendous progress has been made in expanding education access, millions of people around the world still lack basic literacy skills. The consequences are severe, affecting not only individuals but also entire societies and economies.
According to UNESCO, over 770 million adults worldwide are functionally illiterate, most of them in developing countries. Women and girls make up nearly two-thirds of this population. Because education is often deprioritized for girls in certain cultures, gender inequality continues to drive illiteracy across generations. The causes of illiteracy are varied. Poverty is one of the main factors. Families who cannot afford school fees, books, or transportation often keep their children at home. In rural or conflict-affected regions, schools may be too far away, poorly staffed, or even unsafe. Children who grow up without regular schooling often enter adulthood without learning to read or write at all.
Another cause is limited support at home. If parents are illiterate, they may be unable to help their children with reading or homework. In some communities, education is not seen as necessary—especially if the main source of income is farming or manual labor. In such cases, children are expected to work rather than study.
The effects of illiteracy go far beyond academics. Illiterate individuals may struggle to fill out job applications, read safety instructions, or understand medicine labels. Their lack of literacy limits their access to information, legal rights, and healthcare. As a result, they are more vulnerable to exploitation, unemployment, and poverty.
From an economic perspective, widespread illiteracy slows national development. Countries with high illiteracy rates often suffer from low productivity, weak institutions, and poor public health outcomes. Investing in literacy is not only a human right but also an economic necessity. The more literate a population is, the more capable it becomes of driving innovation, governance, and sustainable growth.
Illiteracy also affects democracy. People who cannot read are less likely to understand political platforms, news articles, or voting procedures. This reduces their ability to participate in civic life. A truly democratic society depends on an educated, informed population that can make reasoned decisions and hold leaders accountable.
Technology has both helped and hindered the fight against illiteracy. On one hand, smartphones and online platforms offer access to free learning materials, digital libraries, and literacy apps. On the other hand, digital tools often require basic literacy to use in the first place. In many low-income areas, digital illiteracy and traditional illiteracy go hand in hand.
Governments and NGOs have launched various programs to reduce illiteracy. These include:
•        Adult literacy classes, often held in the evenings for working adults
•        Mobile libraries and learning vans, which bring books to rural communities
•        Teacher training initiatives, aimed at improving literacy instruction in early grades
•        Conditional cash transfers, rewarding families for keeping children in school Some countries have made remarkable progress. Bangladesh, for example, has significantly raised female literacy through community-led programs. In Brazil, a national campaign used TV, radio, and celebrities to encourage adult reading. Political will, investment, and local engagement have proven essential for longterm success.
Despite these efforts, challenges remain. Some people feel ashamed to admit they cannot read, making them reluctant to join adult classes. Others may start learning but drop out due to work, health, or family duties. In conflict zones or refugee camps, education is often disrupted or completely unavailable. Illiteracy is not just about lack of access—it‘s also about stigma, instability, and survival.
Early childhood education plays a crucial role in preventing illiteracy. Research shows that children who are exposed to books, storytelling, and early writing at home or in preschool are far more likely to become fluent readers. This means that literacy efforts must begin before primary school—and continue throughout life.
Multilingual environments present another challenge. In some countries, children speak one language at home but are taught to read and write in another. Without support in both languages, these students may fall behind. Inclusive and culturally relevant teaching strategies are necessary to make literacy accessible to all.
In conclusion, illiteracy is not just a lack of reading skills—it is a barrier to dignity, opportunity, and participation. Solving it requires more than building schools. It demands investment, political commitment, social awareness, and above all, the belief that every human being deserves the power of words. Literacy opens doors—not only to jobs and education, but to freedom, understanding, and selfexpression.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage explains the scale, causes, effects, and solutions related to illiteracy, emphasizing that it is a barrier to dignity and opportunity that requires comprehensive social and political efforts to overcome.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how many adults worldwide are functionally illiterate according to UNESCO?',
        explanation: 'UNESCO reports that over 770 million adults worldwide are functionally illiterate, with most living in developing countries and nearly two-thirds being women and girls.',
      ),
      ReadingQuestion(
        question: 'The word "functionally" in the second paragraph most likely means',
        explanation: 'In context, functionally illiterate refers to people who lack the practical reading and writing skills needed for everyday tasks and participation in society, even if they may have some minimal literacy.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the relationship between gender and illiteracy?',
        explanation: 'Gender inequality contributes to higher illiteracy rates among women and girls because education is often deprioritized for them in certain cultures, perpetuating the problem across generations.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does illiteracy affect democratic participation?',
        explanation: 'People who cannot read are less likely to understand political platforms, news, or voting procedures, which reduces their ability to participate in civic life and hold leaders accountable.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about technology\'s dual role in addressing illiteracy?',
        explanation: 'Technology provides free learning materials and literacy apps, but it also requires basic literacy skills to use, so digital and traditional illiteracy often reinforce each other in low-income areas.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are some programs used to reduce illiteracy?',
        explanation: 'Programs include adult literacy classes, mobile libraries and learning vans, teacher training initiatives, and conditional cash transfers that reward families for keeping children in school.',
      ),
      ReadingQuestion(
        question: 'The phrase "conditional cash transfers" in the eighth paragraph most likely means',
        explanation: 'Conditional cash transfers are financial rewards given to families on the condition that they keep their children in school, serving as an incentive to promote education and reduce illiteracy.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the importance of early childhood education?',
        explanation: 'Children exposed to books, storytelling, and early writing at home or in preschool are far more likely to become fluent readers, so literacy efforts must begin before primary school and continue throughout life.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why do some adults remain reluctant to join literacy classes?',
        explanation: 'Some people feel ashamed to admit they cannot read, while others drop out due to work, health, or family responsibilities, and education may be unavailable in conflict zones or refugee camps.',
      ),
    ],
  ),

  ReadingPassage(
    id: 35,
    title: 'Child Labor',
    topic: 'Society & Culture',
    content: '''Child labor refers to the employment of children in work that deprives them of their childhood, education, and dignity. Despite international laws and rising global awareness, millions of children around the world are still trapped in labor, especially in developing countries. This issue remains one of the most serious human rights concerns of our time.
According to the International Labour Organization (ILO), there are over 160 million child laborers worldwide. Nearly half of them are engaged in hazardous work—jobs that involve exposure to harmful chemicals, dangerous machinery, or long hours. Because these children are often forced to work under poor conditions, their health, development, and safety are severely at risk.
Child labor exists for many reasons. The most common is poverty. Families living in extreme poverty may rely on their children‘s income to survive. If parents cannot afford school fees or materials, they may choose work over education. In some regions, school is seen as a luxury rather than a right. As a result, children may spend their days in fields, factories, or streets instead of classrooms.
Another factor is weak law enforcement. Even where child labor laws exist, they are often ignored due to corruption, lack of monitoring, or economic pressure. Employers may prefer children because they are cheaper, easier to control, and less likely to protest. Without strong regulations, unethical labor practices continue unchecked.
Cultural norms also play a role. In some societies, it is considered normal for children to contribute to the family business, work on farms, or look after siblings. While light work may be acceptable, it becomes harmful when it interferes with education or endangers the child‘s well-being. The line between responsibility and exploitation is often blurred.
The consequences of child labor are long-lasting. Children who miss school often remain illiterate or semi-literate for life. This limits their future job opportunities and increases their risk of poverty in adulthood. The cycle continues across generations, as uneducated parents are more likely to send their own children to work.
Child labor also affects mental and emotional development. Many young workers experience stress, fatigue, abuse, or even trauma. They may lose their sense of play, trust, and hope. In extreme cases, children are trafficked or forced into criminal activities, such as begging or drug smuggling. These experiences can leave deep psychological scars.
Efforts to reduce child labor have shown mixed results. Some countries have made progress by increasing access to free primary education, improving social protection, and supporting poor families. Bangladesh, for example, has reduced child labor by investing in girls‘ education and vocational training. In Brazil, a cash transfer program rewards families who keep children in school. These policies demonstrate that prevention is possible when governments act boldly.
However, global crises like armed conflict, climate disasters, and pandemics have reversed some of this progress. During the COVID-19 pandemic, millions of children dropped out of school and entered the labor market. As families lost income, education was no longer a priority—and the risk of exploitation rose sharply.
One controversial question is whether all child work should be banned. Some experts argue that certain forms of work—like helping at a family shop for a few hours—can teach responsibility and skills. Others say that any labor that replaces schooling or puts children in danger must be eliminated completely. The challenge lies in setting clear, enforceable boundaries.
International organizations like UNICEF and the ILO have called for an end to child labor through coordinated global efforts. Their goals include:
•        Ensuring free, quality education for all children
•        Providing financial support to poor families
•        Enforcing labor laws and punishing offenders
•        Raising public awareness through campaigns and media
Corporations also have a role to play. Many global brands rely on supply chains that include child labor, especially in industries like textiles, agriculture, and mining. Pressure from consumers and watchdog groups has led some companies to adopt ethical sourcing policies and conduct factory inspections. Still, many abuses remain hidden in informal sectors.
Technology can help expose illegal child labor. Satellite imagery, smartphone reporting, and blockchain tracking are being tested to increase transparency in supply chains. But technology alone is not enough. A moral commitment is needed—from governments, companies, communities, and individuals—to protect the rights of every child.
In conclusion, child labor is not simply an economic issue—it is a moral one. While some families and cultures may see it as necessary, the long-term damage to children's lives is undeniable. No child should have to choose between survival and education. Ending child labor requires global cooperation, strong laws, and public compassion. Only then can we ensure that children are learning, growing, and dreaming—not working in silence.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage defines child labor, presents its scale and causes, describes its long-term consequences, reviews efforts and challenges in reducing it, and argues that ending it requires global cooperation, strong laws, and moral commitment.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how many child laborers are there worldwide according to the ILO?',
        explanation: 'The passage states that according to the International Labour Organization (ILO), there are over 160 million child laborers worldwide.',
      ),
      ReadingQuestion(
        question: 'The word "hazardous" in the passage most likely means',
        explanation: 'In context, "hazardous" describes work involving exposure to harmful chemicals, dangerous machinery, or long hours that puts children\'s health, development, and safety at severe risk.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the relationship between poverty and child labor?',
        explanation: 'The passage identifies poverty as the most common reason for child labor, noting that families in extreme poverty may rely on children\'s income and choose work over education when they cannot afford school costs.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are some long-term consequences of child labor?',
        explanation: 'The passage explains that children who miss school often remain illiterate or semi-literate, limiting future job opportunities and increasing the risk of poverty in adulthood, which can continue the cycle across generations.',
      ),
      ReadingQuestion(
        question: 'The word "exploitation" in the discussion of cultural norms most likely means',
        explanation: 'In context, "exploitation" refers to situations where children\'s work interferes with education or endangers their well-being, crossing the line from acceptable responsibility into harmful use of their labor.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the impact of the COVID-19 pandemic on child labor?',
        explanation: 'The passage states that during the pandemic millions of children dropped out of school and entered the labor market as families lost income, causing education to lose priority and sharply raising the risk of exploitation.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what goals have international organizations like UNICEF and the ILO set to end child labor?',
        explanation: 'The passage lists ensuring free quality education for all children, providing financial support to poor families, enforcing labor laws and punishing offenders, and raising public awareness through campaigns and media.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of corporations in addressing child labor?',
        explanation: 'The passage notes that many global brands rely on supply chains that include child labor, and that pressure from consumers and watchdog groups has led some companies to adopt ethical sourcing policies, though many abuses remain hidden in informal sectors.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is child labor described as a moral issue as well as an economic one?',
        explanation: 'The passage concludes that while some families and cultures may see child labor as necessary, the long-term damage to children\'s lives is undeniable, and no child should have to choose between survival and education.',
      ),
    ],
  ),

  ReadingPassage(
    id: 36,
    title: 'Juvenile Delinquency',
    topic: 'Crime & Society',
    content: '''Juvenile delinquency refers to illegal or antisocial behavior committed by individuals under the age of 18. It includes crimes such as theft, vandalism, assault, drug use, and gang involvement. While many young offenders commit minor acts, others engage in serious criminal activity. The causes and consequences of juvenile delinquency are complex and widely debated.
One major cause is family background. Children raised in unstable or violent homes are more likely to engage in criminal behavior. Because parental neglect, abuse, or lack of supervision can weaken a child‘s sense of right and wrong, many young people turn to risky behavior in search of attention or escape. In some cases, parents may themselves be involved in crime, setting a dangerous example. Another key factor is peer influence. During adolescence, the desire to fit in can be extremely strong. Teenagers who associate with delinquent peers may feel pressured to break the law to gain approval. Even those who would not normally commit crimes may do so under the influence of a group. Gangs, in particular, offer a false sense of belonging and identity, especially in poor or violent neighborhoods.
Education also plays a significant role. School failure, low academic achievement, and dropping out are linked to higher rates of juvenile delinquency. Students who feel alienated or humiliated in school may develop resentment and act out. Without positive role models or future goals, many lose hope and see crime as the only way forward.
Poverty is another powerful driver. In low-income areas, opportunities for legal success may be limited. Young people without jobs, money, or access to social services may resort to theft or drug dealing simply to survive. Because they see no alternative, crime becomes a form of economic survival.
Mental health problems often go unnoticed in juvenile offenders. Depression, trauma, ADHD, and substance abuse can increase the risk of criminal behavior if left untreated. Many young people in the justice system have experienced emotional pain or psychological distress, yet few receive the support they need.
The media and environment also contribute. Exposure to violence in films, games, or the news may normalize aggressive behavior. Living in neighborhoods with high crime rates can also desensitize youth to lawbreaking. If a child grows up seeing crime as a daily part of life, their moral boundaries may shift.
Governments deal with juvenile crime in different ways. Some focus on punishment—placing young offenders in detention centers or juvenile prisons. Others emphasize rehabilitation through counseling, education, and community service. The debate continues over which approach is more effective.
Supporters of rehabilitation argue that young people are still developing emotionally and mentally, and deserve a second chance. Harsh punishment, they say, often makes things worse by exposing youth to hardened criminals and damaging their self-esteem. By contrast, education and mentoring programs have been shown to reduce repeat offenses and help teens build a better future.
However, critics of soft approaches believe that leniency sends the wrong message. If crimes go unpunished, they argue, youth will not learn responsibility. Serious crimes must have serious consequences, even if committed by minors. Otherwise, justice is not served, and public safety is threatened.
Juvenile justice systems must find a balance between accountability and rehabilitation. Some countries use ―restorative justice‖ programs, where offenders meet victims to understand the harm they caused. Others invest in diversion programs that keep youth out of court by offering therapy, education, and life skills training. These models aim to break the cycle of crime rather than simply punish it. Education remains a crucial tool. School-based programs that teach emotional regulation, conflict resolution, and career planning can reduce dropout rates and prevent crime. When students feel supported and seen, they are less likely to fall into delinquency. After-school activities—sports, arts, and mentoring—also offer positive alternatives to street life.
Families and communities also have a role. Parenting classes, financial support, and youth centers can strengthen family bonds and offer safe spaces for teenagers. Religious institutions, sports clubs, and volunteer organizations can provide purpose and direction. It takes a whole society to guide youth away from crime.
In conclusion, juvenile delinquency is not caused by a single factor, but by a mix of family issues, social pressure, poverty, mental health, and environment. While punishment has its place, a focus on prevention, education, and emotional support is more likely to reduce youth crime in the long term. Every young person deserves the chance to learn from their mistakes and choose a better path.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to examine the causes of juvenile delinquency, the debate between punishment and rehabilitation, and the importance of prevention, education, and community support in addressing youth crime.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is one major cause of juvenile delinquency related to the home?',
        explanation: 'One major cause is family background; children raised in unstable or violent homes, or those experiencing parental neglect, abuse, or lack of supervision, are more likely to engage in criminal behavior.',
      ),
      ReadingQuestion(
        question: 'The word "desensitize" in the sixth paragraph most likely means...',
        explanation: 'In the context of the passage, "desensitize" means to make less sensitive or less reactive to crime and lawbreaking through repeated exposure.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of gangs in juvenile delinquency?',
        explanation: 'It can be inferred that gangs attract vulnerable youth by offering a false sense of belonging and identity, particularly in poor or violent neighborhoods where other positive options may be lacking.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does education relate to juvenile delinquency?',
        explanation: 'School failure, low academic achievement, and dropping out are linked to higher rates of juvenile delinquency, as students who feel alienated may develop resentment and see crime as their only path forward.',
      ),
      ReadingQuestion(
        question: 'The word "leniency" in the ninth paragraph most likely means...',
        explanation: 'In the context of the passage, "leniency" means a soft or merciful approach that does not impose strong punishment, which critics believe fails to teach responsibility.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about restorative justice programs?',
        explanation: 'It can be inferred that restorative justice programs aim to help offenders understand the harm they caused by meeting victims, focusing on breaking the cycle of crime rather than only punishing the offender.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why do supporters of rehabilitation favor that approach over harsh punishment?',
        explanation: 'Supporters argue that young people are still developing emotionally and mentally and deserve a second chance, while harsh punishment can expose them to hardened criminals and damage their self-esteem.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the importance of community involvement?',
        explanation: 'It can be inferred that families, schools, religious institutions, sports clubs, and volunteer organizations all play essential roles in providing support, purpose, and positive alternatives that guide youth away from crime.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what overall approach is more likely to reduce youth crime in the long term?',
        explanation: 'A focus on prevention, education, and emotional support is more likely to reduce youth crime in the long term than relying primarily on punishment.',
      ),
    ],
  ),

  ReadingPassage(
    id: 37,
    title: 'Disability',
    topic: 'Society & Rights',
    content: '''Disability refers to any physical, mental, intellectual, or sensory condition that limits a person's ability to perform everyday tasks. Globally, more than one billion people live with some form of disability. Despite being one of the largest minority groups, persons with disabilities often face discrimination, exclusion, and inequality in nearly every area of life.
Disabilities vary greatly. Some are visible, such as those requiring wheelchairs or prosthetic limbs. Others, like autism, hearing loss, or depression, are less obvious but equally challenging. Some are present from birth, while others result from accidents, illnesses, or aging. Because disability can affect anyone at any time, creating an inclusive society is not just a matter of compassion—it‘s a necessity.
Access to education is a major concern. Children with disabilities are significantly less likely to attend school, especially in developing countries. Many schools are not equipped with ramps, sign language interpreters, or special education staff. Without inclusive policies and proper resources, these children are left behind.
Employment is another key issue. People with disabilities often struggle to find work, even when they are qualified. Employers may assume they are less productive, more costly, or difficult to accommodate. This stigma leads to high unemployment rates and economic dependence. Inclusive hiring practices, flexible work environments, and anti-discrimination laws are essential for equal opportunity.
Public spaces and transportation systems can also be difficult to navigate. Inaccessible buildings, buses without ramps, or sidewalks without tactile markings make daily life more stressful and isolating. When infrastructure excludes people, so does society. Urban planning must prioritize universal design—spaces usable by everyone, regardless of ability.
Technology has brought both opportunities and challenges. Assistive technologies like screen readers, hearing aids, and mobility devices help millions live independently. However, many websites, apps, and services are still not designed with accessibility in mind. Digital exclusion is becoming a new form of inequality. Healthcare access is another barrier. People with disabilities often face medical staff who are not trained to understand their specific needs. Clinics may lack equipment for wheelchair users or staff fluent in sign language. In poorer areas, people with disabilities may be seen as a burden or ignored altogether. Health systems must treat disability not as a problem to fix, but as a human reality to support.
Social attitudes can be even harder to change than laws or buildings. In some cultures, disability is seen as a punishment, curse, or shame. These views lead to bullying, isolation, or even abandonment. In others, people with disabilities are seen as weak, dependent, or incapable. This mindset blocks progress, even when tools and laws are available.
Fortunately, global awareness is growing. The United Nations Convention on the Rights of Persons with Disabilities (CRPD) outlines the rights of disabled individuals and calls on governments to take action. Many countries now have disability rights laws, though enforcement remains uneven. Legal progress is meaningless without real-world change.
Representation matters, too. When people with disabilities are visible in politics, media, and leadership, stereotypes begin to fade. Paralympic athletes, disabled actors, and advocates have shown that disability does not equal inability. Their stories inspire not just empathy—but respect.
Inclusive education is a powerful tool. When children grow up learning alongside classmates with different abilities, they develop empathy, patience, and cooperation. Inclusion is not about lowering standards, but expanding access. With the right support, students with disabilities can thrive academically and socially.
Another debate is whether society should focus more on "fixing" the individual or changing the environment. This reflects the difference between the medical model of disability, which sees the disability as a problem in the person, and the social model, which sees barriers in society as the real issue. Most experts now favor the social model. The problem isn‘t the wheelchair—it‘s the stairs.
Support systems matter. Families caring for disabled children or adults need emotional, financial, and logistical help. Without it, they may feel overwhelmed or isolated. Governments can support families through caregiver allowances, therapy access, and respite services. Caring for people with disabilities is a shared social responsibility.
In conclusion, disability is not just a health condition—it‘s a human rights issue. People with disabilities deserve the same opportunities, dignity, and freedom as everyone else. While much progress has been made, true inclusion requires effort in every part of society—from schools and workplaces to laws and language. When we design a world for everyone, everyone benefits.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to examine disability as a widespread human rights issue, highlighting barriers in education, employment, infrastructure, healthcare, and attitudes, while advocating for inclusive policies and the social model of disability.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how many people globally live with some form of disability?',
        explanation: 'According to the passage, more than one billion people live with some form of disability, making them one of the largest minority groups.',
      ),
      ReadingQuestion(
        question: 'The word "stigma" in the fourth paragraph most likely means',
        explanation: 'In the context of the fourth paragraph, "stigma" refers to negative assumptions and prejudices that lead employers to view people with disabilities as less productive, more costly, or difficult to accommodate, resulting in high unemployment.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the importance of universal design?',
        explanation: 'It can be inferred that universal design is essential because inaccessible infrastructure excludes people with disabilities from society, and prioritizing spaces usable by everyone reduces isolation and stress in daily life.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is the difference between the medical model and the social model of disability?',
        explanation: 'According to the passage, the medical model sees disability as a problem in the person that needs fixing, while the social model sees barriers in society as the real issue; most experts now favor the social model, illustrated by the idea that the problem is not the wheelchair but the stairs.',
      ),
      ReadingQuestion(
        question: 'The word "assistive" in the sixth paragraph most likely means',
        explanation: 'In the context of the sixth paragraph, "assistive" means helping or supporting, referring to technologies like screen readers, hearing aids, and mobility devices that enable millions of people with disabilities to live independently.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of representation in changing attitudes toward disability?',
        explanation: 'It can be inferred that when people with disabilities appear in politics, media, and leadership roles, such as Paralympic athletes and disabled actors, stereotypes fade and inspire respect rather than just empathy, showing that disability does not equal inability.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is inclusive education considered a powerful tool?',
        explanation: 'According to the passage, inclusive education is powerful because children who learn alongside classmates with different abilities develop empathy, patience, and cooperation, and with the right support, students with disabilities can thrive academically and socially without lowering standards.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the challenges faced by families caring for people with disabilities?',
        explanation: 'It can be inferred that without emotional, financial, and logistical support, families may feel overwhelmed or isolated, and governments can help through measures like caregiver allowances, therapy access, and respite services as part of a shared social responsibility.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what document outlines the rights of persons with disabilities and calls on governments to take action?',
        explanation: 'According to the passage, the United Nations Convention on the Rights of Persons with Disabilities (CRPD) outlines these rights and urges governments to act, though enforcement of related national laws remains uneven.',
      ),
    ],
  ),

  ReadingPassage(
    id: 38,
    title: 'Doping',
    topic: 'Sports & Ethics',
    content: '''Doping refers to the use of banned substances or methods by athletes to improve their performance. From professional cycling to Olympic sprinting, doping scandals have repeatedly shaken the sports world, raising serious questions about fairness, ethics, and the true meaning of competition.
Athletes who dope often take drugs like steroids, hormones, or stimulants to increase strength, speed, or endurance. Some use blood transfusions or advanced medical treatments to enhance oxygen delivery to muscles. These techniques are usually hidden and difficult to detect. Because of this, many athletes escape punishment—at least for a time.
The main argument in favor of banning doping is fairness. Sport is meant to be a test of natural talent, hard work, and discipline. When athletes use artificial aids, they gain an unfair advantage over their clean competitors. This not only ruins the level playing field, but also damages public trust in the sport.
Health risks are another major concern. Many performance-enhancing drugs have serious side effects, including liver damage, heart problems, infertility, and psychological disorders. Some athletes have even died as a result of doping. Because the long-term effects are often unknown, the danger is greater than most athletes realize.
There is also the issue of pressure. In high-level sports, where success can bring fame and fortune, athletes may feel forced to dope just to keep up. If one competitor is cheating and winning, others may feel they have no choice but to follow. This creates a toxic environment where ethics are sacrificed for medals.
To fight doping, organizations like the World Anti-Doping Agency (WADA) were created. WADA maintains a list of banned substances, conducts random drug tests, and supports research into detection methods. Athletes who test positive can face suspensions, stripped titles, or lifetime bans. However, enforcing these rules is a constant battle.
Some doping methods are extremely sophisticated. In the case of Russian athletics, entire national programs were found guilty of state-sponsored doping. Labs were altered, samples were swapped, and results were faked. Such large-scale corruption shows that doping is not just a personal issue—it can be political.
Technology has made doping harder to detect. Micro-dosing, gene editing, and new designer drugs often go undetected by traditional tests. This has led to the introduction of the biological passport, a digital record of an athlete‘s body levels over time. Sudden changes may signal foul play, even without a positive test. Still, no system is perfect.
Not everyone agrees that doping should be banned. Some argue that the line between legal and illegal performance aids is unclear. For example, altitude training, strict diets, and legal supplements all enhance performance—but are allowed. Why should synthetic hormones be treated differently?
Others argue for legalization and regulation. If doping were made legal under medical supervision, they claim, the playing field would level out and health risks could be reduced. Athletes would no longer need to hide or lie. But critics say this would send the wrong message to young athletes—that cheating is acceptable if it works.
Ethics remain at the center of the doping debate. Is sport still meaningful if it becomes a competition of chemistry, not character? Should we reward those who push science further—or punish them for betraying tradition? These are not just athletic questions, but cultural and moral ones.
Doping also affects public perception. When a famous athlete is caught, fans feel betrayed. Records lose meaning, medals seem fake, and trust disappears. Spectators want to believe in heroes—but doping turns them into frauds.
Young athletes are especially vulnerable. Teenagers who see doped champions may think success is impossible without drugs. This can lead to early substance abuse, health problems, and even criminal activity. Role models must set a clean example—or risk destroying the future of the sport.
Education is essential. Anti-doping campaigns in schools, sports clubs, and training academies help raise awareness about the risks and consequences. Athletes should be taught that true success comes from effort, not shortcuts.
In conclusion, doping is a serious threat to the integrity, health, and spirit of sport. While science may offer new ways to cheat, rules and values must evolve to keep competition fair. The goal of sport is not just to win—but to do so with honor, dignity, and respect for others. Without that, the meaning of victory disappears.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to explain what doping is, why it is banned, its health risks and pressures, the efforts of organizations like WADA to combat it, sophisticated methods and detection challenges, arguments for and against legalization, its effects on public perception and young athletes, and the conclusion that doping threatens the integrity and spirit of sport, which should value honor and fairness.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is the main argument in favor of banning doping?',
        explanation: 'According to the passage, the main argument in favor of banning doping is fairness: sport is meant to be a test of natural talent, hard work, and discipline, and artificial aids give athletes an unfair advantage that ruins the level playing field and damages public trust.',
      ),
      ReadingQuestion(
        question: 'The word "toxic" in the fifth paragraph most likely means',
        explanation: 'In the fifth paragraph, "toxic" most likely means harmful or destructive, describing an environment created by doping pressure where ethics are sacrificed for medals.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of WADA?',
        explanation: 'It can be inferred that the World Anti-Doping Agency (WADA) plays a central role in fighting doping by maintaining a list of banned substances, conducting random drug tests, supporting research into detection methods, and imposing penalties such as suspensions, stripped titles, or lifetime bans, though enforcing the rules remains a constant battle.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what does the biological passport involve?',
        explanation: 'According to the passage, the biological passport is a digital record of an athlete‘s body levels over time; sudden changes may signal foul play even without a positive test, and it was introduced because technology has made methods like micro-dosing, gene editing, and designer drugs harder to detect with traditional tests.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about state-sponsored doping?',
        explanation: 'It can be inferred that doping can be political and large-scale rather than purely personal, as shown by the case of Russian athletics where entire national programs were found guilty of state-sponsored doping involving altered labs, swapped samples, and faked results.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what health risks are associated with performance-enhancing drugs?',
        explanation: 'According to the passage, many performance-enhancing drugs have serious side effects including liver damage, heart problems, infertility, and psychological disorders; some athletes have even died as a result of doping, and the long-term effects are often unknown, increasing the danger.',
      ),
      ReadingQuestion(
        question: 'The phrase "level playing field" in the passage most likely refers to',
        explanation: 'In the passage, "level playing field" refers to a fair competitive situation in which all athletes compete under the same conditions without artificial advantages from doping, which the text says is ruined when athletes use banned substances or methods.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the impact of doping on young athletes?',
        explanation: 'It can be inferred that young athletes are especially vulnerable because seeing doped champions may lead them to believe success is impossible without drugs, potentially resulting in early substance abuse, health problems, and even criminal activity; therefore role models must set a clean example to protect the future of the sport.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why do some people argue for legalizing and regulating doping?',
        explanation: 'According to the passage, some argue that if doping were made legal under medical supervision, the playing field would level out, health risks could be reduced, and athletes would no longer need to hide or lie; however, critics counter that this would send the wrong message to young athletes that cheating is acceptable if it works.',
      ),
    ],
  ),

  ReadingPassage(
    id: 39,
    title: 'Crime',
    topic: 'Crime & Society',
    content: '''Crime is a global issue that affects every society, regardless of wealth, culture, or political system. From petty theft to organized gangs, from cybercrime to violent assaults, criminal activity shapes how people live, work, and interact with one another. Understanding the causes and consequences of crime is essential for creating safer, more just societies.
One of the most widely discussed causes of crime is poverty. When people lack access to food, shelter, or employment, they may turn to illegal means of survival. Because economic desperation limits legal choices, some view crime as the only way to support themselves or their families. However, poverty alone does not explain all crime.
Education plays a major role in crime prevention. Individuals who complete secondary or higher education are less likely to commit crimes. Schools provide not only knowledge but also structure, life skills, and social development. In communities where education is underfunded or inaccessible, youth are more vulnerable to criminal influences.
Family background is another important factor. Children raised in violent or unstable homes often experience emotional trauma, lack discipline, and struggle with authority. Without guidance or support, they may fall into crime at an early age. The absence of strong role models increases the risk of delinquency.
Peer pressure and social environment also matter. Young people surrounded by gangs, drugs, or crime are more likely to become involved themselves. In such areas, illegal behavior can be seen as normal or even necessary for survival. Changing the environment can change the behavior.
Not all crime is committed out of need. Some people break the law for power, revenge, or thrill. White-collar criminals, for example, may be wealthy individuals who commit fraud, embezzlement, or tax evasion. These crimes may not involve physical violence but cause massive harm to the economy and society.
Technology has introduced new types of crime. Cybercrime, such as hacking, identity theft, and online scams, is now one of the fastest-growing forms of criminal activity. Criminals no longer need to leave their homes to commit offenses. Because digital evidence is harder to trace and laws are often outdated, catching online criminals can be difficult.
Law enforcement agencies use various strategies to fight crime. These include community policing, surveillance systems, undercover operations, and intelligence gathering. In some countries, heavy punishment such as long prison terms or even the death penalty is used to deter criminals. However, the effectiveness of harsh penalties remains controversial.
Some experts argue that prevention is more effective than punishment. Investing in education, job training, mental health support, and social services can address the root causes of crime. Rather than waiting for crimes to happen, societies can build systems that reduce the likelihood of criminal behavior in the first place.
The justice system is responsible for ensuring that those who commit crimes are fairly tried and, if guilty, appropriately punished. But justice is not always equal. In many countries, wealthy or powerful individuals are less likely to be punished, while the poor face harsher treatment. This leads to public mistrust in legal institutions.
Prisons are meant to punish and rehabilitate. However, overcrowded and underfunded prisons often fail to reform inmates. In some cases, prisoners return to crime shortly after being released. Rehabilitation programs that teach skills, offer counseling, and support reintegration are more successful in reducing repeat offenses.
The media plays a powerful role in shaping how people view crime. News outlets often focus on violent crimes, creating fear and exaggerating risk. While public awareness is important, sensational reporting can lead to prejudice, panic, and demands for overly harsh laws.
In recent years, some countries have experimented with restorative justice. This system focuses on repairing harm between the victim and offender, rather than punishment alone. Offenders are encouraged to accept responsibility and make amends. Restorative practices aim to heal, not just punish.
Cultural and legal views on crime vary widely. In some countries, theft may lead to long prison terms; in others, minor crimes may be handled with warnings or community service. Some legal systems focus on rehabilitation, while others emphasize strict control. There is no single solution—but all societies must find a balance between justice, safety, and human rights.
In conclusion, crime is a complex issue with many root causes: poverty, education, family, peer pressure, and personal choice. While policing and punishment are necessary, long-term solutions must focus on prevention, equality, and rehabilitation. A safer society is not just one with more police—but one with more opportunity, fairness, and support.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to examine crime as a global issue, explore its various causes such as poverty, education, family, and peer pressure, discuss types of crime including cybercrime and white-collar crime, and argue that long-term solutions require prevention, equality, and rehabilitation rather than punishment alone.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is education considered important in preventing crime?',
        explanation: 'According to the passage, individuals who complete secondary or higher education are less likely to commit crimes because schools provide knowledge, structure, life skills, and social development; in communities where education is underfunded or inaccessible, youth are more vulnerable to criminal influences.',
      ),
      ReadingQuestion(
        question: 'The word "delinquency" in the paragraph about family background most likely means',
        explanation: 'In the context of the passage, "delinquency" most likely means minor crime or antisocial behavior by young people, as the text links the absence of strong role models and unstable homes to an increased risk of children falling into crime at an early age.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about white-collar crime from the passage?',
        explanation: 'It can be inferred that white-collar crime is not driven by economic need, since it is committed by wealthy individuals for reasons such as power, and although it may not involve physical violence, it causes massive harm to the economy and society through acts like fraud, embezzlement, or tax evasion.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why can catching cybercriminals be difficult?',
        explanation: 'According to the passage, catching online criminals can be difficult because digital evidence is harder to trace and laws are often outdated, even though cybercrime such as hacking, identity theft, and online scams is one of the fastest-growing forms of criminal activity.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the effectiveness of prisons from the passage?',
        explanation: 'It can be inferred that overcrowded and underfunded prisons often fail at rehabilitation, leading some prisoners to return to crime after release, whereas programs that teach skills, offer counseling, and support reintegration are more successful in reducing repeat offenses.',
      ),
      ReadingQuestion(
        question: 'The phrase "restorative justice" in the passage most likely refers to',
        explanation: 'In the context of the passage, "restorative justice" refers to a system that focuses on repairing harm between the victim and offender rather than punishment alone, encouraging offenders to accept responsibility and make amends with the aim of healing.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does the media influence public views on crime?',
        explanation: 'According to the passage, the media often focuses on violent crimes, creating fear and exaggerating risk; while public awareness is important, sensational reporting can lead to prejudice, panic, and demands for overly harsh laws.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about justice systems from the passage?',
        explanation: 'It can be inferred that justice is not always equal, because in many countries wealthy or powerful individuals are less likely to be punished while the poor face harsher treatment, which leads to public mistrust in legal institutions.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what do some experts believe is more effective than punishment in addressing crime?',
        explanation: 'According to the passage, some experts argue that prevention is more effective than punishment, and that investing in education, job training, mental health support, and social services can address the root causes of crime and reduce the likelihood of criminal behavior.',
      ),
    ],
  ),

  ReadingPassage(
    id: 40,
    title: 'Violence',
    topic: 'Society & Culture',
    content: '''Violence is the intentional use of force or power that causes harm, injury, or death to others. It can be physical, emotional, or psychological—and it affects individuals, families, and societies. Despite global efforts to reduce it, violence remains a daily reality in many parts of the world.
Violence takes many forms. It can occur between individuals (domestic abuse, assault), within communities (gang violence, riots), or at the national level (civil wars, terrorism). It can be visible, such as shootings or fights, or invisible, like emotional abuse or online harassment. Because violence can be both direct and indirect, it is often hard to measure or control.
One of the most common types is domestic violence. Women and children are especially vulnerable to abuse at home, where it is hidden from public view. Victims often suffer in silence, fearing shame or retaliation. Cultural norms, economic dependence, and lack of legal protection make it difficult for them to escape.
Youth violence is also a serious problem. Teenagers involved in gangs or exposed to violent environments may turn to weapons, drugs, and aggression. Because many lack access to education, role models, or employment, violence can become their way of life.
Another rising concern is media violence. Violent video games, films, and online content may desensitize viewers or normalize aggression. Some studies suggest a link between media exposure and aggressive behavior, especially in children. Others argue that the connection is weak or exaggerated. The debate continues, but the influence of media is undeniable.
Terrorism and political violence cause mass destruction and fear. In some regions, armed groups use violence to gain control, send messages, or fight against governments. Civilians often suffer the most, as they are caught between opposing forces. When political goals are pursued through fear and death, society breaks down.
The causes of violence are complex. Poverty, inequality, and unemployment are major contributors. People who feel excluded, powerless, or hopeless may become angry or violent. When justice, opportunity, and respect are missing, violence fills the gap.
Substance abuse is another factor. Alcohol and drugs lower self-control and increase impulsive behavior. Many violent crimes occur under the influence. Addiction does not excuse violence, but it helps explain it.
Mental health can also play a role. Some individuals with untreated psychological conditions may act out violently. But it is important not to generalize—most people with mental illness are not violent, and most violent people are not mentally ill.
Preventing violence requires long-term, coordinated efforts. Education is key. Teaching children emotional intelligence, respect, and non-violent communication from an early age helps build peaceful habits. Schools must become safe spaces— not only for learning, but for emotional growth.
Community programs that offer youth mentoring, sports, and job training can reduce crime and gang activity. When people have hope and structure, they are less likely to turn to violence.
Law enforcement plays a major role in responding to violence. But police brutality or excessive force can create more conflict. Trust must be built between communities and the police, or justice becomes fear. Training officers in deescalation, diversity, and ethics is essential.
Internationally, peacekeeping missions, diplomacy, and humanitarian aid help reduce large-scale violence. But military intervention alone cannot solve deeprooted problems. True peace requires rebuilding trust, infrastructure, and shared identity.
Technology has introduced new forms of violence. Cyberbullying, online threats, and digital hate speech can cause real psychological damage. Because online spaces are often unregulated, victims have little protection. Social media platforms must do more to monitor and block harmful behavior.
Legal systems must also adapt. In some countries, violence—especially against women or minorities—is tolerated or ignored. Laws must be updated, enforced, and supported by public education campaigns. No act of violence should be accepted as normal.
Gender-based violence deserves special attention. Worldwide, one in three women experiences physical or sexual violence in her lifetime. Many are attacked by their own partners. Ending this crisis requires both legal action and cultural change.
In conclusion, violence is not just a personal problem—it is a social, economic, and political one. Reducing it demands education, fairness, opportunity, and compassion. A safer world is not built by fear or force—but by dignity, justice, and the will to protect others.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage defines violence, describes its various forms and causes, examines specific types such as domestic, youth, media, and political violence, and discusses prevention strategies involving education, community programs, law enforcement, technology regulation, and legal reforms to reduce violence through dignity, justice, and compassion.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is domestic violence often difficult for victims to escape?',
        explanation: 'Victims often suffer in silence due to fear of shame or retaliation, and cultural norms, economic dependence, and lack of legal protection make it difficult for them to escape abuse that is hidden from public view.',
      ),
      ReadingQuestion(
        question: 'The word "desensitize" in the paragraph about media violence most likely means',
        explanation: 'It means to make less sensitive or emotionally responsive, as violent video games, films, and online content may desensitize viewers or normalize aggression.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the relationship between poverty and violence?',
        explanation: 'Poverty, inequality, and unemployment are major contributors to violence; people who feel excluded, powerless, or hopeless may become angry or violent when justice, opportunity, and respect are missing.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what role does substance abuse play in violence?',
        explanation: 'Alcohol and drugs lower self-control and increase impulsive behavior, and many violent crimes occur under the influence; while addiction does not excuse violence, it helps explain it.',
      ),
      ReadingQuestion(
        question: 'The word "deeprooted" in the paragraph about international efforts most likely means',
        explanation: 'It means firmly established or deeply embedded, as military intervention alone cannot solve deeprooted problems, and true peace requires rebuilding trust, infrastructure, and shared identity.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the connection between media violence and aggressive behavior?',
        explanation: 'Some studies suggest a link between media exposure and aggressive behavior, especially in children, while others argue the connection is weak or exaggerated; the debate continues, but the influence of media is described as undeniable.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how can education help prevent violence?',
        explanation: 'Teaching children emotional intelligence, respect, and non-violent communication from an early age helps build peaceful habits, and schools must become safe spaces not only for learning but for emotional growth.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the challenges of using law enforcement to address violence?',
        explanation: 'While law enforcement plays a major role in responding to violence, police brutality or excessive force can create more conflict; trust must be built between communities and police, and officers need training in deescalation, diversity, and ethics.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what statistic highlights the scale of gender-based violence?',
        explanation: 'Worldwide, one in three women experiences physical or sexual violence in her lifetime, and many are attacked by their own partners; ending this crisis requires both legal action and cultural change.',
      ),
    ],
  ),

  ReadingPassage(
    id: 41,
    title: 'City Life',
    topic: 'Society & Culture',
    content: '''City life offers a mix of opportunity, diversity, and challenge. As the global population becomes increasingly urban, more people are choosing—or being forced—to live in cities. Because cities are centers of economic activity, education, and culture, they attract millions every year from rural and suburban areas.
One of the main advantages of city life is access. Cities provide better access to jobs, schools, hospitals, and public services. Whether it‘s a university or a specialist doctor, city residents can usually find what they need nearby. This convenience can lead to higher living standards and improved quality of life.
Cities are also hubs of innovation and creativity. People from different backgrounds bring unique skills, languages, and ideas. Art galleries, theaters, and music venues offer constant stimulation. Because of this cultural richness, city dwellers are often more exposed to global trends, movements, and perspectives. Public transport is another benefit. Unlike rural areas where owning a car is essential, cities often provide buses, subways, and bike lanes. This reduces traffic congestion, cuts down pollution, and makes commuting more affordable. Efficient transport systems are a major reason why cities remain attractive.
However, city life is not without problems. One of the biggest issues is overcrowding. As urban populations grow, housing becomes limited and expensive. In many cities, people are forced to live in cramped apartments or informal settlements. This leads to poor sanitation, limited privacy, and increased stress.
Noise and pollution are other major concerns. Cars, factories, and construction sites make city life loud and chaotic. Air quality in urban areas is often poor, which can cause health problems like asthma or heart disease. Because green space is limited, city residents may lack access to parks, trees, and clean air.
Crime is another drawback. High population density, inequality, and unemployment can lead to increased rates of theft, assault, or drug use. While some cities are safe, others struggle to maintain law and order. Fear of crime can reduce social trust and make city life feel dangerous.
Social isolation can also occur. Ironically, despite being surrounded by millions, many city residents feel lonely. Fast-paced lifestyles, long working hours, and constant movement can weaken social bonds. People may know their neighbors less, and personal connections may feel superficial.
Cost of living is yet another challenge. Rent, food, transportation, and entertainment are often far more expensive in cities than in rural areas. This puts pressure on working-class families and young people. Some find themselves working multiple jobs just to cover basic expenses.
Still, for many people, the benefits outweigh the drawbacks. Cities continue to offer better career prospects, advanced healthcare, and access to global networks. Urban areas create more than 80% of global GDP, making them critical engines of development.
Governments around the world are trying to make cities more livable through urban planning and investment. Initiatives like smart cities, bike-sharing programs, and green roofs aim to reduce congestion and improve sustainability. Public housing projects and urban gardens are also being introduced to support lowincome communities.
Education is another area where cities excel. From elite universities to vocational training centers, cities offer more educational choices. Because access to information and learning opportunities is higher, urban youth often have better chances at success.
The rise of megacities—urban areas with over 10 million people—brings both opportunity and danger. While they may offer global influence and economic power, they also face extreme inequality, environmental degradation, and infrastructure overload. Managing such large populations requires smart governance and long-term vision.
Technology plays a growing role in shaping city life. From mobile apps for transport to AI-powered traffic lights, cities are becoming more connected. But these advancements also raise concerns about surveillance, privacy, and social inequality. Not everyone benefits equally from digital innovation.
In conclusion, city life is full of contrast—convenience and chaos, culture and congestion, growth and inequality. Whether it brings success or stress depends largely on how well cities are managed, and how individuals adapt to their fastchanging environments. As more of the world becomes urban, understanding how to live well in cities will become increasingly important.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of this passage is to discuss the advantages and challenges of city life, covering access to opportunities and services, cultural richness, public transport benefits, problems such as overcrowding, pollution, crime, isolation, and high costs, as well as efforts to improve urban living through planning, technology, and education, concluding that successful city life depends on effective management and individual adaptation.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are some advantages of living in a city?',
        explanation: 'Cities provide better access to jobs, schools, hospitals, and public services, leading to higher living standards. They are hubs of innovation and creativity with cultural richness from diverse people. Public transport reduces congestion and pollution while making commuting more affordable. Cities also offer better career prospects, advanced healthcare, access to global networks, and more educational choices.',
      ),
      ReadingQuestion(
        question: 'The word \'overcrowding\' in paragraph 4 most likely means?',
        explanation: 'It most likely means a situation where too many people live in a limited space, as the passage explains that as urban populations grow, housing becomes limited and expensive, forcing people into cramped apartments or informal settlements that lead to poor sanitation, limited privacy, and increased stress.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the cost of living in cities?',
        explanation: 'It can be inferred that the high cost of living in cities creates significant financial pressure, as rent, food, transportation, and entertainment are far more expensive than in rural areas, forcing some working-class families and young people to work multiple jobs just to cover basic expenses.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how are governments trying to improve city life?',
        explanation: 'Governments are trying to make cities more livable through urban planning and investment, including initiatives like smart cities, bike-sharing programs, and green roofs to reduce congestion and improve sustainability, as well as public housing projects and urban gardens to support low-income communities.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about megacities from the passage?',
        explanation: 'It can be inferred that megacities, defined as urban areas with over 10 million people, present both significant opportunities such as global influence and economic power, and serious dangers including extreme inequality, environmental degradation, and infrastructure overload, requiring smart governance and long-term vision to manage.',
      ),
    ],
  ),

  ReadingPassage(
    id: 42,
    title: 'Country Life',
    topic: 'Society & Lifestyle',
    content: '''Country life, often associated with simplicity, nature, and peace, stands in sharp contrast to the speed and noise of urban living. While some people see rural life as outdated, others value its strong sense of community and closeness to nature. As modern society continues to urbanize, debates over rural versus urban living have grown more intense.
One of the biggest advantages of living in the countryside is peace and quiet. Unlike cities, where noise pollution is constant, rural areas tend to be calm and clean. Because traffic is minimal and buildings are widely spaced, people experience less stress and fewer distractions. Many believe this environment supports mental health and emotional well-being.
Another benefit is the connection to nature. Countryside residents often live near rivers, forests, or mountains. This allows for outdoor activities like hiking, fishing, or farming. Fresh air, green landscapes, and slower routines are part of daily life. For many, this natural rhythm is more satisfying than city routines filled with deadlines and digital screens.
Community ties are typically stronger in the country. In rural villages, people often know each other well. Because of smaller populations, social relationships are more personal and supportive. Neighbors help each other, and traditions are passed down through generations. In times of crisis, rural communities tend to show more unity and cooperation.
Cost of living is usually lower. Housing is more affordable, land is more available, and everyday expenses like food and transport tend to be cheaper. This makes country life attractive for families, retirees, or those seeking a simpler lifestyle. People can grow their own food, raise animals, and depend less on supermarkets and services.
However, rural living also has its challenges. Access to healthcare is limited in many areas. Small villages may not have hospitals or even clinics. In emergencies, patients often need to travel long distances. This lack of services can be lifethreatening, especially for the elderly or chronically ill.
Education can be another issue. Country schools often have fewer resources, outdated facilities, and difficulty attracting skilled teachers. Students in rural areas may have fewer academic and extracurricular opportunities, making it harder for them to compete with urban peers.
Employment opportunities are limited as well. Many rural economies depend on agriculture or small local businesses. There are fewer jobs in finance, technology, or international trade. Because of this, young people often move to cities for better prospects, leaving rural areas with aging populations and labor shortages.
Public transportation is also weak or nonexistent. Most country residents need private vehicles to travel to work, school, or hospitals. For those without cars— especially the poor, disabled, or elderly—this isolation can be severe. In some villages, a trip to the nearest town may take over an hour.
Social life in rural areas can feel limited. There may be fewer entertainment options, such as cinemas, cafés, or museums. In some places, conservative traditions may restrict personal freedom or discourage diversity. This can create feelings of boredom, loneliness, or exclusion—especially for newcomers or young adults.
Despite these drawbacks, rural life continues to attract people searching for peace, health, and meaning. Some urban residents have begun relocating to the countryside, especially since the rise of remote work. Technology has made it easier to live in rural areas while staying connected to city jobs or services.
Governments in many countries are trying to improve rural life. Investments in infrastructure, internet access, education, and healthcare aim to reduce the urbanrural gap. Support for farmers, small businesses, and rural tourism can also boost local economies and preserve rural cultures.
The environmental benefits of country living are also worth noting. Less pollution, more green space, and lower population density help protect natural resources and biodiversity. Many rural communities practice sustainable living—relying on solar panels, local food, and minimal waste. These practices may serve as models for more eco-friendly lifestyles.
In conclusion, country life offers peace, community, and a connection to nature— but also faces serious challenges like limited services, job scarcity, and social isolation. While rural areas may not suit everyone, they provide a valuable alternative to city life, especially for those who value simplicity and space. As societies evolve, balancing development between rural and urban regions will be crucial.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to compare country life with urban living by describing the advantages of rural areas such as peace, nature, community, and lower costs, while also examining challenges like limited healthcare, education, jobs, and transportation, and noting ongoing efforts to improve rural conditions.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is one of the biggest advantages of living in the countryside?',
        explanation: 'Peace and quiet. Unlike cities with constant noise pollution, rural areas tend to be calm and clean with minimal traffic and widely spaced buildings, which many believe supports mental health and emotional well-being.',
      ),
      ReadingQuestion(
        question: 'The word \'isolation\' in the ninth paragraph most likely means...',
        explanation: 'A state of being separated or cut off from others or services. The passage notes that for those without cars, especially the poor, disabled, or elderly, the weak or nonexistent public transportation can cause severe isolation.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about community life in rural areas?',
        explanation: 'Community ties are typically stronger because smaller populations lead to more personal and supportive relationships; neighbors help each other, traditions are passed down, and rural communities tend to show more unity and cooperation in times of crisis.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why do many young people leave rural areas?',
        explanation: 'Employment opportunities are limited, as many rural economies depend on agriculture or small local businesses with fewer jobs in finance, technology, or international trade, so young people move to cities for better prospects, leaving aging populations and labor shortages.',
      ),
      ReadingQuestion(
        question: 'The phrase \'urbanrural gap\' in the twelfth paragraph most likely means...',
        explanation: 'The differences or disparities between urban and rural areas in areas such as infrastructure, internet access, education, and healthcare that governments aim to reduce through investments and support.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the impact of remote work on country life?',
        explanation: 'The rise of remote work has encouraged some urban residents to relocate to the countryside, and technology has made it easier to live in rural areas while remaining connected to city jobs or services.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what environmental benefits does country living offer?',
        explanation: 'Less pollution, more green space, and lower population density help protect natural resources and biodiversity; many rural communities practice sustainable living with solar panels, local food, and minimal waste that may serve as models for eco-friendly lifestyles.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about education in rural areas?',
        explanation: 'Country schools often have fewer resources, outdated facilities, and difficulty attracting skilled teachers, so students may have fewer academic and extracurricular opportunities and find it harder to compete with urban peers.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what makes country life attractive despite its challenges?',
        explanation: 'It continues to attract people seeking peace, health, and meaning through lower cost of living, connection to nature, stronger community ties, and the possibility of a simpler lifestyle, including growing food and depending less on external services.',
      ),
    ],
  ),

  ReadingPassage(
    id: 43,
    title: 'Housing',
    topic: 'Society & Economy',
    content: '''Housing is a basic human need, but in many parts of the world, finding affordable, safe, and comfortable living space has become a serious challenge. Whether in wealthy nations or developing countries, access to adequate housing shapes quality of life, health, and economic stability.
In urban areas, housing demand has outpaced supply. As more people move to cities for work and education, real estate prices have soared. Because land is limited and construction costs are high, apartments and homes have become unaffordable for average workers. In some cities, even professionals cannot buy or rent homes near their workplace.
This has led to a rise in overcrowding. Families are forced to share small flats, live far from city centers, or remain in poor-quality buildings. When people live in cramped, unsafe spaces, it affects their physical and mental health. Lack of ventilation, poor sanitation, and structural issues can lead to disease, injury, and stress.
At the same time, many governments struggle with housing inequality. Wealthy individuals often own multiple properties, while low-income families cannot afford even one. In extreme cases, entire neighborhoods are gentrified—transformed by wealthy buyers—forcing long-term residents to move out. This process widens the gap between rich and poor.
In developing countries, the problem is more severe. Millions of people live in informal settlements or slums without legal ownership, clean water, or electricity. These communities grow rapidly, often without planning or infrastructure. Because of their illegal status, residents may face eviction, violence, or disaster risks such as flooding or fires.
Social housing is one possible solution. These are homes built or subsidized by the government for low-income citizens. In countries like Sweden or the Netherlands, social housing plays a large role in maintaining affordability. However, when poorly managed or underfunded, public housing can fall into disrepair and become unsafe.
Some experts believe that the housing crisis is a result of poor urban planning. In many cities, land is not used efficiently. Too much space is given to roads, parking, or luxury buildings, while affordable housing is ignored. Urban areas must prioritize mixed-use development and inclusionary zoning to balance needs.
Others argue that the private market alone cannot solve the crisis. When housing becomes an investment instead of a right, prices rise and speculation increases. Regulation is needed to prevent property hoarding and keep homes accessible to ordinary people.
Home ownership remains a goal for many, but the reality is changing. In the past, buying a house was seen as a sign of success and security. Today, especially among young people, renting is more common due to high prices, job instability, and urban mobility. As economic conditions change, so do attitudes toward housing.
Technology has introduced both solutions and complications. Smart homes, energy-efficient buildings, and modular construction can make housing more sustainable. However, luxury developments often focus on profit rather than accessibility. Digital platforms have also driven up rental prices by turning homes into vacation properties.
The environment must also be considered. Construction is one of the most polluting industries in the world. Building green homes using local materials, solar power, and efficient design can reduce emissions and long-term costs. Sustainable housing is not only a climate issue—it‘s an economic and social one. Governments have several tools to improve housing access:
•        Investing in affordable housing projects
•        Offering subsidies or tax breaks for first-time buyers
•        Controlling rent prices through legislation
•        Promoting rural housing to reduce urban pressure
•        Supporting homeless shelters and emergency housing
Homelessness remains a tragic and growing crisis in many countries. Rising costs, unemployment, and mental illness contribute to the issue. Sleeping rough should not exist in wealthy societies where resources are available but poorly distributed. Cultural expectations also shape housing norms. In some cultures, extended families live together under one roof. In others, independence is valued and young adults move out early. These preferences influence the size, location, and design of homes. Policies must reflect cultural realities, not just economic models.
In conclusion, housing is not just about walls and roofs—it is about stability, dignity, and opportunity. While the private market plays a role, governments and communities must ensure that housing is fair, affordable, and sustainable for all.
The true measure of progress is not in luxury towers, but in how well a society houses its most vulnerable.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to examine the global housing crisis, describing challenges of affordability, overcrowding, inequality, and informal settlements, exploring causes such as urban demand and poor planning, discussing solutions like social housing and government policies, and emphasizing that housing is essential for stability, dignity, and opportunity.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why has housing become unaffordable in many urban areas?',
        explanation: 'Housing demand has outpaced supply as more people move to cities; limited land and high construction costs have driven up real estate prices, making apartments and homes unaffordable even for average workers and some professionals.',
      ),
      ReadingQuestion(
        question: 'The word "gentrified" in the fourth paragraph most likely means',
        explanation: 'In the context of neighborhoods being "gentrified—transformed by wealthy buyers—forcing long-term residents to move out", the word means changed by an influx of wealthier people that raises property values and displaces original lower-income residents.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about informal settlements in developing countries?',
        explanation: 'It can be inferred that these settlements, often lacking legal ownership, clean water, electricity, planning, and infrastructure, leave residents vulnerable to eviction, violence, and disasters such as flooding or fires, making the housing problem more severe than in wealthier nations.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is social housing and how can it help?',
        explanation: 'Social housing consists of homes built or subsidized by the government for low-income citizens; in places like Sweden and the Netherlands it helps maintain affordability, though poor management or underfunding can lead to disrepair and unsafe conditions.',
      ),
      ReadingQuestion(
        question: 'The phrase "inclusionary zoning" in the seventh paragraph most likely refers to',
        explanation: 'In the context of prioritizing mixed-use development and inclusionary zoning to balance needs and provide affordable housing, it refers to planning rules that require or encourage the inclusion of affordable housing units within new developments.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about changing attitudes toward home ownership?',
        explanation: 'While buying a house was once a sign of success and security, today especially among young people renting is more common due to high prices, job instability, and urban mobility, showing that economic conditions are shifting traditional views of housing.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does technology both help and complicate housing issues?',
        explanation: 'Technology enables sustainable solutions such as smart homes, energy-efficient buildings, and modular construction, but luxury developments often prioritize profit over accessibility, and digital platforms have raised rental prices by converting homes into vacation properties.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the environmental impact of housing construction?',
        explanation: 'Construction is one of the most polluting industries; building green homes with local materials, solar power, and efficient design can reduce emissions and long-term costs, making sustainable housing an economic and social issue as well as a climate one.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what tools can governments use to improve housing access?',
        explanation: 'Governments can invest in affordable housing projects, offer subsidies or tax breaks for first-time buyers, control rent prices through legislation, promote rural housing to ease urban pressure, and support homeless shelters and emergency housing.',
      ),
    ],
  ),

  ReadingPassage(
    id: 44,
    title: 'High-Rise Buildings',
    topic: 'Urban Development',
    content: '''High-rise buildings, also known as skyscrapers, have become a defining feature of modern urban landscapes. From New York and Dubai to Shanghai and London, cities around the world compete to build taller and more iconic towers. These structures symbolize progress, ambition, and economic power—but they also raise questions about practicality, sustainability, and quality of life.
The main reason for building upwards is space. As urban populations grow, available land becomes scarce and expensive. Because horizontal expansion is limited, cities turn to vertical construction to house more people and businesses. High-rise buildings allow more residents or workers to occupy a smaller footprint, which is especially valuable in dense city centers.
Skyscrapers are often seen as efficient solutions for housing and commercial needs. They combine residential, office, retail, and leisure spaces into one location, creating ―vertical cities.‖ This mixed-use design can reduce commuting, promote local business, and improve urban mobility.
Modern high-rises are also architectural achievements. With advances in engineering, materials, and design, buildings can now reach over 800 meters in height while withstanding earthquakes, high winds, and temperature extremes. These innovations make skyscrapers more durable, energy-efficient, and visually stunning.
However, critics argue that high-rise buildings are not always the best option. One concern is human well-being. Living or working in tall towers can feel isolating or stressful. Long elevator waits, lack of green space, and poor ventilation may negatively affect mental and physical health. Because natural interaction is limited, community bonds can weaken.
Another issue is safety. In the event of a fire, earthquake, or terrorist attack, evacuating tall buildings is extremely difficult. Emergency services face serious challenges in reaching upper floors quickly. While safety regulations have improved, the risk can never be completely eliminated.
High-rise buildings are also energy-intensive. Elevators, lighting, and airconditioning systems run constantly, consuming large amounts of power. Although newer buildings often use smart technologies to reduce waste, older towers remain environmentally costly. From an urban planning perspective, skyscrapers may disrupt the city‘s character. They can block sunlight, ruin historic skylines, and create wind tunnels at street level. Critics argue that beauty and cultural identity are sacrificed for height and profit.
Some economists question the value of high-rises. Construction and maintenance costs are extremely high. Developers often focus on luxury buildings aimed at the rich, which does not solve housing shortages for average citizens. In many cities, entire high-rises sit empty while millions struggle to afford basic housing. Culturally, attitudes toward tall buildings differ. In the West, they often symbolize capitalism, power, and global ambition. In Asia and the Middle East, they reflect national pride, rapid development, and modern identity. Because cultural meaning varies, so do policies and preferences.
Governments play a role in regulating high-rise development. Some cities, like Paris and Vienna, have height restrictions to preserve historic views and architectural balance. Others, like Hong Kong or Singapore, actively promote vertical living due to limited land. Urban design must reflect the needs and values of its population.
There are also psychological effects to consider. Studies suggest that people living on higher floors may experience more loneliness, anxiety, or detachment. Children growing up in towers may have less outdoor playtime and social interaction. While not all residents are affected, these risks deserve attention.
To address these problems, architects and planners are rethinking vertical design. The concept of the ―vertical village‖ includes shared gardens, schools, gyms, and meeting areas built into high-rises. Such features encourage community and improve the quality of life.
Green skyscrapers are also emerging. These use renewable energy, rainwater harvesting, and natural ventilation. Some even have trees or vertical farms built into their walls. These eco-friendly innovations reduce environmental impact and make cities more sustainable.
In conclusion, high-rise buildings reflect both the possibilities and problems of modern urban life. They offer space-saving, innovative, and iconic solutions—but also come with social, environmental, and ethical concerns. Whether skyscrapers improve cities or damage them depends on how wisely they are designed, built, and used. True progress lies not in building taller—but in building smarter.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage discusses the advantages, disadvantages, cultural meanings, and future directions of high-rise buildings, concluding that true progress depends on designing and using them wisely rather than simply building taller.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is the main reason cities build high-rise buildings?',
        explanation: 'The main reason is limited and expensive land as urban populations grow; vertical construction allows more people and businesses to occupy a smaller footprint in dense city centers.',
      ),
      ReadingQuestion(
        question: 'The phrase "vertical cities" in the third paragraph most likely means',
        explanation: 'Vertical cities refer to high-rise buildings that combine residential, office, retail, and leisure spaces into one location, creating mixed-use environments that reduce commuting and support local activity.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the safety of high-rise buildings?',
        explanation: 'Evacuating tall buildings during emergencies such as fire, earthquake, or attack is extremely difficult, and while safety regulations have improved, the risk can never be completely eliminated.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how can high-rise buildings affect human well-being?',
        explanation: 'Living or working in tall towers can feel isolating or stressful due to long elevator waits, lack of green space, poor ventilation, and limited natural interaction, which may weaken community bonds and harm mental and physical health.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the economic value of many high-rises?',
        explanation: 'Construction and maintenance costs are very high, and developers often focus on luxury buildings for the wealthy, which fails to address housing shortages for average citizens and can leave entire towers empty.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how do cultural attitudes toward skyscrapers differ?',
        explanation: 'In the West they often symbolize capitalism, power, and global ambition, while in Asia and the Middle East they reflect national pride, rapid development, and modern identity.',
      ),
      ReadingQuestion(
        question: 'The phrase "vertical village" in the eleventh paragraph most likely means',
        explanation: 'A vertical village is a high-rise design concept that incorporates shared gardens, schools, gyms, and meeting areas to encourage community interaction and improve residents\' quality of life.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about green skyscrapers?',
        explanation: 'Green skyscrapers use renewable energy, rainwater harvesting, natural ventilation, and features such as trees or vertical farms to reduce environmental impact and promote urban sustainability.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why do some cities impose height restrictions on buildings?',
        explanation: 'Cities like Paris and Vienna restrict building heights to preserve historic views and maintain architectural balance, reflecting local needs and cultural values.',
      ),
    ],
  ),

  ReadingPassage(
    id: 45,
    title: 'Homelessness',
    topic: 'Society & Culture',
    content: '''Homelessness refers to the condition of not having a stable or permanent place to live. While it may appear as people sleeping on sidewalks or in shelters, the reality is more complex and widespread than many assume. Homelessness exists in nearly every country, regardless of wealth or development level.
There are many causes of homelessness. Poverty is the most obvious. When people cannot afford rent, utility bills, or basic necessities, they may lose their homes. Because the cost of living keeps rising while wages stay the same, many lowincome families live on the edge of eviction.
Unemployment is another major factor. Job loss, especially without savings or government support, can quickly lead to housing instability. For those already living paycheck to paycheck, even a minor emergency can cause financial collapse. In such cases, homelessness is not a choice—but a consequence.
Mental illness and addiction also play significant roles. People suffering from depression, anxiety, schizophrenia, or substance abuse disorders often struggle to maintain jobs and relationships. Without access to treatment or support, they may become trapped in a cycle of instability. Lack of affordable mental healthcare deepens the crisis.
Family conflict is another cause. Victims of domestic violence—especially women and children—may flee unsafe homes, only to end up in temporary shelters or on the street. LGBTQ+ youth are also overrepresented in the homeless population, often after being rejected by family members. Because home is not always safe, some choose homelessness over abuse.
In some cases, structural issues make housing impossible. A shortage of affordable housing, rising rents, and gentrification force people out of neighborhoods they‘ve lived in for years. As cities focus on luxury development, ordinary residents are pushed aside.
Homelessness affects different groups in different ways. Children who experience homelessness often fall behind in school, suffer from poor nutrition, and face emotional stress. Veterans may struggle with trauma or disability. The elderly face health risks from sleeping outside in extreme weather. Every case of homelessness is personal—but the patterns are systemic.
The consequences are severe. Homeless individuals face higher rates of illness, injury, and death. Access to hygiene, food, and medical care is limited. Employment is almost impossible without a stable address. Social stigma and isolation make it even harder to escape the cycle.
Governments have responded in various ways. Emergency shelters provide shortterm beds, but they are often overcrowded, unsafe, or restrictive. Long-term solutions like affordable housing programs or rent subsidies are more effective— but also more expensive. Because funding is limited and political will is weak, progress is slow.
Some cities have adopted the ―Housing First‖ model. This approach gives people permanent housing immediately—without requiring sobriety, employment, or counseling first. Once stable, residents can then access support services. Evidence shows that Housing First reduces long-term homelessness more than traditional methods.
However, not all responses are helpful. In some places, local governments criminalize homelessness—issuing fines or jail time for sleeping in public, loitering, or panhandling. Critics argue this punishes the vulnerable instead of solving the root causes. You cannot arrest someone out of homelessness.
Nonprofit organizations, religious groups, and volunteers also play a major role. They provide food banks, outreach, and emergency services. But they cannot solve homelessness alone. Systemic problems require systemic solutions.
Technology can also help. Apps that connect people to shelters, job listings, or legal aid are growing in popularity. Governments can use data to track housing needs, monitor risk zones, and allocate resources more effectively. Smart strategies combined with human compassion can drive real change.
Public attitudes matter, too. Many people wrongly believe that all homeless individuals are lazy or dangerous. In fact, most are simply struggling with circumstances beyond their control. Changing the narrative—from blame to understanding—is crucial for lasting solutions.
Prevention is key. Offering support before people lose housing—through eviction protection, job training, or mental health services—costs less and works better than emergency aid. It is more efficient to prevent a fire than to rebuild the house after it burns down.
In conclusion, homelessness is not just a housing issue—it is a reflection of social failure. A society cannot call itself developed while its people sleep in the streets. Solving homelessness requires not only homes, but justice, compassion, and policy that puts people first..''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage defines homelessness, examines its multiple causes and effects on different groups, reviews government and community responses including the Housing First model, critiques unhelpful approaches, and argues that prevention and systemic solutions rooted in justice and compassion are essential.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is the most obvious cause of homelessness?',
        explanation: 'The passage states that poverty is the most obvious cause, explaining that when people cannot afford rent, utility bills, or basic necessities, they may lose their homes.',
      ),
      ReadingQuestion(
        question: 'The term "Housing First" in the passage most likely refers to',
        explanation: 'The passage describes the Housing First model as an approach that gives people permanent housing immediately without requiring sobriety, employment, or counseling first, after which they can access support services.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the relationship between mental illness and homelessness?',
        explanation: 'The passage notes that people with conditions such as depression, anxiety, schizophrenia, or substance abuse disorders often struggle to maintain jobs and relationships, and without treatment or support they may become trapped in a cycle of instability.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does homelessness affect children?',
        explanation: 'The passage states that children who experience homelessness often fall behind in school, suffer from poor nutrition, and face emotional stress.',
      ),
      ReadingQuestion(
        question: 'The word "gentrification" in the passage most likely means',
        explanation: 'In context, gentrification refers to neighborhood changes driven by luxury development that force ordinary residents out of areas they have lived in for years through rising rents and reduced affordable housing.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about criminalizing homelessness?',
        explanation: 'The passage explains that some local governments issue fines or jail time for sleeping in public or panhandling, and critics argue this punishes the vulnerable instead of solving root causes, noting that one cannot arrest someone out of homelessness.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is prevention considered more effective than emergency aid?',
        explanation: 'The passage states that offering support before people lose housing—through eviction protection, job training, or mental health services—costs less and works better than emergency aid, comparing it to preventing a fire rather than rebuilding afterward.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about public attitudes toward homelessness?',
        explanation: 'The passage notes that many people wrongly believe all homeless individuals are lazy or dangerous, whereas most are struggling with circumstances beyond their control, and changing the narrative from blame to understanding is crucial for lasting solutions.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what role do nonprofit organizations play in addressing homelessness?',
        explanation: 'The passage states that nonprofit organizations, religious groups, and volunteers provide food banks, outreach, and emergency services, but emphasizes that they cannot solve homelessness alone because systemic problems require systemic solutions.',
      ),
    ],
  ),

  ReadingPassage(
    id: 46,
    title: 'Urban Sprawl',
    topic: 'Cities & Environment',
    content: '''Urban sprawl refers to the uncontrolled expansion of cities into surrounding rural or undeveloped land. As populations grow and demand for housing increases, cities tend to spread outward, often in a disorganized and inefficient way. This phenomenon has reshaped landscapes, economies, and lifestyles in both developed and developing nations.
One of the key drivers of urban sprawl is the desire for affordable housing. In many major cities, property prices in the center have become unaffordable for average families. Because people seek larger homes and lower costs, they move to the outskirts—leading to the rapid development of suburbs and residential zones far from the city core.
Another cause is car culture. In areas where public transportation is weak or underdeveloped, personal vehicles become essential. This encourages low-density housing, wide roads, and shopping malls designed for cars rather than people. As a result, communities are spread out, and walking becomes impractical.
Urban planning policies—or lack of them—also play a major role. Poor zoning laws, weak regulation, and short-term political decisions can lead to haphazard growth. When development is left to the market without a long-term vision, land gets used inefficiently, and public services become overstretched.
While urban sprawl offers some benefits, such as cheaper housing and more space, it creates serious problems for the environment, infrastructure, and social life. One of the most visible impacts is the loss of natural land. Forests, farms, and wetlands are often destroyed to make way for roads, houses, and shopping centers. This leads to habitat destruction, reduced biodiversity, and higher carbon emissions. Traffic congestion is another major issue. As more people live farther from the city, they must drive longer distances to work, school, or shops. This increases fuel consumption, air pollution, and time wasted in traffic jams. In cities with little public transport, commuting becomes a daily struggle.
Urban sprawl also puts pressure on public services. Schools, hospitals, police, and fire departments must stretch their resources to serve scattered populations.
Building new infrastructure in remote areas is expensive and time-consuming. Because services are spread thin, quality and access often decline.
Socially, urban sprawl can weaken communities. Low-density neighborhoods may lack gathering places like parks, libraries, or town squares. People may not know their neighbors or feel connected to their surroundings. Isolation and loneliness can rise, especially among the elderly or those without cars.
Economically, sprawl increases inequality. Wealthier residents can afford long commutes or private transport, while low-income individuals may be stuck in poorly connected areas with fewer job opportunities. Unequal access to services, education, and employment can deepen social divides.
In response, many urban planners advocate for ―smart growth.‖ This model promotes compact, mixed-use development that combines housing, shops, schools, and parks in walkable areas. It also supports investment in public transport, green space, and renewable energy. The goal is to create cities that are efficient, inclusive, and sustainable.
Some cities have introduced policies to control sprawl. For example:
•        Green belts: protected areas around cities that prevent construction           Urban growth boundaries: limits beyond which development is restricted
•        Tax incentives for infill development (building within the existing urban area)
•        High-density zoning in public transport corridors
Such strategies encourage cities to grow upward rather than outward, preserving land and reducing infrastructure costs.
Technology can also play a role. Geographic information systems (GIS), data analytics, and AI tools help planners track growth, analyze land use, and forecast needs. These tools improve decision-making and help avoid wasteful expansion.
However, changing existing patterns is difficult. Developers often prefer building on cheap, undeveloped land. Homebuyers are attracted to quiet suburbs with big homes. Politicians may resist reforms that appear restrictive or unpopular. Overcoming these challenges requires public education and long-term commitment.
Climate change adds urgency to the issue. Urban sprawl contributes to deforestation, energy waste, and car dependency—all of which worsen global warming. Dense, transit-oriented cities emit less carbon per capita than sprawling ones. Rethinking how cities grow is critical for climate action.
In conclusion, urban sprawl reflects both opportunity and failure. While it provides space and affordability, it also leads to inefficiency, environmental damage, and inequality. Smart planning, public investment, and community engagement are needed to ensure that urban growth benefits everyone—not just the wealthy or well-connected.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to explain what urban sprawl is, its main causes and negative impacts on the environment, infrastructure, society, and economy, and the smart growth strategies proposed to control it.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is one key driver of urban sprawl related to housing?',
        explanation: 'One key driver is the desire for affordable housing; high property prices in city centers push average families to seek larger, cheaper homes on the outskirts.',
      ),
      ReadingQuestion(
        question: 'The word "haphazard" in the fourth paragraph most likely means...',
        explanation: 'In the context of the passage, "haphazard" means disorganized, random, or lacking careful planning, referring to uncontrolled urban growth.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the relationship between car culture and urban sprawl?',
        explanation: 'It can be inferred that reliance on personal vehicles encourages low-density, car-oriented development that spreads communities outward and makes walking impractical.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does urban sprawl affect the environment?',
        explanation: 'Urban sprawl destroys forests, farms, and wetlands for development, leading to habitat destruction, reduced biodiversity, and higher carbon emissions.',
      ),
      ReadingQuestion(
        question: 'The term "smart growth" in the passage most likely refers to...',
        explanation: 'Smart growth refers to a planning model that promotes compact, mixed-use, walkable development with investment in public transport, green space, and renewable energy to create efficient and sustainable cities.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the social effects of urban sprawl?',
        explanation: 'It can be inferred that low-density neighborhoods often lack community gathering places, which can lead to weaker social connections, isolation, and loneliness, especially for the elderly or those without cars.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what policies have some cities used to control sprawl?',
        explanation: 'Cities have used green belts, urban growth boundaries, tax incentives for infill development, and high-density zoning in public transport corridors to encourage upward rather than outward growth.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the difficulty of controlling urban sprawl?',
        explanation: 'It can be inferred that controlling sprawl is challenging because developers prefer cheap undeveloped land, homebuyers favor spacious suburbs, and politicians may avoid unpopular restrictions, requiring public education and long-term commitment.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why does climate change add urgency to addressing urban sprawl?',
        explanation: 'Urban sprawl contributes to deforestation, energy waste, and car dependency, all of which worsen global warming, while dense, transit-oriented cities emit less carbon per capita.',
      ),
    ],
  ),

  ReadingPassage(
    id: 47,
    title: 'Traffic',
    topic: 'Urban Planning',
    content: '''Traffic congestion is one of the most frustrating and persistent problems in modern cities. As urban populations and car ownership continue to rise, roads become increasingly crowded, causing delays, pollution, and stress. Whether in megacities or smaller towns, managing traffic has become a central challenge for urban planners and governments.
The main cause of traffic is simple: too many vehicles and not enough road space. Because cities were not designed to handle millions of cars, roads quickly become overwhelmed during peak hours. Commuters stuck in daily traffic jams lose valuable time, fuel, and productivity.
Public transport systems can reduce the number of cars on the road. However, in many places, buses, trains, or subways are unreliable, overcrowded, or unavailable. When people do not trust the public system, they rely on private vehicles, making the situation worse. In developing countries, this problem is often more severe due to underfunded infrastructure.
Another factor is poor urban planning. In cities without proper zoning, workplaces, schools, and homes may be scattered across long distances. This forces people to travel far every day, increasing road usage and fuel consumption. Additionally, many cities lack dedicated bike lanes, walkable paths, or intelligent traffic systems. Traffic has many negative effects. Air pollution from car exhaust leads to respiratory problems, especially in children and the elderly. Because cars release carbon dioxide and other harmful gases, traffic contributes significantly to climate change. Noise pollution from engines and honking also harms mental health and quality of life.
Economically, traffic causes billions in lost time and fuel each year. Delivery delays, late arrivals, and fuel waste damage productivity. In cities like Los Angeles, Jakarta, or Mumbai, commuters may spend more than two hours per day in traffic, reducing their personal and professional time.
Governments have tried several solutions to reduce traffic. One popular method is improving public transport—making it faster, cleaner, and more frequent. Cities like Seoul, Tokyo, and Zurich have shown that when public transport is affordable and efficient, people leave their cars at home.
Another approach is congestion pricing. Drivers pay to enter busy areas during peak times, as seen in London and Singapore. This encourages people to travel during off-peak hours or use alternative transport. However, critics argue that it may punish low-income drivers more than wealthy ones.
Carpooling is another strategy. Apps and incentives can encourage people to share rides, reducing the number of vehicles on the road. In some countries, carpool lanes allow shared vehicles to travel faster. If more people ride together, traffic and emissions drop sharply.
Technology also plays a growing role. Smart traffic lights that adjust to real-time conditions can reduce wait times. Navigation apps help drivers avoid busy roads. In the future, autonomous vehicles may improve traffic flow by eliminating human error and reducing sudden braking or unnecessary lane changes.
Urban design matters too. Creating compact, mixed-use neighborhoods means people can walk or cycle to work, school, or shops. When cities prioritize pedestrians and cyclists, traffic naturally decreases. European cities like
Copenhagen and Amsterdam have successfully done this through careful planning. However, changing behavior is difficult. Many people are emotionally attached to their cars. For some, driving is not just about transport—it‘s about freedom, privacy, or social status. Public campaigns are needed to shift mindsets and promote sustainable habits.
Some governments have taken extreme steps. Car-free days, odd-even license systems, and driving bans in certain areas aim to reduce pressure on roads. While these can work in the short term, long-term solutions require better infrastructure and policy.
Electric vehicles (EVs) offer environmental benefits but do not solve congestion. Even if all cars were electric, roads would still be crowded. Thus, the focus must be not just on cleaner cars, but on fewer cars.
Education and enforcement are essential. Drivers must follow road rules and respect other users. Pedestrians, cyclists, and public transport riders also need safety and support. When all users share the road responsibly, traffic flows more smoothly.
In conclusion, traffic is not just a transport issue—it is a public health, economic, and environmental crisis. While there is no single solution, a mix of planning, investment, technology, and cultural change is needed. A future with less traffic is not only possible—it‘s essential for healthier and more livable cities.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to examine traffic congestion as a major urban problem, explaining its causes, negative effects, and various solutions involving public transport, planning, technology, and behavioral change.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is the main cause of traffic congestion?',
        explanation: 'According to the passage, the main cause of traffic is too many vehicles and not enough road space, as cities were not designed to handle millions of cars and become overwhelmed during peak hours.',
      ),
      ReadingQuestion(
        question: 'The word "congestion" in the first paragraph most likely means',
        explanation: 'In the context of the first paragraph, "congestion" means overcrowding or blockage of roads by excessive vehicles, leading to delays, pollution, and stress in modern cities.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the effectiveness of public transport in reducing traffic?',
        explanation: 'It can be inferred that when public transport is made affordable, efficient, faster, cleaner, and more frequent, as in cities like Seoul, Tokyo, and Zurich, people are more likely to leave their cars at home and reduce road congestion.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are some negative effects of traffic on health and the environment?',
        explanation: 'According to the passage, air pollution from car exhaust causes respiratory problems especially in children and the elderly, contributes to climate change through carbon dioxide emissions, and noise pollution harms mental health and quality of life.',
      ),
      ReadingQuestion(
        question: 'The word "zoning" in the fourth paragraph most likely means',
        explanation: 'In the context of the fourth paragraph, "zoning" refers to the planning and designation of different areas for specific uses such as workplaces, schools, and homes; poor zoning scatters these locations and forces longer daily travel.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about congestion pricing as a traffic solution?',
        explanation: 'It can be inferred that congestion pricing, used in places like London and Singapore, can encourage off-peak travel or alternative transport by charging drivers to enter busy areas, though it faces criticism for potentially burdening low-income drivers more than wealthy ones.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why do electric vehicles not fully solve the traffic problem?',
        explanation: 'According to the passage, electric vehicles offer environmental benefits but do not solve congestion because even if all cars were electric, roads would still be crowded; the focus must therefore be on fewer cars overall.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of urban design in reducing traffic?',
        explanation: 'It can be inferred that creating compact, mixed-use neighborhoods and prioritizing pedestrians and cyclists, as successfully done in European cities like Copenhagen and Amsterdam, allows people to walk or cycle for daily needs and naturally decreases traffic.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is changing driving behavior particularly difficult?',
        explanation: 'According to the passage, many people are emotionally attached to their cars, viewing driving as providing freedom, privacy, or social status rather than just transport, which makes public campaigns necessary to shift mindsets toward sustainable habits.',
      ),
    ],
  ),

  ReadingPassage(
    id: 48,
    title: 'Public Transport',
    topic: 'Urban Planning',
    content: '''Public transport plays a vital role in the functioning of modern cities. Buses, trains, subways, and trams allow people to move efficiently without relying on private vehicles. Because well-developed public transport reduces congestion, pollution, and travel time, it is considered a cornerstone of sustainable urban planning.
The benefits of public transport are wide-ranging. First and foremost, it is costeffective. Compared to owning and maintaining a private car, using public systems is significantly cheaper. This makes it especially important for students, workers, and the elderly, who may not afford personal vehicles.
Environmental impact is another major advantage. Public transport produces fewer carbon emissions per passenger than cars or motorcycles. When more people choose buses or trains, cities can reduce greenhouse gas emissions, lower air pollution, and combat climate change. This is especially crucial as urban populations continue to grow.
Public transport also improves traffic flow. In cities where most residents rely on private cars, roads become overcrowded. But when commuters switch to mass transit, fewer vehicles occupy the road, reducing delays and accidents. As a result, cities become safer, cleaner, and more livable.
In terms of energy use, public systems are more efficient. Trains and buses can transport dozens or hundreds of people using less fuel per head than cars. Because they operate on fixed schedules and routes, they optimize space and reduce unnecessary travel.
Moreover, public transport promotes social inclusion. In areas where jobs, education, and healthcare are far from residential zones, reliable transit allows people from all backgrounds to participate in society. It ensures equal access to opportunities, regardless of income, age, or disability.
However, not all public transport systems are effective. In many cities, services are slow, unreliable, or unsafe. Buses may arrive late or be overcrowded. Trains may suffer from poor maintenance or frequent breakdowns. When public transport fails to meet expectations, people turn to private alternatives, worsening traffic and pollution.
Another issue is coverage. Rural areas and low-income neighborhoods are often underserved, lacking proper infrastructure or investment. This creates a gap between those who can afford to live near transit hubs and those who cannot. As a result, inequality deepens and mobility becomes a privilege.
Some people avoid public transport due to safety concerns. Pickpocketing, harassment, or violence may occur in crowded stations or on late-night routes. Cleanliness and hygiene are also issues—especially since the COVID-19 pandemic. Public trust must be rebuilt through cleanliness, security, and reliability. Modernization can improve these systems. Many cities are introducing contactless payment, real-time tracking apps, and electric or hybrid vehicles. These features make transport more convenient and eco-friendly. When systems are modern, people are more likely to use them regularly.
Governments play a key role in supporting public transport. Investment in infrastructure, subsidies for low-income riders, and policies that prioritize buses or trains over cars are essential. If cities spend more on roads than on transit, car dependency will only increase.
Urban design also matters. Walkable streets, protected bike lanes, and well-placed stations make it easier to access public transport. A city where people can easily move without cars is healthier and more efficient. Planners must integrate transport into all areas of city life—not treat it as an afterthought.
There are debates over whether public transport should be free. Some argue that removing fares increases usage and reduces inequality. Others claim it puts too much pressure on public budgets. Still, many cities offer discounted or free rides to students, seniors, or unemployed citizens.
Cultural attitudes influence usage as well. In some countries, public transport is seen as low-status or only for the poor. In others, it is viewed as smart, efficient, and modern. Changing how people see public systems is part of the long-term solution.
The future of public transport may include autonomous vehicles, high-speed trains, or even underground hyperloops. However, the most urgent task is to fix what already exists. Before dreaming of flying buses, cities must make sure ordinary trains run on time.
In conclusion, public transport is not just about moving people—it is about fairness, sustainability, and smart planning. A city without strong public transport cannot truly serve its people. Investing in buses, trains, and subways today is an investment in cleaner, fairer, and more livable cities tomorrow.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to explain the vital role and wide-ranging benefits of public transport for cost, environment, traffic, energy efficiency, and social inclusion, while discussing challenges such as unreliability, poor coverage, safety concerns, and cultural attitudes, and concluding that investment in strong public transport systems is essential for fairness, sustainability, and livable cities.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is public transport considered a cornerstone of sustainable urban planning?',
        explanation: 'According to the passage, well-developed public transport reduces congestion, pollution, and travel time, which is why it is considered a cornerstone of sustainable urban planning.',
      ),
      ReadingQuestion(
        question: 'The word "costeffective" in the second paragraph most likely means',
        explanation: 'In the second paragraph, "costeffective" most likely means providing good value or being significantly cheaper compared to owning and maintaining a private car, making public transport especially important for students, workers, and the elderly who may not afford personal vehicles.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the environmental benefits of public transport?',
        explanation: 'It can be inferred that public transport has major environmental advantages because it produces fewer carbon emissions per passenger than cars or motorcycles; greater use of buses or trains allows cities to reduce greenhouse gas emissions, lower air pollution, and combat climate change, which is especially important as urban populations grow.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does public transport promote social inclusion?',
        explanation: 'According to the passage, public transport promotes social inclusion by allowing people from all backgrounds to access jobs, education, and healthcare that may be far from residential zones, thereby ensuring equal access to opportunities regardless of income, age, or disability.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about problems with coverage in public transport systems?',
        explanation: 'It can be inferred that uneven coverage creates inequality, as rural areas and low-income neighborhoods are often underserved with inadequate infrastructure or investment, leading to a gap between those who can afford to live near transit hubs and those who cannot, making mobility a privilege.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what modernization features can improve public transport systems?',
        explanation: 'According to the passage, many cities are introducing contactless payment, real-time tracking apps, and electric or hybrid vehicles, which make transport more convenient and eco-friendly and increase the likelihood that people will use the systems regularly.',
      ),
      ReadingQuestion(
        question: 'The phrase "car dependency" in the passage most likely refers to',
        explanation: 'In the passage, "car dependency" refers to a situation in which people rely heavily on private cars; the text warns that if cities spend more on roads than on transit, this dependency will only increase.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about cultural attitudes toward public transport?',
        explanation: 'It can be inferred that cultural attitudes strongly influence usage: in some countries public transport is seen as low-status or only for the poor, while in others it is viewed as smart, efficient, and modern, so changing public perception is part of the long-term solution to increasing ridership.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is the most urgent task regarding the future of public transport?',
        explanation: 'According to the passage, while the future may include autonomous vehicles, high-speed trains, or underground hyperloops, the most urgent task is to fix existing systems so that ordinary trains run on time before pursuing more advanced ideas.',
      ),
    ],
  ),

  ReadingPassage(
    id: 49,
    title: 'Culture',
    topic: 'Society & Culture',
    content: '''Culture shapes how we think, act, and relate to the world. It includes language, traditions, beliefs, art, food, clothing, religion, and social behavior. Because culture is passed down from one generation to another, it helps maintain identity and provides a sense of belonging.
Each country, region, or ethnic group has its own unique culture. These differences can enrich global society, offering diversity in thought, expression, and values. At the same time, cultural misunderstandings can lead to conflict or discrimination, especially in today‘s globalized world.
Language is at the heart of culture. It‘s more than just a tool for communication— it‘s a way of thinking. When a language dies, a whole worldview disappears with it. That‘s why many believe preserving minority languages is essential for protecting cultural heritage.
Traditions also play a key role. Festivals, rituals, and ceremonies strengthen community ties and express shared beliefs. For example, weddings, funerals, and New Year celebrations vary across cultures but serve similar purposes—marking important life events and transitions. Because traditions provide continuity, they help people feel rooted and stable.
Art is another core part of culture. Through music, painting, literature, dance, and film, people share their experiences, struggles, and dreams. Cultural products often reflect the values and emotions of a society. Whether it‘s Japanese haiku or Nigerian drumming, every artistic form carries a deep cultural message.
Food is one of the most visible and enjoyable aspects of culture. Every region has distinct ingredients, cooking methods, and meal customs. Eating habits reflect religion, climate, history, and even economic conditions. Because food is shared, it connects people, both locally and globally.
However, culture is not fixed. It evolves over time due to migration, technology, trade, and media. Globalization has accelerated this process, bringing cultures into closer contact. As people travel, study, and work across borders, they bring their customs with them—and adopt new ones.
This has both positive and negative effects. On one hand, cultural exchange can lead to innovation, tolerance, and understanding. People can enjoy foreign music, cuisine, and fashion while appreciating different ways of life. On the other hand, local cultures may be weakened or replaced, especially by dominant global forces like Western media or consumer brands.
Some people worry about ―cultural imperialism,‖ where powerful countries export their values and erase others. Hollywood movies, English-language music, and global fast food chains often spread one lifestyle at the expense of others. Because young people are especially influenced by global trends, traditional customs may be abandoned or forgotten.
At the same time, some cultures resist change. They may see outside influence as a threat and try to preserve old ways through education, law, or religion. National identity is often linked to culture, and any perceived attack on it can lead to strong emotional reactions. Striking a balance between preserving tradition and embracing modernity is not easy.
Multicultural societies face both opportunities and challenges. In countries like Canada, Singapore, or the UK, people of different backgrounds live side by side. If integration is successful, these societies benefit from creativity, productivity, and innovation. However, if differences are ignored or suppressed, tensions may arise. Education plays a major role in cultural understanding. Learning about other customs and histories promotes respect and curiosity. Schools that celebrate cultural diversity help reduce prejudice and build stronger communities. When children grow up appreciating different ways of life, they are less likely to fear or reject them.
Tourism is another way culture spreads. When people visit foreign countries, they experience new languages, foods, and traditions. However, tourism can also commercialize or distort cultures for profit. Sacred ceremonies may become performances, and local crafts may be mass-produced. Responsible tourism should support—not exploit—cultural heritage.
Technology is changing how culture is created and shared. Social media allows anyone to post songs, dances, or opinions with a global audience. While this promotes freedom and diversity, it also leads to cultural blending or even appropriation. The line between appreciation and disrespect is sometimes unclear.
Cultural preservation is a growing concern. UNESCO (the United Nations Educational, Scientific and Cultural Organization) lists World Heritage Sites and supports the protection of cultural traditions. Governments and NGOs are also working to save endangered languages, rebuild ancient monuments, and document oral histories. Because once a culture disappears, it is almost impossible to bring back.
In conclusion, culture is not just about tradition—it is a living, breathing force that shapes our daily lives. As the world becomes more connected, respecting and protecting cultural differences becomes even more important. Culture is what makes us human, and its richness is worth preserving.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to explain what culture is and how it shapes identity and society, describe its key elements such as language, traditions, art, and food, examine how globalization and technology affect it, and emphasize the importance of respecting and preserving cultural differences.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is language considered central to culture?',
        explanation: 'According to the passage, language is at the heart of culture because it is more than a tool for communication—it is a way of thinking, and when a language dies, a whole worldview disappears with it, making the preservation of minority languages essential for protecting cultural heritage.',
      ),
      ReadingQuestion(
        question: 'The phrase "cultural imperialism" in the passage most likely means',
        explanation: 'In the context of the passage, "cultural imperialism" most likely means the process by which powerful countries export their values, media, and lifestyles in ways that weaken or erase other cultures, as illustrated by the spread of Hollywood movies, English-language music, and global fast-food chains.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the effects of globalization on culture?',
        explanation: 'It can be inferred that globalization has both positive and negative effects: it can promote innovation, tolerance, and understanding through cultural exchange, but it can also weaken or replace local cultures through dominant global forces such as Western media and consumer brands.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what role do traditions play in culture?',
        explanation: 'According to the passage, traditions such as festivals, rituals, and ceremonies strengthen community ties, express shared beliefs, mark important life events and transitions, and provide continuity that helps people feel rooted and stable.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about multicultural societies from the passage?',
        explanation: 'It can be inferred that multicultural societies can benefit from creativity, productivity, and innovation when integration is successful, but tensions may arise if cultural differences are ignored or suppressed, and education that celebrates diversity helps reduce prejudice.',
      ),
      ReadingQuestion(
        question: 'The word "appropriation" in the paragraph about technology most likely means',
        explanation: 'In the context of the passage, "appropriation" most likely means the taking or use of elements from another culture in a way that may cross the line into disrespect, as the text notes that social media can lead to cultural blending or appropriation where the boundary between appreciation and disrespect is unclear.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how can tourism affect culture?',
        explanation: 'According to the passage, tourism allows people to experience new languages, foods, and traditions, but it can also commercialize or distort cultures for profit—turning sacred ceremonies into performances and mass-producing local crafts—so responsible tourism should support rather than exploit cultural heritage.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about cultural preservation from the passage?',
        explanation: 'It can be inferred that cultural preservation is urgent because once a culture disappears it is almost impossible to bring back, which is why organizations like UNESCO list World Heritage Sites and governments and NGOs work to save endangered languages, rebuild monuments, and document oral histories.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why do some cultures resist outside influence?',
        explanation: 'According to the passage, some cultures resist change because they may see outside influence as a threat to their identity and try to preserve old ways through education, law, or religion; national identity is often linked to culture, and any perceived attack on it can lead to strong emotional reactions.',
      ),
    ],
  ),

  ReadingPassage(
    id: 50,
    title: 'Cultural Heritage',
    topic: 'Culture & Society',
    content: '''Cultural heritage refers to the traditions, monuments, languages, knowledge, and practices that have been passed down from one generation to the next. It is a record of human creativity, identity, and history. Because cultural heritage reflects who we are and where we come from, protecting it is essential for both present and future societies.
There are two main types of cultural heritage: tangible and intangible.
Tangible heritage includes physical objects such as historical buildings, ancient manuscripts, paintings, monuments, temples, and artifacts. Examples include the Pyramids of Egypt, the Great Wall of China, and the architecture of Samarkand. These structures provide physical evidence of past civilizations, helping us understand how people lived, believed, and built their worlds.
Intangible heritage refers to non-physical elements like oral traditions, music, dance, rituals, festivals, crafts, and languages. For instance, the Japanese tea ceremony, Uzbek embroidery (do‗ppi tikish), and the Indian classical dance Bharatanatyam are all forms of intangible heritage. Even though they cannot be touched, they are just as valuable, as they carry cultural memory and identity.
Preserving cultural heritage is important for many reasons:
•        It strengthens national identity. People feel pride and unity when they see their culture respected and preserved.
•        It supports education and research. Schools and universities rely on historical materials to teach history, art, language, and social values.
•        It boosts tourism. Many countries earn billions through visitors who come to see heritage sites and experience traditional life.
•        It promotes creativity. Artists, designers, and musicians often take inspiration from traditional forms to create new works.
However, cultural heritage is constantly under threat. Natural disasters like earthquakes and floods can destroy centuries-old buildings. Because many sites are made of fragile materials, they need constant care and maintenance.
Human activities are also a major danger. Wars, terrorism, and looting can wipe out cultural treasures in days. The destruction of ancient sites in Syria or Iraq, for example, shocked the world. Once a site is destroyed, it is gone forever.
Urban development is another issue. In fast-growing cities, traditional buildings may be demolished to make room for shopping malls or highways. Governments often prioritize economic growth over heritage preservation. This short-term thinking can lead to permanent cultural loss.
Globalization adds another layer of complexity. As the world becomes more connected, dominant cultures—especially Western ones—spread rapidly. Local traditions, crafts, and languages may fade away, especially among younger generations who adopt global trends.
To protect cultural heritage, international cooperation is crucial. Organizations like UNESCO (United Nations Educational, Scientific and Cultural Organization) have created lists of World Heritage Sites and Intangible Heritage Practices. These lists raise awareness and encourage preservation. Countries that protect their heritage gain not only pride—but also global recognition.
Legal measures can help too. Governments can pass laws that prevent illegal excavation, export, or destruction of cultural property. Museums and institutions can ensure that artifacts are stored properly and shown respectfully. Communities can also be involved in caring for local traditions, especially when it comes to festivals, storytelling, and crafts.
Digital technology is becoming a powerful tool in heritage conservation. 3D scanning, digital archives, and virtual reality can preserve images and structures even if the physical originals are lost. This allows future generations to access and learn from cultural materials, no matter where they live.
Education plays a vital role as well. When children learn about their own and others‘ heritage in school, they develop respect, curiosity, and pride. A society that values its past is more likely to protect it.
Debates sometimes arise about the ownership of cultural items. Many museums in Europe and North America hold artifacts taken from colonies or war zones. Some countries, like Egypt or Nigeria, are demanding the return of their cultural treasures. The question of who owns heritage is both legal and moral.
There‘s also a risk of commercializing culture. Festivals may be turned into tourist shows, and traditional music or clothing may be marketed in ways that lose meaning. While tourism can bring money, it must be managed carefully to protect authenticity.
In conclusion, cultural heritage is more than old buildings or costumes—it is the soul of a people. Losing it means losing part of humanity‘s shared history. While modernization and globalization are inevitable, they should not come at the cost of cultural identity. Protecting heritage is not just about the past—it is about the future.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage defines cultural heritage, distinguishes between tangible and intangible forms, explains why preservation is important, identifies threats such as natural disasters, war, urban development, and globalization, and discusses strategies including international cooperation, legal measures, digital technology, and education to protect it for the future.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is the difference between tangible and intangible cultural heritage?',
        explanation: 'Tangible heritage includes physical objects such as historical buildings, manuscripts, paintings, monuments, temples, and artifacts, while intangible heritage refers to non-physical elements like oral traditions, music, dance, rituals, festivals, crafts, and languages that carry cultural memory and identity.',
      ),
      ReadingQuestion(
        question: 'The word "fragile" in the paragraph about natural disasters most likely means',
        explanation: 'It means easily damaged or delicate, as many heritage sites are made of fragile materials that need constant care and maintenance to avoid destruction from events like earthquakes and floods.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the impact of globalization on cultural heritage?',
        explanation: 'As the world becomes more connected, dominant cultures—especially Western ones—spread rapidly, causing local traditions, crafts, and languages to fade away, particularly among younger generations who adopt global trends.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does UNESCO contribute to protecting cultural heritage?',
        explanation: 'UNESCO has created lists of World Heritage Sites and Intangible Heritage Practices that raise awareness and encourage preservation; countries that protect their heritage gain pride and global recognition through this international cooperation.',
      ),
      ReadingQuestion(
        question: 'The word "authenticity" in the paragraph about commercializing culture most likely means',
        explanation: 'It means genuineness or remaining true to original meaning and form, as tourism and marketing of festivals, music, or clothing must be managed carefully to protect authenticity and avoid losing cultural meaning.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about debates over the ownership of cultural items?',
        explanation: 'Many museums in Europe and North America hold artifacts taken from colonies or war zones, and countries like Egypt or Nigeria are demanding their return; the question of who owns heritage is described as both legal and moral.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is education important for preserving cultural heritage?',
        explanation: 'When children learn about their own and others\' heritage in school, they develop respect, curiosity, and pride, and a society that values its past is more likely to protect it.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of digital technology in heritage conservation?',
        explanation: 'Tools such as 3D scanning, digital archives, and virtual reality can preserve images and structures even if physical originals are lost, allowing future generations to access and learn from cultural materials regardless of location.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are some reasons for preserving cultural heritage?',
        explanation: 'Preserving cultural heritage strengthens national identity and pride, supports education and research, boosts tourism and economic benefits, and promotes creativity by inspiring artists, designers, and musicians to create new works based on traditional forms.',
      ),
    ],
  ),

  ReadingPassage(
    id: 51,
    title: 'Culture Shock',
    topic: 'Society & Culture',
    content: '''Culture shock is the emotional and psychological discomfort people experience when they enter a culture very different from their own. Because everyday routines, values, and communication styles suddenly change, people may feel confused, isolated, or overwhelmed. This reaction is common among international students, immigrants, travelers, and even professionals working abroad.
Culture shock usually happens in four stages:
1.    Honeymoon stage – At first, people are excited. Everything feels new and interesting. They enjoy the food, language, and customs.
2.    Frustration stage – After some time, misunderstandings and daily struggles begin. People miss home and may feel irritated or lonely.
3.    Adjustment stage – Gradually, they start understanding how the new culture works and adapt their behavior.
4.    Acceptance stage – Finally, they feel more comfortable, make connections, and even appreciate cultural differences.
Not everyone experiences these stages in the same way, and the process can take weeks or months depending on the individual and the environment. Language is often the biggest challenge. Even if someone speaks the local language, understanding jokes, slang, or social cues can still be difficult. Miscommunication can lead to embarrassment or feelings of isolation. For example, in some cultures, people speak directly; in others, they communicate in more indirect or polite ways. If someone misreads this, they might seem rude or confused.
Social customs are another major cause of culture shock. In some cultures, it‘s normal to greet strangers with a handshake or eye contact. In others, this could be seen as disrespectful or inappropriate. Because people carry deep habits from their own culture, adjusting to new rules of behavior takes time and effort.
Food, clothing, weather, and even the pace of life can all be surprising. Some people struggle with unfamiliar meals or eating times. Others may find local clothing uncomfortable or the climate difficult to handle. These small daily differences build up, leading to stress.
Homesickness adds to the problem. Missing family, friends, and familiar places can make even a positive experience feel difficult. Without strong support, people may become depressed or want to return home. Emotional well-being is closely linked to a sense of belonging.
However, culture shock is not all negative. It can lead to personal growth, better understanding, and new friendships. When people overcome cultural barriers, they often become more open-minded, flexible, and confident. They learn how to view the world through different eyes.
Schools, companies, and governments can reduce culture shock through orientation programs, language classes, and support groups. When newcomers are guided through the early stages, they adjust faster and feel more welcomed.
Technology can also help. Translation apps, video calls, and online communities allow people to stay connected and informed. Still, relying too much on one's own language and culture may slow down the process of adaptation. True cultural understanding requires effort and exposure.
It‘s also important to respect both cultures—the one you come from and the one you‘re entering. Some people try to reject the new culture completely; others may forget their own traditions to fit in. Neither extreme is healthy. A balanced identity includes pride in your roots and respect for your new environment.
Discrimination and racism can make culture shock worse. When people face judgment or exclusion, they may feel unsafe or unwanted. Host societies must work toward inclusion and equality if they want to benefit from cultural diversity. In contrast, people in multicultural cities may experience less culture shock because diversity is normal. In places like Toronto, London, or Dubai, encountering different traditions is part of daily life. Exposure to many cultures reduces fear and builds tolerance.
Reverse culture shock is also real. When people return home after spending time abroad, they may feel out of place. Family and friends may not understand the changes they‘ve gone through. Adapting back to one‘s original culture can be surprisingly difficult.
In conclusion, culture shock is a natural reaction to a major life change. It involves emotional struggle—but also opportunity. By facing discomfort, people grow stronger and wiser. Understanding culture shock is not just useful for travelers— it‘s essential in an increasingly globalized world.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of this passage is to explain culture shock as the emotional and psychological discomfort experienced when entering a different culture, describe its four stages, identify major causes such as language barriers and social customs, discuss both negative effects and opportunities for growth, and outline ways to reduce it through support programs, technology, and balanced cultural respect in a globalized world.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are the four stages of culture shock?',
        explanation: 'The four stages are the honeymoon stage, where people feel excited about new experiences; the frustration stage, marked by misunderstandings, homesickness, irritation, or loneliness; the adjustment stage, where people begin understanding and adapting to the new culture; and the acceptance stage, where they feel comfortable, make connections, and appreciate cultural differences.',
      ),
      ReadingQuestion(
        question: 'The word \'isolation\' in the passage most likely means?',
        explanation: 'It most likely means a feeling of being alone or separated from others, as the passage describes how miscommunication can lead to embarrassment or feelings of isolation, and how homesickness and lack of support can make people feel disconnected from their new environment.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about reverse culture shock?',
        explanation: 'It can be inferred that reverse culture shock occurs when people return home after time abroad and feel out of place because family and friends may not understand the personal changes they have undergone, making readjustment to the original culture surprisingly difficult.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how can schools, companies, and governments help reduce culture shock?',
        explanation: 'They can reduce culture shock through orientation programs, language classes, and support groups that guide newcomers through the early stages, helping them adjust faster and feel more welcomed.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the long-term effects of overcoming culture shock?',
        explanation: 'It can be inferred that overcoming cultural barriers leads to personal growth, as people often become more open-minded, flexible, and confident, learning to view the world through different perspectives and forming new friendships.',
      ),
    ],
  ),

  ReadingPassage(
    id: 52,
    title: 'Art',
    topic: 'Arts & Culture',
    content: '''Art is a powerful form of human expression. It includes painting, sculpture, music, dance, theatre, film, literature, and even architecture. Because art reflects how people see and feel about the world, it plays a key role in shaping culture, identity, and society.
Throughout history, art has served many purposes. It has been used to record events, express emotions, question beliefs, and inspire change. From the cave paintings of early humans to digital installations in modern galleries, art continues to evolve while staying deeply personal.
One of the main debates surrounding art is its value. Some people believe art should be beautiful and enjoyable, while others see it as a tool for political or social commentary. Because beauty is subjective, opinions about what qualifies as "real art" often differ.
Another question is whether art should be funded by governments. Supporters argue that public funding makes art accessible to everyone, not just the wealthy. It also helps preserve national culture and history. When governments invest in museums, theatres, and cultural programs, they strengthen civic pride and creativity.
Critics, however, say that public money should focus on essential services like healthcare or education. They argue that artists can find private sponsors or sell their work. This raises the question of whether art is a necessity or a luxury.
In education, the role of art is also debated. Some schools reduce art classes to focus on science and math, thinking they are more useful for future careers. But research shows that creative subjects improve problem-solving, communication, and emotional intelligence. Students who study art often perform better overall, especially in innovation and teamwork.
Art is also closely linked to mental health. Creating or experiencing art can reduce stress, improve mood, and build self-confidence. In hospitals and care homes, art therapy is often used to support recovery. Because art helps people express emotions they cannot put into words, it is a powerful healing tool.
In the digital age, art is more accessible than ever. People can share paintings, music, or short films online with global audiences. At the same time, technology raises new questions about ownership, originality, and copyright. When AI or digital tools create artworks, who owns the result?
Street art is another example of how the definition of art has expanded. Once considered vandalism, graffiti is now celebrated in major cities as a form of social or political commentary. Artists like Banksy have blurred the line between illegal acts and public expression. This challenges traditional views of where art belongs and who it is for.
Art can also unite or divide people. It can celebrate cultural identity or challenge existing norms. In times of conflict, art has been used both to protest injustice and to support propaganda. Because it speaks to emotion more than logic, art can influence public opinion more deeply than speeches or statistics.
Economic value matters, too. The global art market is worth billions of dollars. Famous artworks are sold at auctions for record prices. However, many artists struggle to make a living. The gap between commercial success and creative freedom is often wide.
Tourism is another factor. Cities with rich artistic histories—like Paris, Florence, or Kyoto—attract millions of visitors every year. Art boosts the local economy, creates jobs, and promotes cultural exchange. Heritage sites, galleries, and festivals all benefit from this connection.
But commercialization also has its downsides. Some believe that turning art into a product weakens its meaning. When the goal becomes profit, not expression, artistic quality may suffer. Authenticity is sometimes sacrificed for popularity.
In many societies, art is still under threat. War, censorship, and discrimination silence voices and destroy cultural works. Protecting artistic freedom is essential, not only for artists, but for a healthy, democratic society.
In conclusion, art is not just decoration—it is reflection, resistance, and identity. Whether it's a mural on a street wall or a symphony in a concert hall, art continues to shape how people feel, think, and connect. As long as humans exist, they will create—and that creation will always matter.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to explain the significance of art as a form of human expression, discuss debates about its value and funding, examine its roles in education, mental health, society, and the economy, and emphasize its lasting importance in shaping culture and identity.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what purposes has art served throughout history?',
        explanation: 'Art has been used to record events, express emotions, question beliefs, and inspire change, evolving from early cave paintings to modern digital installations while remaining deeply personal.',
      ),
      ReadingQuestion(
        question: 'The word \'subjective\' in the third paragraph most likely means...',
        explanation: 'Based on personal feelings or opinions rather than objective facts. The passage states that because beauty is subjective, opinions about what qualifies as "real art" often differ.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the debate over government funding of art?',
        explanation: 'Supporters believe public funding makes art accessible to everyone and preserves culture, while critics argue public money should prioritize essential services like healthcare or education and that artists can seek private sponsors, raising the question of whether art is a necessity or a luxury.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does studying art benefit students?',
        explanation: 'Research shows that creative subjects improve problem-solving, communication, and emotional intelligence, and students who study art often perform better overall, especially in innovation and teamwork.',
      ),
      ReadingQuestion(
        question: 'The word \'vandalism\' in the ninth paragraph most likely means...',
        explanation: 'Deliberate destruction or damage of property. The passage notes that street art and graffiti, once considered vandalism, are now celebrated in major cities as social or political commentary.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about art\'s relationship with mental health?',
        explanation: 'Creating or experiencing art can reduce stress, improve mood, and build self-confidence; art therapy is used in hospitals and care homes to support recovery because art helps people express emotions they cannot put into words.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what new questions does technology raise about art?',
        explanation: 'Technology makes art more accessible online but raises questions about ownership, originality, and copyright, including who owns artworks created by AI or digital tools.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the economic side of art?',
        explanation: 'The global art market is worth billions and famous works sell for record prices, yet many artists struggle to make a living, creating a wide gap between commercial success and creative freedom; commercialization can also weaken meaning when profit becomes the goal.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is protecting artistic freedom important?',
        explanation: 'In many societies art is under threat from war, censorship, and discrimination that silence voices and destroy cultural works; protecting artistic freedom is essential not only for artists but for a healthy, democratic society.',
      ),
    ],
  ),

  ReadingPassage(
    id: 53,
    title: 'History',
    topic: 'Society & Culture',
    content: '''History is the study of past events, civilizations, cultures, and people. It helps us understand how the world has changed over time and why societies function the way they do today. Because history provides context for current events, it is a key subject in education, politics, and public debate.
Some believe that history repeats itself. Wars, economic crises, and social conflicts often follow similar patterns. By studying the causes and consequences of past events, people can avoid repeating mistakes. For example, examining the roots of world wars can help prevent future global conflicts.
Others argue that each historical period is unique. New technology, values, and circumstances mean that past solutions may not work today. While history offers lessons, it cannot predict the future with certainty.
There are different ways to study history. Some focus on political leaders and major events—wars, revolutions, treaties. Others emphasize the lives of ordinary people: workers, farmers, women, and minorities. This ―bottom-up‖ approach gives a fuller picture of society, not just the actions of the powerful.
History can be written and interpreted in many ways. Textbooks, films, museums, and monuments often present a selective version of the past. Because history is told by people with different views, it may include bias, omission, or even propaganda. That‘s why it‘s important to study multiple sources and ask critical questions.
Debates about history are common. In some countries, people argue over how colonialism, slavery, or wars should be remembered. Statues may be removed, holidays renamed, or school curriculums changed. These debates show that history is not just about facts—but about identity and power.
National history is often used to build pride and unity. Governments highlight achievements and heroic figures to inspire patriotism. While this can create a sense of belonging, it can also lead to nationalism or historical distortion. Glorifying the past without recognizing its problems is dangerous.
In schools, history helps students develop research and analytical skills. They learn how to read sources, identify causes and effects, and build arguments. These skills are useful beyond the classroom, especially in law, journalism, and politics.
Some question the practical value of history. They say students should focus on science, business, or technology to get jobs. But history teaches people how to think, not just what to know. Understanding the past helps people make better decisions in the present.
History also plays a major role in international relations. Disputes between countries often involve historical claims. Conflicts over land, identity, and responsibility are linked to past events. For example, territorial tensions in Asia and Eastern Europe often reference centuries-old history.
Preserving historical sites and documents is important for cultural memory. Museums, archives, and monuments help people connect with their heritage. When history is lost—through war, neglect, or natural disasters—so is a part of national identity.
However, not all history is celebrated. Some periods involve shame, injustice, or trauma. Facing this truth can be painful, but it is necessary. Countries that openly discuss their past are often more democratic and inclusive, because they recognize the harm done and aim to improve.
Digital technology is changing how people access history. Online archives, virtual museums, and podcasts bring the past to life for new audiences. At the same time, misinformation can spread easily. Critical thinking and fact-checking are more important than ever.
Family history is also popular. Many people research their ancestry through DNA tests or historical records. This personal connection to the past helps individuals understand where they come from, and how their ancestors lived, migrated, or struggled.
Tourism based on history—like visiting ancient cities, castles, or battlefields—is a growing industry. It brings income and awareness, but also responsibility. Sites must be preserved and explained respectfully, not turned into entertainment.
In conclusion, history is more than a list of dates and names—it is the story of humanity. To understand who we are and where we are going, we must know where we‘ve been. A society that ignores its past risks losing its future.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to explain the importance of history as the study of the past that provides context for the present, discuss different approaches to studying and interpreting it, explore its roles in education, national identity, international relations, and cultural memory, and emphasize that understanding history is essential for making better decisions and shaping a better future.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why do some people believe that history repeats itself?',
        explanation: 'Wars, economic crises, and social conflicts often follow similar patterns, so by studying the causes and consequences of past events, people can avoid repeating mistakes, such as examining the roots of world wars to help prevent future global conflicts.',
      ),
      ReadingQuestion(
        question: 'The phrase "bottom-up" approach in the fourth paragraph most likely means',
        explanation: 'In contrast to focusing on political leaders and major events, the bottom-up approach emphasizes the lives of ordinary people such as workers, farmers, women, and minorities, giving a fuller picture of society rather than only the actions of the powerful.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the interpretation of history from the passage?',
        explanation: 'It can be inferred that history is often selective and may include bias, omission, or propaganda because it is told by people with different views; therefore, studying multiple sources and asking critical questions is important.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how is national history sometimes used by governments?',
        explanation: 'Governments highlight achievements and heroic figures to inspire patriotism and build pride and unity; while this can create a sense of belonging, it can also lead to nationalism or historical distortion if the past is glorified without recognizing its problems.',
      ),
      ReadingQuestion(
        question: 'The word "distortion" in the seventh paragraph most likely means',
        explanation: 'In the context of nationalism or historical distortion from glorifying the past without recognizing its problems, the word means a misleading or inaccurate representation of historical facts.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the practical value of studying history?',
        explanation: 'Although some question its practical value compared to science, business, or technology, history teaches people how to think critically, develop research and analytical skills, and understand the past in order to make better decisions in the present.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what role does history play in international relations?',
        explanation: 'Disputes between countries often involve historical claims, and conflicts over land, identity, and responsibility are linked to past events; for example, territorial tensions in Asia and Eastern Europe often reference centuries-old history.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about countries that openly discuss difficult periods in their past?',
        explanation: 'It can be inferred that such countries are often more democratic and inclusive because they recognize the harm done in periods of shame, injustice, or trauma and aim to improve, even though facing these truths can be painful.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how is digital technology changing access to history?',
        explanation: 'Online archives, virtual museums, and podcasts bring the past to life for new audiences, but misinformation can also spread easily, making critical thinking and fact-checking more important than ever.',
      ),
    ],
  ),

  ReadingPassage(
    id: 54,
    title: 'Film',
    topic: 'Arts & Media',
    content: '''Film is one of the most influential forms of modern art and entertainment. Because it combines storytelling, visuals, music, and performance, film has the unique ability to capture human emotions and spread ideas across cultures and generations.
Cinema began in the late 19th century as silent black-and-white footage. Over time, it evolved into a multi-billion-dollar global industry. Today, films are produced in nearly every country and shown in cinemas, streamed online, or shared through social media. As technology advanced, so did the power of film to reach global audiences.
Films can serve many purposes:
•        Entertainment – People watch films to relax, escape reality, or laugh.
•        Education – Documentaries and historical dramas can teach facts and raise awareness.
•        Inspiration – Films can motivate people to change, dream, or take action.
•        Expression – Directors and writers often use film to explore personal or political themes.
The impact of film on society is significant. Movies influence fashion, language, values, and behavior. For example, superhero films have shaped how children see bravery and justice. Romantic dramas affect how people think about love. Because film shapes public opinion, it is often used to promote cultural values or challenge stereotypes.
However, the industry also faces criticism. Some argue that many mainstream films lack originality, relying on predictable plots, violence, or special effects. When profits come before creativity, quality can suffer. Independent films, on the other hand, are often praised for their fresh ideas and deeper messages, even if they reach smaller audiences.
Hollywood is considered the global center of film, but other industries are growing rapidly. Bollywood in India produces more films per year than any other country. Korean cinema, especially after the global success of films like Parasite, has gained international respect. These industries reflect local culture while competing on a global stage.
Censorship is a controversial issue. In some countries, governments control which films are shown or edit scenes that they consider immoral or politically sensitive. Supporters say this protects social values, but critics argue it limits artistic freedom. Because film is a form of speech, many believe it should not be restricted.
Violence and inappropriate content in films are also debated. Some believe watching violent or sexual scenes can affect young viewers negatively. Others say the problem lies not in the content itself, but in poor education or lack of guidance. Parental controls and age ratings can help, but they are not always followed.
Film also raises questions about cultural representation. Stereotypes and lack of diversity have long been problems. In many movies, certain groups are shown in limited or negative roles. When films fail to reflect real societies, they reinforce inequality. Recently, filmmakers and audiences have demanded better representation in casting and storytelling.
Streaming services like Netflix, Disney+, and Amazon Prime have transformed the industry. People now watch films at home, anytime. This offers flexibility and access—but also threatens traditional cinemas. Because audiences are moving online, cinemas must adapt to survive.
Animation is another powerful branch of film. It appeals to both children and adults, and often deals with deep emotional or philosophical topics. Studios like Pixar, Ghibli, and DreamWorks have created classics that continue to shape childhood memories around the world. Animation proves that film is not limited by age, language, or realism.
Film festivals also play an important role. Events like Cannes, Sundance, and the Venice Film Festival celebrate artistic cinema and give a platform to new voices. Winning awards at these festivals can launch careers and bring attention to hidden stories. They remind the world that film is not just business—it is art.
Making a film involves many roles: director, writer, actor, editor, composer, set designer, and more. It is a team effort requiring creativity, technical skill, and vision. The success of a film depends not just on the story—but on how it is told.
In conclusion, film is more than just entertainment. It is a mirror of society, a tool for education, and a global language. As technology and culture continue to change, film will continue to shape and reflect the human experience.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage explores the history, purposes, social impact, criticisms, global industries, and evolving forms of film, concluding that it is a mirror of society and a global language that shapes human experience.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what purposes can films serve?',
        explanation: 'Films can serve as entertainment for relaxation and escape, education through documentaries and historical dramas, inspiration to motivate change, and expression for exploring personal or political themes.',
      ),
      ReadingQuestion(
        question: 'The word "mainstream" in the fifth paragraph most likely means',
        explanation: 'In context, mainstream refers to popular, widely distributed commercial films that often prioritize profits and may rely on predictable plots, violence, or special effects rather than originality.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about independent films from the passage?',
        explanation: 'Independent films are often praised for their fresh ideas and deeper messages, even though they typically reach smaller audiences compared to mainstream productions.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how has Korean cinema gained international recognition?',
        explanation: 'Korean cinema gained international respect especially after the global success of films like Parasite, reflecting local culture while competing on the world stage.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the debate over film censorship?',
        explanation: 'Supporters of censorship believe it protects social values by controlling immoral or politically sensitive content, while critics argue it restricts artistic freedom because film is a form of speech.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what problems exist regarding cultural representation in films?',
        explanation: 'Stereotypes and lack of diversity have long been issues, with certain groups shown in limited or negative roles, which can reinforce inequality when films fail to reflect real societies.',
      ),
      ReadingQuestion(
        question: 'The word "transformed" in the tenth paragraph most likely means',
        explanation: 'In context, transformed means that streaming services have fundamentally changed the film industry by enabling people to watch movies at home anytime, offering flexibility while threatening traditional cinemas.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of film festivals?',
        explanation: 'Film festivals such as Cannes, Sundance, and Venice celebrate artistic cinema, provide platforms for new voices, can launch careers, and emphasize that film is art as well as business.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is animation considered a powerful branch of film?',
        explanation: 'Animation appeals to both children and adults, often addresses deep emotional or philosophical topics, and is not limited by age, language, or realism, as shown by studios like Pixar, Ghibli, and DreamWorks.',
      ),
    ],
  ),

  ReadingPassage(
    id: 55,
    title: 'Tourism',
    topic: 'Society & Culture',
    content: '''Tourism is one of the world‘s largest industries, contributing significantly to global employment, culture exchange, and economic growth. Because millions of people travel across borders every year, tourism has the power to shape economies, environments, and societies.
There are many types of tourism—leisure, cultural, adventure, religious, medical, and ecotourism. Some people travel to relax on beaches, while others seek historic landmarks, religious sites, or extreme experiences. The reasons people travel may differ, but the impact of tourism is global.
One of the main advantages of tourism is economic. When tourists spend money on hotels, food, transportation, and entertainment, they support local businesses. In developing countries, tourism creates jobs and stimulates development, especially in areas with few other industries.
Cultural exchange is another key benefit. Tourism allows people to experience different ways of life, learn new languages, and understand other traditions. Because travel brings people together, it promotes tolerance, cooperation, and global awareness.
However, tourism also brings serious challenges. Mass tourism can damage natural environments. Crowds, pollution, and litter harm fragile ecosystems. When too many visitors enter protected areas, plants and animals may be disturbed or destroyed. The beauty that attracts tourists can quickly disappear if not managed properly.
Cultural heritage sites are also at risk. Historical buildings and sacred places can be damaged by careless visitors. In some cases, traditional customs may be turned
into performances to please tourists, losing their meaning. This process, known as cultural commodification, threatens the authenticity of local cultures.
Over-tourism is a growing concern in popular cities like Venice, Barcelona, and Kyoto. Local residents may be pushed out of their neighborhoods as property prices rise and short-term rentals increase. When tourism takes over everyday life, quality of life for locals suffers.
To solve these issues, many cities and countries are promoting sustainable tourism—a model that balances economic growth with environmental protection and cultural respect. This includes limiting visitor numbers, encouraging ecofriendly travel, and involving local communities in tourism planning. If tourism is to last, it must be managed responsibly.
Technology is changing how people travel. Booking platforms, travel blogs, and digital maps make it easier to plan trips. Social media also plays a major role. When people post pictures online, they often influence others to visit the same places. This can cause sudden waves of tourists in previously unknown areas.
The COVID-19 pandemic had a massive impact on tourism. Borders were closed, flights canceled, and millions of jobs lost. While travel is now recovering, the crisis forced the industry to rethink its approach. There is now a stronger focus on health, safety, and sustainability.
Local tourism is gaining popularity. More people are choosing to explore their own countries rather than travel abroad. This reduces environmental damage and supports local economies. Because domestic travel is often cheaper and easier, it may become a long-term trend.
Tourism also plays a role in diplomacy and international image. Countries often use advertising to promote their culture, nature, and hospitality. Hosting global events like the Olympics or World Expo can attract millions of visitors. This form of ―soft power‖ strengthens international relationships.
Education and awareness are key to improving tourism. Tourists must be taught how to respect local customs, behave in sensitive areas, and minimize waste. Governments and businesses must also ensure that tourism benefits all parts of society—not just the wealthy or urban areas. Only then can tourism be truly inclusive.
Some argue that tourism is a modern form of colonialism. Wealthy tourists from developed nations often visit poorer regions, spending little time understanding the local culture. If tourism becomes a one-sided relationship, it can reinforce stereotypes and inequality instead of breaking them.
In conclusion, tourism can be a force for good—but only if managed wisely. It brings income, connection, and knowledge—but also pressure, pollution, and risk. The challenge is not to stop tourism, but to shape it in a way that respects people, protects places, and promotes peace.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage describes the economic, cultural, and social benefits of tourism, examines its environmental and social challenges including over-tourism and cultural commodification, discusses sustainable approaches and the impact of technology and the pandemic, and concludes that tourism must be managed responsibly to respect people and places.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is one of the main advantages of tourism?',
        explanation: 'The passage states that one of the main advantages is economic, as tourist spending on hotels, food, transportation, and entertainment supports local businesses and creates jobs, especially in developing countries.',
      ),
      ReadingQuestion(
        question: 'The term "cultural commodification" in the passage most likely means',
        explanation: 'The passage explains that cultural commodification occurs when traditional customs are turned into performances to please tourists, causing them to lose their meaning and threatening the authenticity of local cultures.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the effects of mass tourism on the environment?',
        explanation: 'The passage notes that mass tourism can damage natural environments through crowds, pollution, and litter, and that excessive visitors to protected areas may disturb or destroy plants and animals, potentially destroying the beauty that attracts tourists.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what problems does over-tourism create for local residents?',
        explanation: 'The passage states that in cities like Venice, Barcelona, and Kyoto, local residents may be pushed out of their neighborhoods as property prices rise and short-term rentals increase, harming their quality of life.',
      ),
      ReadingQuestion(
        question: 'The word "sustainable" in the phrase "sustainable tourism" most likely means',
        explanation: 'In context, sustainable tourism refers to a model that balances economic growth with environmental protection and cultural respect, including limiting visitor numbers and involving local communities.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the impact of the COVID-19 pandemic on the tourism industry?',
        explanation: 'The passage explains that borders were closed, flights canceled, and millions of jobs lost, and that the crisis forced the industry to rethink its approach with a stronger focus on health, safety, and sustainability.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is local or domestic tourism gaining popularity?',
        explanation: 'The passage states that more people are choosing to explore their own countries, which reduces environmental damage, supports local economies, and is often cheaper and easier, potentially becoming a long-term trend.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of social media in tourism?',
        explanation: 'The passage notes that when people post pictures online they often influence others to visit the same places, which can cause sudden waves of tourists in previously unknown areas.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is required for tourism to be truly inclusive?',
        explanation: 'The passage states that governments and businesses must ensure tourism benefits all parts of society—not just the wealthy or urban areas—and that education and awareness about respecting local customs and minimizing waste are also key.',
      ),
    ],
  ),

  ReadingPassage(
    id: 56,
    title: 'Festivals',
    topic: 'Society & Culture',
    content: '''Festivals are a vital part of human culture. They are special occasions that bring communities together to celebrate religion, tradition, history, or national pride. Because festivals are repeated regularly, they create a shared rhythm of life and strengthen social bonds.
Festivals can be religious, seasonal, cultural, or even political. For example:
•        Religious festivals like Eid, Christmas, or Diwali mark sacred events and promote spiritual reflection.
•        Seasonal festivals such as Nowruz or harvest celebrations recognize the changes in nature and honor agricultural life.
•        National festivals like Independence Day or Constitution Day foster unity and patriotism.
•        Modern events like film festivals, music festivals, or food fairs showcase art and innovation.
Each festival has its own unique customs, foods, clothing, and rituals. These cultural elements keep traditions alive and pass them to future generations. Because of this, festivals are essential in preserving heritage.
One key benefit of festivals is community engagement. They give people a chance to gather, relax, and celebrate their identity. In a world where digital life often replaces real connections, festivals remind us of the value of face-to-face joy and shared experience.
Economically, festivals can support local businesses, attract tourism, and create jobs. Hotels, restaurants, performers, and shops all benefit during large-scale events. This economic boost is especially valuable in rural areas, where festivals may be the main attraction of the year.
However, festivals also come with challenges. Large crowds can lead to traffic, pollution, and noise. Waste management becomes difficult when thousands gather in one place. If events are not well organized, they may harm the environment and disrupt daily life.
Religious festivals, in particular, can sometimes create division if they are not inclusive. When one group‘s celebration ignores or disrespects others, tension can rise in multicultural societies. Organizers must ensure that festivals bring people together—not drive them apart.
Another issue is commercialization. As festivals become more popular, businesses often turn them into profit-making events. Traditional practices may be replaced by advertisements, concerts, and mass-produced goods. When cultural meaning is replaced by commercial interest, the original purpose of the festival may fade.
Globalization has both enriched and changed festivals. On one hand, people around the world can now learn about and participate in different cultural celebrations. For instance, Halloween and Valentine‘s Day are celebrated in many countries outside their origin. On the other hand, global influence may weaken local customs, especially among younger generations who follow international trends.
Modern festivals are also increasingly digital. People post photos, livestream ceremonies, or attend virtual events. This can help preserve traditions during times like the COVID-19 pandemic, but it also raises questions about authenticity. Is a digital celebration the same as a real one?
Despite these challenges, festivals continue to play a powerful role in shaping identity and social values. They remind people of their history, beliefs, and shared future. Even in times of crisis or conflict, festivals provide hope, unity, and a break from routine.
Schools and educators often use festivals to teach cultural awareness. By explaining the meaning behind holidays from different traditions, students develop respect and understanding. This helps reduce prejudice and builds stronger, more inclusive communities.
Governments and cultural organizations must protect traditional festivals. Funding, space, and media coverage are all tools they can use to promote local events. Because once a tradition disappears, it is hard to revive.
In multicultural societies, celebrating festivals from various backgrounds builds harmony. Public events that include different cultural performances, foods, and music allow everyone to share their heritage. This not only educates the public but also strengthens social unity.
In conclusion, festivals are more than just fun—they are culture in action. They reflect values, preserve identity, and bring people together across time and space. To keep festivals meaningful in the modern world, we must balance celebration with respect, tradition with innovation, and joy with responsibility.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to explain the cultural importance of festivals, their various types and benefits, the challenges they face such as commercialization and environmental impact, and the need to preserve their meaning in modern society.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how do festivals help preserve heritage?',
        explanation: 'Festivals preserve heritage by featuring unique customs, foods, clothing, and rituals that keep traditions alive and pass them on to future generations.',
      ),
      ReadingQuestion(
        question: 'The word "rhythm" in the first paragraph most likely means...',
        explanation: 'In the context of the passage, "rhythm" means a regular pattern or recurring cycle of life created by the repeated celebration of festivals.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the economic impact of festivals?',
        explanation: 'It can be inferred that festivals provide significant economic benefits by supporting local businesses, attracting tourism, creating jobs, and offering a major boost especially in rural areas.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what challenges can large festivals create?',
        explanation: 'Large festivals can lead to traffic, pollution, noise, and difficulties with waste management; if poorly organized, they may harm the environment and disrupt daily life.',
      ),
      ReadingQuestion(
        question: 'The word "commercialization" in the eighth paragraph most likely means...',
        explanation: 'In the context of the passage, "commercialization" refers to the process of turning festivals into profit-making events where traditional practices are replaced by advertisements and mass-produced goods.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the effect of globalization on festivals?',
        explanation: 'It can be inferred that globalization allows people worldwide to experience different cultural celebrations but may also weaken local customs, particularly among younger generations following international trends.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how can schools use festivals?',
        explanation: 'Schools and educators use festivals to teach cultural awareness by explaining the meaning behind holidays from different traditions, helping students develop respect, reduce prejudice, and build inclusive communities.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about digital festivals?',
        explanation: 'It can be inferred that digital formats such as livestreams and virtual events can help preserve traditions during crises like the COVID-19 pandemic, but they raise questions about whether they offer the same authenticity as in-person celebrations.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is needed to keep festivals meaningful in the modern world?',
        explanation: 'To keep festivals meaningful, society must balance celebration with respect, tradition with innovation, and joy with responsibility while protecting traditional events through funding, space, and media coverage.',
      ),
    ],
  ),

  ReadingPassage(
    id: 57,
    title: 'Astrology',
    topic: 'Beliefs & Culture',
    content: '''Astrology is the belief that the positions and movements of celestial bodies—such as stars, planets, and the moon—can influence human behavior, personality, and life events. Because astrology connects human life with the universe, it has fascinated people for thousands of years.
Astrology dates back to ancient civilizations such as Babylon, Egypt, and Greece.
Early astronomers observed patterns in the sky and linked them to events on Earth. For example, eclipses were believed to predict wars or natural disasters. In many cultures, rulers used astrologers to guide decisions, including when to go to war or whom to marry.
One of the most popular forms of astrology is the zodiac system. It divides the year into twelve signs, each associated with certain traits. People born under Aries, for example, are said to be energetic and bold, while those under Cancer are thought to be emotional and caring. Daily horoscopes use these signs to make predictions about relationships, careers, or health.
Despite its popularity, astrology is highly controversial. Scientists generally reject astrology as a pseudoscience—a belief system that lacks empirical evidence. Because astrological claims cannot be consistently tested or proven, many experts argue it has no scientific basis.
Still, millions of people believe in astrology. Some read horoscopes daily or consult astrologers before making important choices. For them, astrology provides comfort, guidance, and a sense of control. In a world full of uncertainty, looking to the stars offers emotional support.
Astrology also plays a role in culture and identity. In places like India and China, astrological systems are deeply connected to religion and tradition. For example, Hindu astrology (Jyotish) is used to plan weddings and name children. In many Asian countries, people avoid certain dates or colors based on their birth charts.
The rise of social media has made astrology even more popular, especially among young people. Platforms like Instagram, TikTok, and YouTube feature content about zodiac signs, compatibility, and personality types. Astrology memes and posts often go viral, turning ancient beliefs into modern entertainment.
However, some critics argue that astrology encourages irrational thinking. People may base serious life choices—like quitting a job or ending a relationship—on vague predictions. When personal responsibility is replaced by superstition, critical thinking can suffer.
Others say astrology can be used as a tool for self-reflection. Even if the predictions are not accurate, reading about personality traits or life patterns may help people think about their emotions and goals. Because astrology invites people to ask questions about themselves, it can promote self-awareness.
The Barnum effect explains why astrology often feels accurate. It refers to the tendency to accept vague, general statements as personal truths. For example, ―You often feel misunderstood‖ or ―You are sometimes shy, but can also be outgoing‖ could apply to almost anyone. Because horoscopes are written to sound specific yet universal, people often believe they are true.
There is also a commercial side to astrology. Books, apps, personal chart readings, and jewelry based on zodiac signs generate significant income. Some companies target consumers based on their birth signs or astrological preferences. This blend of belief and business can raise ethical concerns.
In education, astrology is not taught as science, but it appears in literature, history, and cultural studies. Famous writers like Shakespeare and Dante referenced astrology in their work. Understanding astrology can help students analyze historical beliefs and cultural symbolism.
In medicine, astrology has no proven role. Some people use ―medical astrology‖ to explain health issues or choose treatment times, but mainstream doctors warn that this can delay proper care. Health decisions should be based on science—not the stars.
In conclusion, astrology continues to attract strong interest and strong criticism. It blends tradition, belief, psychology, and pop culture into one complex system. Whether seen as spiritual guidance or superstition, astrology reflects a deep human desire to find meaning in the universe..''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to explore astrology as an ancient belief system connecting celestial bodies to human life, discussing its history, popularity, cultural role, scientific criticism, psychological appeal, and modern commercial and social aspects.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is the zodiac system?',
        explanation: 'According to the passage, the zodiac system is one of the most popular forms of astrology that divides the year into twelve signs, each associated with certain personality traits, and is used in daily horoscopes to make predictions about relationships, careers, or health.',
      ),
      ReadingQuestion(
        question: 'The word "pseudoscience" in the fifth paragraph most likely means',
        explanation: 'In the context of the fifth paragraph, "pseudoscience" means a belief system that lacks empirical evidence and cannot be consistently tested or proven, which is how scientists generally classify astrology.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about why many people continue to believe in astrology?',
        explanation: 'It can be inferred that astrology provides comfort, guidance, and a sense of control in an uncertain world, offering emotional support that keeps millions of people engaged with horoscopes and astrologers despite scientific rejection.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how has social media affected astrology?',
        explanation: 'According to the passage, the rise of social media has made astrology more popular especially among young people, with platforms like Instagram, TikTok, and YouTube featuring zodiac content that often goes viral and turns ancient beliefs into modern entertainment.',
      ),
      ReadingQuestion(
        question: 'The term "Barnum effect" in the eleventh paragraph most likely refers to',
        explanation: 'In the context of the eleventh paragraph, the Barnum effect refers to the tendency to accept vague, general statements as highly personal truths, which explains why horoscopes often feel accurate even though they could apply to almost anyone.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the use of astrology in cultures like India and China?',
        explanation: 'It can be inferred that astrology is deeply integrated into religion and tradition in places like India and China, where systems such as Hindu astrology (Jyotish) guide important decisions like planning weddings, naming children, and avoiding certain dates or colors based on birth charts.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why do some critics argue that astrology can be harmful?',
        explanation: 'According to the passage, critics argue that astrology encourages irrational thinking by leading people to base serious life choices on vague predictions, which can replace personal responsibility with superstition and weaken critical thinking.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the commercial aspect of astrology?',
        explanation: 'It can be inferred that astrology has become a significant business generating income through books, apps, chart readings, and jewelry, with companies targeting consumers by birth signs, raising ethical concerns about blending belief with commerce.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is the recommended basis for health decisions?',
        explanation: 'According to the passage, health decisions should be based on science rather than the stars, as mainstream doctors warn that relying on medical astrology can delay proper care and astrology has no proven role in medicine.',
      ),
    ],
  ),

  ReadingPassage(
    id: 58,
    title: 'Fame',
    topic: 'Society & Culture',
    content: '''Fame is the state of being widely known by the public, often due to achievements in entertainment, sports, politics, or social media. Because fame brings attention, influence, and money, it has become one of the most desired goals in modern society.
Traditionally, people became famous through talent, hard work, or leadership. Artists, writers, scientists, and national leaders were respected for their contributions. In contrast, today‘s fame is often instant and based on appearance, controversy, or viral content. Reality TV stars and social media influencers can gain millions of followers overnight—with little proven skill.
The rise of the internet has changed the path to fame. Platforms like YouTube,
Instagram, TikTok, and Twitter allow anyone to broadcast themselves to the world. Because fame is now more accessible, it has lost some of its mystery and value.
Being ―famous‖ does not always mean being respected. Fame can bring many benefits:
•        Financial success – Celebrities often earn large amounts through sponsorships, brand deals, and product lines.
•        Social influence – Public figures can raise awareness, promote causes, or influence trends and behaviors.
•        Opportunities – Fame opens doors to travel, meet powerful people, and access elite circles.
However, fame also comes with heavy costs. Privacy disappears, as every move may be captured by cameras or shared online. Rumors, false stories, and public criticism can affect mental health. The pressure to stay relevant and perfect can become overwhelming, especially for young or unprepared individuals.
Famous people often face unrealistic expectations. The public may view them as role models or expect them to act in a certain way. When they fail to meet these standards, they are judged harshly. Even small mistakes can lead to public backlash or ―cancel culture.‖
Children and teenagers are especially influenced by fame. Many dream of becoming famous rather than becoming teachers, doctors, or engineers. Because fame is often linked to luxury and excitement, it may appear more attractive than traditional careers. But few understand the sacrifices involved.
Media plays a major role in shaping ideas about fame. Magazines, websites, and TV shows often celebrate celebrity lifestyles, showing luxury, beauty, and success. This creates unrealistic comparisons, leading to dissatisfaction or envy among viewers.
In some cultures, fame is tied to social status. Families may encourage children to enter sports or entertainment to gain recognition. However, this can place pressure on young people, pushing them into careers they may not truly enjoy.
Not all famous people enjoy being in the spotlight. Some actors, writers, and athletes prefer privacy and try to avoid public attention. Fame can be accidental or unwanted, especially for those involved in news scandals or tragedies.
There is also a difference between short-term and long-term fame. Viral fame— such as becoming a meme or trending online—often disappears quickly. In contrast, those who build their reputation through years of work tend to be remembered longer.
Society often confuses fame with value. Just because someone is well-known does not mean they are important or wise. This creates a dangerous situation, where people with no expertise are given a platform to influence public opinion.
On the other hand, some use fame responsibly. Celebrities who speak about mental health, social justice, or education can make a real difference. When fame is used for good, it becomes a powerful tool for change.
In education, fame can be both a distraction and a topic for discussion. Teachers can help students understand the difference between meaningful success and superficial popularity. Critical thinking is essential in a world full of influencers and filtered images.
In conclusion, fame is a double-edged sword. It offers rewards—but also risks. In a time where anyone can become famous, it‘s more important than ever to ask: Famous for what? and At what cost? Real value comes not from being seen—but from what you give to the world.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to examine the nature of fame in modern society, contrasting traditional and contemporary paths to fame, listing its benefits and heavy costs, discussing its influence on young people and media, distinguishing short-term from long-term fame, and concluding that fame is a double-edged sword whose real value lies in what one contributes rather than mere visibility.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how has the path to fame changed with the rise of the internet?',
        explanation: 'According to the passage, platforms like YouTube, Instagram, TikTok, and Twitter allow anyone to broadcast themselves to the world, making fame more accessible and causing it to lose some of its mystery and value; today‘s fame is often instant and based on appearance, controversy, or viral content rather than proven skill.',
      ),
      ReadingQuestion(
        question: 'The phrase "cancel culture" in the passage most likely refers to',
        explanation: 'In the passage, "cancel culture" refers to the harsh public judgment and backlash that can result even from small mistakes when famous people fail to meet the unrealistic expectations placed on them as role models.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the costs of fame?',
        explanation: 'It can be inferred that fame brings heavy costs including the loss of privacy, exposure to rumors and public criticism that can harm mental health, and overwhelming pressure to stay relevant and perfect, especially for young or unprepared individuals.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what benefits can fame bring?',
        explanation: 'According to the passage, fame can bring financial success through sponsorships, brand deals, and product lines; social influence that allows public figures to raise awareness, promote causes, or influence trends; and opportunities such as travel, meeting powerful people, and accessing elite circles.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the difference between short-term and long-term fame?',
        explanation: 'It can be inferred that short-term or viral fame, such as becoming a meme or trending online, often disappears quickly, whereas those who build their reputation through years of work tend to be remembered longer and achieve more lasting recognition.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does media shape ideas about fame?',
        explanation: 'According to the passage, magazines, websites, and TV shows often celebrate celebrity lifestyles by showing luxury, beauty, and success, which creates unrealistic comparisons and can lead to dissatisfaction or envy among viewers.',
      ),
      ReadingQuestion(
        question: 'The word "superficial" in the education paragraph most likely means',
        explanation: 'In the context of the passage, "superficial" most likely means shallow or lacking depth, as teachers are encouraged to help students distinguish between meaningful success and superficial popularity in a world full of influencers and filtered images.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the relationship between fame and value?',
        explanation: 'It can be inferred that society often confuses fame with value, mistakenly equating being well-known with being important or wise, which creates a dangerous situation in which people with no expertise are given platforms to influence public opinion.',
      ),
      ReadingQuestion(
        question: 'According to the passage, when can fame become a powerful tool for change?',
        explanation: 'According to the passage, fame becomes a powerful tool for change when it is used responsibly, such as when celebrities speak about mental health, social justice, or education and thereby make a real difference.',
      ),
    ],
  ),

  ReadingPassage(
    id: 59,
    title: 'Generation Gap',
    topic: 'Society & Culture',
    content: '''The generation gap refers to the differences in beliefs, values, habits, and communication styles between people of different age groups. Because each generation grows up with different experiences and technologies, misunderstandings often arise between parents and children, teachers and students, or older and younger workers.
Generations are often shaped by the major events of their youth. For example:
•        People born after World War II grew up with radio and printed newspapers.
•        Those born in the 1980s and 1990s experienced the rise of the internet.  Today‘s teenagers have never known a world without smartphones and social media.
Because each generation is influenced by different tools and problems, they develop unique attitudes toward education, work, relationships, and authority.
Communication is one of the biggest issues. Older people often prefer face-to-face conversations or phone calls. Younger generations rely more on texting, voice messages, or social media. This can create the impression that young people are impatient or disrespectful, even when that is not the case.
Values and priorities also differ. Many older people value stability, loyalty, and hard work. They often expect respect for hierarchy and tradition. In contrast, younger generations may prioritize flexibility, self-expression, and equality. These opposing views can lead to conflict in both families and workplaces.
For example, parents may expect their children to follow a traditional career path—doctor, engineer, or lawyer. But young people might choose creative fields, start-ups, or freelance jobs. Because the economy and job market have changed, old advice may not work anymore.
Technology widens the gap further. Older people may struggle to adapt to new tools or feel left behind. Some even see modern habits—like spending hours online—as lazy or harmful. Younger generations, however, see technology as essential, not just for entertainment but for learning, social life, and even activism. Despite these challenges, the generation gap is not always negative. It can lead to dialogue, growth, and innovation—if approached with mutual respect. Older people bring experience, while younger ones bring new ideas. When both sides listen, progress happens.
In the workplace, multigenerational teams are becoming more common. Employers must learn to manage different expectations. While some workers value job security, others prefer work–life balance or remote options. Understanding these needs can improve cooperation.
Education systems also reflect the generation gap. Teachers trained decades ago may struggle to engage students raised on fast, interactive media. Because attention spans and learning styles have changed, traditional methods may need to evolve. Culture and fashion can also cause tension. Music, clothing, slang, and opinions about dating or marriage often differ sharply. Older people may view modern behavior as rude or shallow, while the young may see elders as strict or out of touch.
Media plays a role, too. News reports often portray young people as lazy or addicted to screens, while older people are described as stubborn or resistant to change. These stereotypes increase misunderstanding, instead of encouraging empathy.
Bridging the generation gap requires effort from both sides. Young people must understand that older generations were shaped by hardship, war, or poverty. Elders must accept that change is part of life. When both generations show patience and curiosity, mutual understanding becomes possible.
Family traditions can help connect generations. Sharing stories, cooking meals together, or celebrating holidays builds bonds. Schools can also encourage intergenerational projects, such as interviews or mentoring programs. These activities reduce prejudice and build mutual respect.
Some cultures manage the generation gap better. In many Asian and African societies, elders are respected and cared for. Their wisdom is seen as valuable, not outdated. In contrast, in some Western countries, older people may be isolated or ignored.
Migration adds another layer. Children born in a new country may adopt different values and languages than their parents. This creates not just a generation gap—but a cultural one, leading to identity conflict within families.
In conclusion, the generation gap is a natural part of social evolution. It reflects how the world changes—and how people adapt to it. While it may create tension, it also offers a chance to learn, connect, and grow together.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to explain the generation gap as differences in beliefs, values, habits, and communication styles between age groups, explore its causes such as technology and life experiences, describe its effects in families, workplaces, and education, and show that it can be bridged through mutual respect and understanding.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how are generations shaped?',
        explanation: 'According to the passage, generations are often shaped by the major events and technologies of their youth; for example, people born after World War II grew up with radio and newspapers, those born in the 1980s and 1990s experienced the rise of the internet, and today\'s teenagers have never known a world without smartphones and social media.',
      ),
      ReadingQuestion(
        question: 'The word "hierarchy" in the paragraph about values most likely means',
        explanation: 'In the context of the passage, "hierarchy" most likely means a system of ranking or levels of authority, as older people are described as expecting respect for hierarchy and tradition in contrast to younger generations who may prioritize equality.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about communication differences between generations?',
        explanation: 'It can be inferred that differences in preferred communication methods—face-to-face or phone calls for older people versus texting, voice messages, or social media for younger ones—can create the false impression that young people are impatient or disrespectful even when that is not intended.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why may traditional career advice from parents no longer work?',
        explanation: 'According to the passage, traditional career advice may no longer work because the economy and job market have changed, leading young people to choose creative fields, start-ups, or freelance jobs instead of traditional paths such as doctor, engineer, or lawyer.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the generation gap in the workplace?',
        explanation: 'It can be inferred that multigenerational teams require employers to manage different expectations—some workers value job security while others prefer work–life balance or remote options—and that understanding these needs can improve cooperation.',
      ),
      ReadingQuestion(
        question: 'The word "stereotypes" in the paragraph about media most likely means',
        explanation: 'In the context of the passage, "stereotypes" most likely means oversimplified and fixed ideas about groups of people, as the text states that media portrayals of young people as lazy or screen-addicted and older people as stubborn increase misunderstanding rather than encouraging empathy.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how can the generation gap be bridged?',
        explanation: 'According to the passage, bridging the gap requires effort from both sides: young people must understand that older generations were shaped by hardship, war, or poverty, while elders must accept that change is part of life, and both should show patience and curiosity.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about cultural differences in managing the generation gap?',
        explanation: 'It can be inferred that some cultures, particularly many Asian and African societies, manage the generation gap better by respecting and caring for elders and valuing their wisdom, whereas in some Western countries older people may be isolated or ignored.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does migration affect the generation gap?',
        explanation: 'According to the passage, migration adds another layer because children born in a new country may adopt different values and languages than their parents, creating not just a generation gap but also a cultural one that can lead to identity conflict within families.',
      ),
    ],
  ),

  ReadingPassage(
    id: 60,
    title: 'Pets',
    topic: 'Animals & Society',
    content: '''Keeping pets is a common practice around the world. Whether one lives in a busy city or a rural village, people often form strong emotional bonds with animals. Dogs, cats, birds, fish, and even reptiles can become part of the family. Although motivations for owning pets vary, the emotional, social, and health-related benefits are widely recognized.
Many people view pets as companions, not property. This shift in perspective reflects broader changes in how humans interact with animals. In many societies, pets now receive medical care, special diets, toys, and emotional support— treatment that was once reserved for humans. Because people are living more isolated lives, especially in urban settings, pets help fill emotional gaps.
Numerous studies suggest that pets improve mental health. Not only do they reduce feelings of loneliness, but they also encourage routine and responsibility. For example, walking a dog every morning provides exercise and structure, which can be especially helpful for people suffering from depression or anxiety. In fact, some doctors recommend pet ownership as part of mental health therapy.
Children also benefit from living with animals. By caring for a pet, they learn empathy, patience, and respect for other living beings. Moreover, growing up with animals has been linked to stronger immune systems and reduced risk of allergies. Pets are often used for practical purposes as well. Dogs guard property, guide the blind, and assist the disabled. In some countries, cats are kept in shops or homes to control pests. These roles demonstrate that pets are not just decorative—they can serve vital functions.
However, pet ownership also comes with responsibilities. Animals require time, money, and care. If people adopt pets without understanding these needs, the consequences can be serious. Neglected animals may become aggressive, sick, or depressed. That is why animal shelters are often full of abandoned pets.
In recent years, the ethical treatment of animals has become a hot topic. Many argue that breeding animals for profit is morally wrong, especially when so many stray animals are in need of homes. Pet shops and breeders often prioritize appearance over health, leading to genetic problems in animals like pugs, bulldogs, or Persian cats.
Another issue is exotic pets. Some people buy snakes, monkeys, or wild birds to stand out or feel unique. However, these animals usually require specialized care and environments. Keeping them in domestic spaces can lead to stress, illness, and even aggression. Moreover, the trade in exotic animals is often illegal and harmful to biodiversity.
Pet culture varies across countries. In the UK and USA, pets are commonly viewed as family members. In Japan, pet cafés allow people to spend time with animals without owning them. In some developing countries, animals are still seen more as workers or tools than companions. This cultural diversity affects laws, attitudes, and expectations about pet ownership.
Technology is changing how people interact with pets. Smart collars, healthmonitoring devices, and even pet cameras allow owners to check on their animals remotely. Because of busy lifestyles, services like pet-sitting, dog walking, and even pet hotels are growing in popularity.
Despite the benefits, not everyone supports keeping pets. Some environmentalists argue that domestic animals consume large amounts of resources—food, water, energy—without contributing to society. Others point out that pet waste, especially from dogs in cities, creates hygiene problems. As urban populations rise, questions about the sustainability of pet ownership will become more pressing. Still, the human–animal connection appears to be deeply rooted. Throughout history, pets have served not only practical roles, but also symbolic ones. In literature, pets often represent loyalty, innocence, or emotional support. In politics and social media, leaders frequently use pet photos to appear more relatable or kind-hearted.
In sum, keeping pets involves more than just affection. It requires knowledge, time, and ethical awareness. While pets offer companionship and emotional benefits, they also raise complex questions about responsibility, environment, and animal rights. How we treat our pets often reflects how we treat each other—and the world around us.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage explores the practice of keeping pets, discussing emotional, social, and health benefits, practical roles, responsibilities, ethical concerns such as breeding and exotic pets, cultural variations, technology\'s influence, environmental criticisms, and the broader human-animal connection.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how do pets improve mental health?',
        explanation: 'Pets reduce feelings of loneliness, encourage routine and responsibility, and provide exercise and structure—such as walking a dog every morning—which can help people with depression or anxiety; some doctors even recommend pet ownership as part of mental health therapy.',
      ),
      ReadingQuestion(
        question: 'The word "exotic" in the paragraph about certain pets most likely means',
        explanation: 'It refers to unusual or non-traditional animals that are not commonly kept as pets, such as snakes, monkeys, or wild birds, which often require specialized care and environments.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the shift in how people view pets?',
        explanation: 'Many people now view pets as companions rather than property, reflecting broader changes in human-animal interactions; pets receive medical care, special diets, toys, and emotional support once reserved for humans, helping fill emotional gaps in increasingly isolated urban lives.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what benefits do children gain from living with animals?',
        explanation: 'By caring for a pet, children learn empathy, patience, and respect for other living beings, and growing up with animals has been linked to stronger immune systems and a reduced risk of allergies.',
      ),
      ReadingQuestion(
        question: 'The phrase "hot topic" in the paragraph about ethical treatment most likely means',
        explanation: 'It means a subject of intense current debate or interest, as the ethical treatment of animals, including criticisms of breeding for profit when many strays need homes, has become widely discussed.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the risks of owning exotic pets?',
        explanation: 'Exotic pets usually require specialized care and environments; keeping them in domestic spaces can lead to stress, illness, and aggression, and the trade is often illegal and harmful to biodiversity.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does pet culture differ across countries?',
        explanation: 'In the UK and USA, pets are commonly viewed as family members; in Japan, pet cafés allow interaction without ownership; in some developing countries, animals are still seen more as workers or tools than companions, affecting laws, attitudes, and expectations.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about environmental concerns related to pet ownership?',
        explanation: 'Some environmentalists argue that domestic animals consume large amounts of resources like food, water, and energy without contributing to society, and pet waste in cities creates hygiene problems; as urban populations rise, sustainability questions will become more pressing.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why do animal shelters often fill with abandoned pets?',
        explanation: 'People sometimes adopt pets without understanding the time, money, and care required; neglected animals may become aggressive, sick, or depressed, leading to abandonment and full shelters.',
      ),
    ],
  ),

  ReadingPassage(
    id: 61,
    title: 'Language',
    topic: 'Society & Culture',
    content: '''Language is one of the most important features that separates humans from other species. Whether spoken, written, or signed, it allows people to share ideas, express emotions, and build communities. Because language is both a personal and social tool, it shapes the way we think, learn, and interact.
There are over 7,000 languages spoken today, but many are in danger of disappearing. According to UNESCO, one language dies every two weeks, often because younger generations switch to more dominant tongues. If this trend continues, thousands of unique cultures and traditions may be lost forever.
Although all languages serve the same basic purpose—communication—they differ in structure, sound, and style. Some use tones, like Mandarin; others rely heavily on word order, like English. Languages also vary in how they express politeness, time, or gender. These differences can influence the way people view the world. For example, in some languages, future events must be marked clearly ("I will go"); in others, the future can be implied. This may affect how speakers of different languages think about time and planning.
Language is not static. It constantly evolves as societies change. New words enter a language through technology, migration, or social trends. For instance, terms like "selfie," "influencer," or "AI" didn't exist twenty years ago. At the same time, old words can fade away. Because language reflects culture, every social shift leaves a linguistic trace.
Multilingualism—the ability to speak more than one language—is increasingly common. In globalized societies, people often need multiple languages for work, study, or travel. Children who grow up bilingual tend to develop better problemsolving skills and mental flexibility. Not only does knowing more than one language open doors to opportunity, but it also builds empathy and cultural awareness.
Still, language can also divide people. When one language is seen as more
―prestigious‖ than another, those who speak minority languages may feel inferior. In many countries, local dialects or indigenous languages are ignored in education and media. This leads to linguistic discrimination, which can reduce access to jobs and education.
Governments play a key role in language policy. Some promote a single national language for unity, while others support multilingualism. For example, Switzerland has four official languages, and India recognizes more than twenty. Whether a country supports or suppresses linguistic diversity often reflects deeper political goals.
The digital age has transformed how we use language. Text messaging, social media, and voice assistants have created new forms of expression. Abbreviations, emojis, and memes now carry meaning as efficiently as full sentences. However, some argue this leads to a decline in formal grammar and writing skills.
Language learning has also changed. With mobile apps, online tutors, and AI tools, people can now learn languages anytime, anywhere. Because of this shift, formal classrooms are no longer the only place to master a foreign language. Motivation and exposure often matter more than textbooks.
But learning a language is not just about vocabulary and grammar. It involves understanding how people think, behave, and relate to each other. Idioms, jokes, and expressions reveal cultural attitudes. For instance, the phrase ―time is money‖ reflects a Western view of efficiency. In contrast, other cultures may value patience and relationships over speed.
Language also influences identity. The way we speak often signals where we come from, how we see ourselves, and how others see us. Accents, dialects, and word choices can build trust—or cause bias. In job interviews, for instance, people may be judged not only on what they say, but how they say it.
Despite its complexity, language remains a powerful connector. It enables cooperation, conflict resolution, and the passing down of knowledge. It can be used to build peace—or spread hate. Political speeches, advertising slogans, and media headlines all show how language shapes opinion and behavior.
Ultimately, language is not just a tool for communication—it is a mirror of who we are. The words we choose, the tone we use, and the silence we allow all reveal our values and worldview. If we pay attention to language, we can better understand both ourselves and others.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of this passage is to explore the fundamental role of language in human communication, identity, and society, while discussing the diversity and evolution of languages, the benefits and challenges of multilingualism, the impact of digital technology, the influence of language on thought and culture, and its power both to connect people and to divide them.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why are many languages in danger of disappearing?',
        explanation: 'Many languages are in danger because younger generations switch to more dominant tongues. According to UNESCO, one language dies every two weeks, and if this trend continues, thousands of unique cultures and traditions may be lost forever.',
      ),
      ReadingQuestion(
        question: 'The word \'static\' in paragraph 4 most likely means?',
        explanation: 'It most likely means unchanging or fixed, as the passage states that language is not static but constantly evolves as societies change, with new words entering through technology, migration, or social trends while old words fade away.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the benefits of bilingualism for children?',
        explanation: 'It can be inferred that growing up bilingual provides cognitive and social advantages, as children tend to develop better problem-solving skills and mental flexibility, while also gaining greater empathy and cultural awareness that open doors to opportunity.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how has the digital age affected language use?',
        explanation: 'The digital age has created new forms of expression through text messaging, social media, and voice assistants, where abbreviations, emojis, and memes carry meaning efficiently. However, some argue this contributes to a decline in formal grammar and writing skills.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the relationship between language and identity?',
        explanation: 'It can be inferred that language strongly shapes personal and social identity, as the way people speak—including accents, dialects, and word choices—signals where they come from and how they are perceived, which can build trust or cause bias in situations such as job interviews.',
      ),
    ],
  ),

  ReadingPassage(
    id: 62,
    title: 'Mass Media',
    topic: 'Media & Society',
    content: '''Mass media refers to the various platforms used to communicate information to a large audience. This includes newspapers, television, radio, social media, and online news sites. Because media reaches millions of people simultaneously, it has enormous power to inform, shape opinions, and influence behavior.
Throughout history, mass media has played a key role in shaping society. In the past, newspapers and radio were the main sources of information. Later, television brought visual content into people‘s homes, changing how news, entertainment, and advertising were delivered. With the rise of the internet, media has become more immediate, interactive, and personalized.
Although media was once controlled by a few powerful organizations, today almost anyone can publish content online. Social media platforms allow individuals to become creators, influencers, or even journalists. This shift has democratized information—but also increased the spread of misinformation.
Mass media affects politics, culture, and even personal identity. Not only does it report events, but it also decides which events are worth reporting. This selection process—known as agenda-setting—can influence what people care about. For example, when news outlets repeatedly cover crime stories, the public may feel society is becoming more dangerous, even if crime rates are falling.
Media also affects how people see the world. Because it shapes public opinion, it can create or reinforce stereotypes. For instance, certain groups may be shown in negative or simplistic ways, leading to bias and misunderstanding. The language, images, and tone used in media stories deeply impact perception.
Advertising is another powerful part of mass media. Companies spend billions each year to promote their products through television, websites, and social platforms. While some ads simply inform, others use emotional appeals, celebrity endorsements, or social pressure to influence choices. Young people, in particular, are highly affected by targeted ads online.
Mass media is not just about entertainment or news. It plays a major role in education, public health, and social awareness. Campaigns about smoking, seat belts, or climate change have used television and online platforms to reach large audiences. Because of media, these messages can spread rapidly and change public behavior.
However, media also has negative effects. Sensationalism, bias, and fake news can distort reality. In the rush to get attention, some media sources prioritize speed over accuracy. This creates confusion, mistrust, and division among the public. In recent years, the spread of conspiracy theories through online platforms has raised concerns about democracy and truth.
Children and teenagers are particularly vulnerable. Excessive exposure to media— especially violent or unrealistic content—can affect mental health, behavior, and self-esteem. Social media platforms, for example, often present idealized images that lead to comparison and anxiety. Although these platforms offer connection and creativity, they also raise serious concerns about privacy and mental wellbeing.
Media freedom varies widely across countries. In democratic societies, journalists can investigate, criticize, and challenge authority. This freedom supports transparency and accountability. In contrast, authoritarian regimes often control or censor the media, limiting access to information. Where press freedom is restricted, corruption and human rights abuses are more likely to go unnoticed.
Governments, therefore, face a difficult balance. On one hand, they must protect freedom of expression. On the other, they must fight harmful content such as hate speech, terrorism, or false information. This balance between liberty and regulation is one of the biggest challenges of modern media policy.
In the digital era, the media landscape is changing rapidly. Traditional outlets are losing audiences to online platforms. People now consume information in short clips, headlines, or posts. Algorithms decide what users see, often reinforcing their existing beliefs. As a result, individuals may live in ―echo chambers,‖ only exposed to ideas they already agree with.
Despite these issues, mass media remains essential in a globalized world. It connects people across borders, highlights injustice, and celebrates human achievement. The challenge is not whether we need media—but how to make it more responsible, diverse, and trustworthy.
Ultimately, media reflects society—but also shapes it. The stories it tells, the voices it includes, and the values it promotes all have long-term effects. If we consume media critically and demand higher standards, we can ensure it remains a force for good.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to explain what mass media is, how it has evolved, its powerful influence on society, politics, and individuals, the benefits and harms it can produce, and the challenges of balancing freedom with responsibility in the digital age.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is agenda-setting in mass media?',
        explanation: 'Agenda-setting is the selection process by which media decides which events are worth reporting, thereby influencing what people care about; for example, repeated coverage of crime can make the public feel society is more dangerous even if crime rates are falling.',
      ),
      ReadingQuestion(
        question: 'The word \'democratized\' in the third paragraph most likely means...',
        explanation: 'Made accessible to ordinary people rather than controlled by a few. The passage states that the shift allowing almost anyone to publish content online has democratized information but also increased misinformation.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the effects of social media on young people?',
        explanation: 'Children and teenagers are particularly vulnerable; excessive exposure to idealized images can lead to comparison, anxiety, and lower self-esteem, while platforms also raise concerns about privacy and mental wellbeing despite offering connection and creativity.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does mass media contribute to public health and social awareness?',
        explanation: 'Campaigns about smoking, seat belts, or climate change have used television and online platforms to reach large audiences, allowing messages to spread rapidly and change public behavior.',
      ),
      ReadingQuestion(
        question: 'The phrase \'echo chambers\' in the twelfth paragraph most likely means...',
        explanation: 'Environments in which people are mainly exposed to ideas and information that match their existing beliefs. Algorithms reinforce this by deciding what users see, limiting exposure to differing viewpoints.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about media freedom in different political systems?',
        explanation: 'In democratic societies journalists can investigate and challenge authority, supporting transparency, whereas authoritarian regimes often control or censor media, making corruption and human rights abuses more likely to go unnoticed.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what negative effects can result from sensationalism and fake news?',
        explanation: 'Sensationalism, bias, and fake news can distort reality; prioritizing speed over accuracy creates confusion, mistrust, and division, and the spread of conspiracy theories has raised concerns about democracy and truth.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of advertising in mass media?',
        explanation: 'Advertising is powerful; companies spend billions and use emotional appeals, celebrity endorsements, or social pressure, and young people are especially affected by targeted online ads that influence their choices.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what balance must governments try to achieve regarding media?',
        explanation: 'Governments must protect freedom of expression while also fighting harmful content such as hate speech, terrorism, or false information; this balance between liberty and regulation is one of the biggest challenges of modern media policy.',
      ),
    ],
  ),

  ReadingPassage(
    id: 63,
    title: 'Advertising',
    topic: 'Media & Society',
    content: '''Advertising is a powerful tool used by companies, governments, and organizations to influence public behavior. Whether promoting a product, an idea, or a political message, advertising is everywhere: on TV, websites, billboards, buses, and even inside mobile apps. Because it reaches people across age, class, and culture, its impact is both wide and deep.
Although the goal of advertising is often to boost sales, its influence goes far beyond economics. It affects how people think, feel, and even live. By repeatedly showing certain images or messages, advertising can shape public attitudes, cultural norms, and personal desires.
Modern advertising is more than just showing a product. It often sells a lifestyle, a dream, or a feeling. For example, an ad for perfume may focus less on the scent and more on romance, confidence, or beauty. This emotional appeal makes the message more memorable—and more persuasive.
Technology has completely transformed advertising. In the past, companies paid for space in newspapers or airtime on television. Today, digital platforms allow for personalized, targeted ads based on search history, location, and even emotional state. Because ads are now algorithm-driven, companies can reach the exact audience most likely to buy.
However, this personalization comes with a cost. Many people feel their privacy is being invaded, especially when ads seem to ―follow‖ them online. Not only does this raise ethical questions, but it also creates mistrust in how personal data is collected and used.
Children and teenagers are particularly vulnerable. Since their critical thinking skills are still developing, they may not recognize the persuasive intent behind advertisements. Some ads use cartoons, bright colors, or catchy music to appeal to younger viewers. This has led to concern about fast food, soft drink, and toy marketing, which may encourage unhealthy habits or unrealistic expectations.
Advertising is also criticized for creating false needs. By constantly telling people they need to be richer, thinner, or more stylish, ads can increase dissatisfaction and materialism. This pressure to consume—whether through fashion, gadgets, or cosmetic products—can lead to debt, anxiety, or low self-esteem.
Gender stereotypes in advertising remain a serious issue. Despite progress in recent years, many ads still portray women as objects of beauty or caretakers, while men are shown as strong, dominant, or successful. These repeated images reinforce outdated roles, limiting how people see themselves and each other.
On the other hand, advertising can serve positive goals. Public service announcements have been used to promote seatbelt use, discourage smoking, or raise awareness about mental health. These campaigns prove that advertising can inform and educate—not just sell.
Companies have also begun using advertising to show social responsibility. By including messages about sustainability, diversity, or equality, brands try to align themselves with public values. While some critics call this ―woke marketing,‖ others see it as a step toward a more responsible media environment.
Regulation plays a crucial role. Most countries have laws to prevent misleading or harmful advertising. For example, tobacco ads are banned in many places. Ads for alcohol, gambling, or medication often come with strict rules. However, online ads are harder to control, especially across borders.
The question of whether advertising should be limited is widely debated. Some argue that people must learn to think critically instead of banning ads. Others say that certain types of advertising—especially those targeting children or promoting harmful products—should not be allowed at all.
In schools, teaching media literacy is becoming more important. If students learn how to analyze and question ads, they are less likely to be manipulated. Critical thinking, not censorship, may be the best defense against harmful advertising.
Despite its problems, advertising remains a central part of modern life. It funds media, drives the economy, and introduces people to new products and ideas. The real challenge is not whether to allow advertising—but how to make it more honest, ethical, and inclusive.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to examine the power and influence of advertising in modern society, describing how it shapes attitudes and desires, the effects of technology and personalization, criticisms regarding privacy, vulnerable audiences, false needs, and stereotypes, its positive uses, the role of regulation, and the need for more honest, ethical, and inclusive practices.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does modern advertising often go beyond simply showing a product?',
        explanation: 'Modern advertising often sells a lifestyle, a dream, or a feeling; for example, a perfume ad may focus more on romance, confidence, or beauty than on the scent itself, using emotional appeal to make the message more memorable and persuasive.',
      ),
      ReadingQuestion(
        question: 'The word "algorithm-driven" in the fourth paragraph most likely means',
        explanation: 'In the context of digital platforms allowing personalized, targeted ads based on search history, location, and emotional state so companies can reach the exact audience most likely to buy, algorithm-driven means controlled or determined by computer algorithms that process user data.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the impact of personalized advertising on privacy?',
        explanation: 'It can be inferred that many people feel their privacy is invaded when ads seem to follow them online, raising ethical questions and creating mistrust about how personal data is collected and used.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why are children and teenagers particularly vulnerable to advertising?',
        explanation: 'Their critical thinking skills are still developing, so they may not recognize the persuasive intent behind ads; some ads use cartoons, bright colors, or catchy music to appeal to them, raising concerns about marketing that encourages unhealthy habits or unrealistic expectations.',
      ),
      ReadingQuestion(
        question: 'The phrase "false needs" in the seventh paragraph most likely refers to',
        explanation: 'In the context of ads constantly telling people they need to be richer, thinner, or more stylish, increasing dissatisfaction and materialism, false needs are artificial desires created by advertising rather than genuine requirements.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about gender stereotypes in advertising?',
        explanation: 'Despite some progress, many ads still portray women as objects of beauty or caretakers and men as strong, dominant, or successful; these repeated images reinforce outdated roles and limit how people see themselves and others.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how can advertising serve positive goals?',
        explanation: 'Public service announcements have promoted seatbelt use, discouraged smoking, and raised awareness about mental health, showing that advertising can inform and educate rather than only sell products.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the debate over limiting advertising?',
        explanation: 'Some argue people should learn critical thinking instead of banning ads, while others believe certain types—especially those targeting children or promoting harmful products—should not be allowed at all; media literacy in schools is presented as a key defense against manipulation.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is the real challenge regarding advertising in modern life?',
        explanation: 'Despite its problems, advertising remains central because it funds media, drives the economy, and introduces new products and ideas; the real challenge is not whether to allow it, but how to make it more honest, ethical, and inclusive.',
      ),
    ],
  ),

  ReadingPassage(
    id: 64,
    title: 'Law',
    topic: 'Society & Justice',
    content: '''Law is the foundation of modern society. It sets clear rules about what people can and cannot do, and provides a system for resolving disputes. Whether dealing with theft, contracts, or civil rights, laws are essential for order, stability, and justice. Without laws, societies would face chaos. People would settle arguments with violence, and the weak would have no protection. Because laws apply equally to everyone—at least in theory—they create fairness. For example, both rich and poor are subject to the same criminal codes. This principle of equality before the law is central to democratic systems.
Laws differ from one country to another. Some legal systems are based on religion; others rely on written constitutions or centuries of court decisions. Although legal traditions vary, the basic goals are often the same: to prevent harm, protect rights, and promote peace.
Criminal law deals with actions that are considered harmful to society, such as assault, theft, or fraud. When someone breaks a criminal law, the government prosecutes them on behalf of the public. If found guilty, the person may face a fine, imprisonment, or another penalty.
Civil law, by contrast, handles disputes between individuals or organizations. These cases often involve issues like property, contracts, or family matters. Instead of punishment, the goal is compensation or resolution.
Because laws must reflect changing values, they are often updated or reformed. For example, many countries have changed their laws on marriage, gender rights, or drug use in recent decades. What was illegal fifty years ago may be accepted today. This shows that law is not fixed—it evolves with society.
Still, the process of making and enforcing laws is not always fair. In some countries, laws are used to silence critics, control the media, or limit freedom of expression. Even in democracies, powerful groups may influence legislation for their own benefit. That is why independent courts and free press are essential— they act as checks on government power.
Enforcing the law requires a strong and honest justice system. Police, judges, and lawyers all play important roles. If the system is corrupt, public trust disappears. For instance, when wealthy individuals avoid punishment through bribes or connections, ordinary people lose faith in the rule of law.
International law is another important area. It deals with agreements between countries, such as trade, war, or environmental protection. Although international law lacks a global police force, it relies on treaties, courts, and cooperation to manage global conflicts. The International Criminal Court, for example, prosecutes war crimes and crimes against humanity.
Some people argue that there are too many laws. They believe that excessive regulation restricts freedom and innovation. Others say that laws are too soft, especially on serious crimes. This debate often appears in discussions about sentencing, prison reform, or the death penalty.
Another controversial issue is whether laws always reflect morality. Just because something is legal does not mean it is right. For example, in the past, slavery and segregation were legal in many countries. Today, many argue that laws should go further to ensure fairness—for instance, by protecting the environment or reducing inequality.
Technology also creates legal challenges. Cybercrime, online privacy, and artificial intelligence are areas where the law struggles to keep up. New tools like facial recognition or digital tracking raise questions about surveillance, consent, and data security.
Education about the law is essential. If people don‘t understand their rights or responsibilities, they cannot fully participate in society. That‘s why many schools include basic legal education, such as how to interact with police or sign a contract. Ultimately, the law reflects the values of a society—but also shapes them. It tells people not only what is allowed, but also what is important. When used fairly and wisely, law protects freedom and ensures justice. When abused or ignored, it becomes a tool of power and fear.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage explains the role, types, evolution, challenges, and importance of law in society, emphasizing that fair and wise application of law protects freedom and justice while abuse turns it into a tool of power.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is the principle of equality before the law?',
        explanation: 'Equality before the law means that laws apply equally to everyone, at least in theory, so that both rich and poor are subject to the same criminal codes, creating fairness central to democratic systems.',
      ),
      ReadingQuestion(
        question: 'The word "prosecutes" in the third paragraph most likely means',
        explanation: 'In context, prosecutes means that the government formally charges and takes legal action against a person who has broken a criminal law on behalf of the public.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the difference between criminal and civil law?',
        explanation: 'Criminal law addresses actions harmful to society and aims at punishment such as fines or imprisonment, whereas civil law handles private disputes and seeks compensation or resolution rather than punishment.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why are laws often updated or reformed?',
        explanation: 'Laws must reflect changing societal values, as shown by reforms on marriage, gender rights, or drug use, demonstrating that law is not fixed but evolves with society.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of independent courts and a free press?',
        explanation: 'Independent courts and a free press act as essential checks on government power, helping prevent laws from being used unfairly to silence critics or benefit powerful groups.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what happens when a justice system is corrupt?',
        explanation: 'Corruption causes public trust to disappear; for example, when wealthy individuals avoid punishment through bribes or connections, ordinary people lose faith in the rule of law.',
      ),
      ReadingQuestion(
        question: 'The phrase "rule of law" in the seventh paragraph most likely means',
        explanation: 'The rule of law refers to the principle that laws are applied fairly and consistently to everyone, without favoritism or corruption, so that public confidence in the justice system is maintained.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about international law from the passage?',
        explanation: 'Although international law lacks a global police force, it manages relations between countries through treaties, courts, and cooperation, as illustrated by the International Criminal Court prosecuting war crimes.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is education about the law important?',
        explanation: 'If people do not understand their rights or responsibilities, they cannot fully participate in society, which is why many schools teach basic legal knowledge such as interacting with police or signing contracts.',
      ),
    ],
  ),

  ReadingPassage(
    id: 65,
    title: 'The Internet',
    topic: 'Technology & Society',
    content: '''The internet has become a vital part of modern life. Whether used for work, study, communication, or entertainment, it connects billions of people across the globe. Because it is fast, flexible, and always available, the internet has changed how societies function.
In less than three decades, the internet has transformed the world more than most inventions in human history. Businesses, governments, schools, and families rely on it every day. Not only does it provide instant access to information, but it also enables people to collaborate across borders.
Education has been deeply affected. Online courses, video tutorials, and digital libraries give students access to knowledge once limited to elite institutions. Many universities now offer degrees fully online. Because learning is no longer restricted by time or place, people from remote or poor regions can study globally competitive content.
Work has also shifted online. Remote jobs, freelance platforms, and virtual meetings are now common, especially since the COVID-19 pandemic. Employers save money on office space, while workers enjoy more flexibility. However, not everyone benefits equally, and some jobs have disappeared due to automation and digital tools.
Social media is one of the internet‘s most influential developments. It allows people to share thoughts, photos, and opinions instantly. While this creates connection, it also fuels conflict, misinformation, and addiction. Because algorithms prioritize attention-grabbing content, users are often exposed to extreme views or false information.
E-commerce is another major change. Buying and selling online has replaced traditional shopping for many people. From groceries to electronics, nearly everything can be delivered to your door. Although this is convenient, it raises concerns about data security, local businesses, and environmental impact due to packaging and delivery.
One of the internet‘s greatest strengths is access to information. You can search for anything in seconds—from medical symptoms to historical facts. But just because information is available does not mean it is accurate. Fake news, conspiracy theories, and biased sources can mislead people. That is why digital literacy is becoming as important as reading and writing.
Privacy is another growing concern. While people enjoy free access to apps, news, and social media, they often ―pay‖ with personal data. Companies track user behavior to target ads, influence decisions, and even manipulate emotions. Many users are unaware of how much of their life is being monitored.
The internet also creates a digital divide. Although many people use smartphones daily, billions still lack stable internet access. This gap limits opportunities in education, work, and health. Bridging this divide is essential if the internet is to benefit everyone equally.
Censorship and control are rising as governments react to the internet‘s power. In some countries, certain websites are blocked or monitored. Critics are silenced online, and access to foreign news is limited. While some restrictions are made for national security, others clearly violate freedom of speech.
The legal system is struggling to keep up. Cybercrime—like hacking, identity theft, and online scams—is increasing. Laws that apply in one country may not apply in another. This raises serious questions about who controls the internet— and who should.
Despite its problems, the internet offers hope. It has helped organize protests, educate millions, and connect families across oceans. During disasters or war, it can deliver real-time updates and mobilize aid. If used wisely, the internet can reduce inequality and promote understanding.
However, the key word is ―if.‖ Whether the internet makes the world better or worse depends on how we use it. Like any powerful tool, it can build or destroy, connect or divide, inform or deceive.
Ultimately, the internet is not good or bad by itself—it reflects the people who use it. The challenge for the future is not just access, but responsible, informed use. If we teach digital responsibility and protect individual rights, the internet can remain one of humanity‘s greatest achievements.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage describes the transformative effects of the internet on education, work, social interaction, commerce, and information access, examines challenges such as misinformation, privacy, the digital divide, and censorship, and concludes that its value depends on responsible use and the protection of individual rights.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how has the internet affected education?',
        explanation: 'The passage states that online courses, video tutorials, and digital libraries give students access to knowledge once limited to elite institutions, and that many universities now offer degrees fully online, allowing people from remote or poor regions to study globally competitive content.',
      ),
      ReadingQuestion(
        question: 'The word "algorithms" in the discussion of social media most likely means',
        explanation: 'In context, algorithms refer to the systems that prioritize attention-grabbing content on social media, often exposing users to extreme views or false information.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the impact of social media?',
        explanation: 'The passage notes that while social media creates connection, it also fuels conflict, misinformation, and addiction, and that algorithms can lead users to extreme or false information.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what concerns does e-commerce raise?',
        explanation: 'The passage states that although online buying and selling is convenient, it raises concerns about data security, local businesses, and environmental impact due to packaging and delivery.',
      ),
      ReadingQuestion(
        question: 'The phrase "digital divide" in the passage most likely means',
        explanation: 'The passage describes the digital divide as the gap in which many people use smartphones daily while billions still lack stable internet access, limiting opportunities in education, work, and health.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about privacy on the internet?',
        explanation: 'The passage explains that people often "pay" for free access to apps and social media with personal data, as companies track behavior to target ads and influence decisions, and many users are unaware of how much they are monitored.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is digital literacy becoming important?',
        explanation: 'The passage states that because available information is not always accurate—due to fake news, conspiracy theories, and biased sources—digital literacy is becoming as important as reading and writing.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about government control of the internet?',
        explanation: 'The passage notes that in some countries websites are blocked or monitored, critics are silenced, and foreign news access is limited, with some restrictions claimed for national security while others violate freedom of speech.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what determines whether the internet makes the world better or worse?',
        explanation: 'The passage states that whether the internet makes the world better or worse depends on how we use it, and that the challenge is responsible, informed use through teaching digital responsibility and protecting individual rights.',
      ),
    ],
  ),

  ReadingPassage(
    id: 66,
    title: 'Jobs',
    topic: 'Work & Economy',
    content: '''Work plays a central role in most people‘s lives. Whether someone is a teacher, driver, doctor, or engineer, a job provides not only income, but also structure, purpose, and identity. Because jobs shape our routines and social status, they are often tied to personal dignity and long-term goals.
In the past, people often stayed in one job for their entire career, especially in industrial or government sectors. However, modern economies demand flexibility. Many workers now change careers several times, work freelance, or juggle multiple roles. This shift reflects broader changes in technology, education, and lifestyle.
Technology has had a major impact. Automation, artificial intelligence, and digital tools have replaced many traditional jobs, especially in manufacturing and retail. At the same time, new careers have emerged in fields like data science, app development, and cybersecurity. Because the job market evolves quickly, lifelong learning has become essential.
Education systems are adapting slowly. Although schools still focus on academic subjects, employers often complain that graduates lack practical skills. Critical thinking, teamwork, and communication are now more valuable than memorizing facts. Some argue that education should prepare students for the real world—not just for exams.
Work–life balance is another major issue. While older generations often accepted long hours and job stress, younger people are more focused on flexibility and wellbeing. Remote work, four-day workweeks, and mental health days are becoming more common. Not only do these changes reflect new values, but they also improve productivity and morale.
Still, job insecurity remains a growing problem. Temporary contracts, part-time work, and gig economy platforms offer flexibility but little stability. Many workers lack benefits such as health insurance or paid leave. This uncertainty can lead to stress, anxiety, and long-term financial problems.
Wages and income inequality are also controversial topics. In some industries, top executives earn hundreds of times more than regular employees. While some justify this gap by pointing to responsibility and skill, others see it as unfair and damaging to social trust. Governments are under pressure to raise minimum wages and reduce income gaps.
Gender and diversity issues continue to affect the job market. Despite legal protections, women and minorities still face discrimination in hiring, pay, and promotion. Some industries remain dominated by men, while others struggle to attract diverse talent. Workplace equality is not just a moral issue—it also improves performance and innovation.
Motivation is another key factor. People work not only for money, but also for personal growth, social connection, and meaning. Jobs that offer autonomy, recognition, and purpose tend to attract more loyalty. In contrast, boring or stressful jobs with poor management cause burnout and high turnover.
Unemployment has both personal and social costs. When people lose their jobs, they may suffer from depression, isolation, or poverty. High unemployment rates can also increase crime, reduce tax revenue, and damage public services. That is why job creation is often a top political priority.
Globalization has created both opportunities and challenges. Companies can now hire workers from anywhere, leading to more competition—but also job losses in certain regions. Outsourcing and automation may increase profits but often hurt local communities. Balancing global efficiency with local well-being is a constant challenge.
Job satisfaction is often more important than job title. Even if someone earns a high salary, they may feel unhappy if the work is boring, stressful, or ethically questionable. On the other hand, people in modest jobs may feel proud if their work is meaningful. This shows that personal values matter more than prestige.
Ultimately, jobs are not just about making a living—they are about making a life. The ideal job provides security, purpose, respect, and balance. While no job is perfect, the search for meaningful work is one of the most human pursuits.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to discuss the changing nature of work, including the impact of technology, education, work-life balance, inequality, and motivation, and to emphasize that jobs provide more than income—they shape identity and purpose.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how has the nature of careers changed from the past to the present?',
        explanation: 'In the past, people often stayed in one job for their entire career, but modern economies demand flexibility, with many workers changing careers several times, working freelance, or juggling multiple roles.',
      ),
      ReadingQuestion(
        question: 'The word "juggle" in the second paragraph most likely means...',
        explanation: 'In the context of the passage, "juggle" means to handle or manage multiple roles or jobs at the same time.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the effect of technology on employment?',
        explanation: 'It can be inferred that technology has eliminated many traditional jobs through automation while creating new opportunities in emerging fields, making lifelong learning essential for workers.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what skills do employers often say graduates lack?',
        explanation: 'Employers often complain that graduates lack practical skills such as critical thinking, teamwork, and communication, which are now more valuable than memorizing facts.',
      ),
      ReadingQuestion(
        question: 'The phrase "work–life balance" in the passage most likely refers to...',
        explanation: 'It refers to the equilibrium between professional responsibilities and personal well-being, which younger workers prioritize through flexibility, remote work, and mental health support.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about job insecurity in the modern economy?',
        explanation: 'It can be inferred that temporary contracts, part-time work, and gig platforms provide flexibility but create instability by denying benefits and leading to stress and financial problems for many workers.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is workplace equality important beyond moral reasons?',
        explanation: 'Workplace equality improves performance and innovation, in addition to being a moral issue, by addressing discrimination faced by women and minorities in hiring, pay, and promotion.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the relationship between job satisfaction and salary?',
        explanation: 'It can be inferred that high salary alone does not guarantee happiness if the work is boring, stressful, or unethical, while meaningful work can bring pride even in modest-paying jobs.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are some social costs of high unemployment?',
        explanation: 'High unemployment can increase crime, reduce tax revenue, and damage public services, in addition to causing personal problems such as depression, isolation, or poverty.',
      ),
    ],
  ),

  ReadingPassage(
    id: 67,
    title: 'Unemployment',
    topic: 'Economy & Society',
    content: '''Unemployment remains one of the most serious challenges facing both developed and developing countries. Whether caused by economic crisis, automation, or poor education systems, joblessness affects not only individuals but entire communities. Because work provides income, purpose, and identity, being unemployed can have long-term social and psychological consequences.
Although unemployment is often measured by national statistics, these numbers rarely tell the whole story. Not only do they ignore people who have stopped looking for work, but they also fail to reflect the quality or stability of available jobs. In fact, underemployment—when people work fewer hours than they need or take jobs below their skill level—is also a growing issue.
There are many types of unemployment. Frictional unemployment refers to the short period when people are between jobs. This is normal in any economy.
Structural unemployment, on the other hand, occurs when workers‘ skills no longer match available jobs—often due to technological change. Cyclical unemployment rises during economic downturns when companies cut jobs to reduce costs.
Because automation and artificial intelligence are replacing many routine tasks, some experts fear that millions will lose their jobs in the near future. Retail, transportation, and manufacturing sectors are especially at risk. While new jobs may be created in tech-related industries, they often require skills that many workers do not yet have.
Young people are among the most vulnerable groups. In many countries, youth unemployment rates are double or triple the national average. Even those with university degrees often struggle to find stable work. This can delay major life steps—like moving out, getting married, or starting a family—and lead to frustration or social unrest.
Long-term unemployment can cause serious harm. The longer someone remains jobless, the harder it becomes to re-enter the workforce. Skills may fade, confidence may drop, and employers may view gaps in the résumé with suspicion. This creates a vicious cycle where people feel trapped and hopeless.
Unemployment also has wider social impacts. High joblessness is linked to increased crime, mental health problems, and drug abuse. It reduces consumer spending, lowers tax revenue, and places pressure on public services. As a result, unemployment is not just an economic issue—it is a public health and social stability issue as well.
Governments use various strategies to address unemployment. These include job training programs, public works projects, tax incentives for employers, and unemployment benefits. While financial support can help people survive shortterm gaps, what matters more is helping them gain skills and find long-term opportunities.
Education reform is key. Many argue that schools and universities must prepare students for the actual job market—not just exams. Critical thinking, digital literacy, and adaptability are now more important than memorizing facts. By connecting education with real-world needs, countries can reduce skills mismatch.
Entrepreneurship is often promoted as a solution. By encouraging people to start their own businesses, governments hope to create jobs from the ground up. However, starting a business is risky and often requires capital, knowledge, and support. Without the right infrastructure, few succeed.
Migration can reduce unemployment in some cases. When people move from areas with few jobs to regions with labor shortages, both individuals and economies benefit. However, this can also lead to ―brain drain‖ in poorer areas and increased competition in wealthier ones.
The informal economy—jobs that are not officially recorded or taxed—is another factor. While it provides income for millions, it often lacks stability, legal protection, and long-term prospects. People working in this sector may live in constant insecurity, even though they are technically ―employed.‖
In the long term, solving unemployment requires more than just economic growth. It requires smart policies, investment in people, and a shift in how society views work. Instead of seeing jobs only as a way to survive, we must also see them as a path to dignity, contribution, and fulfillment.
Ultimately, a society that fails to provide decent work for its citizens is at risk of losing trust, stability, and hope. While no country can eliminate unemployment entirely, reducing it must remain a top priority for anyone who cares about fairness, opportunity, and progress.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to examine unemployment as a serious economic and social challenge, describing its types, causes, impacts on individuals and society, and various strategies for addressing it.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is underemployment?',
        explanation: 'According to the passage, underemployment occurs when people work fewer hours than they need or take jobs below their skill level, and it is described as a growing issue that national unemployment statistics often fail to reflect.',
      ),
      ReadingQuestion(
        question: 'The word "frictional" in the third paragraph most likely refers to',
        explanation: 'In the context of the third paragraph, "frictional" unemployment refers to the normal, short-term period when people are between jobs in any economy.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the impact of automation on employment?',
        explanation: 'It can be inferred that automation and artificial intelligence threaten millions of jobs especially in retail, transportation, and manufacturing by replacing routine tasks, while new tech-related jobs may require skills that many current workers lack.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why are young people particularly vulnerable to unemployment?',
        explanation: 'According to the passage, youth unemployment rates are often double or triple the national average, and even university graduates struggle to find stable work, which can delay life milestones and lead to frustration or social unrest.',
      ),
      ReadingQuestion(
        question: 'The phrase "vicious cycle" in the seventh paragraph most likely means',
        explanation: 'In the context of the seventh paragraph, "vicious cycle" describes the self-reinforcing situation in which long-term unemployment causes skills to fade and confidence to drop, making re-entry into the workforce even harder and trapping people in hopelessness.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the limitations of unemployment benefits?',
        explanation: 'It can be inferred that while unemployment benefits and financial support can help people survive short-term gaps, they are less important than programs that help individuals gain skills and secure long-term job opportunities.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how can education reform help reduce unemployment?',
        explanation: 'According to the passage, education reform can reduce skills mismatch by preparing students for the actual job market through emphasis on critical thinking, digital literacy, and adaptability rather than just exam performance or memorizing facts.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the informal economy?',
        explanation: 'It can be inferred that although the informal economy provides income for millions, it leaves workers in constant insecurity because it lacks stability, legal protection, and long-term prospects, even when people are technically employed.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what broader risks does a society face if it fails to provide decent work?',
        explanation: 'According to the passage, a society that fails to provide decent work for its citizens risks losing trust, stability, and hope, making the reduction of unemployment a top priority for fairness, opportunity, and progress.',
      ),
    ],
  ),

  ReadingPassage(
    id: 68,
    title: 'Industrial Relations',
    topic: 'Labor & Employment',
    content: '''Industrial relations refer to the relationship between employers, employees, and trade unions in the workplace. Whether in manufacturing, public services, or technology, how workers and management interact affects productivity, fairness, and workplace stability. Because the interests of employers and workers often conflict, industrial relations require constant negotiation and balance.
In the past, industrial relations were defined by confrontation. Workers faced long hours, low wages, and unsafe conditions. In response, they formed trade unions to demand better treatment. Although conditions have improved in many countries, disputes over pay, safety, and job security remain common.
Unions play a key role. Not only do they represent the collective voice of employees, but they also negotiate wages, working hours, and benefits. This process, known as collective bargaining, is central to industrial relations. When negotiations fail, strikes or protests may follow.
Because strikes can disrupt services and damage the economy, many governments have laws to regulate industrial action. In some countries, strikes in essential sectors—like healthcare or transport—are limited or require notice. While such laws aim to protect public interest, they can also reduce workers‘ ability to push for change.
Industrial relations vary by country and sector. In Scandinavian countries, cooperation between unions and employers is strong, and conflicts are rare. In contrast, in some developing nations, labor rights are weak, and unions are discouraged or even banned. The quality of industrial relations often reflects the level of democracy, legal protections, and economic development.
Technology is changing the landscape. As automation and artificial intelligence reshape the job market, many workers fear job loss or skill mismatch. Employers may prefer machines for efficiency and cost, while employees worry about their future. This tension is becoming a new focus of industrial negotiation.
Globalization adds further complexity. When companies outsource labor to countries with cheaper wages, workers in higher-income nations may lose jobs. Although globalization has increased profits for many firms, it has also reduced bargaining power for local workers. Unions now face the challenge of organizing across borders, which is difficult due to legal and cultural differences.
Flexible work arrangements—such as freelancing, gig work, and remote jobs—are also changing industrial relations. Because gig workers are often not legally classified as employees, they lack access to traditional benefits like paid leave or health insurance. This raises questions about fairness, regulation, and modern definitions of ―employment.‖
Disputes in industrial relations are not always about money. Workplace safety, discrimination, promotion opportunities, and mental health are increasingly important topics. Employees want respect and equality, while employers must maintain efficiency and competitiveness. When either side ignores the other‘s concerns, conflict is likely.
Good industrial relations benefit everyone. Companies with strong employee– management communication tend to have higher morale, lower turnover, and better productivity. Employees are more engaged when they feel heard and valued. Rather than viewing unions as a threat, wise employers see them as partners in building a healthy workplace culture.
Governments often act as mediators during major labor disputes. They may help resolve conflicts through arbitration or impose rules to ensure fairness. For example, minimum wage laws, working hour limits, and safety standards are tools to protect workers without harming businesses. The goal is not to pick sides—but to ensure that both sides follow rules and respect rights.
However, not all industrial conflicts are handled peacefully. In some cases, strikes lead to violence, job losses, or long-term damage to relationships. When trust is broken, rebuilding cooperation takes time. That is why early dialogue and honest negotiation are essential.
Training managers in labor law and communication skills can help prevent conflict. Just as employees are taught their rights, employers must understand their responsibilities. A lack of awareness often leads to misunderstandings, which could be avoided with better education on both sides.
Ultimately, industrial relations are about balance. Workers want security, fairness, and respect. Employers want efficiency, flexibility, and profit. When both sides listen and adapt, progress is possible. When one side dominates, problems grow.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to explain industrial relations as the interactions between employers, employees, and trade unions, covering historical confrontation, the role of unions and collective bargaining, variations by country, impacts of technology and globalization, challenges with flexible work, benefits of good relations, the role of governments, and the need for balance between workers\' and employers\' interests.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is collective bargaining?',
        explanation: 'According to the passage, collective bargaining is the process in which unions negotiate wages, working hours, and benefits on behalf of employees, and it is central to industrial relations; when negotiations fail, strikes or protests may follow.',
      ),
      ReadingQuestion(
        question: 'The word "confrontation" in the second paragraph most likely means',
        explanation: 'In the second paragraph, "confrontation" most likely means conflict or opposition, referring to the past state of industrial relations in which workers faced long hours, low wages, and unsafe conditions and responded by forming trade unions.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about industrial relations in Scandinavian countries compared to some developing nations?',
        explanation: 'It can be inferred that industrial relations vary significantly: in Scandinavian countries cooperation between unions and employers is strong and conflicts are rare, whereas in some developing nations labor rights are weak and unions are discouraged or banned, reflecting differences in democracy, legal protections, and economic development.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how is technology changing industrial relations?',
        explanation: 'According to the passage, automation and artificial intelligence are reshaping the job market, causing workers to fear job loss or skill mismatch while employers may prefer machines for efficiency and cost; this tension is becoming a new focus of industrial negotiation.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the impact of globalization on workers?',
        explanation: 'It can be inferred that globalization has reduced bargaining power for local workers in higher-income nations because companies outsource labor to countries with cheaper wages, leading to potential job losses, even though it has increased profits for many firms; unions face challenges organizing across borders due to legal and cultural differences.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why do flexible work arrangements raise questions about fairness?',
        explanation: 'According to the passage, flexible arrangements such as freelancing, gig work, and remote jobs raise questions about fairness and regulation because gig workers are often not legally classified as employees and therefore lack access to traditional benefits like paid leave or health insurance, challenging modern definitions of ―employment.‖',
      ),
      ReadingQuestion(
        question: 'The phrase "other‘s concerns" in the passage most likely refers to',
        explanation: 'In the passage, "other‘s concerns" refers to the interests of the opposing side in industrial relations—employees seeking respect and equality versus employers needing to maintain efficiency and competitiveness—and ignoring these concerns is likely to lead to conflict.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the benefits of good industrial relations?',
        explanation: 'It can be inferred that good industrial relations benefit both sides: companies with strong employee–management communication tend to have higher morale, lower turnover, and better productivity, while employees are more engaged when they feel heard and valued; wise employers therefore view unions as partners rather than threats.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is the ultimate nature of industrial relations?',
        explanation: 'According to the passage, industrial relations are ultimately about balance: workers want security, fairness, and respect while employers want efficiency, flexibility, and profit; progress is possible when both sides listen and adapt, but problems grow when one side dominates.',
      ),
    ],
  ),

  ReadingPassage(
    id: 69,
    title: 'Brain Drain',
    topic: 'Migration & Economy',
    content: '''Brain drain refers to the large-scale migration of educated, skilled, and talented individuals from one country to another—usually from developing nations to wealthier ones. Whether they are doctors, engineers, scientists, or researchers, these individuals often leave their home countries in search of better job opportunities, higher salaries, and improved living conditions. Because their departure can weaken the national workforce, brain drain is seen as a serious problem by many governments.
Although migration is a personal choice, it creates a national dilemma. Not only do countries lose the people they invested in through education and training, but they also struggle to replace these skilled workers. This weakens sectors such as healthcare, education, and technology, which depend on highly qualified professionals.
Developing countries are most affected. In many cases, talented individuals leave because they see no future at home. Corruption, limited research funding, political instability, and poor working conditions push people to seek better environments abroad. This is often referred to as a ―push factor.‖
On the other side, wealthy nations offer attractive "pull factors." Higher wages, career growth, safety, and access to cutting-edge facilities draw talent from across the world. For instance, countries like the USA, Canada, Germany, and Australia actively recruit foreign professionals through visa programs and job offers. Because of this trend, some developing countries have lost a significant portion of their best minds.
The healthcare sector offers a clear example. Many African and South Asian countries face shortages of doctors and nurses, as thousands move to richer countries for better pay and working conditions. While this helps solve labor shortages in destination countries, it leaves hospitals and clinics back home understaffed and under pressure.
Education is also impacted. Universities lose professors, researchers, and students to institutions abroad. This weakens their ability to innovate, publish, or compete internationally. If the most capable minds leave, national progress slows down.
Some argue that brain drain can have benefits. When migrants send money back home—known as remittances—it supports families and boosts local economies. Also, skilled migrants may return one day with new knowledge, networks, and capital. This is called ―brain gain‖ or ―brain circulation.‖ For example, several Asian countries, such as China and India, have benefited from return migration in the tech and business sectors.
However, this return is never guaranteed. If professionals settle permanently abroad, their skills are lost forever. Moreover, even remittances do not fix the deeper problems: weak institutions, lack of opportunity, and poor governance. To tackle brain drain, some governments are investing in better conditions for professionals. By offering competitive salaries, modern infrastructure, and transparent promotion systems, they try to keep talent at home. Scholarships with return conditions, research grants, and professional development programs also help reduce the urge to migrate.
International cooperation is also important. Some suggest that destination countries should invest in the education systems of the countries they recruit from, especially in sectors like medicine. Others call for ethical recruitment policies that avoid draining critical workers from the poorest nations.
Digital technology may offer part of the solution. With remote work becoming more common, professionals can now contribute to global companies while living in their home countries. If managed correctly, this could allow countries to benefit from international salaries without losing their talent.
Yet challenges remain. Brain drain is not just about money—it is also about dignity, opportunity, and trust. If people believe their country does not value or support them, they are more likely to leave. This shows that retaining talent requires deeper reforms—not just higher wages.
Ultimately, brain drain reflects global inequality. Talented individuals move not only for personal gain, but also to escape systems that limit their growth. Unless these root causes are addressed, even the best retention strategies will fail.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to define brain drain as the migration of skilled individuals from developing to wealthier countries, explain its causes through push and pull factors, describe its negative impacts on sectors like healthcare and education, discuss possible benefits such as remittances and brain circulation, and outline strategies to address it.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are some common push factors that lead to brain drain?',
        explanation: 'According to the passage, push factors include corruption, limited research funding, political instability, and poor working conditions that cause talented individuals in developing countries to see no future at home and seek better environments abroad.',
      ),
      ReadingQuestion(
        question: 'The phrase "pull factors" in the passage most likely means',
        explanation: 'In the context of the passage, "pull factors" most likely means the attractive conditions in wealthier nations—such as higher wages, career growth, safety, and access to cutting-edge facilities—that draw skilled talent from other countries.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the impact of brain drain on healthcare in developing countries?',
        explanation: 'It can be inferred that brain drain causes serious shortages of doctors and nurses in many African and South Asian countries, leaving hospitals and clinics understaffed and under pressure while helping to solve labor shortages in richer destination countries.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is meant by "brain gain" or "brain circulation"?',
        explanation: 'According to the passage, "brain gain" or "brain circulation" refers to the potential benefits when skilled migrants return home with new knowledge, networks, and capital, as seen in examples from China and India in the tech and business sectors.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the limitations of remittances as a solution to brain drain?',
        explanation: 'It can be inferred that while remittances support families and boost local economies, they do not solve deeper problems such as weak institutions, lack of opportunity, and poor governance, and return migration itself is never guaranteed.',
      ),
      ReadingQuestion(
        question: 'The word "remittances" in the passage most likely means',
        explanation: 'In the context of the passage, "remittances" most likely means money that migrants send back to their home countries, which supports families and helps boost local economies.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how can digital technology help address brain drain?',
        explanation: 'According to the passage, with remote work becoming more common, professionals can contribute to global companies while living in their home countries, potentially allowing nations to benefit from international salaries without permanently losing their talent.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the root causes of brain drain from the conclusion?',
        explanation: 'It can be inferred that brain drain ultimately reflects global inequality and systems that limit growth, and that retaining talent requires deeper reforms addressing dignity, opportunity, and trust rather than higher wages alone; otherwise even the best retention strategies will fail.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what strategies do some governments use to reduce brain drain?',
        explanation: 'According to the passage, some governments invest in better conditions by offering competitive salaries, modern infrastructure, and transparent promotion systems, as well as scholarships with return conditions, research grants, and professional development programs to keep talent at home.',
      ),
    ],
  ),

  ReadingPassage(
    id: 70,
    title: 'Bribery',
    topic: 'Society & Governance',
    content: '''Bribery is the act of offering, giving, or receiving something of value—usually money—to influence a person in a position of power. Whether it happens in politics, business, or everyday services, bribery undermines fairness, trust, and accountability. Because it operates in secrecy, it is often difficult to detect or prove.
Although bribery exists in almost every country, its effects are especially damaging in developing nations. Not only does it weaken public institutions, but it also deepens inequality and slows down development. When access to services depends on payments under the table, citizens lose confidence in their leaders and systems.
Bribery takes many forms. In some cases, it may involve paying a government official to speed up paperwork, avoid taxes, or win a contract. In others, it could mean giving gifts or favors to judges, police, or teachers to gain special treatment. Because these actions distort decision-making, they prevent fair competition and punish those who follow the rules.
In business, bribery often appears as corporate corruption. Companies may offer bribes to secure deals, bypass regulations, or hide illegal activity. Multinational firms operating in weak legal environments may use local ―fixers‖ to smooth operations through illegal payments. While this may increase short-term profits, it also exposes companies to legal risks and reputational damage.
The public sector is especially vulnerable. When civil servants are underpaid and poorly supervised, they may turn to bribes to supplement their income. This creates a cycle where public services become unreliable or inaccessible. For example, a bribe may be required to get a driver‘s license, hospital bed, or school admission— even when these should be free or fairly distributed.
Elections and political systems are also at risk. Bribes can influence who gets nominated, elected, or appointed. This damages democracy, as leaders are chosen based on money, not merit. If voters believe elections are bought, not earned, participation drops and cynicism grows.
Bribery often goes hand in hand with a lack of transparency. When government budgets, contracts, or decisions are hidden from the public, corruption becomes easier to hide. Because there is no oversight, dishonest behavior can continue unchecked for years.
To fight bribery, many countries have passed strict anti-corruption laws. These include penalties for both the giver and receiver of bribes, as well as protections for whistleblowers. International treaties like the UN Convention Against Corruption promote cooperation across borders. Still, laws alone are not enough. If enforcement is weak or biased, corruption thrives.
Public awareness is key. Citizens must understand their rights and report illegal activity without fear. Media, education, and civil society play crucial roles in exposing bribery and holding officials accountable. In some countries, investigative journalism has uncovered massive corruption scandals, leading to resignations, trials, and reforms.
Technology can also help. Online payment systems, open data platforms, and egovernance tools reduce human contact and improve transparency. For example, when people pay taxes or apply for permits online, the chance of being asked for a bribe decreases. Digital systems create clear records, which are harder to manipulate. However, in many cultures, the line between bribery and ―gift-giving‖ is unclear. In some societies, giving presents to officials is seen as polite or respectful. This cultural norm makes enforcement difficult. What matters is whether the gift influences a decision or creates an unfair advantage.
Some argue that bribery is a necessary evil in systems that don‘t work. When processes are slow or rules are unclear, people may pay bribes just to get basic services. But this short-term solution leads to long-term damage. It discourages reform and keeps bad systems in place.
Ultimately, bribery is not just a legal issue—it is a moral and structural one. It reflects weak institutions, poor governance, and a lack of accountability. If societies want to reduce bribery, they must fix the conditions that allow it to grow: low salaries, unchecked power, and limited transparency.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage defines bribery, explains its various forms and damaging effects especially in developing nations and public institutions, discusses its presence in business, politics, and everyday services, and outlines strategies to combat it through laws, public awareness, technology, and addressing underlying structural problems.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is bribery especially damaging in developing nations?',
        explanation: 'It weakens public institutions, deepens inequality, and slows down development; when access to services depends on payments under the table, citizens lose confidence in their leaders and systems.',
      ),
      ReadingQuestion(
        question: 'The word "distort" in the paragraph about forms of bribery most likely means',
        explanation: 'It means to twist or alter improperly, as bribery actions distort decision-making, prevent fair competition, and punish those who follow the rules.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the vulnerability of the public sector to bribery?',
        explanation: 'When civil servants are underpaid and poorly supervised, they may turn to bribes to supplement their income, creating a cycle where public services become unreliable or inaccessible, such as requiring bribes for licenses, hospital beds, or school admissions.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how can technology help reduce bribery?',
        explanation: 'Online payment systems, open data platforms, and egovernance tools reduce human contact and improve transparency; for example, paying taxes or applying for permits online decreases the chance of being asked for a bribe, and digital systems create clear records that are harder to manipulate.',
      ),
      ReadingQuestion(
        question: 'The phrase "necessary evil" in the paragraph about systems that do not work most likely means',
        explanation: 'It refers to something undesirable that some people believe is unavoidable or required under the circumstances, as some argue bribery is needed when processes are slow or rules are unclear to obtain basic services, though it causes long-term damage.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the relationship between transparency and bribery?',
        explanation: 'Bribery often goes hand in hand with a lack of transparency; when government budgets, contracts, or decisions are hidden from the public, corruption becomes easier to hide and can continue unchecked for years due to no oversight.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why are laws alone not enough to fight bribery?',
        explanation: 'If enforcement is weak or biased, corruption thrives; although many countries have strict anti-corruption laws and international treaties promote cooperation, effective reduction also requires public awareness, media exposure, and addressing structural conditions.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about cultural attitudes toward gift-giving and bribery?',
        explanation: 'In many cultures the line between bribery and gift-giving is unclear; giving presents to officials may be seen as polite or respectful, making enforcement difficult, but what matters is whether the gift influences a decision or creates an unfair advantage.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what conditions allow bribery to grow, and how should societies address them?',
        explanation: 'Bribery reflects weak institutions, poor governance, and a lack of accountability; societies must fix conditions such as low salaries, unchecked power, and limited transparency to reduce it.',
      ),
    ],
  ),

  ReadingPassage(
    id: 71,
    title: 'Charity',
    topic: 'Society & Culture',
    content: '''Charity refers to the voluntary giving of help—usually money, time, or services— to those in need. Whether supporting disaster victims, the poor, or medical research, charitable work plays a vital role in reducing suffering and promoting social welfare. Because governments cannot solve every problem alone, charitable organizations fill important gaps in education, healthcare, housing, and humanitarian aid.
Although charity is often viewed as an act of kindness, it also reflects deeper values such as solidarity, justice, and compassion. Not only does it help those in immediate need, but it also raises awareness of long-term issues like poverty, inequality, and climate change.
There are many forms of charity. Individuals may donate money to organizations, sponsor a child, or volunteer their time at shelters or hospitals. Others may organize fundraising events or start campaigns on social media. Because technology has made giving easier, even small contributions can reach global causes in seconds.
International charities play a major role in crisis response. When natural disasters, conflicts, or epidemics strike, aid agencies provide food, water, medical care, and shelter. The Red Cross, Médecins Sans Frontières, and UNICEF are examples of organizations that operate across borders. Without such support, many lives would be lost.
However, charity is not without criticism. Some argue that it creates dependency rather than solving root problems. For instance, handing out food may help today, but it doesn‘t fix unemployment or poor infrastructure. Others claim that some charities lack transparency, with too much money spent on administration rather than aid.
Large corporations also engage in charitable giving, often through Corporate Social Responsibility (CSR) programs. While this can generate positive impact, critics argue that some companies use charity to distract from unethical practices. This raises the question: is the motivation genuine—or just a public relations strategy?
Religion has historically played a major role in charity. Most major faiths encourage believers to give a portion of their wealth to the poor. In Islam, this is called zakat; in Christianity, tithing. Because these acts are seen as moral obligations, religious giving remains a powerful source of aid in many communities.
Youth involvement in charity is also increasing. Many young people join volunteer programs, donate through crowdfunding, or advocate for causes they believe in.
Schools and universities often encourage community service as part of education. This helps build empathy, teamwork, and a sense of social responsibility.
Yet, the debate continues: Should wealthy individuals and corporations be expected to give? Some believe the rich have a moral duty to help the less fortunate. Others argue that charity is voluntary and should not replace fair taxation or government responsibility. After all, public services should not depend on private generosity.
There is also a growing trend toward ―effective altruism.‖ This approach emphasizes giving where impact is greatest, using data and evidence to decide how and where to donate. For example, some donors focus on distributing malaria nets in Africa rather than funding art museums. The goal is not to give emotionally, but intelligently.
Despite its challenges, charity remains a powerful force for good. It connects people across cultures and countries, builds stronger communities, and gives hope to those in despair. Even a small act of kindness—such as buying a meal for someone in need—can make a difference.
In the future, the role of charity may evolve. Technology, transparency tools, and global networks may allow for more efficient, accountable, and inclusive giving. However, the core idea will remain the same: that helping others is not only a moral choice, but a social necessity.
Ultimately, charity is more than giving money—it is about building a better world. When done wisely and ethically, it empowers both the giver and the receiver.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of this passage is to explain the concept of charity as voluntary help given to those in need, discuss its various forms and roles in society, examine both its benefits and criticisms, explore the influences of technology, religion, and effective altruism, and conclude that wise and ethical charity helps build a better world by empowering both givers and receivers.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what role do international charities play during crises?',
        explanation: 'International charities play a major role in crisis response by providing food, water, medical care, and shelter when natural disasters, conflicts, or epidemics strike. Organizations such as the Red Cross, Médecins Sans Frontières, and UNICEF operate across borders, and without such support many lives would be lost.',
      ),
      ReadingQuestion(
        question: 'The word \'dependency\' in the passage most likely means?',
        explanation: 'It most likely means a state of relying on external help rather than becoming self-sufficient, as the passage notes that some argue charity creates dependency rather than solving root problems like unemployment or poor infrastructure.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the concept of effective altruism?',
        explanation: 'It can be inferred that effective altruism prioritizes measurable impact over emotional giving, as it uses data and evidence to decide where donations will do the most good, such as distributing malaria nets in Africa rather than funding less impactful causes like art museums.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how has technology affected charitable giving?',
        explanation: 'Technology has made giving easier, allowing even small contributions to reach global causes in seconds. It also enables crowdfunding and social media campaigns, and in the future, technology and transparency tools may support more efficient, accountable, and inclusive giving.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the relationship between religion and charity?',
        explanation: 'It can be inferred that religion remains a strong motivator for charitable giving because most major faiths encourage believers to give a portion of their wealth to the poor as a moral obligation, with practices such as zakat in Islam and tithing in Christianity continuing to provide powerful sources of aid in many communities.',
      ),
    ],
  ),

  ReadingPassage(
    id: 72,
    title: 'Computerization',
    topic: 'Technology & Society',
    content: '''Computerization refers to the process of replacing manual systems with computerbased technologies. Whether applied to banking, education, healthcare, or manufacturing, it has radically transformed how people live and work. Because computers can process information faster and more accurately than humans, they are now central to nearly every sector of modern society.
Although computerization began in the mid-20th century, its real impact has been felt over the past few decades. Not only has it increased efficiency, but it has also changed expectations. Tasks that once took hours can now be completed in minutes—or even seconds. This speed has become the new standard.
Businesses were among the first to adopt computer systems. Accounting, inventory, communication, and project management are now largely digitized.
Automation of repetitive tasks has reduced human error and operating costs. Because companies that fail to adapt often fall behind, computerization is seen as essential for competitiveness.
Governments have also embraced digital systems. Online tax filing, digital IDs, and e-governance portals improve public service delivery and reduce corruption. Citizens can access services without standing in long lines or dealing with paperwork. However, this shift assumes that everyone has access to technology— which is not always the case.
Education is being reshaped as well. Classrooms now use digital tools such as interactive whiteboards, online platforms, and video lessons. Computer literacy has become a basic requirement. Because the future job market demands tech-savvy workers, schools are under pressure to modernize. Yet, not all educators are equally prepared for this change.
Healthcare, too, has seen major improvements. Patient records, diagnostics, and treatment plans are increasingly stored and managed electronically. This allows for faster access, better coordination, and reduced medical errors. Still, concerns about data security and privacy remain, especially when sensitive health information is stored online.
One major outcome of computerization is automation. Machines, guided by algorithms, can now perform tasks once done by people—from driving cars to analyzing legal documents. While this increases productivity, it also raises fears about job loss. If workers are replaced by software, what happens to employment? Many argue that new jobs will be created in areas such as IT, cybersecurity, and data science. However, these jobs often require specialized skills, which not all displaced workers possess. This highlights the need for re-skilling programs, so people can transition into new roles rather than being left behind.
Computerization also affects social interaction. Emails, messaging apps, and video calls have replaced many face-to-face conversations. While communication is now faster and more convenient, some worry that it lacks depth or emotional connection. Not only are relationships becoming more digital, but attention spans and human empathy may be declining.
In developing countries, computerization offers both opportunity and challenge. On one hand, digital tools can support education, agriculture, and health services in remote areas. On the other, lack of infrastructure, electricity, and digital literacy can slow progress. Bridging this digital divide is essential for inclusive growth.
Another concern is over-reliance. As more systems become automated, humans risk losing basic skills. For example, many people no longer remember phone numbers or directions, relying entirely on apps. While convenience is valuable, total dependence can lead to vulnerability—especially during system failures or cyberattacks.
Cybersecurity has become a top priority. As more data moves online, so do threats.
From identity theft to ransomware attacks, the risks of digital systems are real. That is why strong encryption, regulation, and public awareness are critical.
Ethical questions also arise. Should machines be allowed to make life-or-death decisions? For instance, in self-driving cars or medical AI, who is responsible if something goes wrong? Because computers follow code—not conscience—human oversight is still essential.
Despite challenges, the benefits of computerization are undeniable. It enables innovation, expands access to information, and opens new possibilities in every field. Used wisely, it can improve lives and solve complex problems.
Ultimately, computerization is not just a technical shift—it is a social and cultural one. How we adapt to it will determine whether it leads to progress or division. If managed responsibly, it can serve as a tool for equality, efficiency, and empowerment.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to explain computerization as the replacement of manual systems with computer-based technologies, describe its transformative effects across business, government, education, and healthcare, and examine both its benefits and the challenges it creates regarding jobs, social interaction, equity, and ethics.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is computerization considered essential for businesses?',
        explanation: 'Automation of repetitive tasks has reduced human error and operating costs, and companies that fail to adapt often fall behind, making computerization essential for competitiveness.',
      ),
      ReadingQuestion(
        question: 'The word \'digitized\' in the third paragraph most likely means...',
        explanation: 'Converted into a digital or computer-based form. The passage states that accounting, inventory, communication, and project management are now largely digitized.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the impact of computerization on employment?',
        explanation: 'Automation raises fears of job loss as machines perform tasks once done by people, but new jobs may be created in IT, cybersecurity, and data science; however, these require specialized skills, highlighting the need for re-skilling so displaced workers can transition.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how has computerization affected healthcare?',
        explanation: 'Patient records, diagnostics, and treatment plans are increasingly stored and managed electronically, allowing faster access, better coordination, and reduced medical errors, though concerns about data security and privacy remain.',
      ),
      ReadingQuestion(
        question: 'The phrase \'digital divide\' in the tenth paragraph most likely means...',
        explanation: 'The gap between those who have access to digital technology, infrastructure, electricity, and digital literacy and those who do not, which must be bridged for inclusive growth in developing countries.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about over-reliance on computer systems?',
        explanation: 'As systems become automated, humans risk losing basic skills such as remembering phone numbers or directions; total dependence can lead to vulnerability during system failures or cyberattacks despite the convenience.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what ethical questions does computerization raise?',
        explanation: 'Questions include whether machines should make life-or-death decisions, such as in self-driving cars or medical AI, and who is responsible if something goes wrong, since computers follow code rather than conscience and human oversight remains essential.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about computerization in developing countries?',
        explanation: 'It offers opportunities to support education, agriculture, and health services in remote areas, but lack of infrastructure, electricity, and digital literacy can slow progress, making the bridging of the digital divide essential for inclusive growth.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how has computerization changed social interaction?',
        explanation: 'Emails, messaging apps, and video calls have replaced many face-to-face conversations, making communication faster and more convenient, yet some worry it lacks depth or emotional connection and that attention spans and human empathy may be declining.',
      ),
    ],
  ),

  ReadingPassage(
    id: 73,
    title: 'Computer Games',
    topic: 'Technology & Society',
    content: '''Computer games, once seen as a niche hobby, have now become a global industry worth billions of dollars. Whether played on consoles, mobile phones, or PCs, games are a common form of entertainment for children, teenagers, and adults alike. Because of their growing influence on culture, behavior, and education, debates about the role of computer games are intensifying.
Although computer games were originally designed for fun, they now serve a variety of functions—from relaxation to social connection, from education to professional competition. Not only do they entertain, but they also engage players mentally and emotionally. Games today feature complex storylines, lifelike graphics, and multiplayer cooperation across countries.
One major concern is addiction. Because games are designed to reward players frequently, they can be highly engaging—and even addictive. Some players spend several hours a day gaming, sometimes skipping sleep, school, or social interaction. This excessive use can lead to poor academic performance, social withdrawal, or even mental health problems.
Violence in video games is another common issue. First-person shooters and war simulations often involve graphic scenes, which some believe can desensitize players to real-world violence. While research is mixed, some studies suggest a temporary increase in aggressive thoughts after playing violent games. However, others argue that no clear link exists between gaming and real-life behavior.
Despite these concerns, many experts point to the positive effects of computer games. Strategy games, puzzles, and simulations can improve critical thinking, decision-making, and problem-solving skills. Multiplayer games promote teamwork, communication, and leadership. Because players must plan, adapt, and cooperate, they often build useful real-world skills.
Educational games, in particular, are growing in popularity. Used in schools and training programs, these games teach languages, math, science, and history in engaging ways. Instead of passive learning, students become active participants in the learning process. This method, known as ―gamification,‖ is now widely supported by educators.
Esports (electronic sports) have become a professional career path. Top players, often in their teens or twenties, earn income through competitions, sponsorships, and streaming. Some universities even offer scholarships for skilled gamers. Because of this trend, gaming is no longer just a pastime—it is a serious profession for some.
Parents and educators, however, are concerned about screen time. The World Health Organization recommends limits on daily screen exposure, especially for young children. Excessive gaming, particularly late at night, has been linked to sleep problems, poor diet, and decreased physical activity.
Still, not all screen time is equal. Interactive games require focus, memory, and coordination, unlike passive screen activities like watching TV. When chosen carefully and played in moderation, games can actually support healthy development.
Social aspects of gaming are often overlooked. Online games allow players to build friendships, join communities, and compete with others across the globe. For some, gaming is a safe space to connect, especially for shy or isolated individuals. However, toxic behavior, cyberbullying, and exposure to inappropriate content remain real risks.
Regulation and parental control are necessary. Game rating systems, such as PEGI or ESRB, help guide age-appropriate content. Parental control tools can limit screen time and block harmful features like in-game purchases or chat functions. Because children may not understand financial or emotional risks, adult supervision is essential.
Another concern is commercialization. Many modern games include microtransactions—small payments for items or features. While these seem minor, they can lead to large expenses over time, especially when players feel pressured to
―pay to win.‖ This raises ethical questions about marketing strategies targeted at young users.
Ultimately, the impact of computer games depends on content, time spent, and player behavior. Just as books, films, and sports can educate or harm, so can games. The key is not banning games, but guiding their use.
In a balanced lifestyle, computer games can be both entertaining and enriching.
But when they replace physical activity, social life, or schoolwork, problems arise. Managing this balance is a shared responsibility between players, parents, educators, and developers.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to discuss the rise of computer games as a major industry and form of entertainment, examining both concerns such as addiction, violence, screen time, and commercialization, and positive aspects including skill development, education, social connection, and professional opportunities, while emphasizing the need for balanced and guided use.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what functions do computer games serve beyond entertainment?',
        explanation: 'Games now serve functions from relaxation to social connection, education to professional competition; they engage players mentally and emotionally and feature complex storylines, lifelike graphics, and multiplayer cooperation across countries.',
      ),
      ReadingQuestion(
        question: 'The word "desensitize" in the fourth paragraph most likely means',
        explanation: 'In the context of graphic scenes in violent games that some believe can desensitize players to real-world violence, the word means to make less sensitive or responsive to something, reducing emotional reaction to violence.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the research on violence in video games?',
        explanation: 'Research is mixed: some studies suggest a temporary increase in aggressive thoughts after playing violent games, but others argue there is no clear link between gaming and real-life violent behavior.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what positive skills can computer games help develop?',
        explanation: 'Strategy games, puzzles, and simulations can improve critical thinking, decision-making, and problem-solving; multiplayer games promote teamwork, communication, and leadership as players plan, adapt, and cooperate.',
      ),
      ReadingQuestion(
        question: 'The term "gamification" in the sixth paragraph most likely means',
        explanation: 'In the context of educational games that make students active participants rather than passive learners and teach subjects in engaging ways, gamification refers to the method of applying game elements and design to education or other non-game contexts.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about esports from the passage?',
        explanation: 'Esports have become a professional career path where top players earn income through competitions, sponsorships, and streaming, and some universities offer scholarships, showing that gaming is now a serious profession for some rather than just a pastime.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is not all screen time considered equal?',
        explanation: 'Interactive games require focus, memory, and coordination, unlike passive activities such as watching TV; when chosen carefully and played in moderation, games can support healthy development rather than simply being harmful.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the social aspects of online gaming?',
        explanation: 'Online games allow players to build friendships, join communities, and compete globally, providing a safe space especially for shy or isolated individuals, but risks such as toxic behavior, cyberbullying, and inappropriate content also exist.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is the key to managing the impact of computer games?',
        explanation: 'The impact depends on content, time spent, and player behavior; the key is not banning games but guiding their use so that in a balanced lifestyle they can be entertaining and enriching, while preventing them from replacing physical activity, social life, or schoolwork through shared responsibility among players, parents, educators, and developers.',
      ),
    ],
  ),

  ReadingPassage(
    id: 74,
    title: 'Automation',
    topic: 'Technology & Society',
    content: '''Automation refers to the use of machines, software, or technology to perform tasks that were previously done by humans. Whether in factories, offices, hospitals, or homes, automation is reshaping the global workforce. Because machines can operate faster, longer, and more precisely than people, many industries now rely heavily on automated systems.
Although automation increases productivity and reduces costs, it also creates serious challenges for employment. Not only are repetitive manual jobs disappearing, but some white-collar roles—such as data entry or customer service—are being replaced by software. This trend has sparked debates about the future of work.
Manufacturing was one of the first sectors to embrace automation. Robots now assemble cars, package products, and manage warehouses with high speed and accuracy. As a result, production has become more efficient and cheaper.
However, millions of factory workers have lost their jobs, especially in regions that failed to adapt quickly.
Service industries are also changing. Self-checkout machines in supermarkets, chatbots on websites, and automated phone systems have replaced many human workers. While these systems improve convenience, they reduce human interaction and eliminate entry-level jobs. This raises concerns about social inequality and job access.
Some argue that automation creates as many jobs as it destroys. For every job lost in manufacturing, new roles emerge in robotics, software development, and maintenance. However, these new jobs often require advanced skills, which many displaced workers do not have. Unless retraining programs are widely available, large groups of people may be left behind.
Education and training must evolve. Because the job market is changing rapidly, traditional qualifications are no longer enough. People now need digital literacy, adaptability, and problem-solving abilities. Governments and employers must invest in lifelong learning to help workers transition to new roles.
Another concern is income inequality. Highly skilled professionals benefit from automation, while low-skilled workers face job insecurity. In many countries, the wealth gap is widening. Some economists suggest taxing robots or introducing universal basic income as ways to protect those most affected.
Automation is not only about job loss. It also improves safety, accuracy, and convenience. In dangerous environments—like mining, firefighting, or deep-sea exploration—robots can perform tasks without risking human lives. In healthcare, surgical robots assist doctors, reducing errors and recovery time. These advancements would not be possible without automation.
In agriculture, automated tractors, drones, and irrigation systems are boosting productivity. Farmers can now monitor crops and soil using real-time data, leading to smarter and more sustainable practices. This is especially important in countries facing labor shortages or climate challenges.
Despite the benefits, there are ethical concerns. If machines begin making decisions independently, who is responsible when something goes wrong? In selfdriving cars, for example, how should the system respond in a life-or-death scenario? Because algorithms lack moral judgment, human oversight remains essential.
Privacy is another issue. As more systems become automated and connected, vast amounts of personal data are collected. This data can be used to improve services—but also to control or exploit users. Without strict regulations, the risks of surveillance and manipulation increase.
Small businesses may also struggle to keep up. Large corporations can afford to automate quickly, gaining an edge over local shops and startups. This could lead to market monopolies and reduced diversity in business. To prevent this, governments may need to offer support or incentives for small firms.
Cultural impacts are also worth noting. As machines take over everyday tasks, people may lose traditional skills, such as cooking, driving, or repairing items. While convenience is appealing, dependence on technology may reduce selfreliance and human interaction.
Ultimately, automation is neither good nor bad—it is a tool. Its impact depends on how society manages the transition. If used responsibly, it can improve quality of life, free people from dull tasks, and create space for creativity and innovation.
However, if left unchecked, it can deepen inequality, destroy communities, and make workers feel disposable. Balancing progress with fairness is the challenge of our time.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage examines the benefits, challenges, and societal impacts of automation, concluding that it is a tool whose effects depend on responsible management to balance progress with fairness.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is one major advantage of automation in manufacturing?',
        explanation: 'Robots assemble cars, package products, and manage warehouses with high speed and accuracy, making production more efficient and cheaper.',
      ),
      ReadingQuestion(
        question: 'The word "displaced" in the sixth paragraph most likely means',
        explanation: 'In context, displaced refers to workers who have lost their jobs due to automation and need new opportunities or retraining.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the new jobs created by automation?',
        explanation: 'New roles in robotics, software development, and maintenance often require advanced skills that many workers who lost jobs in traditional sectors do not possess, so retraining is essential to avoid leaving people behind.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does automation affect service industries?',
        explanation: 'Self-checkout machines, chatbots, and automated phone systems replace human workers, improving convenience but reducing human interaction and eliminating entry-level jobs, which raises concerns about inequality.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the relationship between automation and income inequality?',
        explanation: 'Highly skilled professionals benefit from automation while low-skilled workers face insecurity, widening the wealth gap; some economists propose taxing robots or universal basic income as protective measures.',
      ),
      ReadingQuestion(
        question: 'According to the passage, in what ways does automation improve safety?',
        explanation: 'In dangerous environments such as mining, firefighting, or deep-sea exploration, robots can perform tasks without risking human lives, and surgical robots in healthcare reduce errors and recovery time.',
      ),
      ReadingQuestion(
        question: 'The word "algorithms" in the eleventh paragraph most likely means',
        explanation: 'In context, algorithms refer to the decision-making rules or programs that control automated systems, which lack moral judgment and therefore require human oversight.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the challenges faced by small businesses?',
        explanation: 'Large corporations can afford rapid automation and gain competitive advantages, potentially leading to market monopolies and reduced business diversity unless governments provide support or incentives for smaller firms.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what cultural impact might automation have?',
        explanation: 'As machines take over everyday tasks, people may lose traditional skills such as cooking, driving, or repairing items, and increased dependence on technology could reduce self-reliance and human interaction.',
      ),
    ],
  ),

  ReadingPassage(
    id: 75,
    title: 'Satellites',
    topic: 'Technology & Science',
    content: '''Satellites are man-made objects placed in orbit around the Earth or other celestial bodies. Whether used for communication, navigation, weather forecasting, or scientific research, satellites have become essential to modern life. Because they provide services most people rely on daily, their role is far more important than many realize.
Although satellites operate far above the Earth, their effects are felt everywhere. Not only do they enable GPS systems and live television broadcasts, but they also support mobile networks, internet access, and emergency response systems. In fact, without satellites, much of the world‘s digital infrastructure would collapse.
There are several types of satellites. Communication satellites transmit data for phones, internet, and broadcasting. Weather satellites monitor climate patterns, track storms, and help predict natural disasters. Navigation satellites, such as those in the Global Positioning System (GPS), allow accurate location tracking. Scientific satellites observe the Earth, the Sun, or distant galaxies to expand our understanding of the universe.
Governments and private companies both launch satellites. While early space missions were dominated by state agencies like NASA or the Soviet space program, the rise of private firms—such as SpaceX, Blue Origin, and OneWeb— has revolutionized the industry. Because of cheaper launch costs and technological advancements, thousands of new satellites are now being launched every year. This growth brings benefits—but also problems. The number of satellites in orbit has increased dramatically, especially with the rise of ―satellite constellations‖ used to deliver global internet. However, this expansion creates space debris— fragments of old satellites, rocket parts, or broken components. If not managed properly, space debris could damage functioning satellites or even cause dangerous chain collisions, known as the ―Kessler Syndrome.‖
Environmental concerns also apply. Each satellite launch burns fuel and releases emissions, contributing to pollution. Although space is vast, the low Earth orbit region is becoming increasingly crowded. Some experts argue that regulations are urgently needed to ensure that space remains usable and safe.
Satellites also raise ethical and security issues. Surveillance satellites can monitor activity on Earth, including troop movements, city infrastructure, or private property. While this can improve security and disaster response, it also raises questions about privacy and misuse. Who controls this data, and how is it used? Military satellites add another layer of complexity. Countries use satellites for reconnaissance, communication, and even missile guidance. In theory, satellites could be targeted or disabled during conflicts. Because many countries rely on them for national defense, space is becoming a potential battleground. Some analysts have already warned of a future ―space arms race.‖
Despite these risks, the advantages of satellites are undeniable. They allow scientists to monitor deforestation, ocean temperatures, and pollution levels, helping governments address climate change. In agriculture, satellite imagery is used to track crop health and predict harvests, improving food security. In disaster zones, they support rescue operations by identifying affected areas.
Developing countries also benefit. In places with poor infrastructure, satellites can provide remote education, healthcare, and internet access. This helps reduce inequality and connects isolated communities to global services. Because they bypass the need for roads or cables, satellites are especially useful in mountainous or rural regions.
However, access is still unequal. Most satellites are owned by wealthy countries or corporations, giving them control over critical information and services. To ensure fair access, international cooperation is needed—along with global standards for ownership, usage, and sustainability.
In education and research, satellites continue to play a major role. Students and scientists use satellite data to study geography, physics, climate, and space. International missions like the Hubble Space Telescope or the James Webb Space Telescope have expanded human knowledge in extraordinary ways. These projects show what is possible when nations collaborate rather than compete.
Ultimately, satellites reflect both the potential and the responsibility of modern technology. They have transformed communication, defense, science, and daily life. Yet, if mismanaged, they could create environmental, political, and ethical problems.
Because space is a shared resource, managing it wisely is in everyone‘s interest. As the number of satellites continues to grow, the need for international dialogue, responsible policies, and scientific cooperation becomes more urgent than ever.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage explains what satellites are and the services they provide, describes different types and the shift to private launches, examines problems such as space debris and security risks, highlights benefits for science, agriculture, and developing countries, and concludes that responsible international management of space is essential.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what would happen without satellites?',
        explanation: 'The passage states that without satellites, much of the world‘s digital infrastructure would collapse, as they enable GPS, live television, mobile networks, internet access, and emergency response systems.',
      ),
      ReadingQuestion(
        question: 'The term "Kessler Syndrome" in the passage most likely refers to',
        explanation: 'The passage describes the Kessler Syndrome as dangerous chain collisions that could result if space debris from old satellites, rocket parts, or broken components is not managed properly and damages functioning satellites.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the growth of private companies in the satellite industry?',
        explanation: 'The passage notes that private firms such as SpaceX, Blue Origin, and OneWeb have revolutionized the industry through cheaper launch costs and technological advancements, leading to thousands of new satellites being launched every year.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what types of satellites exist and what do they do?',
        explanation: 'The passage lists communication satellites that transmit data for phones, internet, and broadcasting; weather satellites that monitor climate and track storms; navigation satellites such as GPS for location tracking; and scientific satellites that observe the Earth, Sun, or distant galaxies.',
      ),
      ReadingQuestion(
        question: 'The word "constellations" in the phrase "satellite constellations" most likely means',
        explanation: 'In context, satellite constellations refer to large groups of satellites used to deliver global internet, contributing to the dramatic increase in the number of satellites in orbit.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the environmental impact of satellites?',
        explanation: 'The passage states that each satellite launch burns fuel and releases emissions contributing to pollution, and that the low Earth orbit region is becoming crowded, leading some experts to call for urgent regulations to keep space usable and safe.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how do satellites benefit developing countries?',
        explanation: 'The passage explains that in places with poor infrastructure, satellites can provide remote education, healthcare, and internet access, helping reduce inequality and connect isolated communities, especially in mountainous or rural regions.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about military use of satellites?',
        explanation: 'The passage notes that countries use satellites for reconnaissance, communication, and missile guidance, that satellites could be targeted or disabled in conflicts, and that some analysts warn of a future space arms race because many nations rely on them for defense.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is international cooperation needed regarding satellites?',
        explanation: 'The passage states that most satellites are owned by wealthy countries or corporations, creating unequal access, and that international cooperation along with global standards for ownership, usage, and sustainability is needed to ensure fair access and responsible management of space as a shared resource.',
      ),
    ],
  ),

  ReadingPassage(
    id: 76,
    title: 'Space Exploration',
    topic: 'Science & Technology',
    content: '''Space exploration is the investigation of the universe beyond Earth, using satellites, telescopes, robotic missions, and human spaceflight. Whether driven by scientific curiosity, national pride, or commercial ambition, the exploration of space has long fascinated humanity. Because it pushes the boundaries of technology and knowledge, space exploration remains one of the most ambitious and controversial fields of modern science.
Although early missions were motivated by military rivalry, especially during the Cold War, space programs today are more diverse. Not only do they aim to study planets and stars, but they also focus on climate monitoring, asteroid defense, and commercial development. This shift reflects a broader understanding of space as both a scientific frontier and a practical resource.
Governments have historically led space missions. NASA, Roscosmos, the European Space Agency (ESA), and China‘s CNSA have launched satellites, probes, and astronauts into orbit and beyond. The 1969 Apollo 11 mission, which landed humans on the Moon, remains one of the most iconic moments in history. Since then, progress has expanded to include Mars rovers, deep space telescopes, and long-term space stations.
In recent years, the private sector has entered the field. Companies like SpaceX, Blue Origin, and Virgin Galactic are revolutionizing access to space. Their reusable rockets and commercial launches have lowered costs and increased frequency. Because of these innovations, space is no longer the exclusive domain of superpowers—it is becoming a global and commercial arena.
Supporters of space exploration point to its many benefits. Satellites launched during space missions provide vital data for weather forecasting, navigation, communication, and environmental monitoring. Technologies developed for space have also led to everyday applications—such as water purification systems, medical imaging, and advanced materials. In this sense, investment in space fuels progress on Earth.
Furthermore, space exploration addresses profound scientific questions. Where did the universe come from? Are we alone? Could humans live on other planets? Missions to Mars, Europa, and exoplanets aim to answer these mysteries. Because such questions cannot be answered through Earth-based research alone, sending instruments and probes into space is essential.
However, critics argue that space exploration is a waste of resources. At a time when poverty, climate change, and healthcare remain urgent global problems, spending billions on space missions can seem irresponsible. Why search for life on other planets, they ask, when millions struggle to survive on this one?
Additionally, space missions carry risks. Rocket launches release harmful emissions, and satellites contribute to space debris. The growing number of objects in Earth‘s orbit raises the risk of collisions and may one day make space travel more dangerous or impossible. Unless international rules are established and followed, outer space could become polluted and militarized.
Another concern is inequality. Only a few countries and companies currently have the capacity for large-scale space missions. This could lead to a new form of colonialism, where powerful actors claim resources—such as minerals on the Moon or Mars—without global agreement. Such scenarios raise ethical and legal questions about ownership, access, and fairness in space.
Yet, others argue that space exploration could provide long-term solutions. As Earth's resources are depleted, mining asteroids or establishing space-based solar energy systems could become viable alternatives. Colonizing Mars, while still theoretical, is seen by some as a backup plan for humanity. Although this may sound extreme, climate change and geopolitical conflict have made the idea more plausible.
International cooperation is key. Projects like the International Space Station (ISS), involving the US, Russia, Europe, Japan, and Canada, show that space can unite rather than divide. Shared missions reduce costs, promote peace, and advance science more efficiently than competition ever could.
Education and inspiration are additional benefits. Space exploration excites young minds and encourages interest in science, technology, engineering, and math (STEM). It gives humanity a sense of shared purpose and wonder. When people watch a rocket launch or see images from a distant planet, they are reminded of what human creativity can achieve.
Ultimately, space exploration reflects our desire to understand the unknown. While not without cost or controversy, it represents a bold vision of progress. If managed wisely, it can drive innovation, strengthen global cooperation, and offer solutions to Earth‘s biggest problems.
Because the future of space belongs to everyone, ensuring it is peaceful, sustainable, and inclusive should be a global priority.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to examine the history, benefits, criticisms, and future potential of space exploration, highlighting both its scientific and practical value and the need for responsible, cooperative management.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what motivated early space missions?',
        explanation: 'Early space missions were motivated by military rivalry, especially during the Cold War.',
      ),
      ReadingQuestion(
        question: 'The word "iconic" in the third paragraph most likely means...',
        explanation: 'In the context of the passage, "iconic" means widely recognized and symbolically important, referring to the lasting historical significance of the Apollo 11 Moon landing.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of private companies in space exploration?',
        explanation: 'It can be inferred that private companies have made space more accessible and affordable through innovations like reusable rockets, transforming space from an exclusive government domain into a global commercial arena.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what practical benefits do satellites provide on Earth?',
        explanation: 'Satellites provide vital data for weather forecasting, navigation, communication, and environmental monitoring.',
      ),
      ReadingQuestion(
        question: 'The word "debris" in the eighth paragraph most likely means...',
        explanation: 'In the context of the passage, "debris" refers to discarded or leftover objects in space, such as inactive satellites and fragments that increase the risk of collisions.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about critics\' main objection to space exploration?',
        explanation: 'It can be inferred that critics believe resources spent on space missions would be better used to address urgent Earth-based problems such as poverty, climate change, and healthcare.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what risk does the growing number of objects in Earth\'s orbit pose?',
        explanation: 'The growing number of objects raises the risk of collisions and may one day make space travel more dangerous or even impossible if international rules are not established.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about international cooperation in space?',
        explanation: 'It can be inferred that cooperative projects like the International Space Station demonstrate that shared missions can reduce costs, promote peace, and advance science more effectively than competition.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is education considered a benefit of space exploration?',
        explanation: 'Space exploration excites young minds, encourages interest in STEM fields, and gives humanity a sense of shared purpose and wonder about human creativity and the unknown.',
      ),
    ],
  ),

  ReadingPassage(
    id: 77,
    title: 'Agriculture',
    topic: 'Environment & Economy',
    content: '''Agriculture, the practice of cultivating land and raising livestock, has been the foundation of human civilization for thousands of years. Whether it involves growing crops or breeding animals, agriculture remains essential for food security, economic development, and rural employment. Because it supports billions of lives globally, its importance cannot be overstated.
Although modern agriculture is more productive than ever, it faces serious challenges. Not only does it depend heavily on land, water, and climate, but it also contributes to environmental problems such as deforestation, water pollution, and greenhouse gas emissions. This means that agriculture must evolve if it is to remain sustainable.
The Green Revolution of the 20th century dramatically increased food production. By introducing high-yield crops, chemical fertilizers, and irrigation systems, many countries managed to reduce hunger and feed growing populations. While this was a breakthrough at the time, over-reliance on chemicals and monoculture farming has since raised concerns.
Today, one of the most pressing issues is land degradation. Because of overfarming, soil erosion, and poor land management, fertile land is being lost at alarming rates. This affects not only food production but also biodiversity and water retention. Unless more sustainable farming methods are adopted, future generations may face serious food shortages.
Water scarcity is another major concern. Agriculture accounts for around 70% of global freshwater use. In dry regions, inefficient irrigation and climate change have worsened the problem. To solve this, farmers need access to modern technologies like drip irrigation, water recycling, and drought-resistant crops.
Climate change further complicates the picture. Rising temperatures, unpredictable rainfall, and extreme weather events threaten crops and livestock worldwide. Smallholder farmers in developing countries are especially vulnerable, since they often lack insurance, savings, or technical support to cope with these disruptions. In response, many experts promote climate-smart agriculture—a set of practices that aim to increase productivity while reducing environmental impact. These include crop rotation, organic farming, reduced tillage, and agroforestry. Not only do such methods protect natural resources, but they also strengthen resilience to climate shocks.
Technology is playing an increasingly important role. Precision farming uses sensors, drones, and data analytics to monitor soil, weather, and plant health. This allows farmers to apply water and fertilizer only where needed, improving yields and reducing waste. Because access to such tools is still limited in poor regions, bridging the digital divide is a major goal.
Another emerging field is genetically modified organisms (GMOs). These crops are engineered to resist pests, diseases, or harsh climates. Supporters argue that GMOs can boost food security and reduce pesticide use. However, critics raise concerns about safety, biodiversity, and corporate control of seeds. The debate continues in many countries.
Agriculture is not only about producing food—it is also an economic engine. In many developing nations, farming employs over half the population. Supporting rural areas with infrastructure, training, and fair markets is crucial for reducing poverty. If farmers receive fair prices and reliable access to buyers, they are more likely to invest in sustainable practices.
Urban agriculture is also gaining attention. With more people living in cities, rooftop gardens, vertical farms, and community plots offer new ways to grow food locally. Not only do these methods reduce transportation costs, but they also promote food education and healthier eating habits.
Food waste is another hidden issue. Roughly one-third of all food produced globally is lost or wasted. Improving storage, transport, and consumer awareness can help reduce this waste and make food systems more efficient. Because reducing waste is often cheaper than increasing production, it is a priority for many governments.
Trade and globalization affect agriculture as well. While international trade allows countries to access foods they cannot grow, it also exposes local farmers to global price swings and competition. Some argue that subsidies in rich countries distort markets and harm farmers in poorer nations, making trade policy a controversial topic.
Ultimately, agriculture is more than just an industry—it is a lifeline. It feeds the world, employs millions, and shapes the environment. If managed wisely, it can provide enough for all without destroying the planet.
However, if business continues as usual, soil will degrade, water will run out, and climate impacts will worsen. The future of agriculture depends on innovation, fairness, and sustainability.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to discuss agriculture as the foundation of civilization, highlighting its importance for food security and economies while examining challenges such as environmental impact, climate change, and the need for sustainable innovations.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what was the Green Revolution?',
        explanation: 'According to the passage, the Green Revolution of the 20th century dramatically increased food production by introducing high-yield crops, chemical fertilizers, and irrigation systems, helping many countries reduce hunger, though it later raised concerns about chemical over-reliance and monoculture.',
      ),
      ReadingQuestion(
        question: 'The word "degradation" in the fourth paragraph most likely means',
        explanation: 'In the context of the fourth paragraph, "degradation" refers to the decline or deterioration of land quality due to overfarming, soil erosion, and poor management, leading to loss of fertile land at alarming rates.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the vulnerability of smallholder farmers?',
        explanation: 'It can be inferred that smallholder farmers in developing countries are especially at risk from climate change impacts because they often lack insurance, savings, or technical support needed to cope with rising temperatures, unpredictable rainfall, and extreme weather.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what percentage of global freshwater use is accounted for by agriculture?',
        explanation: 'According to the passage, agriculture accounts for around 70% of global freshwater use, making water scarcity a major concern especially in dry regions affected by inefficient irrigation and climate change.',
      ),
      ReadingQuestion(
        question: 'The term "climate-smart agriculture" in the sixth paragraph most likely refers to',
        explanation: 'In the context of the sixth paragraph, "climate-smart agriculture" refers to a set of practices such as crop rotation, organic farming, reduced tillage, and agroforestry that aim to increase productivity while reducing environmental impact and strengthening resilience to climate shocks.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about precision farming?',
        explanation: 'It can be inferred that precision farming improves efficiency by using sensors, drones, and data analytics to apply water and fertilizer only where needed, boosting yields and cutting waste, though limited access in poor regions creates a digital divide that needs to be bridged.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are the main arguments for and against GMOs?',
        explanation: 'According to the passage, supporters argue that GMOs can boost food security and reduce pesticide use by resisting pests, diseases, or harsh climates, while critics raise concerns about safety, biodiversity, and corporate control of seeds.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the benefits of urban agriculture?',
        explanation: 'It can be inferred that urban agriculture through rooftop gardens, vertical farms, and community plots reduces transportation costs while also promoting food education and healthier eating habits as more people live in cities.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is reducing food waste considered a priority?',
        explanation: 'According to the passage, roughly one-third of all food produced globally is lost or wasted, and reducing this waste through better storage, transport, and consumer awareness is often cheaper than increasing production, making it a priority for many governments.',
      ),
    ],
  ),

  ReadingPassage(
    id: 78,
    title: 'GM Food',
    topic: 'Science & Society',
    content: '''Genetically Modified (GM) food refers to crops and animals whose DNA has been altered in a laboratory to introduce desired traits, such as pest resistance, faster growth, or improved nutrition. Whether it's corn that resists insects or rice enriched with vitamins, GM food is now found in many supermarkets around the world. Because global food demand is rising, supporters claim that GM technology is a necessary innovation.
Although GM food has been around for decades, public opinion remains deeply divided. Not only are there concerns about safety, but ethical, environmental, and economic questions also shape the debate. This controversy reflects deeper tensions between science, policy, and consumer trust.
Proponents of GM food argue that it offers several advantages. First, it can increase agricultural productivity by making crops resistant to pests, diseases, or drought. This reduces the need for pesticides and increases food supply, especially in regions suffering from food insecurity. Because GM crops can survive in harsh climates, they may also help farmers adapt to climate change.
Another benefit is enhanced nutrition. Golden Rice, for example, is genetically engineered to contain vitamin A, which can help prevent blindness in children in developing countries. Such innovations could save lives, especially where malnutrition is widespread.
GM food may also reduce food waste. Crops can be engineered to have longer shelf lives, resist bruising, or tolerate transportation better. In a world where nearly one-third of food is lost or wasted, this could make food systems more efficient and sustainable.
However, critics raise several concerns. One of the most common objections is safety. Opponents argue that long-term health effects of GM food are not fully understood. Although most scientific studies show no proven harm, the possibility of allergic reactions or unintended side effects continues to worry consumers.
Environmental issues are also debated. Some GM crops are engineered to resist herbicides, leading to heavier use of chemicals in farming. This can damage ecosystems, kill beneficial insects, and create herbicide-resistant weeds. In addition, the widespread planting of genetically identical crops can reduce biodiversity, making food systems more vulnerable to disease outbreaks.
Another concern involves corporate control. A handful of biotech companies hold patents on GM seeds, which means farmers must buy them every season rather than saving seeds from previous harvests. This dependence gives large firms significant power over global food supply, raising questions of fairness, especially for small-scale farmers in poor countries.
Labelling and transparency are also key issues. Some countries require clear labelling of GM foods, while others do not. Because many consumers want to make informed choices, advocates argue that people have the right to know what's in their food. Opponents claim that such labelling causes unnecessary fear, even when products are scientifically proven to be safe.
International trade has also been affected. Many European countries restrict or ban GM imports, while others embrace the technology. This difference has led to trade disputes and confusion over global food standards. It also reflects cultural attitudes toward risk, nature, and food.
In response to concerns, strict regulations govern the development and approval of GM foods in most countries. Before a GM crop reaches the market, it must pass extensive testing for health and environmental impact. Still, because regulation varies across borders, some experts call for more global coordination and transparency.
A growing area of interest is gene editing. Unlike older GM techniques that insert foreign DNA, new methods like CRISPR can make precise changes within a species. Supporters claim this is more natural and less risky, but the ethical and legal questions remain similar.
Public trust is critical. Scientific evidence alone is not enough to change opinions.
Cultural values, media influence, and misinformation all shape public perception.
To build confidence, open communication, labelling, and inclusive policymaking are needed.
Ultimately, the question is not just whether GM food is safe—but whether it is necessary, ethical, and fairly managed. The world must feed a growing population while protecting the environment and respecting individual rights. If used responsibly, GM technology can be part of the solution.
However, if driven solely by profit and without proper oversight, it risks deepening inequalities, damaging ecosystems, and eroding public trust.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to explain what genetically modified (GM) food is, present the arguments for its benefits such as increased productivity, enhanced nutrition, and reduced waste, outline critics\' concerns about safety, environment, corporate control, and labelling, discuss regulation, gene editing, and public trust, and conclude that responsible use could help address global food needs while unmanaged use risks inequalities and eroded trust.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what advantages do proponents claim for GM food?',
        explanation: 'According to the passage, proponents argue that GM food can increase agricultural productivity by making crops resistant to pests, diseases, or drought (reducing pesticide need and boosting supply in food-insecure regions), help farmers adapt to climate change, enhance nutrition (as with Golden Rice containing vitamin A), and reduce food waste through longer shelf lives and better transport tolerance.',
      ),
      ReadingQuestion(
        question: 'The word "proponents" in the third paragraph most likely means',
        explanation: 'In the third paragraph, "proponents" most likely means supporters or advocates of GM food who argue that it offers several advantages.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about environmental concerns related to GM crops?',
        explanation: 'It can be inferred that environmental issues are significant: some GM crops engineered to resist herbicides may lead to heavier chemical use that damages ecosystems, kills beneficial insects, and creates herbicide-resistant weeds, while widespread planting of genetically identical crops can reduce biodiversity and increase vulnerability to disease outbreaks.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is corporate control a concern with GM seeds?',
        explanation: 'According to the passage, a handful of biotech companies hold patents on GM seeds, forcing farmers to buy them every season rather than saving seeds, which gives large firms significant power over the global food supply and raises fairness questions, especially for small-scale farmers in poor countries.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about labelling of GM foods?',
        explanation: 'It can be inferred that labelling and transparency are contested: some countries require clear labelling while others do not; advocates argue consumers have the right to know what\'s in their food to make informed choices, whereas opponents claim labelling causes unnecessary fear even for scientifically safe products.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does gene editing differ from older GM techniques?',
        explanation: 'According to the passage, unlike older GM techniques that insert foreign DNA, new methods like CRISPR can make precise changes within a species; supporters claim this is more natural and less risky, though ethical and legal questions remain similar.',
      ),
      ReadingQuestion(
        question: 'The phrase "public trust" in the passage most likely refers to',
        explanation: 'In the passage, "public trust" refers to consumer confidence in GM food and technology, which is critical because scientific evidence alone is not enough to change opinions; cultural values, media influence, and misinformation shape perception, so open communication, labelling, and inclusive policymaking are needed to build it.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about international differences regarding GM food?',
        explanation: 'It can be inferred that international trade is affected by differing approaches: many European countries restrict or ban GM imports while others embrace the technology, leading to trade disputes, confusion over global standards, and reflections of cultural attitudes toward risk, nature, and food; regulation also varies, prompting calls for more global coordination.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is the ultimate question surrounding GM food?',
        explanation: 'According to the passage, the ultimate question is not just whether GM food is safe, but whether it is necessary, ethical, and fairly managed, given the need to feed a growing population while protecting the environment and respecting individual rights; responsible use can be part of the solution, but profit-driven use without oversight risks inequalities, ecosystem damage, and eroded public trust.',
      ),
    ],
  ),

  ReadingPassage(
    id: 79,
    title: 'Energy',
    topic: 'Energy & Environment',
    content: '''Energy powers modern life. Whether it's used to heat homes, fuel vehicles, or run factories, energy is essential for economic development and human well-being. Because demand is rising globally, finding reliable, affordable, and sustainable sources of energy has become a top priority.
Although fossil fuels—such as coal, oil, and natural gas—still dominate global energy use, they are also the main contributors to air pollution and climate change. Not only do they release greenhouse gases, but they also cause environmental degradation through mining, drilling, and transportation. As a result, governments and scientists are pushing for a shift to cleaner alternatives.
Renewable energy sources offer a potential solution. These include solar, wind, hydroelectric, geothermal, and biomass energy, which can be replenished naturally and have lower environmental impact. Because they emit little or no carbon dioxide, renewables are central to efforts to reduce global warming.
Solar power has seen rapid growth. Thanks to falling costs and improved technology, solar panels are now used in homes, businesses, and large solar farms. Not only are they easy to install, but they can also operate independently in remote or off-grid areas.
Wind energy is another key option. Modern wind turbines can generate large amounts of electricity, especially in coastal or open areas. However, some people object to their visual appearance or noise, and they rely on favorable weather conditions.
Hydropower, generated from rivers and dams, is one of the oldest forms of renewable energy. While it provides consistent power, it can damage ecosystems and displace communities. Because of these concerns, new projects must carefully balance benefits and risks.
Nuclear power is another low-carbon option. Although it does not emit greenhouse gases, it remains controversial due to the risk of accidents, radioactive waste, and high construction costs. Supporters argue that it is efficient and reliable, while critics worry about safety and long-term environmental damage.
One major challenge is energy storage. Because solar and wind power depend on the weather, energy must be stored for times when the sun isn‘t shining or the wind isn‘t blowing. Advances in battery technology are helping, but large-scale storage remains expensive and complex.
Energy access is also a global concern. Over 700 million people still lack electricity, mostly in sub-Saharan Africa and parts of Asia. Without reliable power, communities struggle to access healthcare, education, and clean water. Solving energy poverty is essential for achieving global development goals.
Affordability is another issue. As energy prices fluctuate due to conflict or supply disruptions, low-income households often suffer the most. To address this, some governments offer subsidies or invest in public infrastructure, while others promote local solutions like mini-grids or home-based solar systems.
Energy efficiency plays a vital role. By using appliances, buildings, and vehicles that consume less energy, societies can lower their carbon footprint and reduce demand. Not only does this save money, but it also helps slow environmental damage.
Transportation is a major energy consumer. The shift toward electric vehicles (EVs) aims to reduce oil dependence and emissions. However, charging infrastructure and battery production still pose challenges. If powered by renewable electricity, EVs can offer a greener future for mobility.
Industrial energy use is another area for reform. Factories, chemical plants, and data centers use vast amounts of electricity and heat. Transitioning these sectors to cleaner energy requires innovation, investment, and strong policy support. Without action, industrial emissions could continue rising.
Energy policies vary worldwide. Some countries have set ambitious goals for carbon neutrality, investing heavily in renewables and energy research. Others remain dependent on coal or oil due to economic or political reasons. This creates global tensions, especially as the effects of climate change become more severe.
International cooperation is essential. Climate agreements like the Paris Accord set shared targets, but success depends on national action. Because energy decisions affect everyone, collaboration on research, technology transfer, and investment is needed.
Fossil fuel industries resist change. They argue that their products are still necessary, especially in developing countries. However, critics say that continued investment in coal and oil locks the world into a dangerous path. The debate reflects deep divisions about responsibility, fairness, and the pace of transition.
Ultimately, the future of energy lies in balance. Societies must meet growing needs without destroying the environment. If managed wisely, energy can power sustainable growth, reduce inequality, and protect the planet.
However, if current trends continue unchecked, climate disasters, pollution, and energy shortages may worsen. The decisions made today will shape the energy landscape for generations to come.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to explain the importance of energy in modern life, discuss the problems associated with fossil fuels, present renewable and other low-carbon alternatives, examine challenges such as storage, access, and affordability, and emphasize the need for a balanced, sustainable energy future.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why are fossil fuels problematic despite dominating global energy use?',
        explanation: 'According to the passage, fossil fuels such as coal, oil, and natural gas are the main contributors to air pollution and climate change because they release greenhouse gases and cause environmental degradation through mining, drilling, and transportation.',
      ),
      ReadingQuestion(
        question: 'The word "replenished" in the paragraph about renewable energy most likely means',
        explanation: 'In the context of the passage, "replenished" most likely means naturally restored or renewed, as renewable energy sources like solar, wind, hydroelectric, geothermal, and biomass can be replenished naturally and have lower environmental impact.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about solar power from the passage?',
        explanation: 'It can be inferred that solar power has become more practical and widespread due to falling costs and improved technology, allowing solar panels to be used in homes, businesses, and large farms, and to operate independently in remote or off-grid areas.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is one major challenge of relying on solar and wind power?',
        explanation: 'According to the passage, one major challenge is energy storage because solar and wind power depend on the weather, so energy must be stored for times when the sun isn\'t shining or the wind isn\'t blowing, and large-scale storage remains expensive and complex despite advances in battery technology.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about energy access around the world?',
        explanation: 'It can be inferred that energy poverty remains a serious global problem, with over 700 million people—mostly in sub-Saharan Africa and parts of Asia—still lacking electricity, which limits access to healthcare, education, and clean water and hinders development goals.',
      ),
      ReadingQuestion(
        question: 'The phrase "carbon footprint" in the paragraph about energy efficiency most likely means',
        explanation: 'In the context of the passage, "carbon footprint" most likely means the total amount of greenhouse gas emissions produced by energy use, which societies can lower by using more efficient appliances, buildings, and vehicles.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what potential do electric vehicles offer if powered by renewable electricity?',
        explanation: 'According to the passage, if powered by renewable electricity, electric vehicles can offer a greener future for mobility by reducing oil dependence and emissions, although challenges remain with charging infrastructure and battery production.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of international cooperation in energy transition?',
        explanation: 'It can be inferred that international cooperation is essential because climate agreements like the Paris Accord set shared targets, but success depends on national action, and collaboration on research, technology transfer, and investment is needed since energy decisions affect everyone.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why do fossil fuel industries resist change?',
        explanation: 'According to the passage, fossil fuel industries resist change by arguing that their products are still necessary, especially in developing countries, while critics counter that continued investment in coal and oil locks the world into a dangerous path, reflecting deep divisions about responsibility, fairness, and the pace of transition.',
      ),
    ],
  ),

  ReadingPassage(
    id: 80,
    title: 'Climate',
    topic: 'Environment & Society',
    content: '''Climate refers to the long-term patterns of temperature, precipitation, humidity, and wind in a particular region. Whether discussing rising sea levels, melting glaciers, or extreme weather events, climate issues have become central to global debates on sustainability and development. Because the climate affects every aspect of human life, managing its impact is one of the greatest challenges of the 21st century.
Although climate has always changed over time, scientists agree that the current changes are primarily driven by human activity. Not only are greenhouse gases from burning fossil fuels heating the planet, but deforestation and industrial practices are intensifying the effect. This phenomenon is known as climate change, and its consequences are already visible.
One major impact is global warming. Average global temperatures have risen significantly over the last century, causing glaciers to melt and sea levels to rise. As a result, low-lying coastal regions face increased risk of flooding, erosion, and even disappearance. Countries such as Bangladesh, the Maldives, and parts of Indonesia are particularly vulnerable.
Another consequence is the increase in extreme weather. More frequent droughts, hurricanes, heatwaves, and floods are affecting both rich and poor countries. Because these events destroy homes, disrupt agriculture, and damage infrastructure, they lead to economic instability and human suffering. In some cases, they also trigger migration and conflict.
Agriculture is directly affected by climate. Changes in rainfall patterns and soil quality reduce crop yields, putting pressure on food systems. Farmers must adapt quickly, using drought-resistant seeds, new irrigation methods, or shifting to different crops. However, small-scale farmers in developing countries often lack the resources to make such changes.
Health is also at risk. Rising temperatures can increase the spread of diseases like malaria and dengue fever, especially in tropical areas. Air pollution and heat stress, both linked to climate change, contribute to respiratory and cardiovascular problems. As vulnerable groups suffer the most, climate change is also a social justice issue.
Despite the urgency, progress on climate action remains uneven. Some countries have committed to reducing carbon emissions, investing in renewable energy and promoting sustainability. Others, especially those dependent on fossil fuels, have been slower to act. Because climate change is a global issue, international cooperation is essential.
Agreements such as the Paris Accord aim to limit global temperature rise to 1.5– 2°C above pre-industrial levels. To achieve this, countries must reduce emissions, transition to clean energy, and protect natural carbon sinks like forests and oceans.
However, implementing these goals requires political will, financial investment, and public support.
Technological solutions are part of the answer. Solar panels, wind turbines, electric vehicles, and carbon capture systems offer ways to reduce emissions. Yet these tools alone are not enough. Lifestyle changes—such as reducing meat consumption, using public transport, and cutting energy waste—are also necessary. Economic policies must change too. Subsidies for fossil fuels need to be removed, and carbon taxes or emissions trading systems should be expanded. Such measures can encourage businesses to adopt cleaner technologies, while generating funds for climate adaptation and disaster relief.
Adaptation is as important as prevention. Communities must prepare for the effects of climate change that are already inevitable—by building flood barriers, managing water resources, and developing early-warning systems. If ignored, climate risks will continue to grow, hitting the poorest and most vulnerable first.
Public awareness is rising. Young people, in particular, are demanding stronger climate policies, organizing protests and influencing elections. This generational shift is pushing climate to the top of political agendas in many countries. However, without consistent action, awareness alone will not solve the problem. Some critics question the science behind climate change or argue that climate action harms economic growth. While scientific consensus is strong, misinformation continues to circulate online. In reality, the cost of inaction— through disaster recovery, health impacts, and lost productivity—is far higher than the cost of prevention.
Ultimately, climate is not just an environmental issue—it is an economic, social, and moral one. It shapes the future of food, water, health, migration, and security. If addressed with urgency and fairness, climate action can lead to innovation, green jobs, and a more sustainable world.
However, if delayed or ignored, the consequences will become irreversible. The window for meaningful change is closing, and the decisions made today will shape the climate for generations.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage defines climate and climate change, explains human-driven causes and major impacts such as global warming, extreme weather, effects on agriculture and health, discusses uneven progress and international agreements, and emphasizes the need for technological, lifestyle, economic, and adaptive measures to address this economic, social, and moral issue.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what primarily drives current climate changes according to scientists?',
        explanation: 'Scientists agree that current changes are primarily driven by human activity, including greenhouse gases from burning fossil fuels that heat the planet, as well as deforestation and industrial practices that intensify the effect.',
      ),
      ReadingQuestion(
        question: 'The word "vulnerable" in the paragraph about global warming most likely means',
        explanation: 'It means exposed to the possibility of being harmed or damaged, as low-lying coastal regions and countries such as Bangladesh, the Maldives, and parts of Indonesia face increased risk of flooding, erosion, and even disappearance.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the effects of extreme weather events caused by climate change?',
        explanation: 'More frequent droughts, hurricanes, heatwaves, and floods destroy homes, disrupt agriculture, and damage infrastructure, leading to economic instability, human suffering, and in some cases migration and conflict, affecting both rich and poor countries.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does climate change affect agriculture?',
        explanation: 'Changes in rainfall patterns and soil quality reduce crop yields and put pressure on food systems; farmers must adapt with drought-resistant seeds, new irrigation methods, or different crops, but small-scale farmers in developing countries often lack the resources to do so.',
      ),
      ReadingQuestion(
        question: 'The phrase "carbon sinks" in the paragraph about the Paris Accord most likely means',
        explanation: 'It refers to natural systems that absorb and store carbon, such as forests and oceans, which countries must protect along with reducing emissions and transitioning to clean energy to limit global temperature rise.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of international cooperation in addressing climate change?',
        explanation: 'Because climate change is a global issue, international cooperation is essential; agreements like the Paris Accord aim to limit temperature rise, but implementing goals requires political will, financial investment, and public support across countries.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is adaptation as important as prevention?',
        explanation: 'Communities must prepare for climate change effects that are already inevitable by building flood barriers, managing water resources, and developing early-warning systems; if ignored, climate risks will continue to grow and hit the poorest and most vulnerable first.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about public awareness and climate action?',
        explanation: 'Public awareness is rising, especially among young people who demand stronger policies, organize protests, and influence elections, pushing climate to the top of political agendas; however, without consistent action, awareness alone will not solve the problem.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does the cost of inaction compare to the cost of prevention?',
        explanation: 'The cost of inaction—through disaster recovery, health impacts, and lost productivity—is far higher than the cost of prevention, despite some critics arguing that climate action harms economic growth or questioning the science.',
      ),
    ],
  ),

  ReadingPassage(
    id: 81,
    title: 'Acid Rain',
    topic: 'Environment & Science',
    content: '''Acid rain refers to rainfall made acidic by pollutants in the atmosphere, especially sulfur dioxide (SO₂) and nitrogen oxides (NOₓ). Whether falling as rain, snow, fog, or dust, this form of precipitation has damaging effects on ecosystems, human health, and buildings. Because it travels long distances through the atmosphere, acid rain is considered a transboundary environmental problem.
Although the term ―acid rain‖ sounds dramatic, it often goes unnoticed. Not only is it invisible to the eye, but its harmful effects accumulate slowly over time. This makes it difficult for people to recognize the damage until it becomes severe.
The main sources of acid rain are the burning of fossil fuels—especially in power plants, factories, and vehicles. When coal or oil is burned, sulfur dioxide and nitrogen oxides are released into the air. These gases react with water vapor and other chemicals in the atmosphere to form sulfuric and nitric acid. Eventually, they return to Earth in the form of acidic precipitation.
One major impact of acid rain is on forests. It weakens trees by leaching essential nutrients from the soil, such as calcium and magnesium. It also damages leaves and bark, making trees more vulnerable to disease, cold, and insects. In high-altitude regions, where trees are already under stress, acid rain can be particularly destructive.
Lakes and rivers are also affected. When acid rain falls into freshwater bodies, it lowers the pH level, making the water too acidic for many aquatic organisms. Fish, amphibians, and insects struggle to survive in these altered conditions. Because young fish are more sensitive to pH changes, reproduction rates drop and fish populations decline. In some lakes, life has vanished entirely.
Soils suffer as well. Acid rain alters soil chemistry, washing away important minerals and releasing aluminum into the ground. Aluminum, in turn, can be toxic to plant roots. This chain reaction weakens ecosystems and reduces crop yields, posing a threat to agriculture.
Human health is indirectly impacted. Although acid rain itself does not harm people directly, the pollutants that cause it—especially fine particulate matter—can lead to respiratory problems such as asthma, bronchitis, and lung damage. Because industrial regions often produce more of these emissions, urban populations may be at greater risk.
Another consequence is damage to buildings and monuments. Acid rain reacts with the minerals in stone, concrete, and metal, causing erosion and discoloration. Historic structures made of limestone or marble are especially vulnerable. Famous landmarks like the Parthenon and the Taj Mahal have suffered visible damage due to acid deposition.
Despite these challenges, acid rain is a problem that can be addressed effectively. The most successful example is the United States' Acid Rain Program, launched in the 1990s. By introducing a cap-and-trade system for sulfur dioxide emissions, it encouraged companies to reduce pollution using cleaner technology. As a result, acid rain levels dropped dramatically over two decades.
Similar efforts in Europe also brought significant improvements. Because sulfur emissions declined by over 80% in many EU countries, many damaged lakes and forests are gradually recovering. However, problems remain in regions where industrial regulation is weak or absent. In parts of Asia and Eastern Europe, acid rain continues to pose a serious threat.
Technology and policy both play critical roles. Cleaner energy sources—such as natural gas, wind, and solar—emit fewer pollutants. Installing scrubbers in smokestacks and using low-sulfur fuels can also help. But unless governments enforce strict regulations and invest in monitoring, progress may be limited. Public awareness is key. Many people are unaware of how their energy use contributes to acid rain. Educating citizens about emissions, energy efficiency, and transportation choices can lead to better environmental outcomes. Because acid rain is largely preventable, lifestyle changes—combined with policy—can make a real difference.
Ultimately, acid rain highlights the hidden costs of industrial progress. It reminds us that pollution may travel far from its source, harming nature and people across borders. If action is taken early and collectively, ecosystems can be restored and future damage avoided.
However, if ignored or underestimated, the effects will spread silently—weakening forests, killing lakes, and eroding the world‘s cultural heritage.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of this passage is to explain what acid rain is, identify its main causes from fossil fuel burning, describe its damaging effects on forests, lakes, soils, human health, and buildings, and discuss how technology, policy, and public awareness can effectively reduce it as a preventable transboundary environmental problem.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are the main sources of the pollutants that cause acid rain?',
        explanation: 'The main sources are the burning of fossil fuels, especially in power plants, factories, and vehicles. When coal or oil is burned, sulfur dioxide and nitrogen oxides are released into the air, which then react with water vapor and other chemicals to form sulfuric and nitric acid.',
      ),
      ReadingQuestion(
        question: 'The word \'leaching\' in the passage most likely means?',
        explanation: 'It most likely means washing away or removing dissolved substances from the soil, as the passage states that acid rain weakens trees by leaching essential nutrients such as calcium and magnesium from the soil.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the success of efforts to reduce acid rain in the United States and Europe?',
        explanation: 'It can be inferred that strong policy measures can significantly reduce acid rain, as the United States\' Acid Rain Program using a cap-and-trade system led to dramatic drops in acid rain levels over two decades, and similar European efforts reduced sulfur emissions by over 80%, allowing many damaged lakes and forests to gradually recover.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does acid rain affect lakes and rivers?',
        explanation: 'Acid rain lowers the pH level of freshwater bodies, making the water too acidic for many aquatic organisms. Fish, amphibians, and insects struggle to survive, young fish are more sensitive so reproduction rates drop, populations decline, and in some lakes life has vanished entirely.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of public awareness in addressing acid rain?',
        explanation: 'It can be inferred that public awareness is essential for progress because many people do not realize how their energy use contributes to acid rain, and educating citizens about emissions, energy efficiency, and transportation choices, combined with policy, can lead to better environmental outcomes since the problem is largely preventable.',
      ),
    ],
  ),

  ReadingPassage(
    id: 82,
    title: 'Air Pollution',
    topic: 'Environment & Health',
    content: '''Air pollution refers to the release of harmful substances into the atmosphere, negatively affecting human health, the environment, and the global climate. Whether caused by factories, vehicles, or domestic activities, polluted air has become a serious issue in both developed and developing nations. Because air is a shared resource, pollution in one region can affect the health and environment of another.
Although many people associate pollution with visible smoke or smog, most pollutants are invisible and odorless. Not only do they go unnoticed by the human senses, but they can also enter the lungs and bloodstream without immediate symptoms. This makes air pollution particularly dangerous.
The most common pollutants include particulate matter (PM2.5 and PM10), nitrogen oxides (NOx), sulfur dioxide (SO₂), carbon monoxide (CO), and groundlevel ozone (O₃). Each of these substances harms the respiratory and cardiovascular systems, and some also damage crops, buildings, and ecosystems. Particulate matter, especially, has been linked to asthma, lung cancer, and reduced life expectancy.
The major sources of air pollution vary by region. In urban areas, traffic congestion is often the leading cause. When cars, buses, and trucks burn fuel, they emit carbon monoxide and nitrogen oxides. Because public transportation is underdeveloped in many cities, people rely heavily on private vehicles, increasing emissions further. In industrial regions, factories and power plants release vast amounts of smoke, dust, and toxic gases. Coal-fired power stations, in particular, are major contributors of sulfur dioxide and fine particles. If these facilities are not equipped with proper filtration systems, they pollute surrounding air and water sources. In rural areas, air pollution often comes from open burning and agricultural practices. Burning crop residues, wood, or animal waste releases large amounts of smoke. Indoor pollution, caused by cooking with biomass in poorly ventilated spaces, is also a major concern—especially for women and children in low-income countries.
The health effects of air pollution are severe. According to the World Health Organization, around 7 million people die prematurely each year due to air pollution-related causes. Children, the elderly, and people with pre-existing health conditions are especially vulnerable. Long-term exposure can cause chronic bronchitis, lung cancer, and even stroke.
Environmental consequences are equally damaging. Air pollution harms forests, acidifies water sources, and reduces agricultural productivity. For instance, ground-level ozone interferes with photosynthesis, weakening plant growth and reducing crop yields. Because ecosystems depend on clean air, pollution disrupts the balance of entire natural systems.
Air pollution is also a driver of climate change. Black carbon (soot) absorbs sunlight and contributes to atmospheric warming, while methane and ozone act as potent greenhouse gases. By reducing air pollution, countries can slow global warming and improve public health at the same time.
Several strategies exist to reduce pollution. Transitioning to renewable energy sources, such as wind and solar, can drastically cut emissions from power generation. Improving public transport and promoting electric vehicles reduces traffic-related emissions. Because many pollutants come from outdated infrastructure, modernizing factories and introducing clean technology are essential.
Policy and regulation play a key role. Countries with strict emission laws, like those in the European Union, have seen significant improvements in air quality. However, enforcement is often weak in developing regions, where economic growth is prioritized over environmental protection. Unless international standards are adopted, air pollution will continue to worsen globally.
Public awareness and behavior also matter. When individuals reduce car usage, avoid burning waste, and conserve energy, they contribute to cleaner air. Recycling, using eco-friendly products, and planting trees can also help mitigate pollution locally. Because the issue is both global and personal, action is needed at all levels.
Ultimately, air pollution is not just an environmental problem—it is a public health crisis. It shortens lives, damages ecosystems, and worsens climate change. If immediate and coordinated action is taken, much of the damage can still be reversed.
However, if ignored, air pollution will silently continue to erode the quality of life for billions. Clean air is a basic human right, and protecting it should be treated as a global priority.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to explain what air pollution is, identify its common pollutants and sources, describe its severe effects on human health, the environment, and climate, and outline strategies and the need for action to reduce it.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is air pollution particularly dangerous even when it is invisible?',
        explanation: 'Most pollutants are invisible and odorless, so they go unnoticed by human senses yet can enter the lungs and bloodstream without immediate symptoms.',
      ),
      ReadingQuestion(
        question: 'The word \'prematurely\' in the fifth paragraph most likely means...',
        explanation: 'Earlier than expected or before the natural time. The passage states that around 7 million people die prematurely each year due to air pollution-related causes according to the World Health Organization.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the sources of air pollution in different areas?',
        explanation: 'Sources vary by region: traffic congestion dominates in urban areas, factories and coal-fired power plants in industrial regions, and open burning plus indoor biomass cooking in rural and low-income settings, especially affecting women and children.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does air pollution affect the environment and agriculture?',
        explanation: 'It harms forests, acidifies water sources, and reduces agricultural productivity; ground-level ozone interferes with photosynthesis, weakening plant growth and reducing crop yields, thereby disrupting entire ecosystems.',
      ),
      ReadingQuestion(
        question: 'The phrase \'groundlevel ozone\' in the third paragraph most likely refers to...',
        explanation: 'Ozone present near the Earth\'s surface (as opposed to the protective ozone layer higher up), listed among common pollutants that harm respiratory and cardiovascular systems and damage crops and ecosystems.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the link between air pollution and climate change?',
        explanation: 'Air pollution drives climate change because black carbon absorbs sunlight and warms the atmosphere while methane and ozone act as potent greenhouse gases; reducing air pollution can therefore slow global warming and improve public health simultaneously.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what strategies can help reduce air pollution?',
        explanation: 'Strategies include transitioning to renewable energy such as wind and solar, improving public transport and promoting electric vehicles, modernizing factories with clean technology, enforcing strict emission laws, and individual actions like reducing car use and planting trees.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about policy differences between regions?',
        explanation: 'Countries with strict emission laws, such as those in the European Union, have seen significant air-quality improvements, whereas enforcement is often weak in developing regions that prioritize economic growth, so international standards are needed to prevent worsening pollution.',
      ),
      ReadingQuestion(
        question: 'According to the passage, who is especially vulnerable to the health effects of air pollution?',
        explanation: 'Children, the elderly, and people with pre-existing health conditions are especially vulnerable; long-term exposure can cause chronic bronchitis, lung cancer, and even stroke.',
      ),
    ],
  ),

  ReadingPassage(
    id: 83,
    title: 'Water Pollution',
    topic: 'Environment & Health',
    content: '''Water pollution occurs when harmful substances contaminate rivers, lakes, oceans, or groundwater, making the water unsafe for humans, animals, and plants. Whether the pollutants come from factories, farms, or households, water pollution has become a serious threat to both the environment and public health. Because clean water is essential for life, this issue demands immediate global attention.
Although water covers about 70% of the Earth‘s surface, only a small portion is suitable for drinking or irrigation. Not only is fresh water limited, but it is also under increasing pressure due to population growth, industrialization, and climate change. This makes water pollution not just an environmental problem—but also a social and economic one.
The most common sources of water pollution include:
•        Industrial waste: Many factories discharge chemicals, heavy metals, and toxic substances directly into rivers or lakes. When these pollutants are not treated properly, they poison aquatic life and contaminate drinking water supplies.
•        Agricultural runoff: Fertilizers and pesticides used in farming often wash into nearby water bodies during rainfall. This runoff causes nutrient pollution, which can lead to algal blooms, oxygen depletion, and the death of fish.
•        Sewage and wastewater: In many parts of the world, untreated human waste is dumped into open water. Because of poor infrastructure, millions of people rely on polluted rivers for bathing, cooking, or drinking.
•        Plastic waste: Bottles, bags, and microplastics have reached even the deepest parts of the ocean. These materials take centuries to decompose, and marine animals often mistake them for food.
One of the most dangerous effects of water pollution is the spread of disease. Contaminated water carries bacteria, viruses, and parasites, causing illnesses such as cholera, dysentery, and typhoid fever. In some developing countries, waterborne diseases are among the leading causes of death—especially among children.
Water pollution also affects ecosystems. Toxic substances can kill fish, birds, and other wildlife, while disrupting the food chain. In some cases, entire aquatic ecosystems collapse. Coral reefs, for instance, are particularly sensitive to changes in water quality and temperature.
Another major concern is groundwater contamination. Unlike rivers and lakes, underground water is harder to monitor and clean. When chemicals or waste seep into the soil, they can pollute wells and aquifers. Because groundwater provides drinking water for billions, protecting it is critical.
Economic impacts are significant too. Polluted water hurts agriculture, tourism, and fishing industries. Farmers depend on clean water to grow crops and feed livestock. If irrigation water contains harmful substances, food safety can be compromised. Similarly, polluted beaches and lakes reduce tourism and recreational activities, affecting local economies.
Governments have a key role to play. Stricter regulations on industrial discharge, investment in sewage treatment plants, and enforcement of anti-dumping laws are essential. In countries where these measures have been implemented, water quality has improved significantly.
Technological solutions are available. Water purification systems, advanced filtration, and eco-friendly farming practices can reduce pollution. However, if these tools are too expensive or unavailable, poorer communities may not benefit from them.
Public awareness is just as important. People often pollute water without realizing it—by pouring oil down drains, using chemical cleaners, or wasting plastic. Education and community engagement can lead to better waste management and conservation habits. Because everyone uses water, everyone must take part in protecting it.
Climate change is making the problem worse. Rising temperatures, longer droughts, and extreme floods affect both the quantity and quality of water. If action is not taken, many regions will face both water scarcity and increased pollution.
Some argue that economic growth justifies certain levels of pollution. They claim that industries must use natural resources to develop, and that regulation can hurt job creation. While this may be true in the short term, long-term damage to health and the environment is far more costly.
Ultimately, water pollution threatens health, ecosystems, and economic stability. The causes are well-known, and the solutions exist. If immediate, coordinated action is taken, the world‘s water resources can be protected and restored.
However, if ignored, polluted water will continue to kill, contaminate, and degrade life on Earth—drop by drop.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to explain water pollution as a serious environmental, social, and economic threat, outline its common sources and effects on health, ecosystems, and economies, discuss the roles of governments, technology, and public awareness, and urge immediate coordinated action to protect and restore water resources.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are the most common sources of water pollution?',
        explanation: 'The most common sources include industrial waste (chemicals, heavy metals, toxic substances), agricultural runoff (fertilizers and pesticides causing nutrient pollution), sewage and wastewater (untreated human waste), and plastic waste (bottles, bags, and microplastics that harm marine life).',
      ),
      ReadingQuestion(
        question: 'The term "nutrient pollution" in the third paragraph most likely means',
        explanation: 'In the context of fertilizers and pesticides washing into water bodies and leading to algal blooms, oxygen depletion, and the death of fish, nutrient pollution refers to excess nutrients in water that disrupt ecosystems by promoting excessive algae growth.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the availability of fresh water?',
        explanation: 'Although water covers about 70% of the Earth\'s surface, only a small portion is suitable for drinking or irrigation, and it is under increasing pressure from population growth, industrialization, and climate change, making pollution both an environmental and a socio-economic problem.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does water pollution affect human health?',
        explanation: 'Contaminated water spreads disease by carrying bacteria, viruses, and parasites that cause illnesses such as cholera, dysentery, and typhoid fever; in some developing countries, waterborne diseases are among the leading causes of death, especially among children.',
      ),
      ReadingQuestion(
        question: 'The word "aquifers" in the seventh paragraph most likely means',
        explanation: 'In the context of chemicals or waste seeping into the soil and polluting wells and aquifers that provide drinking water for billions, aquifers refer to underground layers of water-bearing rock or sediment that hold groundwater.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the economic impacts of water pollution?',
        explanation: 'Polluted water harms agriculture by compromising food safety through contaminated irrigation, damages tourism and recreational activities at polluted beaches and lakes, and hurts fishing industries, thereby affecting local economies significantly.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what role should governments play in addressing water pollution?',
        explanation: 'Governments should implement stricter regulations on industrial discharge, invest in sewage treatment plants, and enforce anti-dumping laws; where these measures have been applied, water quality has improved significantly.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the relationship between climate change and water pollution?',
        explanation: 'Climate change worsens the problem through rising temperatures, longer droughts, and extreme floods that affect both the quantity and quality of water, potentially leading to both water scarcity and increased pollution in many regions if action is not taken.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is public awareness important in fighting water pollution?',
        explanation: 'People often pollute water unknowingly by pouring oil down drains, using chemical cleaners, or wasting plastic; education and community engagement can improve waste management and conservation habits, and since everyone uses water, everyone must help protect it.',
      ),
    ],
  ),

  ReadingPassage(
    id: 84,
    title: 'Recycling',
    topic: 'Environment & Sustainability',
    content: '''Recycling refers to the process of converting waste materials into reusable products. Whether it involves paper, plastic, glass, or metal, recycling plays a key role in managing waste and conserving resources. Because modern societies generate enormous amounts of garbage, recycling has become a critical part of sustainable development.
Although many countries have implemented recycling programs, results vary greatly. Not only does recycling depend on technology and infrastructure, but also on public awareness and behavior. If properly supported, recycling can reduce pollution, save energy, and lower the pressure on landfills.
One of the main benefits of recycling is environmental protection. When materials like paper and plastic are recycled, fewer natural resources are extracted from the Earth. For instance, recycling one ton of paper can save 17 trees and 7,000 gallons of water. This is especially important, given the ongoing deforestation and water scarcity in many regions.
Recycling also helps reduce greenhouse gas emissions. Producing goods from recycled materials often uses less energy than making them from raw materials. For example, making aluminum from recycled metal uses 95% less energy than producing it from ore. Because energy production is a major source of carbon emissions, recycling supports the fight against climate change.
Another advantage is waste reduction. Landfills are filling up quickly, and many cities are running out of space for new ones. By diverting waste from landfills, recycling extends their lifespan and reduces soil and water contamination. This is especially true for toxic materials, such as batteries and electronics, which should never be dumped in ordinary trash.
Despite these benefits, recycling also has limitations. Not all materials are recyclable, and some, like mixed plastics or greasy food containers, can contaminate entire batches of recyclables. Although modern facilities can sort and clean waste, they require significant investment and advanced systems. Without such technology, recycling becomes inefficient or even counterproductive. In some cases, recycling costs more than disposal. Collection, sorting, and processing require time, labor, and machinery. If the market for recycled materials is weak, municipalities may lose money. Because of these concerns, some governments have reduced their recycling targets or outsourced waste processing to other countries.
Another issue is public participation. Recycling programs depend heavily on individuals sorting their waste correctly. If people mix recyclables with regular garbage, or fail to clean them, the system breaks down. Education campaigns and incentives are needed, but success varies by region and culture.
Some experts argue that recycling is only one part of the solution, and that reducing consumption is more important. They point out that avoiding waste in the first place—by buying less, reusing items, or choosing sustainable products—is more effective than dealing with waste afterward. This approach is often
summarized by the slogan: ―Reduce, Reuse, Recycle.‖
Technology offers potential improvements. Advanced sorting machines, chemical recycling methods, and biodegradable materials are making recycling more efficient. If widely adopted, these innovations could reduce dependence on landfills and incineration.
Government policies are also critical. Banning single-use plastics, taxing landfill disposal, and setting recycling quotas can push businesses and individuals toward more sustainable practices. In countries like Germany, South Korea, and Sweden, strong regulation has led to high recycling rates and low landfill use.
On the other hand, some critics argue that recycling is promoted as a distraction, allowing companies to continue producing excessive packaging and waste. They believe that real change must come from regulation, not just personal responsibility. Unless production is addressed, they say, recycling will remain a temporary fix.
Ultimately, recycling is a practical and necessary tool for waste management—but it is not a complete solution. It works best when combined with waste reduction, sustainable design, and strong public policy. If integrated into a broader environmental strategy, recycling can significantly benefit both people and the planet.
However, if treated as a quick fix or left to individuals alone, it risks becoming ineffective or even misleading.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage explains the benefits, limitations, and broader context of recycling, arguing that it is a useful but incomplete solution that works best when combined with waste reduction, sustainable design, and strong policy.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is one major environmental benefit of recycling paper?',
        explanation: 'Recycling one ton of paper can save 17 trees and 7,000 gallons of water, which helps address deforestation and water scarcity.',
      ),
      ReadingQuestion(
        question: 'The word "diverting" in the fifth paragraph most likely means',
        explanation: 'In context, diverting means redirecting or keeping waste away from landfills so that materials can be recycled instead of being buried.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the energy savings from recycling aluminum?',
        explanation: 'Making aluminum from recycled metal uses 95% less energy than producing it from ore, which significantly reduces greenhouse gas emissions linked to energy production.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why can recycling sometimes be inefficient?',
        explanation: 'Not all materials are recyclable, and contaminants such as mixed plastics or greasy containers can spoil entire batches; without advanced sorting technology and investment, the process becomes inefficient or counterproductive.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the economic challenges of recycling?',
        explanation: 'Collection, sorting, and processing involve high costs, and if the market for recycled materials is weak, municipalities may lose money, leading some governments to lower targets or outsource processing.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is public participation essential for recycling programs?',
        explanation: 'Programs depend on individuals correctly sorting and cleaning recyclables; mixing them with regular garbage or failing to clean them causes the system to break down.',
      ),
      ReadingQuestion(
        question: 'The slogan "Reduce, Reuse, Recycle" in the eighth paragraph most likely emphasizes',
        explanation: 'The slogan prioritizes avoiding waste by buying less and reusing items first, with recycling as a later step, because reducing consumption is more effective than managing waste afterward.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of government policies in recycling success?',
        explanation: 'Strong regulations such as banning single-use plastics, taxing landfill disposal, and setting quotas have enabled high recycling rates and low landfill use in countries like Germany, South Korea, and Sweden.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what do some critics believe about the promotion of recycling?',
        explanation: 'Critics argue that recycling is sometimes promoted as a distraction that allows companies to keep producing excessive packaging and waste, and that real change requires addressing production through regulation rather than relying only on individual responsibility.',
      ),
    ],
  ),

  ReadingPassage(
    id: 85,
    title: 'Environment',
    topic: 'Environment & Science',
    content: '''The environment includes all natural surroundings—air, water, soil, climate, and biodiversity—that support life on Earth. Whether we live in cities, villages, or forests, we depend on the environment for food, shelter, clean air, and water.
Because human activity increasingly disrupts natural systems, environmental protection has become one of the most urgent global challenges.
Although people have always interacted with nature, the scale and speed of environmental degradation in recent decades are unprecedented. Not only has deforestation accelerated, but air and water pollution, overfishing, and species extinction have also reached dangerous levels. If left unaddressed, these changes could permanently damage the Earth‘s ecosystems.
One major concern is climate change. Caused primarily by the burning of fossil fuels, climate change leads to rising global temperatures, melting ice caps, and extreme weather. Because greenhouse gases trap heat in the atmosphere, they upset weather patterns, threaten food security, and increase the frequency of droughts, floods, and storms.
Another issue is pollution. Industries, vehicles, and plastic waste all contribute to air, water, and soil contamination. When pollutants enter rivers or the atmosphere, they affect not only human health but also the survival of wildlife. This is especially harmful in developing countries, where waste treatment systems are often inadequate or non-existent.
Deforestation is another threat. Forests act as carbon sinks, absorbing CO₂ and protecting biodiversity. When trees are cut down for agriculture, mining, or construction, ecosystems collapse, and soil quality declines. Tropical rainforests, in particular, are being lost at alarming rates, often to grow cash crops like soy or palm oil.
Biodiversity loss is closely linked to environmental harm. As habitats are destroyed and climate changes, many plant and animal species are unable to adapt. Some scientists estimate that we are losing dozens of species every day, which weakens ecosystems and reduces genetic diversity.
Urbanization contributes to these problems. As more people move to cities, green spaces are replaced by concrete, increasing air pollution and reducing access to nature. Although cities offer economic opportunities, they also produce large amounts of waste and consume vast energy resources. Unless urban planning becomes more sustainable, environmental stress will only worsen.
The oceans are also under threat. Plastic waste, overfishing, and oil spills have damaged marine ecosystems, while rising temperatures cause coral bleaching and disrupt migration patterns. Because oceans regulate global temperatures and provide food, their degradation has global consequences.
Governments have a key role in protecting the environment. By enforcing environmental laws, regulating emissions, and preserving natural areas, they can prevent damage and promote restoration. Some countries have made progress, introducing green energy, reducing deforestation, or investing in public transport. However, in many places, economic growth is still prioritized over ecological balance.
Technology can offer solutions. Solar and wind energy reduce dependence on fossil fuels, while electric vehicles and energy-efficient buildings lower emissions. If such technologies become affordable and widely used, they could help shift economies towards sustainability.
Individual actions matter too. Recycling, conserving water, reducing plastic use, and eating less meat are simple ways to reduce environmental impact. Because consumer behavior influences industry, widespread lifestyle changes can drive broader reforms.
Education and awareness are essential. People need to understand the causes and consequences of environmental damage, as well as the steps they can take to help. Without public support and pressure, many governments will not act quickly enough to solve the crisis.
Critics argue that some environmental measures are too expensive or unrealistic. They claim that strict regulations can slow economic growth or cause job losses, especially in sectors like mining or oil. While this may be true in the short term, long-term environmental damage will be far more costly and irreversible.
Ultimately, protecting the environment is not a choice—it is a necessity. It requires cooperation between governments, businesses, communities, and individuals. If action is taken now, ecosystems can recover, and future generations can inherit a livable planet.
However, if current trends continue, the damage may reach a point where recovery is no longer possible. The decisions made today will shape the Earth‘s future for centuries.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage defines the environment and explains major threats such as climate change, pollution, deforestation, biodiversity loss, urbanization, and ocean degradation, while outlining roles for governments, technology, individuals, and education, and concluding that protection is a necessity requiring immediate cooperation.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is the primary cause of climate change?',
        explanation: 'The passage states that climate change is caused primarily by the burning of fossil fuels, which leads to rising global temperatures, melting ice caps, and extreme weather.',
      ),
      ReadingQuestion(
        question: 'The term "carbon sinks" in the passage most likely means',
        explanation: 'In context, carbon sinks refers to forests that absorb CO₂ and protect biodiversity, so that when trees are cut down ecosystems collapse and soil quality declines.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the rate of biodiversity loss?',
        explanation: 'The passage notes that some scientists estimate we are losing dozens of species every day as habitats are destroyed and climate changes, weakening ecosystems and reducing genetic diversity.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does urbanization contribute to environmental problems?',
        explanation: 'The passage explains that as more people move to cities, green spaces are replaced by concrete, increasing air pollution and reducing access to nature, while cities produce large amounts of waste and consume vast energy resources.',
      ),
      ReadingQuestion(
        question: 'The word "degradation" in the discussion of the oceans most likely means',
        explanation: 'In context, degradation refers to the damage to marine ecosystems from plastic waste, overfishing, oil spills, and rising temperatures that cause coral bleaching and disrupt migration patterns.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of technology in addressing environmental issues?',
        explanation: 'The passage states that solar and wind energy reduce dependence on fossil fuels, while electric vehicles and energy-efficient buildings lower emissions, and that if such technologies become affordable and widely used they could help shift economies towards sustainability.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what individual actions can help reduce environmental impact?',
        explanation: 'The passage lists recycling, conserving water, reducing plastic use, and eating less meat as simple ways to reduce environmental impact, noting that consumer behavior influences industry.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the arguments of critics of environmental measures?',
        explanation: 'The passage states that critics claim some measures are too expensive or unrealistic and that strict regulations can slow economic growth or cause job losses, but it counters that long-term environmental damage will be far more costly and irreversible.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is protecting the environment described as a necessity rather than a choice?',
        explanation: 'The passage concludes that protection requires cooperation among governments, businesses, communities, and individuals, and that if action is taken now ecosystems can recover, but if current trends continue the damage may become irreversible, shaping the Earth‘s future for centuries.',
      ),
    ],
  ),

  ReadingPassage(
    id: 86,
    title: 'Natural Disasters',
    topic: 'Environment & Science',
    content: '''Natural disasters are sudden and extreme events caused by natural forces that result in significant damage to life, property, and the environment. Whether it is an earthquake, hurricane, flood, drought, or wildfire, these events disrupt societies and economies across the world. Because their impact can be devastating and widespread, preparing for natural disasters is a major global concern.
Although natural disasters have occurred throughout history, their frequency and intensity appear to be increasing. Not only are more people being affected, but the economic losses are also growing, especially in densely populated and poorly prepared regions. This trend raises questions about climate change, urban planning, and disaster management.
Earthquakes are among the most destructive disasters. They strike without warning and can cause buildings to collapse, trigger landslides, and damage infrastructure. Regions along tectonic plate boundaries, such as Japan, Turkey, and Chile, are particularly vulnerable. If construction standards are weak, the death toll can be much higher.
Floods are the most common natural disaster. Heavy rainfall, river overflow, and poor drainage systems can cause widespread flooding in both rural and urban areas. Because floods can destroy homes, contaminate water, and displace communities, their social and economic effects can last for years. In some places, entire villages are submerged.
Tropical storms—known as hurricanes, typhoons, or cyclones depending on the region—bring powerful winds, heavy rain, and storm surges. Coastal cities are especially at risk. When a storm makes landfall, it can cut off electricity, flood roads, and damage hospitals, making emergency response extremely difficult.
Droughts occur when there is a prolonged shortage of rainfall. This leads to water scarcity, crop failure, and food insecurity. Because many regions depend on rainfall for agriculture, droughts can destroy livelihoods and cause mass migration. Sub-Saharan Africa and parts of South Asia are frequently affected.
Wildfires are another growing concern. Often sparked by heat, lightning, or human negligence, wildfires can spread rapidly, destroying forests, homes, and wildlife. In recent years, countries like Australia, the United States, and Greece have experienced record-breaking fire seasons, fueled by rising temperatures and dry conditions.
Volcanic eruptions, though less frequent, can be highly destructive. Lava, ash, and toxic gases can threaten nearby populations and disrupt global air travel. If ash reaches the atmosphere, it can also influence climate patterns by blocking sunlight. The human cost of natural disasters is enormous. Thousands of lives are lost each year, and millions are left injured, homeless, or traumatized. The economic cost is also staggering—damaged infrastructure, lost productivity, and emergency aid create massive financial burdens for governments and communities. Developing countries suffer the most, as they often lack the resources for preparation and recovery.
However, not all disasters are equally deadly. Countries with strong emergency systems, early warning technology, and public education campaigns tend to experience fewer casualties. Japan, for example, has invested heavily in earthquake-resistant buildings, which significantly reduce the damage when quakes occur. This shows that preparedness, not just wealth, determines outcomes.
Climate change is believed to be increasing the severity and frequency of certain disasters. Warmer oceans feed stronger storms, and changing rainfall patterns lead to more intense floods and droughts. If greenhouse gas emissions continue unchecked, scientists warn that natural disasters will become more frequent and unpredictable.
Governments play a central role in disaster management. They must invest in risk assessment, infrastructure, emergency training, and public education. Early warning systems and evacuation plans can save thousands of lives. Unfortunately, in many countries, disaster preparation is underfunded and poorly implemented.
International cooperation is essential. When disasters strike, humanitarian aid, medical teams, and financial support are often needed from other nations.
Organizations like the Red Cross, UN, and Médecins Sans Frontières play critical roles in response and recovery efforts. But long-term resilience requires more than just emergency aid—it needs planning and prevention.
Technology offers new possibilities. Satellites, drones, and AI-based prediction systems can help detect risks and monitor damage in real time. If used effectively, these tools can improve decision-making and speed up emergency response.
Individual action matters too. People can prepare emergency kits, follow safety protocols, and stay informed about risks in their region. Community-based disaster preparedness programs are especially useful in educating residents and building local resilience.
Critics argue that governments focus too much on rebuilding and not enough on prevention. They suggest that money is often wasted on temporary relief, while long-term solutions—like reforestation, sustainable farming, and climate adaptation—are ignored. Without addressing root causes, disasters will continue to hit the same regions again and again.
Ultimately, natural disasters are unavoidable—but their impact is not. With early warning systems, better planning, stronger infrastructure, and public education, many lives can be saved. If societies invest in resilience and act before disasters strike, the damage can be reduced and recovery made faster.
However, if we continue to ignore science, delay action, and underfund disaster response, the next crisis may be even more deadly.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to describe various types of natural disasters, their increasing frequency and impacts, the role of climate change and preparedness, and the importance of prevention, technology, and international cooperation in reducing harm.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why are earthquakes particularly dangerous?',
        explanation: 'Earthquakes strike without warning and can cause buildings to collapse, trigger landslides, and damage infrastructure, with higher death tolls in regions that have weak construction standards.',
      ),
      ReadingQuestion(
        question: 'The word "submerged" in the fourth paragraph most likely means...',
        explanation: 'In the context of the passage, "submerged" means completely covered or flooded by water, referring to entire villages being underwater during floods.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the relationship between preparedness and disaster outcomes?',
        explanation: 'It can be inferred that preparedness, such as strong emergency systems and earthquake-resistant buildings, is more important than wealth alone in reducing casualties and damage.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does climate change affect natural disasters?',
        explanation: 'Climate change is believed to increase the severity and frequency of certain disasters by warming oceans that feed stronger storms and altering rainfall patterns that lead to more intense floods and droughts.',
      ),
      ReadingQuestion(
        question: 'The word "resilience" in the passage most likely means...',
        explanation: 'In the context of the passage, "resilience" means the ability of communities and systems to prepare for, withstand, and recover quickly from disasters through planning and prevention.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the challenges faced by developing countries?',
        explanation: 'It can be inferred that developing countries suffer the most from natural disasters because they often lack the resources needed for effective preparation and recovery.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what role do international organizations play?',
        explanation: 'Organizations like the Red Cross, UN, and Médecins Sans Frontières provide humanitarian aid, medical teams, and financial support during disaster response and recovery efforts.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the authors\' view on prevention versus rebuilding?',
        explanation: 'It can be inferred that the passage supports greater focus on prevention and long-term solutions such as reforestation and climate adaptation, rather than relying mainly on temporary relief and rebuilding after disasters occur.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how can individuals contribute to disaster preparedness?',
        explanation: 'Individuals can prepare emergency kits, follow safety protocols, stay informed about local risks, and participate in community-based disaster preparedness programs to build local resilience.',
      ),
    ],
  ),

  ReadingPassage(
    id: 87,
    title: 'Global Warming',
    topic: 'Environment & Climate',
    content: '''Global warming refers to the long-term rise in Earth‘s average surface temperature, largely caused by human activities such as burning fossil fuels and deforestation. Whether it is melting glaciers, rising sea levels, or more frequent heatwaves, the signs of global warming are now visible on every continent. Because the Earth's climate is a delicate system, even small shifts in temperature can have widereaching consequences.
Although climate has changed naturally throughout history, the current pace and scale of warming are unprecedented. Not only is the planet warming faster than ever, but scientists agree that human activity is the dominant cause. If emissions are not reduced, the damage could become irreversible within decades.
The main cause of global warming is the greenhouse effect. When fossil fuels like coal, oil, and gas are burned, they release carbon dioxide (CO₂), methane (CH₄), and other gases into the atmosphere. These gases trap heat from the sun, preventing it from escaping into space and causing global temperatures to rise. Deforestation also plays a role, since trees absorb CO₂, and cutting them down reduces this capacity.
The impacts of global warming are already being felt. Rising sea levels threaten low-lying coastal areas, while more frequent droughts and floods affect agriculture and food supply. Extreme weather events—such as hurricanes, wildfires, and heatwaves—have become more intense, causing billions in damage and displacing millions of people.
Because polar regions are warming faster than the global average, ice sheets in Greenland and Antarctica are melting rapidly. If this trend continues, major cities like New York, Jakarta, and Dhaka could be underwater within a century. Island nations like the Maldives face an even more immediate threat.
Ecosystems are also under stress. Warmer temperatures are shifting growing seasons, disrupting animal migration patterns, and causing coral reefs to bleach and die. Species that cannot adapt quickly enough may face extinction, reducing biodiversity and weakening natural ecosystems.
The economic cost of global warming is enormous. Crop failures, property damage, healthcare costs, and disaster response all add up to billions of dollars annually. Developing countries suffer the most, as they often lack the infrastructure and resources to adapt.
Global warming is also a social issue. As resources like water and farmland become scarce, conflicts over land and migration may increase. Climate refugees—people forced to leave their homes due to environmental changes—are becoming more common. This places additional pressure on governments and international organizations.
Solutions exist, but they require coordinated effort. Reducing greenhouse gas emissions is the most urgent priority. This can be done by shifting to renewable energy sources, such as solar, wind, and hydro, improving energy efficiency, and reforming transportation systems. If countries work together, emissions can be cut while still supporting economic growth.
The Paris Agreement, signed by nearly every nation, aims to limit global warming to below 2°C, and preferably 1.5°C, above pre-industrial levels. Although the goals are clear, progress has been slow. Some countries are taking bold action, while others continue to rely on coal and oil.
Technology offers promising solutions. Carbon capture and storage (CCS), electric vehicles, sustainable agriculture, and green building practices can help reduce emissions. However, if these technologies remain expensive or underdeveloped, they may not be adopted quickly enough.
Individual choices matter too. By conserving energy, reducing meat consumption, minimizing waste, and supporting eco-friendly products, people can reduce their personal carbon footprint. Public pressure on governments and companies can also lead to policy changes.
Some argue that focusing on economic growth is more important than environmental protection. They claim that climate action may slow industrial development, especially in poor countries. While this may seem logical in the short term, the long-term cost of inaction will be far greater.
Ultimately, global warming is the defining challenge of our time. It affects not just the environment, but also health, security, and the global economy. If we act decisively, reduce emissions, and adapt wisely, it is still possible to avoid the worst outcomes.
However, if delay and denial continue, the consequences will reshape life on Earth for generations to come—and those who suffer most may be the ones least responsible.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to explain global warming as a human-caused rise in Earth‘s temperature, describing its causes, widespread impacts, and the urgent need for coordinated solutions involving emissions reductions, technology, and individual action.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is the main cause of global warming?',
        explanation: 'According to the passage, the main cause is the greenhouse effect, in which burning fossil fuels releases gases like carbon dioxide and methane that trap heat in the atmosphere, with deforestation further reducing the planet‘s capacity to absorb CO₂.',
      ),
      ReadingQuestion(
        question: 'The word "unprecedented" in the second paragraph most likely means',
        explanation: 'In the context of the second paragraph, "unprecedented" means never known or experienced before, emphasizing that the current pace and scale of warming are unlike any natural climate changes in history.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the threat to low-lying areas and island nations?',
        explanation: 'It can be inferred that rapid melting of polar ice sheets could submerge major coastal cities within a century and poses an even more immediate existential threat to low-lying island nations such as the Maldives.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are some already visible impacts of global warming?',
        explanation: 'According to the passage, visible impacts include rising sea levels, more frequent droughts and floods affecting agriculture, and intensified extreme weather events such as hurricanes, wildfires, and heatwaves that cause damage and displacement.',
      ),
      ReadingQuestion(
        question: 'The term "climate refugees" in the eighth paragraph most likely refers to',
        explanation: 'In the context of the eighth paragraph, "climate refugees" refers to people forced to leave their homes due to environmental changes caused by global warming, adding pressure on governments and international organizations.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the Paris Agreement?',
        explanation: 'It can be inferred that while nearly every nation has signed the Paris Agreement aiming to limit warming to below 2°C (preferably 1.5°C), progress remains slow because some countries continue heavy reliance on coal and oil despite the clear goals.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how can individuals help address global warming?',
        explanation: 'According to the passage, individuals can reduce their carbon footprint by conserving energy, reducing meat consumption, minimizing waste, and supporting eco-friendly products, while also applying public pressure on governments and companies for policy changes.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the economic argument against climate action?',
        explanation: 'It can be inferred that although some claim climate action may slow industrial development especially in poor countries, the passage argues that the long-term cost of inaction will far outweigh any short-term economic concerns.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why are developing countries particularly affected by global warming?',
        explanation: 'According to the passage, developing countries suffer the most from the economic costs of global warming because they often lack the infrastructure and resources needed to adapt to crop failures, property damage, and other climate-related impacts.',
      ),
    ],
  ),

  ReadingPassage(
    id: 88,
    title: 'AIDS',
    topic: 'Health & Science',
    content: '''AIDS, which stands for Acquired Immune Deficiency Syndrome, is a lifethreatening condition caused by the Human Immunodeficiency Virus (HIV). It weakens the immune system by attacking the body‘s defense cells, making it difficult to fight infections and diseases. Since it was first identified in the early 1980s, AIDS has become one of the most serious global health issues, affecting millions of people worldwide.
HIV is transmitted through certain bodily fluids, including blood, semen, vaginal fluids, and breast milk. The most common ways it spreads are through unprotected sexual contact, sharing needles, transfusion of infected blood, and from mother to child during childbirth or breastfeeding. It is not transmitted through casual contact like hugging, shaking hands, or sharing food.
Once a person is infected with HIV, the virus begins to destroy CD4 cells, which are crucial for immune defense. Over time, if untreated, the immune system becomes too weak to fight off infections or cancers. When this stage is reached, the person is said to have AIDS. Without treatment, AIDS is fatal. However, with proper care, people with HIV can live long and healthy lives without developing AIDS.
The symptoms of HIV may not appear for years after infection. When they do, they often include fever, weight loss, fatigue, swollen lymph nodes, and recurring infections. Once AIDS develops, symptoms may include severe respiratory infections, neurological issues, cancers such as Kaposi's sarcoma, and opportunistic infections that a healthy immune system would normally control. Testing and early diagnosis are crucial. HIV can be detected through blood or saliva tests. Early treatment reduces the risk of complications and prevents the spread of the virus to others. It is recommended that people at higher risk—such as those with multiple sexual partners or who share needles—get tested regularly. Antiretroviral therapy (ART) is the standard treatment for HIV. It involves a combination of medications that reduce the amount of virus in the body. While ART does not cure HIV, it allows the immune system to recover and reduces the risk of transmission. People on ART can lead productive lives, work, and have families without infecting others if the treatment is properly followed.
Preventing HIV involves several strategies. The most effective is using protection during sex and avoiding the sharing of needles. Education campaigns have helped raise awareness about how HIV spreads and how it can be prevented. Pre-exposure prophylaxis (PrEP), a medication taken by people at high risk, can prevent infection before exposure.
Despite medical progress, stigma remains a major barrier. Many people living with HIV face discrimination at work, in healthcare settings, or within their communities. This stigma discourages people from getting tested, disclosing their status, or seeking treatment. Public education is essential to reduce fear and misinformation about HIV/AIDS.
Globally, efforts to fight AIDS have improved, but the problem persists. SubSaharan Africa remains the most affected region, accounting for nearly two-thirds of all people living with HIV. Many people there still lack access to testing, treatment, and prevention tools. Women and young people are particularly vulnerable.
International organizations such as UNAIDS, the World Health Organization, and non-governmental groups work together to fund treatment programs, distribute medication, and promote awareness. Advances in research continue, including efforts to develop vaccines or even a functional cure. So far, however, there is no vaccine or complete cure for HIV.
Children born to HIV-positive mothers can now be protected through medical interventions during pregnancy and childbirth. These efforts have significantly reduced the number of new infections among infants, especially in high-income countries.
The history of AIDS is also a story of human resilience. The disease once considered a death sentence is now manageable with lifelong treatment. People living with HIV are becoming educators, activists, and leaders. Communities around the world organize events such as World AIDS Day (December 1st) to honor those affected and push for continued progress.
In conclusion, AIDS remains a global health challenge, but it is no longer a hopeless condition. With early diagnosis, effective treatment, and public education, people with HIV can live full and healthy lives. Ending the HIV/AIDS epidemic requires not only medical solutions but also social change to overcome stigma, increase access, and support vulnerable communities.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to explain what AIDS and HIV are, how the virus is transmitted and progresses, its symptoms, the importance of testing and antiretroviral therapy, prevention strategies, the problem of stigma, the global situation especially in Sub-Saharan Africa, ongoing efforts by organizations, protection of infants, and the conclusion that with treatment and education HIV is manageable while ending the epidemic also requires social change.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how is HIV transmitted?',
        explanation: 'According to the passage, HIV is transmitted through certain bodily fluids including blood, semen, vaginal fluids, and breast milk, most commonly via unprotected sexual contact, sharing needles, transfusion of infected blood, and from mother to child during childbirth or breastfeeding; it is not transmitted through casual contact such as hugging, shaking hands, or sharing food.',
      ),
      ReadingQuestion(
        question: 'The word "opportunistic" in the symptoms paragraph most likely means',
        explanation: 'In the passage, "opportunistic" most likely means infections that take advantage of a weakened immune system and that a healthy immune system would normally control, which appear once AIDS develops.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the progression from HIV to AIDS?',
        explanation: 'It can be inferred that HIV destroys CD4 cells crucial for immune defense, and if untreated the immune system eventually becomes too weak to fight infections or cancers, at which point the person has AIDS; without treatment AIDS is fatal, but with proper care people with HIV can live long healthy lives without developing AIDS.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what does antiretroviral therapy (ART) do?',
        explanation: 'According to the passage, ART involves a combination of medications that reduce the amount of virus in the body; while it does not cure HIV, it allows the immune system to recover and reduces the risk of transmission, enabling people on properly followed treatment to lead productive lives, work, and have families without infecting others.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of stigma in the HIV/AIDS epidemic?',
        explanation: 'It can be inferred that stigma remains a major barrier because many people living with HIV face discrimination at work, in healthcare, or in communities, which discourages testing, disclosure of status, and seeking treatment; public education is therefore essential to reduce fear and misinformation.',
      ),
      ReadingQuestion(
        question: 'According to the passage, which region is most affected by HIV?',
        explanation: 'According to the passage, Sub-Saharan Africa remains the most affected region, accounting for nearly two-thirds of all people living with HIV, and many people there still lack access to testing, treatment, and prevention tools, with women and young people particularly vulnerable.',
      ),
      ReadingQuestion(
        question: 'The phrase "functional cure" in the passage most likely refers to',
        explanation: 'In the passage, "functional cure" refers to a potential treatment outcome sought in ongoing research (alongside vaccines) that would control HIV without continuous medication, although so far there is no vaccine or complete cure for HIV.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about preventing mother-to-child transmission?',
        explanation: 'It can be inferred that medical interventions during pregnancy and childbirth can protect children born to HIV-positive mothers and have significantly reduced the number of new infections among infants, especially in high-income countries.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is required to end the HIV/AIDS epidemic?',
        explanation: 'According to the passage, ending the HIV/AIDS epidemic requires not only medical solutions such as early diagnosis and effective treatment but also social change to overcome stigma, increase access to care, and support vulnerable communities, so that people with HIV can live full and healthy lives.',
      ),
    ],
  ),

  ReadingPassage(
    id: 89,
    title: 'Accidents',
    topic: 'Health & Safety',
    content: '''Accidents are unplanned events that cause injury, damage, or even death. They can happen anywhere—on roads, at home, in the workplace, or in public places. While some accidents are minor, others have life-changing or fatal consequences.
Understanding the causes and impacts of accidents is essential for prevention and safety planning.
One of the most common types of accidents occurs on the road. Traffic accidents involve cars, motorcycles, bicycles, or pedestrians. According to the World Health Organization, over 1.3 million people die every year in road crashes, and tens of millions suffer injuries. The leading causes include speeding, drunk driving, distracted driving (such as using mobile phones), and failure to obey traffic rules. Poor road conditions, vehicle defects, and weather also contribute to accidents.
To reduce road accidents, governments have implemented safety measures such as speed limits, seat belt laws, and helmet requirements for motorcyclists. Traffic cameras and fines encourage compliance. Public education campaigns warn about the dangers of texting while driving or driving under the influence. Technology such as anti-lock braking systems (ABS), automatic emergency braking, and lane assist also enhance vehicle safety.
Workplace accidents are another concern, especially in industries like construction, mining, or manufacturing. Falling from heights, exposure to hazardous substances, equipment malfunctions, or lack of protective gear can cause serious harm. Repetitive strain injuries and stress-related accidents are also common in office environments.
Employers have a responsibility to ensure safe working conditions. This includes providing training, safety equipment, and proper supervision. Governments enforce occupational safety laws through inspections and penalties. Creating a culture of safety can reduce injuries and improve morale and productivity.
Accidents at home are frequent but often overlooked. Slips and falls, burns, cuts, and poisoning are among the most reported incidents. Elderly people and young children are especially vulnerable. For example, leaving cleaning chemicals within a child‘s reach or failing to install grab bars in bathrooms can lead to avoidable injuries.
Home safety requires awareness and precaution. Installing smoke detectors, locking away dangerous substances, and using child-proofing devices are simple but effective strategies. Public health campaigns often provide tips on creating safer living spaces.
Accidents can also happen in schools, parks, or during sports and leisure activities. Children may get hurt during play, and athletes risk injury during training or competitions. Equipment failure, poor supervision, and overcrowding increase the likelihood of such events.
Natural disasters, such as earthquakes or floods, can trigger accidents by collapsing buildings or blocking roads. In these cases, emergency response plans and infrastructure design are key to minimizing casualties. Fire drills, evacuation maps, and disaster preparedness kits help reduce risks in public buildings and homes. Accidents not only cause physical harm but also have economic and emotional costs. Victims may require medical treatment, rehabilitation, or long-term care.
They may lose their ability to work or face psychological trauma. Families may struggle with financial burdens or emotional stress. National economies also suffer from reduced productivity and increased healthcare costs.
Insurance systems help people recover financially after accidents. Health insurance, auto insurance, and worker compensation provide support for medical expenses, lost income, and legal claims. However, in many countries, access to insurance remains limited or unaffordable for large segments of the population.
Technology plays a growing role in accident prevention and response. Surveillance cameras, GPS tracking, and emergency alert systems help detect and report incidents quickly. Mobile apps can guide users to nearby hospitals or contact emergency services. Artificial intelligence is being used to analyze accident data and predict high-risk areas, leading to better planning and prevention.
Education is perhaps the most powerful tool in preventing accidents. Teaching people how to recognize hazards, use equipment safely, and respond to emergencies builds a culture of safety. Schools, employers, and media all have roles in promoting safety awareness.
However, not all accidents can be prevented. In such cases, emergency services— such as ambulances, fire departments, and police—must respond quickly and effectively. Training emergency personnel, maintaining reliable communication systems, and investing in hospitals and trauma care are critical.
In conclusion, accidents are a major cause of injury and death worldwide, but most are preventable. Whether on the road, at work, or at home, safety requires a combination of awareness, regulation, technology, and responsibility. By understanding the risks and acting to reduce them, societies can save lives, reduce suffering, and build safer environments for all.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to define accidents as unplanned events causing injury or death, examine common types such as road, workplace, and home accidents along with their causes, discuss prevention measures involving regulation, technology, and education, and emphasize that most accidents are preventable through awareness and responsibility.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are the leading causes of road accidents?',
        explanation: 'According to the passage, the leading causes of road accidents include speeding, drunk driving, distracted driving such as using mobile phones, and failure to obey traffic rules, with poor road conditions, vehicle defects, and weather also contributing.',
      ),
      ReadingQuestion(
        question: 'The word "compliance" in the paragraph about road safety measures most likely means',
        explanation: 'In the context of the passage, "compliance" most likely means following or obeying the rules, as traffic cameras and fines are said to encourage compliance with safety measures like speed limits and seat belt laws.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about workplace accidents from the passage?',
        explanation: 'It can be inferred that workplace accidents are a serious concern especially in high-risk industries like construction, mining, or manufacturing, but they can be reduced when employers provide training, safety equipment, and supervision, and when governments enforce occupational safety laws.',
      ),
      ReadingQuestion(
        question: 'According to the passage, who is especially vulnerable to accidents at home?',
        explanation: 'According to the passage, elderly people and young children are especially vulnerable to home accidents such as slips and falls, burns, cuts, and poisoning, which can result from hazards like accessible cleaning chemicals or missing grab bars.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the broader impacts of accidents beyond physical injury?',
        explanation: 'It can be inferred that accidents impose economic and emotional costs, including medical treatment, rehabilitation, loss of work ability, psychological trauma for victims, financial and emotional stress for families, and reduced productivity plus higher healthcare costs for national economies.',
      ),
      ReadingQuestion(
        question: 'The phrase "culture of safety" in the passage most likely means',
        explanation: 'In the context of the passage, "culture of safety" most likely means a shared set of attitudes and practices that prioritize preventing harm, as creating such a culture at work can reduce injuries and improve morale and productivity, and education builds it more broadly.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does technology help with accident prevention and response?',
        explanation: 'According to the passage, technology helps through surveillance cameras, GPS tracking, and emergency alert systems that detect and report incidents quickly, mobile apps that guide users to hospitals or emergency services, and artificial intelligence that analyzes data to predict high-risk areas for better planning.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of education in accident prevention?',
        explanation: 'It can be inferred that education is one of the most powerful tools because teaching people to recognize hazards, use equipment safely, and respond to emergencies builds a culture of safety, with schools, employers, and media all playing roles in promoting awareness.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is needed when accidents cannot be prevented?',
        explanation: 'According to the passage, when accidents cannot be prevented, emergency services such as ambulances, fire departments, and police must respond quickly and effectively, which requires training personnel, maintaining reliable communication systems, and investing in hospitals and trauma care.',
      ),
    ],
  ),

  ReadingPassage(
    id: 90,
    title: 'Mental Health',
    topic: 'Health & Psychology',
    content: '''Mental health refers to a person‘s emotional, psychological, and social well-being. It affects how individuals think, feel, and act, as well as how they handle stress, relate to others, and make decisions. Good mental health allows people to cope with life‘s challenges, build strong relationships, and contribute to their communities. However, mental health issues are increasingly recognized as a major public concern across the globe.
Mental health disorders include a wide range of conditions such as depression, anxiety, bipolar disorder, schizophrenia, eating disorders, and post-traumatic stress disorder (PTSD). These conditions vary in severity and duration. Some may be temporary and triggered by specific events, while others are chronic and require long-term treatment and support.
The causes of mental health problems are complex and often involve a combination of factors. Biological influences such as genetics, brain chemistry, and hormonal imbalances can play a role. Environmental factors—including trauma, abuse, poverty, discrimination, and social isolation—can also have a profound impact. Lifestyle choices, such as lack of sleep, substance abuse, and poor diet, may contribute to mental distress.
Signs of poor mental health include persistent sadness, mood swings, fatigue, changes in eating or sleeping patterns, withdrawal from social activities, and difficulty concentrating. In severe cases, individuals may have thoughts of selfharm or suicide. Recognizing these signs early is crucial to getting the help needed.
Despite growing awareness, stigma remains a major barrier to mental health care. Many people fear being judged, misunderstood, or discriminated against if they admit to having a mental health problem. This often leads to silence, denial, and delayed treatment. Reducing stigma through education and open conversations is essential.
Access to mental health services is another major challenge. In many countries, mental health care is underfunded and understaffed. There may be long waiting times, high costs, or a lack of trained professionals. In rural or low-income areas, services may be unavailable altogether. Mental health must be given the same priority as physical health in national healthcare policies.
Treatment options vary depending on the condition and the individual. They may include psychotherapy (talk therapy), medication, lifestyle changes, or support groups. Cognitive-behavioral therapy (CBT) is one of the most widely used and effective methods. It helps individuals recognize and change negative thought patterns. Medications like antidepressants or mood stabilizers may also be prescribed, though they should be monitored for side effects.
Mental health support in schools and workplaces is increasingly recognized as important. Students and employees often face stress from academic pressure or job demands. Providing counseling services, stress management programs, and mental health days can improve performance and reduce absenteeism. Encouraging worklife balance and healthy routines is equally important.
Technology is transforming mental health care. Online counseling, mental health apps, and telepsychiatry provide greater access to support, especially for those in remote areas or during times of crisis like the COVID-19 pandemic. However, digital solutions should complement, not replace, face-to-face care.
Prevention is just as important as treatment. Promoting mental wellness through healthy habits, supportive relationships, and emotional education helps build resilience. Teaching children how to express emotions, solve problems, and seek help creates a foundation for lifelong mental well-being.
The global burden of mental health conditions is significant. According to the World Health Organization, depression is the leading cause of disability worldwide. Suicide is among the top causes of death among young people. The economic impact of lost productivity, healthcare costs, and disability payments runs into billions of dollars annually.
Governments, health organizations, and communities must work together to create inclusive mental health systems. This includes training more professionals, integrating mental health into primary care, and ensuring services are culturally sensitive and accessible to all.
In conclusion, mental health is a fundamental part of human well-being. It affects every aspect of life and should be treated with the same seriousness as physical health. Breaking stigma, expanding access, and supporting prevention are key steps in building a mentally healthier world.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage defines mental health, describes various disorders and their causes and signs, discusses barriers such as stigma and limited access to care, outlines treatment and prevention strategies including technology and support in schools and workplaces, and emphasizes the need to treat mental health with the same seriousness as physical health.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are some biological influences that can contribute to mental health problems?',
        explanation: 'Biological influences such as genetics, brain chemistry, and hormonal imbalances can play a role in the complex causes of mental health problems.',
      ),
      ReadingQuestion(
        question: 'The word "stigma" in the paragraph about barriers to care most likely means',
        explanation: 'It means a mark of shame or negative social judgment, as many people fear being judged, misunderstood, or discriminated against if they admit to having a mental health problem, leading to silence, denial, and delayed treatment.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the importance of early recognition of mental health signs?',
        explanation: 'Recognizing signs such as persistent sadness, mood swings, fatigue, changes in eating or sleeping patterns, withdrawal, or difficulty concentrating early is crucial to getting the help needed, especially since severe cases may involve thoughts of selfharm or suicide.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is access to mental health services a major challenge?',
        explanation: 'In many countries, mental health care is underfunded and understaffed, with possible long waiting times, high costs, or a lack of trained professionals; in rural or low-income areas, services may be unavailable altogether, so mental health must be given the same priority as physical health.',
      ),
      ReadingQuestion(
        question: 'The word "resilience" in the paragraph about prevention most likely means',
        explanation: 'It means the ability to recover from or adjust to difficulties, as promoting mental wellness through healthy habits, supportive relationships, and emotional education helps build resilience.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of technology in mental health care?',
        explanation: 'Online counseling, mental health apps, and telepsychiatry provide greater access to support, especially for those in remote areas or during crises like the COVID-19 pandemic, but digital solutions should complement rather than replace face-to-face care.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what does the World Health Organization report about depression?',
        explanation: 'According to the World Health Organization, depression is the leading cause of disability worldwide, and suicide is among the top causes of death among young people, with the economic impact of mental health conditions running into billions of dollars annually.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about mental health support in schools and workplaces?',
        explanation: 'It is increasingly recognized as important because students and employees face stress from academic pressure or job demands; providing counseling, stress management programs, and mental health days can improve performance and reduce absenteeism, while encouraging worklife balance and healthy routines is also key.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are key steps in building a mentally healthier world?',
        explanation: 'Breaking stigma, expanding access to care, and supporting prevention are key steps; governments, health organizations, and communities must work together to create inclusive systems by training more professionals, integrating mental health into primary care, and ensuring services are culturally sensitive and accessible to all.',
      ),
    ],
  ),

  ReadingPassage(
    id: 91,
    title: 'Vaccination',
    topic: 'Health & Science',
    content: '''Vaccination is the process of administering a vaccine to help the immune system develop protection against a specific infectious disease. Vaccines are one of the most effective public health tools in human history, responsible for preventing millions of deaths and reducing the spread of deadly illnesses.
The basic idea behind vaccination is to expose the body to a harmless form of a pathogen, such as a weakened or inactivated virus, or a small part of it like a protein. This stimulates the immune system to produce antibodies and memory cells that recognize and fight the real disease if encountered in the future. This process is called immunization.
Vaccines have successfully controlled or eliminated many dangerous diseases. For example, smallpox, a deadly virus that killed millions throughout history, was declared eradicated in 1980 thanks to a global vaccination campaign. Polio is now close to being eliminated, and vaccines have dramatically reduced cases of measles, tetanus, diphtheria, and whooping cough.
Vaccination programs benefit not only individuals but also communities through what is called ―herd immunity.‖ When a large portion of the population is immune to a disease, the spread of the disease slows or stops. This protects vulnerable groups, such as newborns, the elderly, or people with weakened immune systems who cannot be vaccinated themselves.
Despite its proven success, vaccination remains a controversial issue in some parts of the world. Vaccine hesitancy—the reluctance or refusal to vaccinate despite availability—has been identified as a global health threat. Reasons include misinformation, fear of side effects, religious or philosophical beliefs, and lack of trust in healthcare systems.
Misinformation spreads easily, especially through social media. False claims about vaccine ingredients, exaggerated risks, or conspiracy theories can cause public fear. As a result, some parents choose not to vaccinate their children, leading to outbreaks of diseases that were once under control. The measles outbreaks in Europe and the United States in recent years are examples of this.
Vaccines, like all medical treatments, can have side effects. However, serious reactions are extremely rare. The vast majority of side effects are mild, such as a sore arm or low fever. Health authorities such as the World Health Organization and national health agencies conduct rigorous testing before approving vaccines. Continued monitoring ensures safety after vaccines are in use.
The COVID-19 pandemic brought vaccination into global focus. Scientists developed several vaccines in record time, using both traditional and new technologies, such as mRNA-based vaccines. Mass vaccination campaigns helped reduce hospitalizations and deaths, although global distribution faced challenges. Inequality in vaccine access between rich and poor countries became a major issue, highlighting the need for global cooperation.
Vaccination is also important in preparing for future pandemics. Researchers are now working on universal flu vaccines, new malaria vaccines, and updated versions of existing ones. These efforts are part of a broader strategy to strengthen public health systems and respond quickly to emerging threats.
Mandatory vaccination policies vary by country. Some governments require vaccination for school entry, travel, or certain jobs, especially in healthcare. Others rely on public education and voluntary participation. Balancing individual freedom with public health responsibility is a complex issue that continues to be debated. Public trust is essential to the success of vaccination programs. Clear communication from health authorities, transparency about vaccine development, and respectful engagement with communities help increase acceptance. Involving religious leaders, community health workers, and schools can build support at the local level.
Vaccines not only prevent illness but also have economic benefits. They reduce the cost of medical treatment, lower the burden on hospitals, and keep workers and students healthy and productive. According to the World Bank, every dollar spent on immunization returns up to \$44 in economic benefits.
In conclusion, vaccination is a powerful tool for preventing disease, protecting communities, and saving lives. While challenges such as hesitancy and inequality remain, continued investment in research, education, and public health infrastructure is key to maintaining and expanding the benefits of vaccines for current and future generations.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of this passage is to explain how vaccination works to protect against infectious diseases, highlight its historical successes in controlling or eliminating illnesses, discuss the concept of herd immunity, address challenges such as vaccine hesitancy and misinformation, examine issues of access and policy, and emphasize the ongoing importance of vaccines for public health and economic benefits.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does vaccination work to protect the body?',
        explanation: 'Vaccination exposes the body to a harmless form of a pathogen, such as a weakened or inactivated virus or a protein from it. This stimulates the immune system to produce antibodies and memory cells that recognize and fight the real disease if encountered in the future, a process called immunization.',
      ),
      ReadingQuestion(
        question: 'The word \'hesitancy\' in the passage most likely means?',
        explanation: 'It most likely means reluctance or unwillingness to act, as the passage defines vaccine hesitancy as the reluctance or refusal to vaccinate despite availability, which has been identified as a global health threat due to reasons like misinformation and lack of trust.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the impact of misinformation on vaccination rates?',
        explanation: 'It can be inferred that misinformation, especially through social media, contributes to lower vaccination rates by causing public fear through false claims, exaggerated risks, or conspiracy theories, leading some parents not to vaccinate their children and resulting in outbreaks of previously controlled diseases like measles.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is herd immunity and why is it important?',
        explanation: 'Herd immunity occurs when a large portion of the population is immune to a disease, slowing or stopping its spread. It is important because it protects vulnerable groups such as newborns, the elderly, or people with weakened immune systems who cannot be vaccinated themselves.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the economic benefits of vaccination?',
        explanation: 'It can be inferred that vaccination provides substantial economic returns by reducing medical treatment costs, lowering the burden on hospitals, and keeping workers and students healthy and productive, with the World Bank estimating that every dollar spent on immunization returns up to $44 in economic benefits.',
      ),
    ],
  ),

  ReadingPassage(
    id: 92,
    title: 'Vaccination',
    topic: 'Health & Science',
    content: '''Vaccination is the process of administering a vaccine to help the immune system develop protection against a specific infectious disease. Vaccines are one of the most effective public health tools in human history, responsible for preventing millions of deaths and reducing the spread of deadly illnesses.
The basic idea behind vaccination is to expose the body to a harmless form of a pathogen, such as a weakened or inactivated virus, or a small part of it like a protein. This stimulates the immune system to produce antibodies and memory cells that recognize and fight the real disease if encountered in the future. This process is called immunization.
Vaccines have successfully controlled or eliminated many dangerous diseases. For example, smallpox, a deadly virus that killed millions throughout history, was declared eradicated in 1980 thanks to a global vaccination campaign. Polio is now close to being eliminated, and vaccines have dramatically reduced cases of measles, tetanus, diphtheria, and whooping cough.
Vaccination programs benefit not only individuals but also communities through what is called ―herd immunity.‖ When a large portion of the population is immune to a disease, the spread of the disease slows or stops. This protects vulnerable groups, such as newborns, the elderly, or people with weakened immune systems who cannot be vaccinated themselves.
Despite its proven success, vaccination remains a controversial issue in some parts of the world. Vaccine hesitancy—the reluctance or refusal to vaccinate despite availability—has been identified as a global health threat. Reasons include misinformation, fear of side effects, religious or philosophical beliefs, and lack of trust in healthcare systems.
Misinformation spreads easily, especially through social media. False claims about vaccine ingredients, exaggerated risks, or conspiracy theories can cause public fear. As a result, some parents choose not to vaccinate their children, leading to outbreaks of diseases that were once under control. The measles outbreaks in Europe and the United States in recent years are examples of this.
Vaccines, like all medical treatments, can have side effects. However, serious reactions are extremely rare. The vast majority of side effects are mild, such as a sore arm or low fever. Health authorities such as the World Health Organization and national health agencies conduct rigorous testing before approving vaccines. Continued monitoring ensures safety after vaccines are in use.
The COVID-19 pandemic brought vaccination into global focus. Scientists developed several vaccines in record time, using both traditional and new technologies, such as mRNA-based vaccines. Mass vaccination campaigns helped reduce hospitalizations and deaths, although global distribution faced challenges. Inequality in vaccine access between rich and poor countries became a major issue, highlighting the need for global cooperation.
Vaccination is also important in preparing for future pandemics. Researchers are now working on universal flu vaccines, new malaria vaccines, and updated versions of existing ones. These efforts are part of a broader strategy to strengthen public health systems and respond quickly to emerging threats.
Mandatory vaccination policies vary by country. Some governments require vaccination for school entry, travel, or certain jobs, especially in healthcare. Others rely on public education and voluntary participation. Balancing individual freedom with public health responsibility is a complex issue that continues to be debated.
Public trust is essential to the success of vaccination programs. Clear communication from health authorities, transparency about vaccine development, and respectful engagement with communities help increase acceptance. Involving religious leaders, community health workers, and schools can build support at the local level.
Vaccines not only prevent illness but also have economic benefits. They reduce the cost of medical treatment, lower the burden on hospitals, and keep workers and students healthy and productive. According to the World Bank, every dollar spent on immunization returns up to \$44 in economic benefits.
In conclusion, vaccination is a powerful tool for preventing disease, protecting communities, and saving lives. While challenges such as hesitancy and inequality remain, continued investment in research, education, and public health infrastructure is key to maintaining and expanding the benefits of vaccines for current and future generations.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to explain how vaccination works, highlight its historical successes in controlling diseases, describe benefits such as herd immunity, address challenges like hesitancy and misinformation, and emphasize its ongoing importance for public health and future pandemic preparedness.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does vaccination stimulate the immune system?',
        explanation: 'It exposes the body to a harmless form of a pathogen, such as a weakened or inactivated virus or a protein, which stimulates the production of antibodies and memory cells that recognize and fight the real disease if encountered later; this process is called immunization.',
      ),
      ReadingQuestion(
        question: 'The phrase \'herd immunity\' in the fourth paragraph most likely means...',
        explanation: 'The protection of a community that occurs when a large portion of the population is immune to a disease, slowing or stopping its spread and thereby protecting vulnerable groups who cannot be vaccinated.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the impact of vaccine hesitancy?',
        explanation: 'Vaccine hesitancy, driven by misinformation, fear of side effects, beliefs, or lack of trust, can lead parents to refuse vaccination for their children and result in outbreaks of diseases that were once under control, as seen with recent measles outbreaks.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are the typical side effects of vaccines?',
        explanation: 'Serious reactions are extremely rare; the vast majority of side effects are mild, such as a sore arm or low fever, and vaccines undergo rigorous testing and continued monitoring by health authorities to ensure safety.',
      ),
      ReadingQuestion(
        question: 'The word \'eradicated\' in the third paragraph most likely means...',
        explanation: 'Completely eliminated or wiped out. The passage states that smallpox was declared eradicated in 1980 thanks to a global vaccination campaign.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about vaccine access during the COVID-19 pandemic?',
        explanation: 'Although mass vaccination campaigns reduced hospitalizations and deaths, global distribution faced challenges and inequality in access between rich and poor countries became a major issue, highlighting the need for global cooperation.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what economic benefits do vaccines provide?',
        explanation: 'They reduce the cost of medical treatment, lower the burden on hospitals, and keep workers and students healthy and productive; according to the World Bank, every dollar spent on immunization returns up to $44 in economic benefits.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about mandatory vaccination policies?',
        explanation: 'Policies vary by country: some governments require vaccination for school entry, travel, or certain jobs, while others rely on education and voluntary participation, reflecting an ongoing debate about balancing individual freedom with public health responsibility.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is public trust important for vaccination programs?',
        explanation: 'Clear communication from health authorities, transparency about vaccine development, and respectful engagement with communities help increase acceptance; involving religious leaders, community health workers, and schools can build local support.',
      ),
    ],
  ),

  ReadingPassage(
    id: 93,
    title: 'Hygiene',
    topic: 'Health & Science',
    content: '''Hygiene refers to practices and conditions that help maintain health and prevent the spread of diseases. It includes personal hygiene, such as washing hands and bathing, as well as public hygiene practices like waste disposal, water sanitation, and food safety. Good hygiene is a fundamental aspect of public health and plays a critical role in preventing infections and promoting well-being.
Personal hygiene is the daily practice of keeping one‘s body clean. This includes bathing, brushing teeth, washing hands, wearing clean clothes, and keeping hair and nails tidy. Handwashing is especially important, as hands can carry bacteria and viruses from one surface to another. According to the World Health
Organization, handwashing with soap can reduce the risk of diarrheal diseases by up to 40%.
Oral hygiene, such as brushing and flossing teeth regularly, prevents cavities, gum disease, and bad breath. Poor dental hygiene has also been linked to other health issues, including heart disease and diabetes. Teaching children the importance of these routines helps establish lifelong habits.
Environmental hygiene is equally important. Safe drinking water, clean public spaces, and proper waste management reduce the spread of diseases. In areas where sanitation is poor, outbreaks of waterborne illnesses like cholera and typhoid are common. Ensuring proper sewage systems and clean toilets is crucial, especially in densely populated or low-income regions.
Food hygiene involves the safe handling, preparation, and storage of food to prevent contamination. Foodborne illnesses, such as salmonella or E. coli, can result from improper cooking, unclean surfaces, or expired ingredients. Restaurants and food manufacturers are required to follow strict hygiene standards to ensure public safety.
During pandemics, such as COVID-19, hygiene becomes even more important. Guidelines like frequent handwashing, disinfecting surfaces, wearing masks, and maintaining physical distance help prevent viral transmission. These measures have shown how basic hygiene can save lives on a global scale.
Hygiene also impacts mental and social well-being. People who maintain good personal hygiene often feel more confident and are more accepted in social and professional settings. In contrast, poor hygiene can lead to isolation, bullying, and reduced self-esteem. In schools, teaching hygiene helps children stay healthy and attend regularly.
Cultural and religious beliefs often influence hygiene practices. For instance, many cultures have specific rituals for cleanliness before prayer or meals. While these practices vary, the common theme is the link between cleanliness and health, morality, or spiritual purity.
Challenges to good hygiene exist in many parts of the world. In low-income countries, lack of access to clean water, soap, and sanitation facilities makes maintaining hygiene difficult. Girls and women are particularly affected, especially during menstruation when safe hygiene is essential for dignity and health.
Organizations like UNICEF and the World Bank support programs to improve hygiene infrastructure in underserved areas. These include building latrines, providing soap, and promoting hygiene education in schools and communities. Even simple interventions—like teaching children to wash their hands—can have a huge impact on reducing disease.
Technology has also contributed to better hygiene. Innovations like no-touch soap dispensers, antibacterial fabrics, and air purifiers help prevent contamination in homes, hospitals, and public spaces. Smart sanitation systems are being developed to manage waste more efficiently in growing cities.
Workplace hygiene is another important area. Employers are responsible for providing clean and safe environments for their workers. This includes regular cleaning, access to clean restrooms, and safe handling of chemicals or waste. During outbreaks, companies may provide masks, hand sanitizer, and remote work options to protect staff.
In healthcare settings, hygiene can mean the difference between life and death. Hospitals follow strict protocols to prevent infections, such as sterilizing equipment, isolating patients, and ensuring that staff follow hand hygiene rules. Hospital-acquired infections (HAIs) are a serious threat, and proper hygiene is the first line of defense.
Despite its importance, hygiene is often neglected or underestimated. Public awareness campaigns, such as Global Handwashing Day, aim to remind people of its value. Schools, media, and governments play essential roles in educating citizens and encouraging responsible hygiene behavior.
In conclusion, hygiene is a simple yet powerful tool for protecting health and preventing disease. From personal routines to national infrastructure, hygiene affects every aspect of life. Investing in hygiene is not only about cleanliness—it is about dignity, safety, and the foundation of a healthy society.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to explain the importance of hygiene as a fundamental aspect of public health, covering personal, environmental, food, and other forms of hygiene, their role in preventing disease, impacts on well-being, challenges in access, and the need for education, technology, and investment to promote a healthy society.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what does personal hygiene include?',
        explanation: 'Personal hygiene is the daily practice of keeping one\'s body clean and includes bathing, brushing teeth, washing hands, wearing clean clothes, and keeping hair and nails tidy.',
      ),
      ReadingQuestion(
        question: 'The word "sanitation" in the fourth paragraph most likely means',
        explanation: 'In the context of poor sanitation leading to outbreaks of waterborne illnesses and the need for proper sewage systems and clean toilets, sanitation refers to systems and practices for maintaining clean and healthy conditions through waste disposal and water management.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the importance of handwashing from the passage?',
        explanation: 'It can be inferred that handwashing is especially critical because hands carry bacteria and viruses, and according to the World Health Organization, handwashing with soap can reduce the risk of diarrheal diseases by up to 40%, making it a key practice for preventing infections.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does poor oral hygiene affect overall health?',
        explanation: 'Poor dental hygiene can lead to cavities, gum disease, and bad breath, and has also been linked to other health issues including heart disease and diabetes.',
      ),
      ReadingQuestion(
        question: 'The term "foodborne illnesses" in the fifth paragraph most likely refers to',
        explanation: 'In the context of illnesses such as salmonella or E. coli resulting from improper cooking, unclean surfaces, or expired ingredients, foodborne illnesses are diseases caused by contaminated food.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of hygiene during pandemics?',
        explanation: 'It can be inferred that basic hygiene measures such as frequent handwashing, disinfecting surfaces, wearing masks, and physical distancing become even more important during pandemics like COVID-19 because they help prevent viral transmission and can save lives on a global scale.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does hygiene impact mental and social well-being?',
        explanation: 'People who maintain good personal hygiene often feel more confident and are more accepted in social and professional settings, while poor hygiene can lead to isolation, bullying, and reduced self-esteem; teaching hygiene in schools helps children stay healthy and attend regularly.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about challenges to hygiene in low-income countries?',
        explanation: 'Lack of access to clean water, soap, and sanitation facilities makes maintaining hygiene difficult, and girls and women are particularly affected during menstruation when safe hygiene is essential for dignity and health.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is hygiene especially critical in healthcare settings?',
        explanation: 'Hygiene can mean the difference between life and death in hospitals, where strict protocols such as sterilizing equipment, isolating patients, and ensuring staff follow hand hygiene rules are used to prevent infections; hospital-acquired infections are a serious threat and proper hygiene is the first line of defense.',
      ),
    ],
  ),

  ReadingPassage(
    id: 94,
    title: 'Migration',
    topic: 'Society & Global Issues',
    content: '''Migration is the movement of people from one place to another, often across borders, in search of better living conditions, employment, safety, or education. It is one of the most significant social, economic, and political phenomena of the modern world. Migration affects individuals, families, societies, and nations in complex and far-reaching ways.
There are two main types of migration: internal and international. Internal migration occurs within a country, such as people moving from rural to urban areas in search of jobs or services. This is common in developing nations where cities offer more opportunities. International migration involves crossing national borders and may be temporary or permanent.
People migrate for various reasons, commonly categorized as ―push‖ and ―pull‖ factors. Push factors include poverty, unemployment, war, political persecution, and natural disasters. Pull factors involve better job prospects, higher education, safety, or a higher standard of living in the destination country. For example, many people from Latin America move to the United States for better economic opportunities, while refugees from conflict zones like Syria seek safety in Europe or neighboring countries.
Economic migration is one of the most common forms. Migrants often take on jobs that are in high demand but less attractive to locals, such as agricultural labor, domestic work, or construction. While these workers contribute to the economy, they often face low wages, limited rights, and poor working conditions.
Another type is forced migration. Refugees and asylum seekers are people forced to flee their countries due to violence, conflict, or persecution. According to the United Nations, there are more than 100 million displaced people globally. Many live in temporary shelters or camps and face long waits for legal status, education, and integration into society.
Migration has both positive and negative effects. On the positive side, it can reduce labor shortages, fill skill gaps, and contribute to cultural diversity. Migrants often send remittances—money sent back home—to support their families, which strengthens local economies. Migrants also bring new ideas, languages, and cultural practices, enriching the host country‘s society.
On the negative side, migration can strain public services such as housing, healthcare, and education, especially if numbers increase rapidly. In some countries, political tensions rise when locals perceive migrants as a threat to jobs or national identity. Cultural misunderstandings, xenophobia, or discrimination may also occur, making it harder for migrants to integrate.
Legal migration is governed by strict rules. Many countries have visa systems that allow entry based on employment, education, family reunification, or humanitarian reasons. However, irregular or undocumented migration is also common, often involving dangerous journeys and vulnerability to exploitation by traffickers.
Managing migration effectively requires international cooperation. Border security must be balanced with humanitarian obligations. Integration policies—such as language training, job support, and anti-discrimination laws—can help migrants become productive members of society. Education systems must accommodate students from diverse backgrounds, while healthcare providers must address different cultural needs.
Technology is changing migration patterns. Social media helps migrants stay connected with their families and share information about job opportunities or safe routes. Online job applications and remote work options are also creating new forms of mobility, such as digital nomads who work online while living abroad. Climate change is emerging as a major driver of migration. Rising sea levels, extreme weather, and resource scarcity are forcing people to leave their homes. These climate migrants are not always recognized under international refugee laws, creating legal and humanitarian challenges.
Public opinion about migration varies widely. Some people view it as a threat, especially during times of economic difficulty or social change. Others see it as an opportunity for growth, innovation, and global understanding. Media coverage, political rhetoric, and economic conditions all shape how migration is perceived. Policies that support safe, orderly, and regular migration benefit everyone. Host countries gain economic and cultural advantages, while migrants achieve personal and professional growth. At the same time, addressing the root causes of forced migration—such as conflict, inequality, and environmental degradation—remains essential.
In conclusion, migration is a powerful force shaping the modern world. It brings both opportunities and challenges that must be managed through fair laws, inclusive policies, and international cooperation. As people continue to move in search of better lives, building societies that are open, resilient, and just becomes more important than ever.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage explains the types, causes, effects, and management of migration, concluding that it is a powerful force requiring fair laws, inclusive policies, and international cooperation to maximize benefits and address challenges.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are the two main types of migration?',
        explanation: 'The two main types are internal migration, which occurs within a country such as rural-to-urban movement, and international migration, which involves crossing national borders and may be temporary or permanent.',
      ),
      ReadingQuestion(
        question: 'The phrase "push factors" in the third paragraph most likely means',
        explanation: 'Push factors are negative conditions in the home country—such as poverty, unemployment, war, political persecution, or natural disasters—that compel people to leave.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about economic migrants from the passage?',
        explanation: 'Economic migrants often fill high-demand but less desirable jobs such as agricultural labor, domestic work, or construction, contributing to the host economy while frequently facing low wages, limited rights, and poor conditions.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how many people are displaced globally according to the United Nations?',
        explanation: 'According to the United Nations, there are more than 100 million displaced people globally, many of whom live in temporary shelters or camps while awaiting legal status and integration.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the positive economic impact of migration on origin countries?',
        explanation: 'Migrants send remittances—money transferred back home—to support their families, which strengthens local economies in the countries they left.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what negative effects can rapid migration have on host countries?',
        explanation: 'Rapid increases in migrant numbers can strain public services such as housing, healthcare, and education, and may raise political tensions if locals perceive migrants as threats to jobs or national identity.',
      ),
      ReadingQuestion(
        question: 'The word "xenophobia" in the seventh paragraph most likely means',
        explanation: 'In context, xenophobia refers to fear, dislike, or prejudice against people from other countries or cultures, which can hinder migrant integration alongside discrimination and cultural misunderstandings.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about climate migrants from the passage?',
        explanation: 'Climate migrants are people forced to leave their homes due to rising sea levels, extreme weather, or resource scarcity, yet they are not always recognized under international refugee laws, creating legal and humanitarian challenges.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is needed for effective management of migration?',
        explanation: 'Effective management requires international cooperation that balances border security with humanitarian obligations, along with integration policies such as language training, job support, and anti-discrimination laws.',
      ),
    ],
  ),

  ReadingPassage(
    id: 95,
    title: 'Famine',
    topic: 'Society & Culture',
    content: '''Famine is a severe shortage of food that results in widespread hunger, malnutrition, and increased mortality. It is one of the most serious humanitarian crises, affecting millions of people throughout history and continuing to threaten lives today. Famines are rarely caused by a single factor; they typically arise from a combination of natural disasters, economic instability, political conflict, and poor governance.
Historically, famines were often triggered by crop failures due to droughts, floods, pests, or disease. In agrarian societies, where communities depended heavily on local harvests, even one season of poor weather could lead to starvation. A wellknown example is the Great Irish Famine (1845–1852), which was caused by a potato blight and led to over a million deaths and massive emigration.
Today, many famines are man-made or worsened by human factors. Armed conflict is a leading cause of food shortages. War disrupts farming, displaces populations, and damages infrastructure. Food supply chains are interrupted, and access to aid is often blocked. The famine in Yemen, for instance, has been driven largely by civil war and economic collapse, leaving millions on the brink of starvation.
Climate change is also a growing contributor. Rising temperatures, desertification, erratic rainfall, and extreme weather events reduce agricultural productivity. Prolonged droughts in parts of East Africa have led to repeated food crises, particularly affecting nomadic herders who rely on livestock. Climate-related food insecurity is expected to increase in the coming decades unless urgent action is taken.
Economic instability and poverty can prevent people from accessing food even when it is available. In many developing countries, food prices fluctuate wildly due to inflation or currency devaluation. When wages remain low and prices rise, poor households are forced to reduce meals, rely on low-nutrition diets, or go without food entirely. In countries like Venezuela and Sudan, economic crises have contributed to severe food shortages.
Governance and policy failures also play a critical role. Corruption, mismanagement, and lack of planning can turn food shortages into full-scale famines. Governments that fail to invest in agriculture, storage systems, or disaster response put their populations at greater risk. Sometimes, political leaders deliberately use food as a weapon—controlling access or withholding aid to punish opponents, as seen in several historical and modern conflicts.
Early warning systems and international aid can prevent food crises from turning into famines. Organizations like the World Food Programme (WFP) and FAO monitor weather patterns, harvests, and conflict zones to detect signs of famine. When high risk is identified, emergency food aid, cash assistance, and nutritional support are delivered to vulnerable areas. However, aid can be delayed or restricted due to political obstacles or lack of funding.
Malnutrition, especially among children, is a key indicator of famine. In affected areas, people—especially children under five—suffer from stunted growth, weakened immune systems, and diseases like cholera or measles. Pregnant and breastfeeding women are also at high risk due to increased nutritional needs. Without proper intervention, long-term effects can include developmental delays and increased mortality rates.
Addressing famine requires both short-term relief and long-term solutions. In the short term, emergency food aid, medical treatment, and safe water must be delivered quickly and efficiently. Mobile clinics, feeding centers, and community health workers are vital in crisis zones.
In the long term, investment in agriculture is essential. This includes training farmers, improving irrigation, using drought-resistant crops, and building better storage and distribution systems. Education and family planning also play a role— smaller, healthier families are more resilient in times of crisis.
Another long-term strategy is building resilient communities. Empowering women, promoting local food production, improving infrastructure, and creating social safety nets help reduce dependence on external aid. Governments and international partners must also work together to resolve conflicts and strengthen peacekeeping efforts.
Technology and innovation offer new tools to fight famine. Satellite imagery, data analytics, and mobile apps can track crop health, forecast droughts, and deliver alerts to aid agencies. Cash transfer programs using mobile money allow families to buy food locally, supporting both consumers and local markets.
Despite the progress in early warning systems and aid response, famine remains a threat. According to the United Nations, regions at high risk include Horn of Africa, Sahel, South Asia, and conflict zones across the Middle East. The COVID19 pandemic, war in Ukraine, and global inflation have further disrupted food supply chains and increased hunger worldwide.
In conclusion, famine is a preventable tragedy that reflects a combination of environmental stress, political failure, and social inequality. While the causes are complex, the solutions are known: proactive governance, investment in food security, conflict resolution, and international solidarity. In a world capable of producing enough food for everyone, no one should die of hunger.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage defines famine, explains its historical and modern causes including natural disasters, conflict, climate change, economic instability, and governance failures, describes impacts and indicators, outlines short- and long-term solutions, and concludes that famine is preventable through known measures and international solidarity.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what caused the Great Irish Famine?',
        explanation: 'The passage states that the Great Irish Famine (1845–1852) was caused by a potato blight and led to over a million deaths and massive emigration.',
      ),
      ReadingQuestion(
        question: 'The word "agrarian" in the passage most likely means',
        explanation: 'In context, agrarian refers to societies that depended heavily on local harvests, so that even one season of poor weather could lead to starvation.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of armed conflict in modern famines?',
        explanation: 'The passage identifies armed conflict as a leading cause of food shortages because war disrupts farming, displaces populations, damages infrastructure, interrupts supply chains, and often blocks access to aid, as illustrated by the famine in Yemen.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does climate change contribute to famine?',
        explanation: 'The passage explains that rising temperatures, desertification, erratic rainfall, and extreme weather events reduce agricultural productivity, with prolonged droughts in East Africa leading to repeated food crises, especially for nomadic herders.',
      ),
      ReadingQuestion(
        question: 'The phrase "food as a weapon" in the passage most likely refers to',
        explanation: 'The passage describes political leaders deliberately controlling access to food or withholding aid to punish opponents, turning food shortages into full-scale famines as seen in historical and modern conflicts.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the importance of early warning systems?',
        explanation: 'The passage states that organizations like the WFP and FAO monitor weather, harvests, and conflict zones to detect signs of famine so that emergency food aid, cash assistance, and nutritional support can be delivered, though aid can still be delayed by political obstacles or lack of funding.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is malnutrition among children a key indicator of famine?',
        explanation: 'The passage notes that children under five in affected areas suffer from stunted growth, weakened immune systems, and diseases, and that without intervention long-term effects can include developmental delays and increased mortality rates.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about long-term solutions to famine?',
        explanation: 'The passage emphasizes investment in agriculture (training farmers, irrigation, drought-resistant crops, storage), education and family planning, building resilient communities through empowering women and local production, conflict resolution, and the use of technology such as satellite imagery and cash transfers.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is famine described as a preventable tragedy?',
        explanation: 'The passage concludes that while causes are complex, the solutions are known—proactive governance, investment in food security, conflict resolution, and international solidarity—and that in a world capable of producing enough food for everyone, no one should die of hunger.',
      ),
    ],
  ),

  ReadingPassage(
    id: 96,
    title: 'Poverty',
    topic: 'Society & Economy',
    content: '''Poverty is a condition in which individuals or communities lack the financial resources necessary to meet basic living standards such as food, shelter, healthcare, and education. It is one of the most widespread and persistent global problems, affecting over 700 million people worldwide. Poverty is not just about low income; it also reflects a lack of opportunity, access, and security.
Poverty is commonly divided into two categories: absolute poverty and relative poverty. Absolute poverty refers to a situation where individuals cannot afford the basic necessities of life. This is usually measured using the international poverty line set by the World Bank, which is currently \$2.15 per day. Relative poverty, on the other hand, is based on income inequality within a particular society. People are considered relatively poor if their income is significantly below the national average, affecting their ability to participate fully in society.
The causes of poverty are numerous and interconnected. Low levels of education, unemployment, and lack of access to land or credit prevent people from earning a stable income. In rural areas, many families depend on subsistence farming, which is vulnerable to droughts, floods, and changing weather patterns. In urban settings, informal labor markets often provide low and unpredictable wages without job security.
Historical and political factors also contribute to poverty. Colonization, war, and corruption have shaped unequal development across regions. In some cases, governments fail to invest in public services or infrastructure, leaving entire communities without schools, hospitals, or clean water. Gender inequality further compounds poverty, as women and girls often face discrimination in education, employment, and property rights.
Health and poverty are closely linked. Poor communities are more exposed to diseases due to inadequate sanitation, unsafe drinking water, and limited healthcare access. Illness reduces people's ability to work or attend school, creating a cycle that traps families in poverty. Malnutrition, especially in children, leads to stunted growth and cognitive delays, which affect long-term development.
Education is one of the most powerful tools to fight poverty. Children who attend school are more likely to find employment, earn higher incomes, and escape poverty as adults. However, in many low-income countries, families cannot afford school fees, uniforms, or supplies. Girls are especially at risk of dropping out due to early marriage or domestic responsibilities.
Poverty has wide-reaching consequences. It increases social instability, fuels crime, and contributes to political unrest. In democratic societies, economic inequality can weaken public trust and reduce participation in civic life. Globally, poverty limits economic growth, as poor populations have low purchasing power and limited ability to invest in their futures.
Efforts to reduce poverty involve both short-term relief and long-term development. Humanitarian aid provides food, shelter, and emergency healthcare in times of crisis. Development programs focus on building roads, schools, and hospitals, as well as creating job opportunities. Microfinance initiatives help small entrepreneurs start or expand businesses with small loans.
Social protection policies, such as cash transfers, pensions, and unemployment benefits, play a vital role in preventing families from falling into extreme poverty. In countries like Brazil and Mexico, conditional cash transfer programs have successfully improved school attendance and health outcomes among low-income families.
The global community has recognized poverty as a priority issue. The United
Nations Sustainable Development Goals (SDGs) aim to end extreme poverty by 2030. This goal requires coordinated efforts among governments, nongovernmental organizations, businesses, and communities. Climate action, education, gender equality, and economic growth are all interconnected with poverty reduction.
Technology and innovation offer new opportunities to address poverty. Mobile banking allows people in remote areas to save money and access loans. E-learning platforms provide education to students in underserved regions. Agricultural innovations, such as drought-resistant seeds and smart irrigation systems, help farmers increase yields and incomes.
Despite progress, challenges remain. Income inequality is rising in many countries, even as poverty rates decline. The COVID-19 pandemic reversed years of improvement by increasing job loss, food insecurity, and school closures. Conflicts in regions like the Middle East and sub-Saharan Africa have displaced millions and disrupted development efforts.
In conclusion, poverty is a complex and urgent global issue that affects health, education, equality, and peace. It cannot be solved by charity alone; sustainable solutions require investment, good governance, social inclusion, and international cooperation. A world without poverty is possible—but only if we address its root causes and ensure that progress reaches even the most vulnerable.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose is to define poverty, explain its causes and consequences, describe efforts to reduce it, and emphasize that sustainable solutions require addressing root causes through investment, governance, and international cooperation.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is the difference between absolute poverty and relative poverty?',
        explanation: 'Absolute poverty is the inability to afford basic necessities of life, measured by the international poverty line of $2.15 per day, while relative poverty is based on income significantly below the national average within a society, limiting full participation.',
      ),
      ReadingQuestion(
        question: 'The word "interconnected" in the third paragraph most likely means...',
        explanation: 'In the context of the passage, "interconnected" means linked or related to one another, referring to the multiple causes of poverty that influence and reinforce each other.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the relationship between health and poverty?',
        explanation: 'It can be inferred that poor health and poverty form a cycle, as disease and malnutrition reduce the ability to work or learn, which in turn keeps families trapped in poverty.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why is education considered a powerful tool against poverty?',
        explanation: 'Children who attend school are more likely to find employment, earn higher incomes, and escape poverty as adults, although barriers such as costs and gender discrimination often prevent access.',
      ),
      ReadingQuestion(
        question: 'The word "stunted" in the fifth paragraph most likely means...',
        explanation: 'In the context of the passage, "stunted" means slowed or hindered in growth and development, referring to the physical and cognitive effects of malnutrition on children.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the impact of the COVID-19 pandemic on poverty?',
        explanation: 'It can be inferred that the pandemic reversed years of progress by causing job losses, food insecurity, and school closures, thereby increasing poverty levels.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what role do social protection policies play?',
        explanation: 'Social protection policies such as cash transfers, pensions, and unemployment benefits help prevent families from falling into extreme poverty and have improved school attendance and health outcomes in countries like Brazil and Mexico.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of technology in fighting poverty?',
        explanation: 'It can be inferred that technology provides practical tools—such as mobile banking, e-learning, and agricultural innovations—that improve access to finance, education, and higher farm yields for people in poverty.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is required for sustainable solutions to poverty?',
        explanation: 'Sustainable solutions require investment, good governance, social inclusion, and international cooperation rather than charity alone, in order to address root causes and reach the most vulnerable.',
      ),
    ],
  ),

  ReadingPassage(
    id: 97,
    title: 'Overpopulation',
    topic: 'Society & Environment',
    content: '''Overpopulation occurs when the number of people in a given area exceeds the resources and capacity needed to support them. This phenomenon is often discussed in the context of global population growth and its impact on food supply, housing, environment, and public services. Although population growth has slowed in many developed countries, global numbers continue to rise, particularly in developing regions.
The world‘s population surpassed 8 billion in 2022 and is projected to keep increasing, especially in countries across Africa and South Asia. While population growth itself is not inherently negative, rapid and unmanaged growth can place immense strain on natural resources, infrastructure, and social systems.
One of the primary concerns of overpopulation is the pressure on resources. As population increases, so does the demand for food, water, and energy. Agricultural land becomes overused, forests are cleared for farming or settlement, and water sources are depleted or polluted. In many densely populated areas, this leads to soil degradation, loss of biodiversity, and scarcity of drinking water.
Urban areas experience significant impacts. Overcrowded cities face challenges in housing, transportation, sanitation, and waste management. Slums and informal settlements grow when housing cannot keep up with demand. These areas often lack clean water, electricity, and sewage systems, increasing the risk of disease and poor living conditions. Traffic congestion, air pollution, and overburdened public services become common features of life in megacities.
Unemployment and poverty are also linked to overpopulation. When the labor force grows faster than job creation, unemployment rises, and wages fall. This leads to higher rates of poverty, especially among young people and women. In rural areas, land fragmentation can make farming unprofitable, pushing people to migrate to cities in search of work, further increasing urban pressures.
Healthcare and education systems struggle to keep up with population growth. In regions with high birth rates, hospitals and schools are often overcrowded, underfunded, and understaffed. Children may receive poor-quality education, and maternal and child health services become overstretched, leading to higher rates of illness and mortality.
Overpopulation also contributes significantly to environmental degradation. More people means more cars, more waste, and higher energy consumption. Greenhouse gas emissions increase, driving climate change. Deforestation and habitat destruction accelerate as land is cleared for housing and agriculture. Wildlife faces extinction due to loss of habitat and overexploitation of resources.
Despite these challenges, some experts argue that the problem is not simply population numbers but how resources are used and distributed. For example, a relatively small portion of the global population consumes the majority of the world‘s resources and produces most of its pollution. Wealthy nations with stable or declining populations still have a large environmental footprint. Therefore, addressing overconsumption and inequality is as important as managing population size.
Family planning is one of the most effective tools for addressing overpopulation. Access to contraception, reproductive healthcare, and education—particularly for women and girls—leads to lower birth rates and more sustainable population growth. Studies have shown that when women are educated and empowered, they tend to marry later and have fewer children.
Government policies also influence population trends. In the past, some countries introduced controversial measures to control growth. China‘s former one-child policy is one such example. While it helped slow population growth, it also led to negative social consequences, such as gender imbalance and an aging population. Today, more humane and rights-based approaches to family planning are promoted.
Technology and innovation offer potential solutions to cope with overpopulation. Advances in agriculture—such as vertical farming, genetically modified crops, and efficient irrigation—can increase food production. Renewable energy, smart city planning, and public transportation systems can reduce environmental impacts and improve quality of life in urban areas.
Migration policies and regional development can also help. Encouraging people to settle in less populated or rural areas, investing in small towns, and decentralizing economic activity can relieve pressure on major cities. However, such efforts require careful planning and adequate resources.
Education is a key component of any long-term solution. Teaching people about sustainability, resource management, and reproductive health equips them to make informed choices. Public awareness campaigns, media engagement, and school curricula can all promote responsible behaviors and policy support.
In conclusion, overpopulation remains a pressing global issue, particularly in regions where population growth outpaces development. Its consequences affect health, education, the environment, and social stability. However, with smart planning, technological innovation, investment in education, and international cooperation, it is possible to manage population growth sustainably and improve quality of life for future generations.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to examine overpopulation as a global challenge, describing its causes, impacts on resources, cities, economy, health, and environment, while outlining solutions such as family planning, technology, and education.',
      ),
      ReadingQuestion(
        question: 'According to the passage, when did the world‘s population surpass 8 billion?',
        explanation: 'According to the passage, the world‘s population surpassed 8 billion in 2022 and is projected to keep increasing, especially in countries across Africa and South Asia.',
      ),
      ReadingQuestion(
        question: 'The word "depleted" in the third paragraph most likely means',
        explanation: 'In the context of the third paragraph, "depleted" means used up or reduced to a low level, referring to water sources that become exhausted or polluted due to rising population demand.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the relationship between overpopulation and urban living conditions?',
        explanation: 'It can be inferred that rapid population growth leads to overcrowded cities where housing shortages create slums lacking basic services, resulting in higher disease risks, traffic congestion, air pollution, and strained public infrastructure.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how does overpopulation contribute to environmental degradation?',
        explanation: 'According to the passage, more people lead to more cars, waste, and energy use, increasing greenhouse gas emissions and climate change, while deforestation and habitat destruction accelerate, threatening wildlife with extinction.',
      ),
      ReadingQuestion(
        question: 'The phrase "land fragmentation" in the fifth paragraph most likely refers to',
        explanation: 'In the context of the fifth paragraph, "land fragmentation" refers to the division of farmland into smaller, less viable plots, which can make farming unprofitable and push rural people to migrate to cities.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of women‘s education in addressing overpopulation?',
        explanation: 'It can be inferred that educating and empowering women is highly effective because studies show they then tend to marry later and have fewer children, leading to lower birth rates and more sustainable population growth.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what were some negative consequences of China‘s former one-child policy?',
        explanation: 'According to the passage, while the policy helped slow population growth, it led to negative social consequences such as gender imbalance and an aging population, which is why more rights-based approaches are now promoted.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the argument that overconsumption matters as much as population size?',
        explanation: 'It can be inferred that a relatively small wealthy portion of the global population consumes most resources and produces most pollution, so addressing inequality and overconsumption in rich nations is as important as controlling population growth in developing regions.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how can technology help cope with overpopulation?',
        explanation: 'According to the passage, advances such as vertical farming, genetically modified crops, efficient irrigation, renewable energy, smart city planning, and public transportation can increase food production, reduce environmental impacts, and improve urban quality of life.',
      ),
    ],
  ),

  ReadingPassage(
    id: 98,
    title: 'Globalization',
    topic: 'Economy & Society',
    content: '''Globalization refers to the growing interconnection of the world‘s economies, cultures, and populations, brought about by cross-border trade, investment, information technology, and the movement of people and ideas. Over the past few decades, globalization has transformed how countries interact and how individuals live and work.
At its core, globalization is driven by technological advances and economic liberalization. Innovations in transport and communication—such as jet travel, container shipping, the internet, and mobile technology—have dramatically reduced the barriers of time and space. At the same time, many countries have reduced tariffs, opened their markets to foreign investment, and adopted policies that encourage international business.
One of the most visible effects of globalization is international trade. Goods produced in one country are sold all over the world. For example, smartphones may be designed in the United States, manufactured in China, and assembled with parts from Japan, South Korea, and Germany. Global supply chains connect producers and consumers across continents.
Multinational corporations (MNCs) are major players in globalization. Companies like Apple, Toyota, and Unilever operate in multiple countries, creating jobs and transferring technology. Foreign direct investment (FDI) by such firms often helps developing countries grow by bringing in capital, skills, and access to new markets.
Cultural exchange is another significant aspect of globalization. Through films, music, fashion, and cuisine, people around the world are exposed to different ways of life. American fast food chains, Korean pop music, Indian cinema, and Japanese video games are examples of cultural products that have global reach. This exposure fosters mutual understanding but also raises concerns about cultural erosion and loss of local identity.
Labor mobility is part of the globalization process. People migrate for work, education, or safety, contributing to global knowledge-sharing and economic activity. Many economies rely on migrant workers to fill labor gaps, especially in agriculture, construction, and healthcare. At the same time, this movement has led to debates about immigration, national security, and cultural integration.
The digital revolution has accelerated globalization. Online platforms enable instant communication, remote work, and e-commerce. Small businesses can sell products internationally with the help of digital payment systems and global logistics. Educational institutions offer online courses to students worldwide, breaking down barriers to knowledge.
Despite these benefits, globalization has also led to economic inequality. While some countries and individuals have gained enormously, others have been left behind. Jobs in manufacturing have moved from high-income to low-income countries, leading to unemployment and social tension in some regions. In the Global South, workers may face poor working conditions and low wages in factories supplying goods to richer nations.
Environmental concerns are another major issue. Increased production and transportation contribute to carbon emissions and resource depletion. Critics argue that globalization promotes a model of overconsumption and unsustainable growth. Global supply chains can make it difficult to enforce environmental standards or hold polluters accountable.
The global financial system is more interconnected than ever, but also more vulnerable to shocks. The 2008 financial crisis showed how economic problems in one country can spread rapidly across borders. During the COVID-19 pandemic, disruptions in trade and travel exposed weaknesses in global supply chains and healthcare coordination.
Nationalism and protectionism have gained popularity in response to the perceived downsides of globalization. Some governments have implemented tariffs, tightened immigration rules, or withdrawn from international agreements. Brexit, for instance, reflected concerns over sovereignty, immigration, and economic dependence. The challenge is to balance national interests with the benefits of cooperation.
International institutions play a key role in managing globalization. Organizations such as the World Trade Organization (WTO), International Monetary Fund (IMF), and United Nations (UN) help countries work together on trade rules, financial stability, and global challenges like climate change. However, these institutions face criticism for being dominated by powerful countries or failing to protect vulnerable populations.
To make globalization more inclusive and sustainable, many experts advocate for reforms. These include fairer trade agreements, stronger labor and environmental protections, corporate accountability, and support for education and infrastructure in poorer regions. Technology must be harnessed to close—not widen—gaps between and within countries.
Education is crucial. A globalized world requires workers who can adapt, innovate, and collaborate across cultures. Language skills, digital literacy, and cross-cultural understanding are becoming essential in the modern workforce.
In conclusion, globalization is a complex and dynamic process that has reshaped the world. It offers opportunities for growth, connection, and innovation, but also presents serious challenges in terms of inequality, environmental impact, and cultural preservation. How societies manage globalization in the years ahead will determine whether its benefits are shared widely or remain concentrated among the few.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to define globalization as the growing interconnection of economies, cultures, and populations, describe its drivers and effects such as trade, multinational corporations, cultural exchange, labor mobility, and digital acceleration, examine challenges including inequality, environmental harm, and financial vulnerability, discuss responses like nationalism and the role of international institutions, and conclude that managing it inclusively will determine whether benefits are widely shared.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what drives globalization at its core?',
        explanation: 'According to the passage, globalization is driven by technological advances and economic liberalization: innovations in transport and communication have reduced barriers of time and space, while many countries have reduced tariffs, opened markets to foreign investment, and adopted policies encouraging international business.',
      ),
      ReadingQuestion(
        question: 'The word "interconnection" in the first paragraph most likely means',
        explanation: 'In the first paragraph, "interconnection" most likely means the growing links and interdependence among the world‘s economies, cultures, and populations brought about by cross-border trade, investment, information technology, and the movement of people and ideas.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the role of multinational corporations in globalization?',
        explanation: 'It can be inferred that multinational corporations are major players because they operate in multiple countries, create jobs, transfer technology, and through foreign direct investment help developing countries grow by bringing capital, skills, and access to new markets.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are some effects of cultural exchange under globalization?',
        explanation: 'According to the passage, cultural exchange through films, music, fashion, and cuisine exposes people to different ways of life (examples include American fast food, Korean pop music, Indian cinema, and Japanese video games), fostering mutual understanding while also raising concerns about cultural erosion and loss of local identity.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about economic inequality resulting from globalization?',
        explanation: 'It can be inferred that globalization has produced uneven gains: while some countries and individuals have benefited enormously, others have been left behind, with manufacturing jobs moving from high-income to low-income countries causing unemployment and social tension, and workers in the Global South sometimes facing poor conditions and low wages.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how has the digital revolution accelerated globalization?',
        explanation: 'According to the passage, online platforms enable instant communication, remote work, and e-commerce; small businesses can sell internationally via digital payments and global logistics, and educational institutions offer online courses worldwide, breaking down barriers to knowledge.',
      ),
      ReadingQuestion(
        question: 'The phrase "protectionism" in the passage most likely refers to',
        explanation: 'In the passage, "protectionism" refers to policies such as implementing tariffs, tightening immigration rules, or withdrawing from international agreements that some governments have adopted in response to the perceived downsides of globalization, reflecting a preference for national interests over open cooperation.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the vulnerability of the global financial system?',
        explanation: 'It can be inferred that greater interconnection makes the system more vulnerable to shocks, as shown by the 2008 financial crisis spreading rapidly across borders and by COVID-19 disruptions exposing weaknesses in global supply chains and healthcare coordination.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what do experts advocate to make globalization more inclusive and sustainable?',
        explanation: 'According to the passage, experts advocate reforms including fairer trade agreements, stronger labor and environmental protections, corporate accountability, support for education and infrastructure in poorer regions, and harnessing technology to close rather than widen gaps between and within countries.',
      ),
    ],
  ),

  ReadingPassage(
    id: 99,
    title: 'Animal Testing',
    topic: 'Science & Ethics',
    content: '''Animal testing, also known as animal experimentation, refers to the use of nonhuman animals in scientific research and product development. It is commonly used to test the safety and effectiveness of medical treatments, cosmetics, chemicals, and household products. While supporters argue it is essential for scientific progress, critics believe it is unethical and unnecessary in the modern world.
Historically, animal testing has played a central role in the development of vaccines, antibiotics, and surgical procedures. For example, insulin was discovered through experiments on dogs, and polio vaccines were developed using monkeys. Many scientific breakthroughs would not have been possible without animal research, and it continues to contribute to treatments for diseases such as cancer,
HIV/AIDS, and Alzheimer‘s.
Animals are used in a wide range of research. Rodents such as mice and rats make up the majority of test subjects due to their small size, short lifespans, and genetic similarities to humans. Rabbits, monkeys, dogs, and pigs are also used for specific types of testing. Procedures may involve administering drugs, performing surgeries, or observing behavior under controlled conditions.
Supporters of animal testing argue that it provides valuable insights into biological systems and disease processes. Animal models allow researchers to study the effects of substances on living organisms before moving to human trials. They claim that without such testing, the development of medicines and treatments would be slower and riskier.
Furthermore, regulatory agencies in many countries require animal testing before new drugs or products are approved for human use. This is seen as a necessary step to ensure public safety. For example, pharmaceutical companies must demonstrate that their products are not toxic, carcinogenic, or harmful to organs before beginning clinical trials in humans.
However, animal testing is highly controversial and raises serious ethical concerns.
Opponents argue that it is cruel to subject animals to pain, suffering, or death for human benefit. They point out that animals are sentient beings with the capacity to feel fear and distress, and that they should be protected from unnecessary harm. Critics also question the scientific reliability of animal experiments. They argue that differences in biology, genetics, and metabolism between humans and animals can lead to misleading results. In some cases, drugs that passed animal tests later failed in human trials, either because they were ineffective or caused unexpected side effects. This has led some scientists to advocate for alternative methods.
In recent years, non-animal testing alternatives have advanced significantly. These include in vitro (test tube) methods using human cells and tissues, computer modeling, and organ-on-a-chip technologies. These systems aim to replicate human responses more accurately and avoid ethical issues associated with animal use. While not yet capable of replacing all forms of testing, they are increasingly being adopted in research and development.
Many countries now have regulations to reduce animal testing. The ―3Rs‖ principle—Replacement, Reduction, and Refinement—guides researchers to seek alternatives, use fewer animals, and minimize suffering whenever possible. The European Union has banned the sale of cosmetics tested on animals and funds research into humane testing methods. In the United States and other regions, laws require ethical review and justification before animal experiments are approved.
Despite these developments, animal testing still persists in large quantities. Globally, tens of millions of animals are used in research each year. In some countries, enforcement of ethical standards is weak or non-existent, leading to unregulated and inhumane practices. Animal rights organizations continue to campaign for stricter laws and greater transparency.
The debate over animal testing involves a complex balance between scientific advancement, human safety, and animal welfare. On one hand, researchers argue that the risks of skipping animal trials could lead to public health disasters. On the other, animal rights advocates stress the moral obligation to treat all living beings with respect and compassion.
Public opinion on the issue varies. Surveys show that many people support animal testing when it is used for medical research but oppose it for cosmetics or nonessential products. Awareness campaigns, documentaries, and celebrity endorsements have helped shift attitudes, especially among younger generations.
Educational institutions are also adapting. Some universities now use simulations and virtual dissections instead of live animals in biology classes. Medical training is increasingly conducted using realistic mannequins or computer software, reducing the need for animal models.
In conclusion, animal testing remains a deeply controversial but evolving practice. It has contributed significantly to scientific and medical progress, yet it also poses ethical dilemmas that cannot be ignored. As technology advances, the future may see a decline in animal testing and greater reliance on humane, effective alternatives. Achieving this will require global cooperation, investment in innovation, and a commitment to both science and compassion.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of the passage is to explain animal testing as the use of non-human animals in research and product development, outline its historical contributions and current uses, present arguments for and against it, discuss ethical concerns and scientific limitations, and describe emerging alternatives and regulations that may reduce its use.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what historical medical advances depended on animal testing?',
        explanation: 'According to the passage, animal testing played a central role in the development of vaccines, antibiotics, and surgical procedures; for example, insulin was discovered through experiments on dogs and polio vaccines were developed using monkeys, and it continues to contribute to treatments for diseases such as cancer, HIV/AIDS, and Alzheimer\'s.',
      ),
      ReadingQuestion(
        question: 'The word "sentient" in the paragraph about ethical concerns most likely means',
        explanation: 'In the context of the passage, "sentient" most likely means capable of feeling or experiencing sensations such as fear and distress, as opponents argue that animals are sentient beings that should be protected from unnecessary harm.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the reliability of animal testing from the passage?',
        explanation: 'It can be inferred that animal testing is not always scientifically reliable because differences in biology, genetics, and metabolism between humans and animals can produce misleading results, and some drugs that passed animal tests later failed in human trials due to ineffectiveness or unexpected side effects.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what is the "3Rs" principle?',
        explanation: 'According to the passage, the "3Rs" principle—Replacement, Reduction, and Refinement—guides researchers to seek alternatives to animal testing, use fewer animals, and minimize suffering whenever possible.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about public opinion on animal testing?',
        explanation: 'It can be inferred that public support for animal testing is conditional: many people accept it for medical research but oppose it for cosmetics or non-essential products, and awareness campaigns have helped shift attitudes, particularly among younger generations.',
      ),
      ReadingQuestion(
        question: 'The phrase "in vitro" in the paragraph about alternatives most likely means',
        explanation: 'In the context of the passage, "in vitro" most likely means experiments conducted in a test tube or outside a living organism, using human cells and tissues as one of the non-animal testing alternatives that aim to replicate human responses more accurately.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why do regulatory agencies require animal testing?',
        explanation: 'According to the passage, regulatory agencies in many countries require animal testing before new drugs or products are approved for human use as a necessary step to ensure public safety, for example by demonstrating that products are not toxic, carcinogenic, or harmful to organs before clinical trials begin.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the future of animal testing from the conclusion?',
        explanation: 'It can be inferred that as technology advances, animal testing may decline in favor of more humane and effective alternatives, but achieving this shift will require global cooperation, investment in innovation, and a commitment to both scientific progress and compassion.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how are educational institutions reducing the use of animals?',
        explanation: 'According to the passage, some universities now use simulations and virtual dissections instead of live animals in biology classes, and medical training increasingly relies on realistic mannequins or computer software, thereby reducing the need for animal models.',
      ),
    ],
  ),

  ReadingPassage(
    id: 100,
    title: 'Zoos',
    topic: 'Animals & Conservation',
    content: '''Zoos are facilities that house animals for public viewing, education, research, and conservation. They have existed in various forms for thousands of years, from royal menageries in ancient civilizations to the modern zoological parks found across the world today. While zoos offer opportunities for recreation and learning, they are also subjects of ongoing ethical debate regarding animal welfare and conservation effectiveness.
The traditional purpose of zoos was entertainment. People visited to see exotic animals from distant parts of the world, many of which they could not otherwise encounter. Over time, however, the mission of zoos has expanded to include education, species preservation, and scientific research. Today, many zoos present themselves as conservation centers, playing a role in protecting endangered species and raising public awareness of environmental issues.
Education is one of the main justifications for zoos. By observing animals up close, visitors—especially children—can learn about biodiversity, ecosystems, and animal behavior. Informational signs, guided tours, and interactive exhibits aim to increase public understanding of wildlife. Proponents argue that this exposure fosters a connection between people and animals, encouraging conservationminded behavior.
Conservation is another key function. Zoos are involved in breeding programs for endangered species, often in cooperation with global networks. These programs help preserve genetic diversity and may provide animals for future reintroduction into the wild. The reintroduction of species such as the Arabian oryx and the California condor are cited as success stories made possible by zoo-based conservation efforts.
Scientific research conducted in zoos contributes to veterinary science, animal behavior studies, and wildlife management. Studying animals in a controlled environment allows scientists to collect data that would be difficult or impossible to gather in the wild. This research can improve care practices and inform conservation strategies.
Despite these benefits, zoos face criticism, particularly from animal rights advocates who question the ethics of keeping wild animals in captivity. Opponents argue that many zoo enclosures are too small or lack environmental complexity, causing stress, boredom, or abnormal behaviors—known as "zoochosis"—such as pacing or self-harm.
Even in modern, well-funded zoos, some animals do not thrive. Large, wideranging species like elephants, polar bears, and big cats often suffer in confined spaces. Critics also question whether breeding endangered animals in captivity— without realistic plans for release—truly contributes to conservation or merely maintains populations for display purposes.
Animal welfare concerns are heightened in poorly managed zoos or roadside attractions, where conditions can be inhumane. In some regions, zoos operate with little oversight, inadequate funding, or no veterinary care. International organizations like the World Association of Zoos and Aquariums (WAZA) set ethical guidelines and accreditation standards, but enforcement varies widely by country.
Another criticism is that zoos can give the public a misleading view of animals. Animals in enclosures behave differently from those in the wild, and their surroundings are often artificial. This may reduce visitors‘ understanding of true animal behavior or the challenges wildlife faces in natural habitats.
In recent years, alternatives to traditional zoos have gained popularity. Wildlife sanctuaries, nature reserves, and safari parks offer more naturalistic environments, allowing animals to roam freely while still being protected and observed. Virtual reality and high-definition nature documentaries also provide new ways to educate the public without keeping animals in captivity.
Supporters of zoos counter that not all species can be protected or studied in the wild due to habitat destruction, poaching, or human conflict. For some animals, captivity may be the only option for survival. Zoos can serve as a last refuge for animals threatened by extinction, while also promoting broader environmental awareness.
Zoos also contribute economically and socially. They attract tourism, provide jobs, and support local economies. In urban areas, zoos offer accessible green spaces and educational resources, especially for children who may never have the chance to see wildlife in natural settings.
Efforts are ongoing to improve zoo practices. Modern zoos are increasingly investing in enrichment programs to stimulate animals mentally and physically. Larger, more naturalistic enclosures are becoming the standard, and many zoos now prioritize the welfare of animals over the size or rarity of their collections.
Public expectations are shifting as well. Many visitors now demand higher ethical standards, transparency, and evidence of genuine conservation work. Zoos that fail to adapt to these expectations may lose public trust, funding, and attendance.
In conclusion, zoos are complex institutions that play multiple roles in society. They offer educational value, support conservation, and contribute to scientific knowledge. At the same time, they raise serious ethical questions about animal rights and the effectiveness of captivity. The future of zoos depends on their ability to balance these roles, improve animal welfare, and evolve into truly responsible centers for conservation and learning.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The passage examines zoos as facilities for viewing, education, research, and conservation, discusses their historical evolution and benefits, presents ethical criticisms regarding animal welfare and captivity, explores alternatives, and concludes that their future depends on balancing roles while improving welfare and becoming responsible conservation centers.',
      ),
      ReadingQuestion(
        question: 'According to the passage, how has the mission of zoos expanded over time?',
        explanation: 'The traditional purpose was entertainment for viewing exotic animals, but the mission has expanded to include education, species preservation, and scientific research; today many zoos present themselves as conservation centers protecting endangered species and raising environmental awareness.',
      ),
      ReadingQuestion(
        question: 'The word "zoochosis" in the paragraph about animal rights criticism most likely means',
        explanation: 'It refers to abnormal behaviors caused by stress, boredom, or inadequate enclosures in captivity, such as pacing or self-harm, as described by opponents of keeping wild animals in zoos.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the effectiveness of zoo-based conservation programs?',
        explanation: 'Breeding programs help preserve genetic diversity and may provide animals for reintroduction into the wild, with success stories like the Arabian oryx and California condor, though critics question whether breeding without realistic release plans truly contributes to conservation or mainly maintains display populations.',
      ),
      ReadingQuestion(
        question: 'According to the passage, why do some large species struggle in zoos?',
        explanation: 'Even in modern, well-funded zoos, large, wide-ranging species like elephants, polar bears, and big cats often suffer in confined spaces that are too small or lack environmental complexity.',
      ),
      ReadingQuestion(
        question: 'The word "enrichment" in the paragraph about improving zoo practices most likely means',
        explanation: 'It refers to programs designed to stimulate animals mentally and physically, as modern zoos invest in enrichment to improve welfare along with larger, more naturalistic enclosures.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about alternatives to traditional zoos?',
        explanation: 'Wildlife sanctuaries, nature reserves, and safari parks offer more naturalistic environments where animals can roam freely while being protected and observed; virtual reality and nature documentaries also educate the public without captivity.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what economic and social contributions do zoos make?',
        explanation: 'Zoos attract tourism, provide jobs, and support local economies; in urban areas they offer accessible green spaces and educational resources, especially for children who may never see wildlife in natural settings.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about public expectations of zoos?',
        explanation: 'Public expectations are shifting as many visitors now demand higher ethical standards, transparency, and evidence of genuine conservation work; zoos that fail to adapt may lose public trust, funding, and attendance.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what role does scientific research in zoos play?',
        explanation: 'Research in controlled environments contributes to veterinary science, animal behavior studies, and wildlife management by allowing data collection that would be difficult or impossible in the wild, improving care practices and informing conservation strategies.',
      ),
    ],
  ),

  ReadingPassage(
    id: 101,
    title: 'Privacy and Surveillance',
    topic: 'Society & Technology',
    content: '''Privacy refers to an individual‘s right to control their personal information, communications, and daily activities without unwanted intrusion. Surveillance, in contrast, involves monitoring individuals or groups—often by governments or corporations—for purposes such as national security, law enforcement, or commercial profit. Because modern technology enables constant data collection, the balance between privacy and surveillance has become one of the most debated issues of the 21st century.
Although surveillance is often justified in the name of public safety, it raises serious concerns about human rights and democratic values. Not only can it be used to detect crime, but it may also be misused to suppress dissent, invade private lives, or manipulate public behavior. If left unchecked, surveillance can lead to authoritarian control and loss of civil liberties.
Governments increasingly use surveillance systems such as CCTV cameras, phone tapping, internet monitoring, and biometric tracking. While these tools may deter crime or terrorism, they also monitor ordinary citizens. In many countries, data is collected without consent and stored indefinitely. Because legal safeguards are often weak or outdated, individuals may not even know they are being watched.
Mass surveillance has become especially widespread in the digital age. Every time a person uses a smartphone, sends an email, or browses the internet, data is collected. Search engines, social media platforms, and mobile apps track user behavior to generate profit through targeted advertising. Even though users agree to terms and conditions, many are unaware of how their data is used or shared. National security is the most common justification for surveillance. Following major terrorist attacks, countries have passed laws granting intelligence agencies expanded powers to monitor communication. Supporters argue that such measures are necessary to protect the public and prevent future attacks. They believe that if a person has nothing to hide, they have nothing to fear.
However, critics argue this logic is dangerous. They point out that privacy is not about hiding wrongdoing—but about protecting personal freedom. If governments or corporations know every detail about someone‘s life, they can control or influence that person in subtle ways. This may lead to self-censorship, social pressure, or political fear.
Another major concern is data breaches. When sensitive personal information is stored on government or corporate servers, it becomes a target for hackers. Identity theft, blackmail, and financial fraud are just some of the consequences. Because security is never perfect, collecting large amounts of data always carries risks. Surveillance technology is also being used in controversial ways. Facial recognition systems, predictive policing, and artificial intelligence are used to identify potential threats before crimes occur. Although such tools promise efficiency, they often rely on biased algorithms or flawed data, leading to wrongful accusations or discrimination—particularly against minorities.
Some countries have implemented strong privacy laws. The European Union‘s General Data Protection Regulation (GDPR) gives individuals more control over their personal data and requires companies to be transparent. If similar regulations were adopted globally, users could protect their privacy more effectively.
Nevertheless, enforcement remains a challenge. Even in countries with strong laws, powerful companies often operate across borders and avoid responsibility. Unless global standards are created, data privacy will remain inconsistent and difficult to defend.
Public awareness is rising. Many people are now using encrypted apps, disabling location services, or rejecting cookies to limit tracking. However, complete privacy is almost impossible in a connected world. Even if someone avoids social media, their information may still be collected by others or leaked online.
Some argue that privacy is outdated in the digital age. They claim that total transparency improves safety, efficiency, and convenience. For example, smart cities use surveillance to manage traffic, detect emergencies, and reduce crime. While this may be true, it raises the question: who controls the data, and for what purpose?
Ultimately, the challenge is not choosing between privacy and security—but balancing the two. Surveillance may be necessary in some contexts, but it must be limited, transparent, and subject to democratic oversight. If surveillance becomes too powerful, society may sacrifice the very freedoms it seeks to protect.
However, if privacy is fully ignored, individuals lose autonomy, dignity, and control over their own lives. Democracies depend on free thought, open debate, and the ability to live without constant observation.''',
    questions: [
      ReadingQuestion(
        question: 'What is the main purpose of this passage?',
        explanation: 'The main purpose of this passage is to examine the tension between privacy as an individual right and surveillance by governments and corporations, discuss the justifications and risks of modern surveillance technologies, highlight concerns such as data breaches, bias, and loss of civil liberties, and argue for a balanced approach that limits surveillance through transparency, legal safeguards, and democratic oversight.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what are some common forms of government surveillance?',
        explanation: 'Governments use systems such as CCTV cameras, phone tapping, internet monitoring, and biometric tracking. These tools may deter crime or terrorism but also monitor ordinary citizens, often collecting data without consent and storing it indefinitely.',
      ),
      ReadingQuestion(
        question: 'The word \'transboundary\' is not used, but the word \'indefinitely\' in the passage most likely means?',
        explanation: 'It most likely means without a set end or for an unlimited period of time, as the passage states that in many countries data is collected without consent and stored indefinitely because legal safeguards are often weak or outdated.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the author\'s view on the argument that people with nothing to hide have nothing to fear?',
        explanation: 'It can be inferred that the author considers this argument dangerous, because privacy is presented as a protection of personal freedom rather than a way to hide wrongdoing, and extensive knowledge of someone\'s life by governments or corporations can lead to control, self-censorship, social pressure, or political fear.',
      ),
      ReadingQuestion(
        question: 'According to the passage, what risks are associated with collecting large amounts of personal data?',
        explanation: 'Collecting large amounts of data always carries risks because security is never perfect. Sensitive information stored on servers becomes a target for hackers, potentially leading to identity theft, blackmail, and financial fraud.',
      ),
      ReadingQuestion(
        question: 'What can be inferred about the effectiveness of current privacy protections?',
        explanation: 'It can be inferred that privacy protections remain limited and inconsistent, as even strong laws like the GDPR face enforcement challenges when companies operate across borders, and without global standards data privacy is difficult to defend fully in a connected world where complete privacy is almost impossible.',
      ),
    ],
  ),
];
