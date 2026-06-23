class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const addPlant = '/add-plant';
  static const identifyPlant = '/identify-plant';
  static const plantDetail = '/plant/:id';
  static const careLog = '/plant/:id/history';
  static const growthHistory = '/plant/:id/growth';
  static const profile = '/profile';
  static const notifications = '/notifications';

  static String plantDetailPath(String id) => '/plant/$id';
  static String careLogPath(String id) => '/plant/$id/history';
  static String growthHistoryPath(String id) => '/plant/$id/growth';
}
