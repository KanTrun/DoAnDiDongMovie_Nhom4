# Chat System Usage Guide

## 🚀 Quick Start

### 1. Backend Setup
```bash
# Navigate to backend
cd MoviePlusBackend/MoviePlusApi

# Run migrations
dotnet ef migrations add ChatSystemMigration --context ChatDbContext
dotnet ef database update --context ChatDbContext

# Start backend
dotnet run
```

### 2. Flutter Setup
```bash
# Install dependencies
flutter pub get

# Generate code
flutter packages pub run build_runner build --delete-conflicting-outputs

# Run app
flutter run
```

## 📱 Using the Chat System

### 1. Conversations Screen
- **View Conversations**: Danh sách tất cả cuộc trò chuyện
- **Search**: Tìm kiếm cuộc trò chuyện theo tên
- **Filter**: Lọc theo "All" hoặc "Following"
- **Create New**: Tạo cuộc trò chuyện mới

### 2. Chat Screen
- **Send Messages**: Gửi tin nhắn text
- **Real-time Updates**: Nhận tin nhắn realtime
- **Typing Indicators**: Hiển thị khi ai đó đang gõ
- **Message Status**: Hiển thị trạng thái đã gửi/đã đọc

### 3. Features
- ✅ **1-to-1 Conversations**: Trò chuyện riêng tư
- ✅ **Group Conversations**: Trò chuyện nhóm
- ✅ **Real-time Messaging**: Tin nhắn realtime qua SignalR
- ✅ **Local Caching**: Lưu trữ local với SQLite
- ✅ **Push Notifications**: Thông báo đẩy qua FCM
- ✅ **Offline Support**: Hoạt động offline

## 🔧 Configuration

### API Configuration
Tất cả cấu hình được lưu trong `lib/core/config/chat_config.dart`:

```dart
class ChatConfig {
  // API Configuration
  static const String apiBaseUrl = 'https://silvana-detainable-nongratifyingly.ngrok-free.dev/api';
  static const String wsBaseUrl = 'wss://silvana-detainable-nongratifyingly.ngrok-free.dev';
  
  // SignalR Hub endpoint
  static const String hubEndpoint = '/chathub';
}
```

### Backend Configuration
CORS đã được cấu hình để hỗ trợ ngrok domain trong `Program.cs`.

## 🧪 Testing

### 1. Test API Connection
```bash
# Test health endpoint
curl https://silvana-detainable-nongratifyingly.ngrok-free.dev/api/health

# Test authentication
curl -X POST https://silvana-detainable-nongratifyingly.ngrok-free.dev/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'
```

### 2. Test WebSocket Connection
```javascript
// Test WebSocket connection
const ws = new WebSocket('wss://silvana-detainable-nongratifyingly.ngrok-free.dev/chathub?access_token=YOUR_TOKEN');
ws.onopen = () => console.log('Connected');
ws.onmessage = (event) => console.log('Message:', event.data);
```

## 📋 API Endpoints

### Conversations
- `GET /api/conversations` - Lấy danh sách cuộc trò chuyện
- `POST /api/conversations` - Tạo cuộc trò chuyện mới
- `GET /api/conversations/{id}` - Lấy thông tin cuộc trò chuyện
- `POST /api/conversations/{id}/participants` - Thêm thành viên
- `DELETE /api/conversations/{id}/participants/{userId}` - Xóa thành viên

### Messages
- `GET /api/conversations/{id}/messages` - Lấy tin nhắn
- `POST /api/conversations/{id}/messages` - Gửi tin nhắn
- `PUT /api/conversations/{id}/messages/{messageId}` - Sửa tin nhắn
- `DELETE /api/conversations/{id}/messages/{messageId}` - Xóa tin nhắn
- `POST /api/conversations/{id}/messages/{messageId}/read` - Đánh dấu đã đọc

### Contacts
- `GET /api/contacts` - Lấy danh sách liên hệ
- `GET /api/contacts/following` - Lấy danh sách đang theo dõi

### Device Tokens
- `POST /api/devicetokens` - Đăng ký device token
- `DELETE /api/devicetokens/{token}` - Hủy đăng ký device token

## 🔍 Troubleshooting

### Common Issues

1. **Connection Failed**
   - Kiểm tra ngrok tunnel có đang chạy không
   - Kiểm tra backend có đang chạy không
   - Kiểm tra URL trong `chat_config.dart`

2. **Authentication Error**
   - Kiểm tra JWT token có hợp lệ không
   - Đảm bảo user đã đăng nhập

3. **WebSocket Connection Failed**
   - Kiểm tra SignalR Hub có được map đúng không
   - Kiểm tra CORS configuration

4. **Database Error**
   - Chạy migration: `dotnet ef database update --context ChatDbContext`
   - Kiểm tra connection string

### Debug Steps

1. **Check Backend Logs**
   ```bash
   cd MoviePlusBackend/MoviePlusApi
   dotnet run
   ```

2. **Check Flutter Logs**
   ```bash
   flutter run --verbose
   ```

3. **Test API Manually**
   ```bash
   curl -v https://silvana-detainable-nongratifyingly.ngrok-free.dev/api/health
   ```

## 🎯 Production Deployment

### 1. Backend
- Sử dụng production database
- Cấu hình SSL certificates
- Set up proper domain
- Configure CORS cho production domain

### 2. Flutter
- Build release version
- Configure Firebase cho production
- Set up proper API endpoints

## 📊 Monitoring

### Backend Monitoring
- Application performance
- Database performance
- SignalR connections
- Error tracking

### Flutter Monitoring
- Crash reporting
- Performance metrics
- User analytics
- Push notification delivery

## 🔄 Maintenance

### Regular Tasks
1. Database cleanup (old messages)
2. Token refresh
3. Performance monitoring
4. Security updates
5. Backup verification

### Updates
1. Update dependencies
2. Run migrations
3. Test functionality
4. Deploy changes

## 📞 Support

Nếu gặp vấn đề, hãy kiểm tra:
1. Backend logs
2. Flutter logs
3. Network connectivity
4. Database connection
5. API endpoints

Hệ thống chat đã sẵn sàng sử dụng với đầy đủ tính năng realtime messaging!
