class ApiConstants {
  static const String baseUrl = 'https://inventory.himaloyagrocare.com/api/v1';
  static const String defaultBaseUrl = baseUrl;
  static const String productionBaseUrl = baseUrl;

  // Auth Endpoints
  static const String login = '/login';
  static const String logout = '/logout';
  static const String me = '/me';

  // Core Endpoints
  static const String dashboard = '/dashboard';
  static const String products = '/products';
  static const String customers = '/customers';
  static const String employeeOrders = '/employee-orders';
  static const String dueCollections = '/due-collections';
  static const String dueCollectionHistory = '/due-collections/history';
  static const String targets = '/targets/my-targets';
  static const String deliveries = '/deliveries';
  static const String expenses = '/expenses';
  static const String notices = '/notices';
  static const String warehouses = '/warehouses';
}
