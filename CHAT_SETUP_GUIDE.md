# Chat System Setup Guide

## 🔧 Backend Setup

### 1. Database Migration
```bash
cd MoviePlusBackend/MoviePlusApi
dotnet ef migrations add ChatSystemMigration --context ChatDbContext
dotnet ef database update --context ChatDbContext
```

### 2. Update CORS Configuration
Đã cập nhật `Program.cs` để hỗ trợ ngrok domain:
```csharp
policy.WithOrigins(
    "https://silvana-detainable-nongratifyingly.ngrok-free.dev",
    "http://localhost:3000",
    "http://localhost:8080"
)
```

### 3. Start Backend
```bash
cd MoviePlusBackend/MoviePlusApi
dotnet run
```

## 📱 Flutter Setup

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Generate Code
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### 3. Test Connection
```bash
dart run lib/features/chat/services/connection_test.dart
```

## 🌐 API Configuration

### Current API URL
- **REST API**: `https://silvana-detainable-nongratifyingly.ngrok-free.dev/api`
- **WebSocket**: `wss://silvana-detainable-nongratifyingly.ngrok-free.dev/chathub`

### Configuration File
Tất cả URL được cấu hình trong `lib/core/config/chat_config.dart`

## 🧪 Testing

### 1. API Endpoints Test
```bash
# Test health endpoint
curl https://silvana-detainable-nongratifyingly.ngrok-free.dev/api/health

# Test authentication
curl -X POST https://silvana-detainable-nongratifyingly.ngrok-free.dev/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'
```

### 2. WebSocket Test
```javascript
// Test WebSocket connection
const ws = new WebSocket('wss://silvana-detainable-nongratifyingly.ngrok-free.dev/chathub?access_token=YOUR_TOKEN');
ws.onopen = () => console.log('Connected');
ws.onmessage = (event) => console.log('Message:', event.data);
```

## 🚀 Running the App

### 1. Start Backend
```bash
cd MoviePlusBackend/MoviePlusApi
dotnet run
```

### 2. Start Flutter
```bash
flutter run
```

## 🔍 Troubleshooting

### Common Issues

1. **CORS Error**
   - Kiểm tra CORS configuration trong `Program.cs`
   - Đảm bảo ngrok URL được thêm vào allowed origins

2. **WebSocket Connection Failed**
   - Kiểm tra ngrok tunnel có đang chạy không
   - Đảm bảo SignalR Hub được map đúng trong `Program.cs`

3. **Authentication Error**
   - Kiểm tra JWT token có hợp lệ không
   - Đảm bảo token được gửi đúng format

### Debug Commands

```bash
# Check ngrok status
ngrok status

# Test API with curl
curl -v https://silvana-detainable-nongratifyingly.ngrok-free.dev/api/health

# Check Flutter dependencies
flutter doctor
flutter pub deps
```

## 📋 Checklist

- [ ] Backend running on ngrok
- [ ] Database migration completed
- [ ] CORS configured for ngrok domain
- [ ] Flutter dependencies installed
- [ ] Code generation completed
- [ ] API connection test passed
- [ ] WebSocket connection test passed

## 🎯 Next Steps

1. **Test Basic Functionality**
   - Create conversation
   - Send messages
   - Receive real-time updates

2. **Test Advanced Features**
   - Message reactions
   - Typing indicators
   - Push notifications

3. **Production Deployment**
   - Configure production database
   - Set up proper domain
   - Configure SSL certificates
