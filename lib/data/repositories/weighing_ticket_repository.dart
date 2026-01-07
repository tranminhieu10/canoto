import 'package:canoto/data/models/weighing_ticket.dart';

/// Repository cho phiếu cân
abstract class WeighingTicketRepository {
  /// Lấy tất cả phiếu cân
  Future<List<WeighingTicket>> getAll();

  /// Lấy phiếu cân theo ID
  Future<WeighingTicket?> getById(int id);

  /// Lấy phiếu cân theo số phiếu
  Future<WeighingTicket?> getByTicketNumber(String ticketNumber);

  /// Lấy phiếu cân theo biển số xe
  Future<List<WeighingTicket>> getByLicensePlate(String licensePlate);

  /// Lấy phiếu cân trong khoảng thời gian
  Future<List<WeighingTicket>> getByDateRange(DateTime from, DateTime to);

  /// Lấy phiếu cân theo trạng thái
  Future<List<WeighingTicket>> getByStatus(String status);

  /// Thêm phiếu cân mới
  Future<int> insert(WeighingTicket ticket);

  /// Cập nhật phiếu cân
  Future<int> update(WeighingTicket ticket);

  /// Xóa phiếu cân
  Future<int> delete(int id);

  /// Tạo số phiếu cân mới
  Future<String> generateTicketNumber();

  /// Đếm số phiếu cân trong ngày
  Future<int> countToday();

  /// Tổng khối lượng trong ngày
  Future<double> totalWeightToday();

  // ============ SYNC METHODS ============
  
  /// Lấy tất cả phiếu cân chưa đồng bộ (isSynced == false)
  Future<List<WeighingTicket>> getUnsynced();

  /// Đếm số phiếu cân chưa đồng bộ
  Future<int> countUnsynced();

  /// Đếm số phiếu cân đã đồng bộ
  Future<int> countSynced();

  /// Đánh dấu các phiếu cân đã đồng bộ
  Future<void> markAsSynced(List<int> localIds, List<int?>? azureIds);

  /// Đánh dấu một phiếu cân đã đồng bộ
  Future<void> markOneSynced(int localId, int? azureId);

  /// Lấy phiếu cân 30 ngày gần nhất
  Future<List<WeighingTicket>> getLast30Days();
}
