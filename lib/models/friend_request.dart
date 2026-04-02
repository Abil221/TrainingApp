class FriendRequest {
  final String friendshipId;
  final String profileId;
  final String name;
  final String email;
  final bool isOutgoing;

  const FriendRequest({
    required this.friendshipId,
    required this.profileId,
    required this.name,
    required this.email,
    required this.isOutgoing,
  });
}