import 'dart:async';
import 'package:cut_match_app/api/api_service.dart';
import 'package:cut_match_app/models/salon_model.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class SalonFinderProvider with ChangeNotifier {
  LatLng? _currentPosition;
  LatLng? _searchCenter;
  List<Salon> _salons = [];
  bool _isLoading = true;
  String _message = 'กำลังค้นหาตำแหน่งของคุณ...'; // ✨ [i18n]
  Timer? _debounce;

  LatLng? get currentPosition => _currentPosition;
  LatLng? get searchCenter => _searchCenter;
  List<Salon> get salons => _salons;
  bool get isLoading => _isLoading;
  String get message => _message;

  SalonFinderProvider() {
    init();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> init() async {
    _isLoading = true;
    _message = 'กำลังค้นหาตำแหน่งของคุณ...'; // ✨ [i18n]
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled)
        throw Exception('กรุณาเปิดบริการตำแหน่ง (GPS)'); // ✨ [i18n]

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied)
          throw Exception('การเข้าถึงตำแหน่งถูกปฏิเสธ'); // ✨ [i18n]
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('การเข้าถึงตำแหน่งถูกปฏิเสธถาวร'); // ✨ [i18n]
      }

      Position position = await Geolocator.getCurrentPosition();
      _currentPosition = LatLng(position.latitude, position.longitude);
      _searchCenter = _currentPosition;

      _message = 'กำลังค้นหาร้านซาลอนใกล้เคียง...'; // ✨ [i18n]
      notifyListeners();
      _salons = await ApiService.findNearbySalons(
        _searchCenter!.latitude,
        _searchCenter!.longitude,
      );
    } catch (e) {
      _message = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNearbySalons(LatLng position, {String? searchQuery}) async {
    _isLoading = true;
    _message = searchQuery == null || searchQuery.isEmpty
        ? 'กำลังค้นหาร้านซาลอนใกล้เคียง...' // ✨ [i18n]
        : 'กำลังค้นหา "$searchQuery"...'; // ✨ [i18n]
    _salons = [];
    notifyListeners();

    try {
      _salons = await ApiService.findNearbySalons(
        position.latitude,
        position.longitude,
        search: searchQuery,
      );
    } catch (e) {
      _message = 'ไม่สามารถค้นหาร้านซาลอนได้: $e'; // ✨ [i18n]
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      if (_searchCenter != null) {
        fetchNearbySalons(_searchCenter!, searchQuery: query.trim());
      }
    });
  }

  void recenterOnUser() {
    if (_currentPosition != null) {
      _searchCenter = _currentPosition;
      fetchNearbySalons(_currentPosition!);
    } else {
      init();
    }
  }

  void setNewSearchCenter(LatLng point) {
    _searchCenter = point;
    fetchNearbySalons(point);
  }
}