import '../models/group.dart';
import 'api_service.dart';
import '../constants/api_endpoints.dart';

class GroupService {
  final ApiService _apiService = ApiService();

  // Create group (PIC only)
  Future<Group> createGroup(String name, {String? areaId}) async {
    final data = {
      'name': name,
      if (areaId != null) 'areaId': areaId,
    };

    final response = await _apiService.post(ApiEndpoints.createGroup, data: data);
    return Group.fromJson(response.data['data']);
  }

  // Add members to group (PIC only, group creator)
  Future<List<GroupMember>> addMembers(String groupId, List<String> candidateIds) async {
    final data = {
      'groupId': groupId,
      'candidateIds': candidateIds,
    };

    final response = await _apiService.post(ApiEndpoints.addMembers, data: data);
    final addedMembers = response.data['data']['members'] as List;
    return addedMembers.map((member) => GroupMember.fromJson(member)).toList();
  }

  // Get user's groups
  Future<List<Group>> getMyGroups() async {
    final response = await _apiService.get(ApiEndpoints.getMyGroups);
    final groupsData = response.data['data']['groups'] as List;
    return groupsData.map((group) => Group.fromJson(group)).toList();
  }

  // Get group members
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    final response = await _apiService.get(ApiEndpoints.getGroupMembers(groupId));
    final membersData = response.data['data']['members'] as List;
    return membersData.map((member) => GroupMember.fromJson(member)).toList();
  }
}
