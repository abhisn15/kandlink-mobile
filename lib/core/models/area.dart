class Area {
  final String id;
  final String name;
  final int lastPicIndex;

  Area({
    required this.id,
    required this.name,
    required this.lastPicIndex,
  });

  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      lastPicIndex: json['last_pic_index'] is int
          ? json['last_pic_index']
          : int.tryParse(json['last_pic_index']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'last_pic_index': lastPicIndex,
    };
  }
}
