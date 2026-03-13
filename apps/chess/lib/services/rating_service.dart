import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RatingService {
  static const _gamesKey = 'rating_games_count';
  static const _lastReviewKey = 'rating_last_review_ms';
  static const int _minGames = 1;
  static const int _cooldownDays = 7;

  Future<void> recordGameCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final games = (prefs.getInt(_gamesKey) ?? 0) + 1;
    await prefs.setInt(_gamesKey, games);

    if (games < _minGames) return;

    final lastReviewMs = prefs.getInt(_lastReviewKey);
    final now = DateTime.now().millisecondsSinceEpoch;
    final cooldownMs = const Duration(days: _cooldownDays).inMilliseconds;

    if (lastReviewMs != null && (now - lastReviewMs) < cooldownMs) return;

    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
      await prefs.setInt(_lastReviewKey, now);
    }
  }
}
