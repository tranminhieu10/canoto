/// API Endpoints cho ứng dụng
class ApiEndpoints {
  static const String baseUrl = 'http://localhost:8080/api';

  // Authentication
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';

  // Phiếu cân
  static const String weighingTickets = '/weighing-tickets';
  static const String weighingTicketById = '/weighing-tickets/{id}';
  static const String weighingTicketsByDate = '/weighing-tickets/by-date';
  static const String weighingTicketsByVehicle = '/weighing-tickets/by-vehicle';

  // Xe
  static const String vehicles = '/vehicles';
  static const String vehicleByPlate = '/vehicles/{plate}';

  // Khách hàng
  static const String customers = '/customers';
  static const String customerById = '/customers/{id}';

  // Sản phẩm/Hàng hóa
  static const String products = '/products';
  static const String productById = '/products/{id}';

  // Thiết bị
  static const String devices = '/devices';
  static const String deviceStatus = '/devices/status';

  // Báo cáo
  static const String reports = '/reports';
  static const String dailyReport = '/reports/daily';
  static const String monthlyReport = '/reports/monthly';

  // Cảnh báo
  static const String alerts = '/alerts';
  static const String alertSettings = '/alerts/settings';
}
