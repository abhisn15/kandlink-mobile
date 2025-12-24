import 'user.dart';
import 'area.dart';

class Group {
  final String id;
  final String name;
  final String createdBy;
  final String? areaId;
  final String? avatar;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? creator;
  final Area? area;
  final List<GroupMember>? members;

  Group({
    required this.id,
    required this.name,
    required this.createdBy,
    this.areaId,
    this.avatar,
    required this.createdAt,
    required this.updatedAt,
    this.creator,
    this.area,
    this.members,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      createdBy: json['created_by'],
      areaId: json['area_id'],
      avatar: json['avatar'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      creator: json['creator'] != null ? User.fromJson(json['creator']) : null,
      area: json['area'] != null ? Area.fromJson(json['area']) : null,
      members: json['members'] != null
          ? (json['members'] as List).map((member) => GroupMember.fromJson(member)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_by': createdBy,
      'area_id': areaId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'creator': creator?.toJson(),
      'area': area?.toJson(),
      'members': members?.map((member) => member.toJson()).toList(),
    };
  }

  int get memberCount => members?.length ?? 0;

  bool get isCreator => createdBy == 'current_user_id'; // Will be set by provider
}

class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final String addedBy;
  final DateTime addedAt;
  final User? user;
  final User? adder;

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.addedBy,
    required this.addedAt,
    this.user,
    this.adder,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'],
      groupId: json['group_id'] ?? json['groupId'],
      userId: json['user_id'] ?? json['userId'],
      addedBy: json['added_by'] ?? json['addedBy'],
      addedAt: DateTime.parse(json['added_at'] ?? json['addedAt']),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      adder: json['adder'] != null ? User.fromJson(json['adder']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'added_by': addedBy,
      'added_at': addedAt.toIso8601String(),
      'user': user?.toJson(),
      'adder': adder?.toJson(),
    };
  }
}
