class FriendProfile {
  final String id;
  final String name;

  const FriendProfile({required this.id, required this.name});

  FriendProfile copyWith({String? id, String? name}) {
    return FriendProfile(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory FriendProfile.fromJson(Map<String, dynamic> json) {
    return FriendProfile(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}
