import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io';
import '../controllers/nearby_cinema_controller.dart';
import '../widgets/cinema_list_item.dart';
import '../widgets/permission_gate.dart';

class NearbyCinemaScreen extends ConsumerStatefulWidget {
  const NearbyCinemaScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NearbyCinemaScreen> createState() => _NearbyCinemaScreenState();
}

class _NearbyCinemaScreenState extends ConsumerState<NearbyCinemaScreen> {
  final List<int> _radiusOptions = [5000, 10000, 20000, 50000]; // 5km, 10km, 20km, 50km
  int _selectedRadius = 10000;

  @override
  void initState() {
    super.initState();
    // Kiểm tra permission và load dữ liệu khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionAndLoad();
    });
  }

  Future<void> _checkPermissionAndLoad() async {
    final controller = ref.read(nearbyCinemaControllerProvider.notifier);
    await controller.checkLocationPermission();
    
    if (mounted) {
      await controller.loadNearbyCinemas(radiusMeters: _selectedRadius);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nearbyCinemaControllerProvider);
    final controller = ref.read(nearbyCinemaControllerProvider.notifier);

    return PermissionGate(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rạp gần tôi'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => controller.refresh(),
              tooltip: 'Làm mới',
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showRadiusSelector(context),
              tooltip: 'Bán kính tìm kiếm',
            ),
          ],
        ),
        body: Column(
          children: [
            // Header với thông tin vị trí và bán kính
            _buildHeader(state),
            
            // Nội dung chính
            Expanded(
              child: _buildContent(state, controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(NearbyCinemaState state) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: theme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.userLat != null && state.userLon != null
                      ? 'Vị trí hiện tại: ${state.userLat!.toStringAsFixed(4)}, ${state.userLon!.toStringAsFixed(4)}'
                      : 'Đang lấy vị trí...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.radio_button_checked,
                color: theme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Bán kính: ${_formatRadius(_selectedRadius)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                ),
              ),
              const Spacer(),
              if (state.hasData)
                Text(
                  '${state.cinemas.length} rạp',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.primaryColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(NearbyCinemaState state, NearbyCinemaController controller) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tìm rạp gần bạn...'),
          ],
        ),
      );
    }

    if (state.hasError) {
      return _buildErrorWidget(state.error!, controller);
    }

    if (!state.hasData) {
      return _buildEmptyWidget(controller);
    }

    return _buildCinemaList(state.cinemas);
  }

  Widget _buildErrorWidget(String error, NearbyCinemaController controller) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Không thể tải dữ liệu',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => controller.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(NearbyCinemaController controller) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_creation_outlined,
              size: 64,
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy rạp nào',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử tăng bán kính tìm kiếm hoặc di chuyển đến vị trí khác.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showRadiusSelector(context),
              icon: const Icon(Icons.tune),
              label: const Text('Thay đổi bán kính'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCinemaList(List<dynamic> cinemas) {
    return RefreshIndicator(
      onRefresh: () async {
        final controller = ref.read(nearbyCinemaControllerProvider.notifier);
        await controller.refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: cinemas.length,
        itemBuilder: (context, index) {
          final cinema = cinemas[index];
          return CinemaListItem(
            cinema: cinema,
            onTap: () => _showCinemaDetails(cinema),
          );
        },
      ),
    );
  }

  void _showRadiusSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _RadiusSelectorBottomSheet(
        currentRadius: _selectedRadius,
        options: _radiusOptions,
        onRadiusSelected: (radius) {
          setState(() {
            _selectedRadius = radius;
          });
          ref.read(nearbyCinemaControllerProvider.notifier)
              .changeRadius(radius);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showCinemaDetails(dynamic cinema) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CinemaDetailsBottomSheet(cinema: cinema),
    );
  }

  String _formatRadius(int meters) {
    if (meters < 1000) {
      return '${meters}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(0)}km';
    }
  }
}

class _RadiusSelectorBottomSheet extends StatelessWidget {
  final int currentRadius;
  final List<int> options;
  final Function(int) onRadiusSelected;

