import 'dart:async';
import 'package:cut_match_app/api/api_service.dart';
import 'package:cut_match_app/models/salon_model.dart';
import 'package:cut_match_app/utils/app_theme.dart';
import 'package:cut_match_app/utils/notification_helper.dart';
import 'package:cut_match_app/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class SalonFinderScreen extends StatefulWidget {
  const SalonFinderScreen({super.key});

  @override
  State<SalonFinderScreen> createState() => _SalonFinderScreenState();
}

class _SalonFinderScreenState extends State<SalonFinderScreen> {
  LatLng? _currentPosition;
  LatLng? _searchCenter;
  List<Salon> _salons = [];
  List<Marker> _salonMarkers = [];
  bool _isLoading = true;
  String _message = 'กำลังค้นหาตำแหน่งของคุณ...';
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    _updateLoadingState(true, 'กำลังค้นหาตำแหน่งของคุณ...');
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('กรุณาเปิดบริการตำแหน่ง (GPS)');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('การเข้าถึงตำแหน่งถูกปฏิเสธ');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('การเข้าถึงตำแหน่งถูกปฏิเสธถาวร');
      }

      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _searchCenter = _currentPosition;
        _mapController.move(_currentPosition!, 14.0);
        await _fetchNearbySalons(_searchCenter!);
      }
    } catch (e) {
      if (mounted) {
        _updateLoadingState(
          false,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  Future<void> _fetchNearbySalons(
    LatLng position, {
    String? searchQuery,
  }) async {
    _updateLoadingState(
      true,
      searchQuery == null || searchQuery.isEmpty
          ? 'กำลังค้นหาร้านตัดผมใกล้เคียง...'
          : 'กำลังค้นหา "$searchQuery"...',
    );

    try {
      final fetchedSalons = await ApiService.findNearbySalons(
        position.latitude,
        position.longitude,
        search: searchQuery,
      );
      final markers = fetchedSalons.map((salon) {
        return Marker(
          width: 120.0,
          height: 80.0,
          point: salon.location,
          child: GestureDetector(
            onTap: () => _showSalonDetails(salon),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  backgroundColor: AppTheme.primary,
                  child: Icon(Icons.cut, color: Colors.white, size: 20),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

      if (mounted) {
        setState(() {
          _salons = fetchedSalons;
          _salonMarkers = markers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) _updateLoadingState(false, 'ไม่สามารถค้นหาร้านตัดผมได้: $e');
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _salons = []);
      _debounce?.cancel();
      _fetchNearbySalons(_searchCenter!);
      return;
    }
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      if (_searchCenter != null) {
        _fetchNearbySalons(_searchCenter!, searchQuery: query.trim());
      }
    });
  }

  void _updateLoadingState(bool loading, String message) {
    setState(() {
      _isLoading = loading;
      _message = message;
    });
  }

  void _showSalonDetails(Salon salon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
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
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  salon.address,
                  style: Theme.of(
                    ctx,
                  ).textTheme.bodyLarge?.copyWith(color: AppTheme.lightText),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.directions_outlined),
                label: const Text('นำทาง'),
                onPressed: () async {
                  final url = Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=${salon.location.latitude},${salon.location.longitude}',
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else if (ctx.mounted) {
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
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Find a Salon'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(255, 144, 144, 193),
                const Color.fromARGB(255, 65, 65, 130).withOpacity(0),
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
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  _currentPosition ?? const LatLng(13.7563, 100.5018),
              initialZoom: 14.0,
              onLongPress: (tapPosition, point) {
                _searchController.clear();
                setState(() => _searchCenter = point);
                _fetchNearbySalons(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.cut_match_app',
              ),
              MarkerLayer(markers: _salonMarkers),
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      child: const Icon(
                        Icons.my_location,
                        color: AppTheme.primary,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              if (_searchCenter != null && _searchCenter != _currentPosition)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _searchCenter!,
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
          Column(
            children: [
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
                    controller: _searchController,
                    hintText: 'ค้นหาร้านตัดผมในบริเวณนี้...',
                    icon: Icons.search,
                    onChanged: _onSearchChanged,
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty &&
                  _salons.isNotEmpty &&
                  !_isLoading)
                _buildSearchResultsList(),
            ],
          ),
          if (_isLoading)
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
                        Text(_message, style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentPosition != null) {
            _mapController.move(_currentPosition!, 14.0);
            _searchController.clear();
            setState(() {
              _searchCenter = _currentPosition;
              _salons = [];
            });
            _fetchNearbySalons(_currentPosition!);
          } else {
            _determinePosition();
          }
        },
        tooltip: 'ตำแหน่งของฉัน',
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Widget _buildSearchResultsList() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.35,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.only(top: 8),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: _salons.length,
            itemBuilder: (context, index) {
              final salon = _salons[index];
              return ListTile(
                title: Text(salon.name),
                subtitle: Text(
                  salon.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  _mapController.move(salon.location, 16.0);
                  FocusScope.of(context).unfocus();
                  _searchController.clear();
                  setState(() => _salons = []);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
