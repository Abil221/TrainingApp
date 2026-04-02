class ProfileSearchResult {
  final String profileId;
  final String displayName;
  final String email;
  final String? friendshipId;
  final String? friendshipStatus;
  final bool isOutgoing;

  const ProfileSearchResult({
    required this.profileId,
    required this.displayName,
    required this.email,
    this.friendshipId,
    this.friendshipStatus,
    this.isOutgoing = false,
  });
}