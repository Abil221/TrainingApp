class FriendProfile {
  final String id;
  final String name;
  final String? friendshipId;
  final bool isOnline;
  final DateTime? lastSeen;

  const FriendProfile({
    required this.id,
    required this.name,
    this.friendshipId,
    this.isOnline = false,
    this.lastSeen,
  });

  FriendProfile copyWith({
    String? id,
    String? name,
    String? friendshipId,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return FriendProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      friendshipId: friendshipId ?? this.friendshipId,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'friendshipId': friendshipId,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }

  factory FriendProfile.fromJson(Map<String, dynamic> json) {
    return FriendProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      friendshipId: json['friendshipId'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] == null
          ? null
          : DateTime.parse(json['lastSeen'] as String),
    );
  }
}
