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
    return Assignment(
      id: json['id'] ?? json['assignmentId'] ?? '',
      candidateId: json['candidate_id'] ?? '',
      picId: json['pic_id'] ?? '',
      areaId: json['area_id'] ?? '',
      assignedAt: DateTime.parse(json['assigned_at'] ?? json['assignedAt']),
      candidate: json['candidate'] != null ? User.fromJson(json['candidate']) : null,
      pic: json['pic'] != null ? User.fromJson(json['pic']) : null,
      area: json['area'] != null ? Area.fromJson(json['area']) : null,
    );
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
