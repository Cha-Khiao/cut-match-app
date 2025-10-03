import 'package:cut_match_app/api/api_service.dart';
import 'package:cut_match_app/models/hairstyle_model.dart';
import 'package:flutter/material.dart';

class HairstyleProvider with ChangeNotifier {
  List<Hairstyle> _hairstyles = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<Hairstyle> get hairstyles => _hairstyles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchHairstyles({String? gender, String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _hairstyles = await ApiService.getHairstyles(
        gender: gender,
        search: search,
      );
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
