import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io';
import '../../../core/models/cinema.dart';
import '../../../core/services/distance.dart';

class CinemaListItem extends StatelessWidget {
  final Cinema cinema;
  final VoidCallback? onTap;
  final bool showDistance;

  const CinemaListItem({
    Key? key,
    required this.cinema,
    this.onTap,
    this.showDistance = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header với tên và brand
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cinema.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (cinema.brand != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              cinema.brand!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showDistance && cinema.distanceMeters != null) ...[
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatDistance(cinema.distanceMeters!),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'khoảng cách',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Địa chỉ
              if (cinema.address != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cinema.address!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // Thông tin bổ sung
              Row(
                children: [
                  // Giờ mở cửa
                  if (cinema.openingHours != null) ...[
                    _InfoChip(
                      icon: Icons.access_time,
                      text: cinema.openingHours!,
                    ),
                    const SizedBox(width: 8),
                  ],
                  
                  // Số điện thoại
                  if (cinema.phone != null) ...[
                    _InfoChip(
                      icon: Icons.phone,
                      text: cinema.phone!,
                      onTap: () => _makePhoneCall(cinema.phone!),
                    ),
                    const SizedBox(width: 8),
                  ],
                  
                  // Website
                  if (cinema.website != null) ...[
                    _InfoChip(
                      icon: Icons.language,
                      text: 'Website',
                      onTap: () => _openWebsite(cinema.website!),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openInMaps(cinema, context),
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text('Chỉ đường'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _copyAddress(cinema, context),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Sao chép'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openWebsite(String website) async {
    String url = website;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openInMaps(Cinema cinema, BuildContext context) async {
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

  void _copyAddress(Cinema cinema, BuildContext context) {
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const _InfoChip({
    required this.icon,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
