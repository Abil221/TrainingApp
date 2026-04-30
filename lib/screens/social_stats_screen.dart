import 'package:flutter/material.dart';

import '../models/friend_profile.dart';
import '../models/friend_request.dart';
import '../models/profile_search_result.dart';
import '../models/chat_message.dart';
import '../services/workout_service.dart';
import '../widgets/app_surfaces.dart';
import 'chat_screen.dart';

class SocialStatsScreen extends StatefulWidget {
  const SocialStatsScreen({super.key});

  @override
  State<SocialStatsScreen> createState() => _SocialStatsScreenState();
}

class _SocialStatsScreenState extends State<SocialStatsScreen> {
  final WorkoutService _workoutService = WorkoutService();
  final TextEditingController _searchController = TextEditingController();

  List<FriendRequest> _incomingRequests = const [];
  List<FriendRequest> _outgoingRequests = const [];
  List<ProfileSearchResult> _searchResults = const [];
  Map<String, ChatMessage?> _lastChatMessages = {};
  Map<String, int> _unreadChatCounts = {};
  
  String? _selectedFriendId;
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _workoutService.addListener(_handleServiceChanged);
    _refresh();
  }

  @override
  void dispose() {
    _workoutService.removeListener(_handleServiceChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleServiceChanged() {
    if (!mounted) {
      return;
    }

    setState(() {
      _lastChatMessages = _workoutService.getLastChatMessages();
      _unreadChatCounts = _workoutService.getUnreadChatCounts();
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
    });

    await _workoutService.refreshSocialData();
    final incoming =
        await _workoutService.getPendingFriendRequests(outgoing: false);
    final outgoing =
        await _workoutService.getPendingFriendRequests(outgoing: true);

    if (!mounted) {
      return;
    }

    setState(() {
      _incomingRequests = incoming;
      _outgoingRequests = outgoing;
      _lastChatMessages = _workoutService.getLastChatMessages();
      _unreadChatCounts = _workoutService.getUnreadChatCounts();
      _isLoading = false;

      final friends = _workoutService.getFriendProfiles();
      if (friends.isNotEmpty && _selectedFriendId == null) {
        _selectedFriendId = friends.first.id;
      }
    });

    if (_searchController.text.trim().length >= 2) {
      await _runSearch();
    }
  }

  Future<void> _runSearch() async {
    final query = _searchController.text.trim();
    if (query.length < 2) {
      setState(() {
        _searchResults = const [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final results = await _workoutService.searchProfiles(query);
    if (!mounted) {
      return;
    }

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  Future<void> _handleSendRequest(ProfileSearchResult result) async {
    final messenger = ScaffoldMessenger.of(context);
    await _workoutService.sendFriendRequest(result.profileId);
    if (!mounted) {
      return;
    }
    messenger.showSnackBar(
      const SnackBar(content: Text('Заявка отправлена')),
    );
    await _refresh();
  }

  Future<void> _handleOpenChat(FriendProfile friend) async {
    if (friend.friendshipId == null || friend.friendshipId!.isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(friend: friend),
      ),
    );

    if (!mounted) {
      return;
    }

    await _refresh();
  }

  Future<void> _handleRespond(FriendRequest request, bool accept) async {
    final messenger = ScaffoldMessenger.of(context);
    await _workoutService.respondToFriendRequest(
      request.friendshipId,
      accept: accept,
    );
    if (!mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(accept ? 'Заявка принята' : 'Заявка отклонена'),
      ),
    );
    await _refresh();
  }

  Future<void> _handleRemoveFriendship(
    String friendshipId,
    String successMessage,
  ) async {
    if (friendshipId.isEmpty) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    await _workoutService.removeFriendship(friendshipId);
    if (!mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final friends = _workoutService.getFriendProfiles();
    final activeFriend = friends.isNotEmpty
        ? friends.firstWhere(
            (friend) => friend.id == _selectedFriendId,
            orElse: () => friends.first,
          )
        : null;

    return ListenableBuilder(
      listenable: _workoutService,
      builder: (context, child) {
        final stats = _workoutService.getStats();
        final friendStats = activeFriend != null && activeFriend.id != 'none'
            ? _workoutService.getFriendStats(activeFriend.id)
            : {'totalWorkouts': 0, 'totalCalories': 0, 'totalDuration': 0};

        return Scaffold(
          appBar: AppBar(
            title: const Text('Статистика и Друзья'),
          ),
          body: AppScreenBackground(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  // Hero Stats
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF111827),
                          Color(0xFF283548),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF2A9D8F).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'SOCIAL MODE',
                            style: TextStyle(
                              color: Color(0xFFA8F0E6),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Статистика и Соревнование',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Сравнивай свой прогресс с друзьями и мотивируй себя',
                          style: TextStyle(
                            color: Color(0xFFD1D5DB),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Comparison Card
                  if (activeFriend != null)
                    _ComparisonCard(
                      activeFriend: activeFriend,
                      friends: friends,
                      selectedFriendId: _selectedFriendId,
                      onFriendChanged: (value) {
                        setState(() {
                          _selectedFriendId = value;
                        });
                      },
                      totalWorkouts: stats['totalWorkouts'] ?? 0,
                      friendWorkouts: friendStats['totalWorkouts'] ?? 0,
                      totalCalories: stats['totalCalories'] ?? 0,
                      friendCalories: friendStats['totalCalories'] ?? 0,
                      totalDuration: (stats['totalDuration'] ?? 0) ~/ 60,
                      friendDuration:
                          (friendStats['totalDuration'] ?? 0) ~/ 60,
                      streak: _workoutService.getTrainingStreak(),
                      friendStreak:
                          _workoutService.getFriendTrainingStreak(activeFriend.id),
                      sharedDays:
                          _workoutService.getSharedTrainingDays(activeFriend.id),
                      sharedStreak: _workoutService
                          .getSharedTrainingStreak(activeFriend.id),
                      isDark: isDark,
                    ),
                  const SizedBox(height: 24),

                  // Friends List Section
                  if (friends.isNotEmpty)
                    _FriendsListCard(
                      friends: friends,
                      lastMessages: _lastChatMessages,
                      unreadCounts: _unreadChatCounts,
                      onOpenChat: _handleOpenChat,
                      onRemoveFriend: (friendshipId) =>
                          _handleRemoveFriendship(
                        friendshipId,
                        'Друг удален',
                      ),
                      isDark: isDark,
                    ),
                  const SizedBox(height: 24),

                  // Requests Section
                  if (_incomingRequests.isNotEmpty)
                    _RequestsCard(
                      title: 'Входящие заявки',
                      requests: _incomingRequests,
                      onRespond: _handleRespond,
                      isDark: isDark,
                    ),
                  if (_incomingRequests.isNotEmpty)
                    const SizedBox(height: 16),

                  if (_outgoingRequests.isNotEmpty)
                    _RequestsCard(
                      title: 'Отправленные заявки',
                      requests: _outgoingRequests,
                      onRespond: (request, accept) =>
                          _handleRemoveFriendship(
                        request.friendshipId,
                        'Заявка отменена',
                      ),
                      isDark: isDark,
                      isOutgoing: true,
                    ),
                  if (_outgoingRequests.isNotEmpty)
                    const SizedBox(height: 24),

                  // Search Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: isDark
                          ? const Color(0xFF1A2538).withValues(alpha: 0.8)
                          : const Color(0xFFF8FAFC),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Поиск пользователей',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _searchController,
                          onChanged: (_) => _runSearch(),
                          decoration: InputDecoration(
                            hintText: 'Введи имя пользователя...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.search),
                          ),
                        ),
                        if (_isSearching)
                          const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: SizedBox(
                              height: 40,
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          ),
                        if (!_isSearching && _searchResults.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          ..._searchResults.map(
                            (result) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF243041)
                                        : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor:
                                          const Color(0xFF111827),
                                      child: Text(
                                        result.displayName.substring(0, 1).toUpperCase(),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            result.displayName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            result.email,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          _handleSendRequest(result),
                                      child: const Text('Добавить'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final FriendProfile activeFriend;
  final List<FriendProfile> friends;
  final String? selectedFriendId;
  final ValueChanged<String> onFriendChanged;
  final int totalWorkouts;
  final int friendWorkouts;
  final int totalCalories;
  final int friendCalories;
  final int totalDuration;
  final int friendDuration;
  final int streak;
  final int friendStreak;
  final int sharedDays;
  final int sharedStreak;
  final bool isDark;

  const _ComparisonCard({
    required this.activeFriend,
    required this.friends,
    required this.selectedFriendId,
    required this.onFriendChanged,
    required this.totalWorkouts,
    required this.friendWorkouts,
    required this.totalCalories,
    required this.friendCalories,
    required this.totalDuration,
    required this.friendDuration,
    required this.streak,
    required this.friendStreak,
    required this.sharedDays,
    required this.sharedStreak,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A2538).withValues(alpha: 0.8)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Соревнование с другом',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: selectedFriendId ?? activeFriend.id,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: friends
                .map(
                  (friend) => DropdownMenuItem<String>(
                    value: friend.id,
                    child: Text(friend.name),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) {
                onFriendChanged(value);
              }
            },
          ),
          const SizedBox(height: 20),
          _StatRow(
            label: 'Тренировки',
            yourValue: totalWorkouts,
            friendValue: friendWorkouts,
            yourLabel: 'Мои',
            friendLabel: activeFriend.name,
          ),
          const SizedBox(height: 12),
          _StatRow(
            label: 'Калории',
            yourValue: totalCalories,
            friendValue: friendCalories,
            yourLabel: 'Мои',
            friendLabel: activeFriend.name,
          ),
          const SizedBox(height: 12),
          _StatRow(
            label: 'Время (мин)',
            yourValue: totalDuration,
            friendValue: friendDuration,
            yourLabel: 'Мои',
            friendLabel: activeFriend.name,
          ),
          const SizedBox(height: 12),
          _StatRow(
            label: 'Стрик',
            yourValue: streak,
            friendValue: friendStreak,
            yourLabel: 'Свой',
            friendLabel: activeFriend.name,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  title: 'Общие дни',
                  value: '$sharedDays',
                  subtitle: 'когда вы тренировались оба',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  title: 'Общий стрик',
                  value: '$sharedStreak',
                  subtitle: 'подряд вместе',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int yourValue;
  final int friendValue;
  final String yourLabel;
  final String friendLabel;

  const _StatRow({
    required this.label,
    required this.yourValue,
    required this.friendValue,
    required this.yourLabel,
    required this.friendLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isBetter = yourValue > friendValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFF6B35)
                        .withValues(alpha: isBetter ? 0.5 : 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      yourLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      '$yourValue',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A9D8F).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF2A9D8F)
                        .withValues(alpha: !isBetter ? 0.5 : 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friendLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      '$friendValue',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _MetricTile({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF2A9D8F), Color(0xFF1B8B7B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFFA8F0E6),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendsListCard extends StatelessWidget {
  final List<FriendProfile> friends;
  final Map<String, ChatMessage?> lastMessages;
  final Map<String, int> unreadCounts;
  final Function(FriendProfile) onOpenChat;
  final Function(String) onRemoveFriend;
  final bool isDark;

  const _FriendsListCard({
    required this.friends,
    required this.lastMessages,
    required this.unreadCounts,
    required this.onOpenChat,
    required this.onRemoveFriend,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final sortedFriends = friends.toList(growable: false)
      ..sort((a, b) {
        final aMessage = a.friendshipId == null
            ? null
            : lastMessages[a.friendshipId!];
        final bMessage = b.friendshipId == null
            ? null
            : lastMessages[b.friendshipId!];

        final aTime = aMessage?.createdAt;
        final bTime = bMessage?.createdAt;
        if (aTime != null && bTime != null) {
          return bTime.compareTo(aTime);
        }
        if (aTime != null) {
          return -1;
        }
        if (bTime != null) {
          return 1;
        }
        return a.name.compareTo(b.name);
      });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: isDark
            ? const Color(0xFF1A2538).withValues(alpha: 0.8)
            : const Color(0xFFF8FAFC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Мои друзья',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          ...sortedFriends.map(
            (friend) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FriendTile(
                friend: friend,
                lastMessage: friend.friendshipId != null
                    ? lastMessages[friend.friendshipId!]
                    : null,
                unreadCount: friend.friendshipId != null
                    ? (unreadCounts[friend.friendshipId!] ?? 0)
                    : 0,
                isDark: isDark,
                onOpenChat: () => onOpenChat(friend),
                onRemove: () =>
                    onRemoveFriend(friend.friendshipId ?? ''),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final FriendProfile friend;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final bool isDark;
  final VoidCallback onOpenChat;
  final VoidCallback onRemove;

  const _FriendTile({
    required this.friend,
    required this.lastMessage,
    required this.unreadCount,
    required this.isDark,
    required this.onOpenChat,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFF243041)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF111827),
                child: Text(
                  friend.name.substring(0, 1).toUpperCase(),
                ),
              ),
              if (friend.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10B981),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF111827)
                            : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  lastMessage?.content ?? 'Нет сообщений',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          const SizedBox(width: 12),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Написать'),
                onTap: onOpenChat,
              ),
              PopupMenuItem(
                child: const Text('Удалить'),
                onTap: onRemove,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestsCard extends StatelessWidget {
  final String title;
  final List<FriendRequest> requests;
  final Function(FriendRequest, bool) onRespond;
  final bool isDark;
  final bool isOutgoing;

  const _RequestsCard({
    required this.title,
    required this.requests,
    required this.onRespond,
    required this.isDark,
    this.isOutgoing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: isDark
            ? const Color(0xFF1A2538).withValues(alpha: 0.8)
            : const Color(0xFFF8FAFC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          ...requests.map(
            (request) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF243041)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF111827),
                      child: Text(
                        request.name.substring(0, 1).toUpperCase(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        request.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (!isOutgoing) ...[
                      ElevatedButton(
                        onPressed: () => onRespond(request, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text('Принять'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => onRespond(request, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text('Отклонить'),
                      ),
                    ] else
                      OutlinedButton(
                        onPressed: () => onRespond(request, false),
                        child: const Text('Отменить'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
