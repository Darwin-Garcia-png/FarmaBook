class AppConstants {
  static const String baseUrl = 'https://farmabook-mr5m.onrender.com';
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);

  static const String cloudinaryUploadUrl =
      'https://api.cloudinary.com/v1_1/dfffmvroq/image/upload';
  static const String cloudinaryUploadPreset = 'farmabook';

  static const String tokenKey = 'jwt_token';
  static const int defaultPageLimit = 20;
  static const int maxPageLimit = 100;
}
