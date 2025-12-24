import 'package:flutter/foundation.dart';
import '../models/group.dart';
import '../services/group_service.dart';

class GroupProvider with ChangeNotifier {
  final GroupService _groupService = GroupService();

  List<Group> _myGroups = [];
  List<GroupMember> _groupMembers = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Group> get myGroups => _myGroups;
  List<GroupMember> get groupMembers => _groupMembers;
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  // Load user's groups
  Future<bool> loadMyGroups() async {
    _setLoading(true);
    _setError(null);

    try {
      final groups = await _groupService.getMyGroups();
      _myGroups = groups;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Create new group (PIC only)
  Future<bool> createGroup(String name, {String? areaId}) async {
    _setLoading(true);
    _setError(null);

    try {
      final group = await _groupService.createGroup(name, areaId: areaId);
      _myGroups.insert(0, group); // Add to the beginning of the list
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Load group members
  Future<bool> loadGroupMembers(String groupId) async {
    _setLoading(true);
    _setError(null);

    try {
      final members = await _groupService.getGroupMembers(groupId);
      _groupMembers = members;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Add members to group (PIC only)
  Future<bool> addMembers(String groupId, List<String> candidateIds) async {
    _setLoading(true);
    _setError(null);

    try {
      final addedMembers = await _groupService.addMembers(groupId, candidateIds);

      // Update the group member count in my groups list
      final groupIndex = _myGroups.indexWhere((g) => g.id == groupId);
      if (groupIndex != -1) {
        _myGroups[groupIndex] = Group(
          id: _myGroups[groupIndex].id,
          name: _myGroups[groupIndex].name,
          createdBy: _myGroups[groupIndex].createdBy,
          areaId: _myGroups[groupIndex].areaId,
          avatar: _myGroups[groupIndex].avatar,
          createdAt: _myGroups[groupIndex].createdAt,
          updatedAt: _myGroups[groupIndex].updatedAt,
          creator: _myGroups[groupIndex].creator,
          area: _myGroups[groupIndex].area,
          members: [...?_myGroups[groupIndex].members, ...addedMembers],
        );
      }

      // Reload group members if currently viewing this group
      await loadGroupMembers(groupId);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Get group by ID
  Group? getGroupById(String groupId) {
    try {
      return _myGroups.firstWhere(
        (group) => group.id == groupId,
      );
    } catch (e) {
      return null;
    }
  }

  // Check if user is group creator
  bool isGroupCreator(String groupId, String userId) {
    final group = getGroupById(groupId);
    return group?.createdBy == userId;
  }

  // Get groups created by user (for PICs)
  List<Group> getMyCreatedGroups(String userId) {
    return _myGroups.where((group) => group.createdBy == userId).toList();
  }

  // Get groups joined by user (for candidates)
  List<Group> getMyJoinedGroups(String userId) {
    return _myGroups.where((group) => group.createdBy != userId).toList();
  }

  // Clear data (for logout)
  void clearData() {
    _myGroups.clear();
    _groupMembers.clear();
    notifyListeners();
  }
}
