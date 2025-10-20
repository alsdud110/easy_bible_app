import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/favorite_provider.dart';
import 'favorite_detail_screen.dart';

class FavoriteListScreen extends StatefulWidget {
  const FavoriteListScreen({super.key});

  @override
  State<FavoriteListScreen> createState() => _FavoriteListScreenState();
}

class _FavoriteListScreenState extends State<FavoriteListScreen> {
  bool _isDeleteMode = false;
  final Set<String> _selectedKeys = {};

  String _formatDateTime(DateTime dateTime) {
    final localTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    return DateFormat('yyyy-MM-dd HH:mm').format(localTime);
  }

  void _enterDeleteMode() {
    setState(() {
      _isDeleteMode = true;
      _selectedKeys.clear();
    });
  }

  void _exitDeleteMode() {
    setState(() {
      _isDeleteMode = false;
      _selectedKeys.clear();
    });
  }

  void _toggleSelectAll(int totalCount) {
    setState(() {
      if (_selectedKeys.length == totalCount) {
        _selectedKeys.clear();
      } else {
        final favoriteProvider = context.read<FavoriteProvider>();
        _selectedKeys.clear();
        _selectedKeys.addAll(favoriteProvider.favorites.map((f) => f.key));
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedKeys.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('선택 항목 삭제'),
        content: Text('${_selectedKeys.length}개의 북마크를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final favoriteProvider = context.read<FavoriteProvider>();
      for (final key in _selectedKeys) {
        await favoriteProvider.removeFavorite(key);
      }

      if (mounted) {
        _exitDeleteMode();
      }
    }
  }

  Future<void> _deleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('전체 삭제'),
        content: const Text('모든 북마크를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('전체 삭제'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<FavoriteProvider>().clearAll();
      if (mounted) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final favoriteProvider = context.watch<FavoriteProvider>();
    final favorites = favoriteProvider.favorites;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isDeleteMode ? '${_selectedKeys.length}개 선택됨' : '북마크',
          style: theme.appBarTheme.titleTextStyle,
        ),
        leading: _isDeleteMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitDeleteMode,
              )
            : IconButton(
                icon: const Icon(Icons.home),
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (route) => false,
                  );
                },
                tooltip: '홈으로',
              ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation ?? 0,
        scrolledUnderElevation: theme.appBarTheme.scrolledUnderElevation ?? 0,
        centerTitle: theme.appBarTheme.centerTitle ?? true,
        actions: _isDeleteMode
            ? [
                IconButton(
                  icon: Icon(
                    _selectedKeys.length == favorites.length
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                  ),
                  tooltip: '전체 선택',
                  onPressed: () => _toggleSelectAll(favorites.length),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: '삭제',
                  onPressed: _selectedKeys.isEmpty ? null : _deleteSelected,
                ),
              ]
            : [
                if (favorites.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: '선택 삭제',
                    onPressed: _enterDeleteMode,
                  ),
                if (favorites.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep),
                    tooltip: '전체 삭제',
                    onPressed: _deleteAll,
                  ),
              ],
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sentiment_dissatisfied_outlined,
                    size: 80,
                    color: cs.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '아직 마음에 드는\n성경 구절을 찾지 못했어요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface.withOpacity(0.6),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '구절을 길게 눌러 북마크에 추가해보세요',
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: favorites.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final favorite = favorites[index];
                final isSelected = _selectedKeys.contains(favorite.key);
                final hasMemos = favorite.memos.isNotEmpty;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: _isDeleteMode
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedKeys.add(favorite.key);
                              } else {
                                _selectedKeys.remove(favorite.key);
                              }
                            });
                          },
                        )
                      : Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber[700],
                              size: 28,
                            ),
                            if (hasMemos)
                              Positioned(
                                right: -4,
                                bottom: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: cs.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: cs.surface,
                                      width: 1.5,
                                    ),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    favorite.memos.length > 9
                                        ? '9+'
                                        : '${favorite.memos.length}',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: cs.onPrimary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                  title: Text(
                    favorite.reference,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        favorite.text.split('\n').first.length > 50
                            ? '${favorite.text.split('\n').first.substring(0, 50)}...'
                            : favorite.text.split('\n').first,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasMemos) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.comment,
                                size: 14,
                                color: cs.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '메모 ${favorite.memos.length}개',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        _formatDateTime(favorite.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  trailing: _isDeleteMode
                      ? null
                      : Icon(
                          Icons.chevron_right,
                          color: cs.onSurface.withOpacity(0.3),
                        ),
                  onTap: () {
                    if (_isDeleteMode) {
                      setState(() {
                        if (isSelected) {
                          _selectedKeys.remove(favorite.key);
                        } else {
                          _selectedKeys.add(favorite.key);
                        }
                      });
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FavoriteDetailScreen(
                            favorite: favorite,
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}
