# Chat System Deployment Guide

## Backend Deployment

### 1. Database Setup

#### SQL Server Configuration
```sql
-- Ensure SQL Server is running and accessible
-- Create database if not exists
CREATE DATABASE MoviePlusDb;
```

#### Run Migrations
```bash
# Navigate to backend project
cd MoviePlusBackend/MoviePlusApi

# Add migration
dotnet ef migrations add ChatSystemMigration --context ChatDbContext

# Update database
dotnet ef database update --context ChatDbContext

# Or use the provided scripts:
# Windows PowerShell
.\Data\Migrations\RunMigration.ps1

# Linux/Mac
chmod +x Data/Migrations/RunMigration.sh
./Data/Migrations/RunMigration.sh
```

### 2. Backend Configuration

#### appsettings.json
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=your-server;Database=MoviePlusDb;Trusted_Connection=true;MultipleActiveResultSets=true;TrustServerCertificate=true"
  },
  "JwtSettings": {
    "SecretKey": "your-super-secret-key-that-is-at-least-32-characters-long",
    "Issuer": "MoviePlusApi",
    "Audience": "MoviePlusClient"
  },
  "FCM": {
    "ServerKey": "your-firebase-server-key"
  },
  "Redis": {
    "Connection": "localhost:6379"
  }
}
```

#### Required NuGet Packages
```xml
<PackageReference Include="Microsoft.AspNetCore.SignalR" Version="1.1.0" />
<PackageReference Include="Microsoft.AspNetCore.SignalR.StackExchangeRedis" Version="8.0.0" />
<PackageReference Include="Microsoft.EntityFrameworkCore.SqlServer" Version="8.0.0" />
<PackageReference Include="Microsoft.EntityFrameworkCore.Tools" Version="8.0.0" />
```

### 3. Backend Deployment Steps

1. **Build the project:**
   ```bash
   dotnet build
   ```

2. **Run the application:**
   ```bash
   dotnet run
   ```

3. **For production deployment:**
   ```bash
   dotnet publish -c Release -o ./publish
   ```

## Flutter Client Setup

### 1. Dependencies Installation

```bash
flutter pub get
```

### 2. Firebase Configuration

1. **Create Firebase project:**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create new project
   - Enable Cloud Messaging

2. **Configure Firebase for Flutter:**
   ```bash
   # Install FlutterFire CLI
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   
   # Configure Firebase
   flutterfire configure
   ```

3. **Update firebase_options.dart:**
   - Replace placeholder values with actual Firebase configuration
   - Ensure all platforms (Android, iOS, Web) are configured

### 3. Android Configuration

#### android/app/build.gradle
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}

dependencies {
    implementation 'com.google.firebase:firebase-messaging:23.4.0'
}
```

#### android/app/src/main/AndroidManifest.xml
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.VIBRATE" />

<application>
    <service
        android:name=".MyFirebaseMessagingService"
        android:exported="false">
        <intent-filter>
            <action android:name="com.google.firebase.MESSAGING_EVENT" />
        </intent-filter>
    </service>
</application>
```

### 4. iOS Configuration

#### ios/Runner/Info.plist
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

#### ios/Runner/AppDelegate.swift
```swift
import UIKit
import Flutter
import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## Testing Checklist

### Backend Testing

1. **Start the API server:**
   ```bash
   cd MoviePlusBackend/MoviePlusApi
   dotnet run
   ```

2. **Test endpoints:**
   ```bash
   # Test authentication
   curl -X POST http://localhost:5127/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"password"}'

   # Test SignalR connection
   # Use a SignalR client or browser developer tools
   ```

3. **Database verification:**
   ```sql
   -- Check if tables are created
   SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME LIKE '%Conversation%'
   SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME LIKE '%Message%'
   ```

### Flutter Testing

1. **Run the Flutter app:**
   ```bash
   flutter run
   ```

2. **Test chat functionality:**
   - Create new conversation
   - Send messages
   - Verify real-time updates
   - Test push notifications

3. **Test offline functionality:**
   - Disconnect from internet
   - Send messages (should be queued)
   - Reconnect and verify sync

## Production Deployment

### Backend (IIS/Azure)

1. **Publish application:**
   ```bash
   dotnet publish -c Release -o ./publish
   ```

2. **Configure IIS:**
   - Set up application pool
   - Configure bindings
   - Set up SSL certificate

3. **Database:**
   - Use production SQL Server
   - Configure connection strings
   - Set up backup strategy

### Flutter (Google Play/App Store)

1. **Build release:**
   ```bash
   flutter build apk --release  # Android
   flutter build ios --release  # iOS
   ```

2. **Configure Firebase:**
   - Set up production Firebase project
   - Configure app signing
   - Set up push notification certificates

## Monitoring and Maintenance

### Backend Monitoring

1. **Application Insights:**
   - Monitor API performance
   - Track SignalR connections
   - Monitor database performance

2. **Logging:**
   - Set up structured logging
   - Monitor error rates
   - Track user activity

### Flutter Monitoring

1. **Crashlytics:**
   - Set up Firebase Crashlytics
   - Monitor app crashes
   - Track performance metrics

2. **Analytics:**
   - Set up Firebase Analytics
   - Track user engagement
   - Monitor chat usage

## Security Considerations

1. **Authentication:**
   - Use strong JWT secrets
   - Implement token refresh
   - Set up rate limiting

2. **Data Protection:**
   - Encrypt sensitive data
   - Implement message encryption
   - Set up data retention policies

3. **Network Security:**
   - Use HTTPS/WSS
   - Implement CORS properly
   - Set up firewall rules

## Troubleshooting

### Common Issues

1. **SignalR Connection Issues:**
   - Check CORS configuration
   - Verify JWT token format
   - Check network connectivity

2. **Database Issues:**
   - Verify connection string
   - Check migration status
   - Monitor connection pool

3. **Push Notification Issues:**
   - Verify FCM configuration
   - Check device token registration
   - Monitor FCM quotas

### Debug Commands

```bash
# Check database connection
dotnet ef database update --context ChatDbContext --verbose

# Test SignalR connection
# Use browser developer tools or SignalR client

# Check Flutter dependencies
flutter doctor
flutter pub deps
```

## Performance Optimization

1. **Database:**
   - Add appropriate indexes
   - Optimize queries
   - Set up connection pooling

2. **SignalR:**
   - Use Redis backplane for scaling
   - Implement connection management
   - Monitor connection limits

3. **Flutter:**
   - Implement message pagination
   - Use local caching effectively
   - Optimize image loading

## Scaling Considerations

1. **Horizontal Scaling:**
   - Use load balancer
   - Implement Redis backplane
   - Set up multiple API instances

2. **Database Scaling:**
   - Consider read replicas
   - Implement database sharding
   - Set up backup strategies

3. **Push Notifications:**
   - Monitor FCM quotas
   - Implement batching
   - Set up fallback mechanisms
