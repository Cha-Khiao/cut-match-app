import 'package:cut_match_app/api/api_service.dart';
import 'package:cut_match_app/models/hairstyle_model.dart';
import 'package:cut_match_app/models/review_model.dart';
import 'package:flutter/material.dart';

class HairstyleDetailProvider with ChangeNotifier {
  Hairstyle hairstyle;
  List<Review> reviews = [];
  bool isLoading = true;
  String? errorMessage;

  HairstyleDetailProvider(this.hairstyle) {
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    isLoading = true;
    notifyListeners();

    try {
      final fetchedReviews = await ApiService.getReviewsForHairstyle(
        hairstyle.id,
      );
      reviews = fetchedReviews;
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> refreshData() async {
    await _fetchAllData();
  }

  Future<void> submitReview({
    required String token,
    required double rating,
    required String comment,
  }) async {
    await ApiService.submitReview(
      token: token,
      hairstyleId: hairstyle.id,
      rating: rating,
      comment: comment,
    );
    await refreshData();
  }
}
