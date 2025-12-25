import '../models/assignment.dart';
import 'api_service.dart';
import '../constants/api_endpoints.dart';

class AssignmentService {
  final ApiService _apiService = ApiService();

  // Assign PIC to candidate (candidate only)
  Future<AssignmentResponse> assignPIC(String areaId) async {
    final data = {'areaId': areaId};
    final response = await _apiService.post(ApiEndpoints.assignPIC, data: data);
    return AssignmentResponse.fromJson(response.data['data']);
  }

  // Get current PIC for candidate (candidate only)
  Future<Assignment?> getCurrentPIC() async {
    try {
      final response = await _apiService.get(ApiEndpoints.getCurrentPIC);
      if (response.data['data'] != null) {
        return Assignment.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      if (e.toString().contains('Belum ada PIC yang diassign')) {
        return null;
      }
      rethrow;
    }
  }

  // Get candidates for PIC (PIC only)
  Future<List<Assignment>> getCandidatesForPIC() async {
    final response = await _apiService.get(ApiEndpoints.getCandidatesForPIC);
    final candidatesData = response.data['data']['candidates'] as List;
    return candidatesData
        .map((candidate) => Assignment.fromJson(candidate))
        .toList();
  }

  // Redirect candidate to different area (PIC only)
  Future<AssignmentResponse> redirectCandidate(
      String candidateId, String newAreaId) async {
    final data = {
      'candidateId': candidateId,
      'newAreaId': newAreaId,
    };
    final response =
        await _apiService.post(ApiEndpoints.redirectCandidate, data: data);
    return AssignmentResponse.fromJson(response.data['data']);
  }

  // Get assignment history
  Future<List<Assignment>> getAssignmentHistory({
    int page = 1,
    int limit = 50,
    String? candidateId,
    String? picId,
    String? areaId,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (candidateId != null) queryParams['candidateId'] = candidateId;
    if (picId != null) queryParams['picId'] = picId;
    if (areaId != null) queryParams['areaId'] = areaId;

    final response = await _apiService.get(ApiEndpoints.getAssignmentHistory,
        queryParameters: queryParams);
    final assignmentsData = response.data['data']['assignments'] as List;
    return assignmentsData
        .map((assignment) => Assignment.fromJson(assignment))
        .toList();
  }
}
