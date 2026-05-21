class SymptomCategory {
  final String title;
  final List<String> items;

  SymptomCategory({required this.title, required this.items});
}

class SymptomConstants {
  static final List<SymptomCategory> categories = [
    SymptomCategory(title: 'Period & Flow', items: [
      'Cramps',
      'Heavy Flow',
      'Light Flow',
      'Spotting',
      'Clots',
      'Tender Breasts',
    ]),
    SymptomCategory(title: 'Pain', items: [
      'Back Pain',
      'Headache',
      'Pelvic Pain',
      'Leg Pain',
      'Body Ache',
    ]),
    SymptomCategory(title: 'Digestive', items: [
      'Bloating',
      'Nausea',
      'Constipation',
      'Diarrhea',
      'Food Cravings',
      'Appetite Change',
    ]),
    SymptomCategory(title: 'Skin & Body', items: [
      'Acne',
      'Oily Skin',
      'Dry Skin',
      'Hair Fall',
      'Swelling',
    ]),
    SymptomCategory(title: 'Energy & Sleep', items: [
      'Fatigue',
      'Low Energy',
      'Insomnia',
      'Sleepy',
    ]),
    SymptomCategory(title: 'Emotional', items: [
      'Mood Swings',
      'Irritated',
      'Anxious',
      'Emotional',
      'Sad',
    ]),
  ];

  static final List<String> defaultCompactSymptoms = [
    'Cramps',
    'Headache',
    'Bloating',
    'Back Pain',
    'Fatigue',
    'Acne',
  ];
}
