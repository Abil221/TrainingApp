class FriendProfile {
  final String id;
  final String name;
  final String? friendshipId;

  const FriendProfile({
    required this.id,
    required this.name,
    this.friendshipId,
  });

  FriendProfile copyWith({String? id, String? name, String? friendshipId}) {
    return FriendProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      friendshipId: friendshipId ?? this.friendshipId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'friendshipId': friendshipId,
    };
  }

  factory FriendProfile.fromJson(Map<String, dynamic> json) {
    return FriendProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      friendshipId: json['friendshipId'] as String?,
    );
  }
}
