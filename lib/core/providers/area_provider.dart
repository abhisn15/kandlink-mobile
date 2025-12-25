import 'package:flutter/foundation.dart';
import '../models/area.dart';
import '../services/auth_service.dart';

class AreaProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  List<Area> _areas = [];
  bool _isLoading = false;
  String? _error;
  Area? _selectedArea;

  // Getters
  List<Area> get areas => _areas;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Area? get selectedArea => _selectedArea;

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Load areas from API
  Future<bool> loadAreas() async {
    _setLoading(true);
    _setError(null);

    try {
      _areas = await _authService.getAreas();
      debugPrint('🏙️ AREAS_LOADED: ${_areas.length} areas');
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to load areas: $e');
      _setLoading(false);
      return false;
    }
  }

  // Select area
  void selectArea(Area area) {
    _selectedArea = area;
    debugPrint('🎯 AREA_SELECTED: ${area.name} (${area.id})');
    notifyListeners();
  }

  // Clear selection
  void clearSelection() {
    _selectedArea = null;
    notifyListeners();
  }

  // Get filtered areas for search
  List<Area> getFilteredAreas(String query) {
    if (query.isEmpty) return _areas;

    return _areas.where((area) =>
      area.name.toLowerCase().contains(query.toLowerCase()) ||
      area.id.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}
