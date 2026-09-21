import 'package:flutter/material.dart';
import 'package:mycomic/core/app_navigator.dart';
import 'package:mycomic/domain/ranking_item_model.dart';
import 'package:mycomic/service/api.dart';
import 'package:mycomic/widget/comic_filter_panel.dart';

class RankingTabView extends StatefulWidget {
  final bool filtersVisible;
  const RankingTabView({super.key, required this.filtersVisible});

  @override
  State<RankingTabView> createState() => _RankingTabViewState();
}

class _RankingTabViewState extends State<RankingTabView> {
  final _selectedValues = <String, String?>{};
  List<RankingItemModel> _items = const [];
  bool _isLoading = false;
  Object? _error;
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    for (final group in rankingFilterGroups) {
      _selectedValues[group.queryKey] = null;
    }
    _reload();
  }

  Uri _buildUri() {
    final parameters = <String, String>{};
    for (final entry in _selectedValues.entries) {
      if (entry.value != null) parameters[entry.key] = entry.value!;
    }
    return Uri.https(
      'mycomic.com',
      '/cn/rank',
      parameters.isEmpty ? null : parameters,
    );
  }

  Future<void> _reload() async {
    final generation = ++_requestGeneration;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await Api.rankings(_buildUri());
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  void _selectFilter(ComicFilterGroup group, String? value) {
    if (_selectedValues[group.queryKey] == value) return;
    _selectedValues[group.queryKey] = value;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _reload,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: widget.filtersVisible
                    ? ComicFilterPanel(
                        groups: rankingFilterGroups,
                        selectedValues: _selectedValues,
                        onSelected: _selectFilter,
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ),
            if (_isLoading && _items.isNotEmpty)
              const SliverToBoxAdapter(child: LinearProgressIndicator()),
            if (_items.isNotEmpty)
              SliverList.separated(
                itemCount: _items.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 62),
                itemBuilder: (context, index) =>
                    _RankingTile(item: _items[index]),
              ),
            if (_items.isEmpty && _isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_items.isEmpty && !_isLoading)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _RankingEmptyState(error: _error, onRetry: _reload),
              ),
          ],
        ),
      ),
    );
  }
}

class _RankingTile extends StatelessWidget {
  const _RankingTile({required this.item});

  final RankingItemModel item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rankColor = switch (item.rank) {
      1 => const Color(0xffffb300),
      2 => const Color(0xff90a4ae),
      3 => const Color(0xffbc7a4b),
      _ => colors.onSurfaceVariant,
    };
    return InkWell(
      onTap: () => AppNavigator.startComicDetail(context, item.url),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 38,
              child: Text(
                '${item.rank}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: rankColor,
                  fontSize: item.rank <= 3 ? 22 : 16,
                  fontWeight: item.rank <= 3
                      ? FontWeight.w800
                      : FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (item.authors.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.authors,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      if (item.chapter.isNotEmpty)
                        Text(
                          item.chapter,
                          style: TextStyle(fontSize: 12, color: colors.primary),
                        ),
                      if (item.updatedAt.isNotEmpty)
                        Text(
                          item.updatedAt,
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (item.score.isNotEmpty) ...[
              const SizedBox(width: 8),
              Column(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: Color(0xffffb300),
                  ),
                  Text(
                    item.score,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RankingEmptyState extends StatelessWidget {
  const _RankingEmptyState({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            error == null ? Icons.leaderboard_outlined : Icons.error_outline,
            size: 44,
          ),
          const SizedBox(height: 12),
          Text(error == null ? '没有找到符合条件的排行' : '排行榜加载失败'),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