  const _RadiusSelectorBottomSheet({
    required this.currentRadius,
    required this.options,
    required this.onRadiusSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn bán kính tìm kiếm',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...options.map((radius) => ListTile(
            title: Text(_formatRadius(radius)),
            subtitle: Text(_getRadiusDescription(radius)),
            trailing: currentRadius == radius
                ? Icon(Icons.check, color: theme.primaryColor)
                : null,
            onTap: () => onRadiusSelected(radius),
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatRadius(int meters) {
    if (meters < 1000) {
      return '${meters}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(0)}km';
    }
  }

  String _getRadiusDescription(int meters) {
    switch (meters) {
      case 5000:
        return 'Gần (trong phường/xã)';
      case 10000:
        return 'Trung bình (trong quận/huyện)';
      case 20000:
        return 'Xa (trong thành phố)';
      case 50000:
        return 'Rất xa (toàn tỉnh/thành phố)';
      default:
        return '';
    }
  }
}

class _CinemaDetailsBottomSheet extends StatelessWidget {
  final dynamic cinema;

  const _CinemaDetailsBottomSheet({required this.cinema});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cinema.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (cinema.brand != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                cinema.brand!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (cinema.address != null) ...[
            _DetailRow(
              icon: Icons.location_on,
              label: 'Địa chỉ',
              value: cinema.address!,
            ),
            const SizedBox(height: 12),
          ],
          if (cinema.phone != null) ...[
            _DetailRow(
              icon: Icons.phone,
              label: 'Điện thoại',
              value: cinema.phone!,
            ),
            const SizedBox(height: 12),
          ],
          if (cinema.openingHours != null) ...[
            _DetailRow(
              icon: Icons.access_time,
              label: 'Giờ mở cửa',
              value: cinema.openingHours!,
            ),
            const SizedBox(height: 12),
          ],
          if (cinema.website != null) ...[
            _DetailRow(
              icon: Icons.language,
              label: 'Website',
              value: cinema.website!,
            ),
            const SizedBox(height: 12),
          ],
          if (cinema.distanceMeters != null) ...[
            _DetailRow(
              icon: Icons.straighten,
              label: 'Khoảng cách',
              value: _formatDistance(cinema.distanceMeters!),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openInMaps(cinema, context),
                  icon: const Icon(Icons.directions),
                  label: const Text('Chỉ đường'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _copyAddress(cinema, context),
                  icon: const Icon(Icons.copy),
                  label: const Text('Sao chép'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  void _openInMaps(dynamic cinema, BuildContext context) async {
    try {
      final lat = cinema.lat;
      final lon = cinema.lon;
      final name = Uri.encodeComponent(cinema.name);
      
      bool launched = false;
      
      // Thử Android Intent trước (chỉ hoạt động trên Android)
      if (Platform.isAndroid) {
        try {
          final intent = AndroidIntent(
            action: 'android.intent.action.VIEW',
            data: 'geo:$lat,$lon?q=$lat,$lon($name)',
          );
          await intent.launch();
          launched = true;
        } catch (e) {
          // Nếu Android Intent không hoạt động, thử cách khác
        }
      }
      
      // Nếu Android Intent không hoạt động, thử Google Maps
      if (!launched) {
        final googleMapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
        if (await canLaunchUrl(googleMapsUri)) {
          await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
          launched = true;
        }
      }
      
      // Nếu vẫn không được, thử Google Maps với tên địa điểm
      if (!launched) {
        final googleMapsWithName = Uri.parse('https://www.google.com/maps/search/?api=1&query=$name+$lat,$lon');
        if (await canLaunchUrl(googleMapsWithName)) {
          await launchUrl(googleMapsWithName, mode: LaunchMode.externalApplication);
          launched = true;
        }
      }
      
      // Nếu vẫn không được, thử mở trong browser
      if (!launched) {
        final webUri = Uri.parse('https://www.google.com/maps/@$lat,$lon,15z');
        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
          launched = true;
        }
      }
      
      if (!launched) {
        // Nếu không mở được app nào, hiển thị thông báo với tọa độ
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể mở bản đồ. Tọa độ: $lat, $lon'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Sao chép',
                onPressed: () => _copyAddress(cinema, context),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi mở bản đồ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyAddress(dynamic cinema, BuildContext context) {
    final address = cinema.address ?? '${cinema.name}, ${cinema.lat}, ${cinema.lon}';
    Clipboard.setData(ClipboardData(text: address));
    
    // Hiển thị thông báo đã sao chép
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã sao chép địa chỉ: ${cinema.name}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
