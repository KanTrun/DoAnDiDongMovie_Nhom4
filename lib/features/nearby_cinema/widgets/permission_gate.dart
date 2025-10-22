import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionGate extends ConsumerWidget {
  final Widget child;
  final Widget? permissionDeniedWidget;
  final Widget? locationDisabledWidget;

  const PermissionGate({
    Key? key,
    required this.child,
    this.permissionDeniedWidget,
    this.locationDisabledWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<PermissionStatus>(
      future: Permission.location.status,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final permissionStatus = snapshot.data!;
        
        // Kiểm tra location service
        return FutureBuilder<bool>(
          future: _checkLocationService(),
          builder: (context, serviceSnapshot) {
            if (!serviceSnapshot.hasData || !serviceSnapshot.data!) {
              return locationDisabledWidget ?? _LocationDisabledWidget();
            }

            // Kiểm tra permission
            if (!permissionStatus.isGranted) {
              return permissionDeniedWidget ?? _PermissionDeniedWidget();
            }

            return child;
          },
        );
      },
    );
  }

  Future<bool> _checkLocationService() async {
    try {
      return await Permission.location.serviceStatus.isEnabled;
    } catch (e) {
      return false;
    }
  }
}

class _PermissionDeniedWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 80,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Cần quyền truy cập vị trí',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Để tìm rạp chiếu phim gần bạn, ứng dụng cần quyền truy cập vị trí của bạn.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _requestPermission(context),
                icon: const Icon(Icons.location_on),
                label: const Text('Cấp quyền truy cập vị trí'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _requestPermission(BuildContext context) async {
    try {
      // Sử dụng permission_handler để yêu cầu quyền truy cập vị trí
      final status = await Permission.location.request();
      
      if (status.isGranted) {
        // Permission được cấp, đóng dialog và refresh
        Navigator.of(context).pop();
        // Trigger rebuild để kiểm tra lại permission
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã cấp quyền truy cập vị trí thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (status.isDenied) {
        // Permission bị từ chối, hiển thị thông báo
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quyền truy cập vị trí bị từ chối. Vui lòng cấp quyền trong cài đặt.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (status.isPermanentlyDenied) {
        // Permission bị từ chối vĩnh viễn, mở cài đặt
        await openAppSettings();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi yêu cầu quyền: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _LocationDisabledWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_disabled,
                size: 80,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Dịch vụ vị trí bị tắt',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Vui lòng bật dịch vụ vị trí trong cài đặt để sử dụng tính năng tìm rạp gần bạn.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _openLocationSettings(context),
                icon: const Icon(Icons.settings),
                label: const Text('Mở cài đặt'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLocationSettings(BuildContext context) async {
    try {
      // Mở cài đặt vị trí của thiết bị
      await openAppSettings();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở cài đặt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class LocationPermissionDialog extends StatelessWidget {
  final VoidCallback? onGranted;
  final VoidCallback? onDenied;

  const LocationPermissionDialog({
    Key? key,
    this.onGranted,
    this.onDenied,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.location_on,
            color: theme.primaryColor,
          ),
          const SizedBox(width: 12),
          const Text('Quyền truy cập vị trí'),
        ],
      ),
      content: const Text(
        'Để tìm rạp chiếu phim gần bạn, ứng dụng cần quyền truy cập vị trí của bạn. '
        'Thông tin vị trí chỉ được sử dụng để tìm rạp và không được lưu trữ.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDenied?.call();
          },
          child: const Text('Từ chối'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onGranted?.call();
          },
          child: const Text('Cho phép'),
        ),
      ],
    );
  }
}
