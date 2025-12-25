import 'package:flutter/foundation.dart';
import 'user.dart';
import 'area.dart';

class Assignment {
  final String id;
  final String candidateId;
  final String picId;
  final String areaId;
  final DateTime assignedAt;
  final User? candidate;
  final User? pic;
  final Area? area;

  Assignment({
    required this.id,
    required this.candidateId,
    required this.picId,
    required this.areaId,
    required this.assignedAt,
    this.candidate,
    this.pic,
    this.area,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    debugPrint('🔍 Assignment.fromJson - input JSON: $json');

    // Extract PIC ID from nested structure
    String picId = '';
    if (json['pic_id'] != null && json['pic_id'].toString().isNotEmpty) {
      picId = json['pic_id'].toString();
    } else if (json['picId'] != null && json['picId'].toString().isNotEmpty) {
      picId = json['picId'].toString();
    } else if (json['pic'] is Map && json['pic']['id'] != null) {
      picId = json['pic']['id'].toString();
    }

    // Extract Area ID from nested structure
    String areaId = '';
    if (json['area_id'] != null && json['area_id'].toString().isNotEmpty) {
      areaId = json['area_id'].toString();
    } else if (json['areaId'] != null && json['areaId'].toString().isNotEmpty) {
      areaId = json['areaId'].toString();
    } else if (json['area'] is Map && json['area']['id'] != null) {
      areaId = json['area']['id'].toString();
    }

    debugPrint('🔍 Assignment.fromJson - extracted picId: "$picId"');
    debugPrint('🔍 Assignment.fromJson - extracted areaId: "$areaId"');

    // Parse assignedAt with fallback
    DateTime assignedAt;
    try {
      assignedAt = DateTime.parse(json['assigned_at'] ?? json['assignedAt'] ?? DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('🔍 Assignment.fromJson - error parsing date: $e, using current time');
      assignedAt = DateTime.now();
    }

    final assignment = Assignment(
      id: json['id']?.toString() ?? json['assignmentId']?.toString() ?? '',
      candidateId: json['candidate_id']?.toString() ?? json['candidateId']?.toString() ?? '',
      picId: picId,
      areaId: areaId,
      assignedAt: assignedAt,
      candidate: json['candidate'] != null ? User.fromJson(json['candidate']) : null,
      pic: json['pic'] != null ? User.fromJson(json['pic']) : null,
      area: json['area'] != null ? Area.fromJson(json['area']) : null,
    );

    debugPrint('🔍 Assignment.fromJson - created assignment with picId: "${assignment.picId}"');

    return assignment;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'candidate_id': candidateId,
      'pic_id': picId,
      'area_id': areaId,
      'assigned_at': assignedAt.toIso8601String(),
      'candidate': candidate?.toJson(),
      'pic': pic?.toJson(),
      'area': area?.toJson(),
    };
  }
}

class AssignmentResponse {
  final User pic;
  final Area area;
  final String assignmentId;
  final DateTime assignedAt;

  AssignmentResponse({
    required this.pic,
    required this.area,
    required this.assignmentId,
    required this.assignedAt,
  });

  factory AssignmentResponse.fromJson(Map<String, dynamic> json) {
    return AssignmentResponse(
      pic: User.fromJson(json['pic']),
      area: Area.fromJson(json['area']),
      assignmentId: json['assignmentId'],
      assignedAt: DateTime.parse(json['assignedAt']),
    );
  }
}
