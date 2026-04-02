import 'package:flutter/material.dart';

import '../models/friend_profile.dart';
import '../models/friend_request.dart';
import '../models/profile_search_result.dart';
import '../services/workout_service.dart';
import '../widgets/app_surfaces.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final WorkoutService _workoutService = WorkoutService();
  final TextEditingController _searchController = TextEditingController();

  List<FriendRequest> _incomingRequests = const [];
  List<FriendRequest> _outgoingRequests = const [];
  List<ProfileSearchResult> _searchResults = const [];
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      _isLoading = false;
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
    final friends = _workoutService.getFriendProfiles();

    return Scaffold(
      appBar: AppBar(title: const Text('Друзья')),
      body: AppScreenBackground(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF111827), Color(0xFF283548)],
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
                        color: const Color(0xFF2A9D8F).withValues(alpha: 0.18),
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
                      'Друзья и сравнение прогресса',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Друзей: ${friends.length}  |  входящих: ${_incomingRequests.length}  |  исходящих: ${_outgoingRequests.length}',
                      style: const TextStyle(
                        color: Color(0xFFD1D5DB),
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: appPanelDecoration(
                  context,
                  accent: const Color(0xFF2A9D8F),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Найти пользователя',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Имя или email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                            onSubmitted: (_) => _runSearch(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isSearching ? null : _runSearch,
                            child: Text(_isSearching ? '...' : 'Найти'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_searchResults.isEmpty)
                      const Text(
                        'Введи минимум 2 символа, чтобы найти пользователя и отправить заявку.',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      )
                    else
                      ..._searchResults.map(
                        (result) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SearchResultTile(
                            result: result,
                            onAdd: () => _handleSendRequest(result),
                            onAccept: result.friendshipId == null
                                ? null
                                : () => _handleRespond(
                                      FriendRequest(
                                        friendshipId: result.friendshipId!,
                                        profileId: result.profileId,
                                        name: result.displayName,
                                        email: result.email,
                                        isOutgoing: false,
                                      ),
                                      true,
                                    ),
                            onCancel: result.friendshipId == null
                                ? null
                                : () => _handleRemoveFriendship(
                                      result.friendshipId!,
                                      'Заявка отменена',
                                    ),
                            onRemoveFriend: result.friendshipId == null
                                ? null
                                : () => _handleRemoveFriendship(
                                      result.friendshipId!,
                                      'Друг удалён',
                                    ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Входящие заявки',
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _incomingRequests.isEmpty
                        ? const _EmptySection(
                            text: 'Новых заявок пока нет.',
                          )
                        : Column(
                            children: _incomingRequests
                                .map(
                                  (request) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _RequestTile(
                                      request: request,
                                      onAccept: () =>
                                          _handleRespond(request, true),
                                      onDecline: () =>
                                          _handleRespond(request, false),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Исходящие заявки',
                child: _outgoingRequests.isEmpty
                    ? const _EmptySection(
                        text: 'Ты пока никому не отправил заявку.',
                      )
                    : Column(
                        children: _outgoingRequests
                            .map(
                              (request) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _OutgoingRequestTile(
                                  request: request,
                                  onCancel: () => _handleRemoveFriendship(
                                    request.friendshipId,
                                    'Заявка отменена',
                                  ),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Текущие друзья',
                child: friends.isEmpty
                    ? const _EmptySection(
                        text: 'Пока нет друзей для сравнения статистики.',
                      )
                    : Column(
                        children: friends
                            .map(
                              (friend) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _FriendTile(
                                  friend: friend,
                                  onRemove: () => _handleRemoveFriendship(
                                    friend.friendshipId ?? '',
                                    'Друг удалён',
                                  ),
                                  workoutCount: _workoutService
                                      .getFriendStats(friend.id)['totalWorkouts']!,
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: appPanelDecoration(
        context,
        accent: const Color(0xFF111827),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final ProfileSearchResult result;
  final VoidCallback onAdd;
  final VoidCallback? onAccept;
  final VoidCallback? onCancel;
  final VoidCallback? onRemoveFriend;

  const _SearchResultTile({
    required this.result,
    required this.onAdd,
    this.onAccept,
    this.onCancel,
    this.onRemoveFriend,
  });

  @override
  Widget build(BuildContext context) {
    final action = _buildAction();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.72),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF111827),
            child: Icon(Icons.person_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  result.email,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          action,
        ],
      ),
    );
  }

  Widget _buildAction() {
    switch (result.friendshipStatus) {
      case 'accepted':
        return TextButton(
          onPressed: onRemoveFriend,
          child: const Text('Удалить'),
        );
      case 'pending':
        if (result.isOutgoing) {
          return TextButton(
            onPressed: onCancel,
            child: const Text('Отменить'),
          );
        }
        return TextButton(
          onPressed: onAccept,
          child: const Text('Принять'),
        );
      case 'declined':
      case null:
        return ElevatedButton(
          onPressed: onAdd,
          child: const Text('Добавить'),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _RequestTile extends StatelessWidget {
  final FriendRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _RequestTile({
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.72),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF111827),
                child: Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      request.email,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  child: const Text('Принять'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  child: const Text('Отклонить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OutgoingRequestTile extends StatelessWidget {
  final FriendRequest request;
  final VoidCallback onCancel;

  const _OutgoingRequestTile({
    required this.request,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.72),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFFF6B35),
                child: Icon(Icons.schedule_send_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      request.email,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const _StatusPill(label: 'Ожидает', color: Color(0xFFFF6B35)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onCancel,
              child: const Text('Отменить заявку'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final FriendProfile friend;
  final int workoutCount;
  final VoidCallback onRemove;

  const _FriendTile({
    required this.friend,
    required this.workoutCount,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.72),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF2A9D8F),
                child: Icon(Icons.people_alt_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      '$workoutCount тренировок в общей статистике',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const _StatusPill(label: 'Друг', color: Color(0xFF2A9D8F)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onRemove,
              child: const Text('Удалить из друзей'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String text;

  const _EmptySection({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 14,
          height: 1.45,
        ),
      ),
    );
  }
}