# Cân Ô Tô - Truck Weighing System

Ứng dụng quản lý cân ô tô tích hợp camera giám sát, barrier, nhận diện biển số và nhiều tính năng khác.

## Tính năng chính

### 1. Quản lý cân xe
- Kết nối đầu cân qua Serial/TCP
- Hiển thị trọng lượng realtime
- Cân 2 lần (cân tổng và cân bì)
- Tự động tính khối lượng hàng

### 2. Camera giám sát
- Kết nối IP Camera (RTSP)
- Chụp ảnh tự động khi cân
- Lưu ảnh theo phiếu cân

### 3. Nhận diện biển số (Vision Master)
- Tự động nhận diện biển số xe
- Hỗ trợ biển số Việt Nam
- Độ chính xác cao

### 4. Barrier/Barie
- Điều khiển barrier qua Modbus TCP
- Mở/đóng tự động
- Tích hợp với quy trình cân

### 5. In phiếu cân
- Kết nối máy in Windows
- Tùy chỉnh mẫu phiếu
- In tự động sau khi hoàn thành

### 6. Cảnh báo
- Cảnh báo thiết bị mất kết nối
- Cảnh báo cân quá tải
- Cảnh báo bảo mật

### 7. Báo cáo
- Báo cáo theo ngày/tháng
- Xuất Excel
- Thống kê tổng hợp

## Cấu trúc thư mục

```
lib/
├── core/                    # Core utilities
│   ├── constants/           # Hằng số
│   ├── theme/               # Theme
│   ├── utils/               # Tiện ích
│   └── errors/              # Xử lý lỗi
│
├── data/                    # Data layer
│   ├── models/              # Models
│   │   └── enums/           # Enums
│   ├── database/            # SQLite
│   └── repositories/        # Repositories
│
├── services/                # Business services
│   ├── scale/               # Dịch vụ đầu cân
│   ├── camera/              # Dịch vụ camera
│   ├── barrier/             # Dịch vụ barrier
│   ├── license_plate/       # Nhận diện biển số
│   ├── printer/             # Dịch vụ in
│   └── alert/               # Dịch vụ cảnh báo
│
├── presentation/            # UI layer
│   ├── screens/             # Màn hình
│   │   ├── home/
│   │   ├── weighing/
│   │   ├── tickets/
│   │   └── settings/
│   └── widgets/             # Widgets dùng chung
│
└── main.dart                # Entry point
```

## Cài đặt

1. Clone project
2. Chạy `flutter pub get`
3. Cấu hình thiết bị trong Settings
4. Chạy `flutter run -d windows`

## Yêu cầu hệ thống

- Windows 10/11
- Flutter 3.10+
- Dart 3.0+

## Thiết bị hỗ trợ

### Đầu cân
- Các loại đầu cân hỗ trợ giao tiếp Serial/TCP
- Baud rate: 9600, 19200, 38400, 115200

### Camera
- IP Camera hỗ trợ RTSP
- Camera ONVIF

### Barrier
- Barrier điều khiển qua Modbus TCP
- Hỗ trợ các loại controller PLC

### Vision Master
- Hệ thống nhận diện biển số qua TCP
- Hỗ trợ nhiều loại camera LPR

## License

Copyright © 2026
