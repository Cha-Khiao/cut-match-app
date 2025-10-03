import 'package:cut_match_app/models/salon_model.dart';
import 'package:cut_match_app/providers/salon_finder_provider.dart';
import 'package:cut_match_app/utils/app_theme.dart';
import 'package:cut_match_app/utils/notification_helper.dart';
import 'package:cut_match_app/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SalonFinderScreen extends StatelessWidget {
  const SalonFinderScreen({super.key});

  void _showSalonDetails(BuildContext context, Salon salon) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              salon.name,
              style: Theme.of(
                ctx,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (salon.address.isNotEmpty)
              Text(
                salon.address,
                style: Theme.of(
                  ctx,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.lightText),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.directions_outlined),
                // ✨ [i18n]
                label: const Text('นำทาง'),
                onPressed: () async {
                  final url = Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=${salon.location.latitude},${salon.location.longitude}',
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    if (ctx.mounted)
                      // ✨ [i18n]
                      NotificationHelper.showError(
                        ctx,
                        message: 'ไม่สามารถเปิดแอปแผนที่ได้',
                      );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final salonProvider = context.watch<SalonFinderProvider>();
    final searchController = TextEditingController();

    final List<Marker> salonMarkers = salonProvider.salons.map((salon) {
      return Marker(
        width: 120.0,
        height: 80.0,
        point: salon.location,
        child: GestureDetector(
          onTap: () => _showSalonDetails(context, salon),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                backgroundColor: AppTheme.primary,
                child: Icon(Icons.cut, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  salon.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        // ✨ [i18n]
        title: const Text('ค้นหาร้านซาลอน'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.scaffoldBackgroundColor,
                theme.scaffoldBackgroundColor.withOpacity(0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.5, 1.0],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: MapController(),
            options: MapOptions(
              initialCenter:
                  salonProvider.currentPosition ??
                  const LatLng(13.7563, 100.5018),
              initialZoom: 14.0,
              onLongPress: (tapPosition, point) {
                searchController.clear();
                salonProvider.setNewSearchCenter(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.cut_match_app',
              ),
              MarkerLayer(markers: salonMarkers),
              if (salonProvider.currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: salonProvider.currentPosition!,
                      child: const Icon(
                        Icons.my_location,
                        color: AppTheme.primary,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              if (salonProvider.searchCenter != null &&
                  salonProvider.searchCenter != salonProvider.currentPosition)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: salonProvider.searchCenter!,
                      child: const Icon(
                        Icons.location_searching,
                        color: AppTheme.accent,
                        size: 30,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight - 10,
              left: 16,
              right: 16,
            ),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: CustomTextField(
                controller: searchController,
                // ✨ [i18n]
                hintText: 'ค้นหาร้านซาลอนในบริเวณนี้...',
                icon: Icons.search,
                onChanged: salonProvider.onSearchChanged,
              ),
            ),
          ),
          if (salonProvider.isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          salonProvider.message,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: salonProvider.recenterOnUser,
        // ✨ [i18n]
        tooltip: 'ตำแหน่งของฉัน',
        child: const Icon(Icons.my_location),
      ),
    );
  }
}