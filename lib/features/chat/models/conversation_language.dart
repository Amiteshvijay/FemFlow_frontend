class ConversationLanguage {
  final String code;
  final String localeId;
  final String name;
  final String nativeName;
  final bool isSupportedInMvp;

  const ConversationLanguage({
    required this.code,
    required this.localeId,
    required this.name,
    required this.nativeName,
    this.isSupportedInMvp = true,
  });

  static const List<ConversationLanguage> supportedLanguages = [
    ConversationLanguage(
      code: 'hi-IN',
      localeId: 'hi_IN',
      name: 'Hindi',
      nativeName: 'हिन्दी',
      isSupportedInMvp: true,
    ),
    ConversationLanguage(
      code: 'en-IN',
      localeId: 'en_IN',
      name: 'English',
      nativeName: 'English',
      isSupportedInMvp: true,
    ),
    ConversationLanguage(
      code: 'gu-IN',
      localeId: 'gu_IN',
      name: 'Gujarati',
      nativeName: 'ગુજરાતી',
      isSupportedInMvp: false,
    ),
    ConversationLanguage(
      code: 'ta-IN',
      localeId: 'ta_IN',
      name: 'Tamil',
      nativeName: 'தமிழ்',
      isSupportedInMvp: false,
    ),
    ConversationLanguage(
      code: 'te-IN',
      localeId: 'te_IN',
      name: 'Telugu',
      nativeName: 'తెలుగు',
      isSupportedInMvp: false,
    ),
    ConversationLanguage(
      code: 'bn-IN',
      localeId: 'bn_IN',
      name: 'Bengali',
      nativeName: 'বাংলা',
      isSupportedInMvp: false,
    ),
    ConversationLanguage(
      code: 'mr-IN',
      localeId: 'mr_IN',
      name: 'Marathi',
      nativeName: 'मराठी',
      isSupportedInMvp: false,
    ),
    ConversationLanguage(
      code: 'kn-IN',
      localeId: 'kn_IN',
      name: 'Kannada',
      nativeName: 'ಕನ್ನಡ',
      isSupportedInMvp: false,
    ),
    ConversationLanguage(
      code: 'ml-IN',
      localeId: 'ml_IN',
      name: 'Malayalam',
      nativeName: 'മലയാളം',
      isSupportedInMvp: false,
    ),
    ConversationLanguage(
      code: 'pa-IN',
      localeId: 'pa_IN',
      name: 'Punjabi',
      nativeName: 'ਪੰਜਾਬੀ',
      isSupportedInMvp: false,
    ),
  ];

  static ConversationLanguage getByCode(String code) {
    return supportedLanguages.firstWhere(
      (lang) => lang.code.toLowerCase() == code.toLowerCase() || lang.name.toLowerCase() == code.toLowerCase(),
      orElse: () => supportedLanguages.first,
    );
  }
}
