// Исправленный класс Environment
class Environment {
  // Убедимся, что API_URL не заканчивается слешем, чтобы избежать двойных слешей
  static String get API_URL {
    const String baseUrl = 'https://tehnostrelka.etherveil.baby/api';
    // Убираем завершающий слеш, если он есть
    if (baseUrl.endsWith('/')) {
      return baseUrl.substring(0, baseUrl.length - 1);
    }
    return baseUrl;
  }

  // Метод для получения полного URL с явным слешем на конце
  static String getFullUrl(String path) {
    // Убедимся, что путь начинается со слеша
    String normalizedPath = path;
    if (!normalizedPath.startsWith('/')) {
      normalizedPath = '/$normalizedPath';
    }

    // Убедимся, что путь заканчивается слешем
    if (!normalizedPath.endsWith('/')) {
      normalizedPath = '$normalizedPath/';
    }

    return '$API_URL$normalizedPath';
  }
}