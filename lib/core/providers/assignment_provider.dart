import 'package:flutter/foundation.dart';
import '../models/assignment.dart';
import '../models/user.dart';
import '../models/area.dart';
import '../services/assignment_service.dart';

class AssignmentProvider with ChangeNotifier {
  final AssignmentService _assignmentService = AssignmentService();

  Assignment? _currentAssignment;
  List<Assignment> _assignmentHistory = [];
  List<Assignment> _candidatesForPIC = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  Assignment? get currentAssignment => _currentAssignment;
  List<Assignment> get assignmentHistory => _assignmentHistory;
  List<Assignment> get candidatesForPIC => _candidatesForPIC;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasCurrentAssignment => _currentAssignment != null;

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

  // Assign PIC to candidate (candidate only)
  Future<bool> assignPIC(String areaId) async {
    _setLoading(true);
    _setError(null);

    try {
      final assignment = await _assignmentService.assignPIC(areaId);
      _currentAssignment = Assignment(
        id: assignment.assignmentId,
        candidateId: '', // Will be filled from current user
        picId: assignment.pic.id,
        areaId: assignment.area.id,
        assignedAt: assignment.assignedAt,
        pic: assignment.pic,
        area: assignment.area,
      );
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Get current PIC for candidate (candidate only)
  Future<bool> loadCurrentPIC() async {
    _setLoading(true);
    _setError(null);

    try {
      final assignment = await _assignmentService.getCurrentPIC();
      _currentAssignment = assignment;
      _setLoading(false);
      notifyListeners();
      return assignment != null;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Get candidates for PIC (PIC only)
  Future<bool> loadCandidatesForPIC() async {
    _setLoading(true);
    _setError(null);

    try {
      final candidates = await _assignmentService.getCandidatesForPIC();
      _candidatesForPIC = candidates;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Redirect candidate to different area (PIC only)
  Future<bool> redirectCandidate(String candidateId, String newAreaId) async {
    _setLoading(true);
    _setError(null);

    try {
      final newAssignment = await _assignmentService.redirectCandidate(candidateId, newAreaId);

      // Update the assignment in the list if it exists
      final index = _candidatesForPIC.indexWhere((assignment) => assignment.candidateId == candidateId);
      if (index != -1) {
        _candidatesForPIC[index] = Assignment(
          id: newAssignment.assignmentId,
          candidateId: candidateId,
          picId: newAssignment.pic.id,
          areaId: newAssignment.area.id,
          assignedAt: newAssignment.assignedAt,
          candidate: _candidatesForPIC[index].candidate,
          pic: newAssignment.pic,
          area: newAssignment.area,
        );
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Get assignment history
  Future<bool> loadAssignmentHistory({
    int page = 1,
    int limit = 50,
    String? candidateId,
    String? picId,
    String? areaId,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final history = await _assignmentService.getAssignmentHistory(
        page: page,
        limit: limit,
        candidateId: candidateId,
        picId: picId,
        areaId: areaId,
      );

      if (page == 1) {
        _assignmentHistory = history;
      } else {
        _assignmentHistory.addAll(history);
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Refresh current assignment
  Future<void> refreshCurrentAssignment() async {
    await loadCurrentPIC();
  }

  // Clear current assignment (for logout, etc.)
  void clearCurrentAssignment() {
    _currentAssignment = null;
    _assignmentHistory.clear();
    _candidatesForPIC.clear();
    notifyListeners();
  }
}
