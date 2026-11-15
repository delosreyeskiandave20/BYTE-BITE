import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The buyer's own motorcycle, used by the Shop's "My Motorcycle" filter.
///
/// Buyers do not have accounts, so the choice is saved on this device and
/// comes back the next time the app opens.
class MyMotorcycle extends ChangeNotifier {
  MyMotorcycle({this.persist = true}) {
    if (persist) _load();
  }

  static const _key = 'my_motorcycle';

  /// False in tests, which keep the choice in memory only.
  final bool persist;

  String? _model;
  bool _onlyFits = false;

  /// Full table name, e.g. "Yamaha NMAX 155"; null until the buyer picks one.
  String? get model => _model;

  /// "Show only parts that fit my motorcycle".
  bool get onlyFits => _onlyFits && _model != null;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved != null && saved.isNotEmpty && _model == null) {
        _model = saved;
        notifyListeners();
      }
    } catch (_) {
      // No storage (e.g. an unsupported platform): keep it for this session.
    }
  }

  Future<void> choose(String? model) async {
    _model = model;
    if (model == null) _onlyFits = false;
    notifyListeners();
    if (!persist) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (model == null) {
        await prefs.remove(_key);
      } else {
        await prefs.setString(_key, model);
      }
    } catch (_) {}
  }

  void setOnlyFits(bool value) {
    _onlyFits = value;
    notifyListeners();
  }
}

/// The app-wide buyer motorcycle choice.
final myMotorcycle = MyMotorcycle();
