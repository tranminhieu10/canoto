/// Trạng thái phiếu cân
enum WeighingStatus {
  /// Đang chờ cân lần 1
  pending('pending', 'Chờ cân'),

  /// Đã cân lần 1 (cân tổng)
  firstWeighed('first_weighed', 'Đã cân lần 1'),

  /// Đã cân lần 2 (cân bì)
  completed('completed', 'Hoàn thành'),

  /// Đã hủy
  cancelled('cancelled', 'Đã hủy');

  final String value;
  final String displayName;

  const WeighingStatus(this.value, this.displayName);

  static WeighingStatus fromValue(String value) {
    return WeighingStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => WeighingStatus.pending,
    );
  }
}

/// Loại cân
enum WeighingType {
  /// Cân nhập (xe vào)
  incoming('incoming', 'Cân nhập'),

  /// Cân xuất (xe ra)
  outgoing('outgoing', 'Cân xuất');

  final String value;
  final String displayName;

  const WeighingType(this.value, this.displayName);

  static WeighingType fromValue(String value) {
    return WeighingType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => WeighingType.incoming,
    );
  }
}
