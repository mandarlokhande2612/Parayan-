class AppStrings {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Parayan Reader',
      'user_view': 'User View',
      'admin_view': 'Admin View',
      'user_mode': 'User',
      'admin_mode': 'Admin',
      'select_chapter': 'Select Chapter',
      'read_now': 'Read Now',
      'upload_pdf': 'Upload Chapter PDF',
      'admin_controls': 'Admin Controls',
      'analytics': 'View Analytics',
      'chapters_list': 'Available Chapters',
    },
    'mr': {
      'app_title': 'पारायण वाचक',
      'user_view': 'वाचक विभाग',
      'admin_view': 'प्रशासक विभाग',
      'user_mode': 'वाचक',
      'admin_mode': 'प्रशासक',
      'select_chapter': 'अध्याय निवडा',
      'read_now': 'आत्ता वाचा',
      'upload_pdf': 'नवीन अध्याय पीडीएफ अपलोड करा',
      'admin_controls': 'प्रशासक नियंत्रण',
      'analytics': 'वाचक आकडेवारी पहा',
      'chapters_list': 'उपलब्ध अध्याय',
    },
  };

  static String get(String key, String langCode) {
    return _localizedValues[langCode]?[key] ?? key;
  }
}