import 'package:flutter/material.dart';
import 'package:mycomic/domain/comic_model.dart';
import 'package:mycomic/service/api.dart';
import 'package:mycomic/service/data_cache.dart';
import 'package:mycomic/widget/comic_grid.dart';
import 'package:mycomic/widget/comic_filter_panel.dart';

class DatabaseTabView extends StatefulWidget {
  final bool filtersVisible;
  const DatabaseTabView({super.key, required this.filtersVisible});

  @override
  State<DatabaseTabView> createState() => _DatabaseTabViewState();
}

class _DatabaseTabViewState extends State<DatabaseTabView> {
  final _scrollController = ScrollController();
  final _selectedValues = <String, String?>{};
  final _comics = <ComicModel>[];

  bool _isLoading = false;
  bool _hasMore = true;
  Object? _error;
  int _page = 1;
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    for (final group in databaseFilterGroups) {
      _selectedValues[group.queryKey] = null;
    }
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 500) {
      _loadNextPage();
    }
  }

  Uri _buildUri(int page) {
    final parameters = <String, String>{};
    for (final entry in _selectedValues.entries) {
      final value = entry.value;
      if (value != null) parameters[entry.key] = value;
    }
    if (page > 1) parameters['page'] = '$page';

    return Uri.https(
      'mycomic.com',
      '/cn/comics',
      parameters.isEmpty ? null : parameters,
    );
  }

  String get _cacheKey =>
      'database_${Uri.encodeComponent(_buildUri(1).toString())}';

  Future<void> _load({bool forceRefresh = false}) async {
    final generation = ++_requestGeneration;
    if (!forceRefresh) {
      final cached = await DataCache.read(_cacheKey);
      if (!mounted || generation != _requestGeneration) return;
      if (cached != null) {
        final values = (cached['items'] as List<dynamic>? ?? [])
            .map((item) => ComicModel.fromMap(item as Map<String, dynamic>))
            .toList();
        setState(() {
          _comics
            ..clear()
            ..addAll(values);
          _page = cached['page'] as int? ?? 1;
          _hasMore = cached['hasMore'] as bool? ?? true;
          _isLoading = false;
          _error = null;
        });
        return;
      }
    }
    setState(() {
      if (!forceRefresh) _comics.clear();
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await Api.comics(_buildUri(1));
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _comics
          ..clear()
          ..addAll(items);
        _page = 1;
        _hasMore = items.isNotEmpty;
        _isLoading = false;
      });
      await _saveCache();
    } catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore || _comics.isEmpty) return;
    final generation = _requestGeneration;
    final nextPage = _page + 1;
    setState(() => _isLoading = true);

    try {
      final items = await Api.comics(_buildUri(nextPage));
      if (!mounted || generation != _requestGeneration) return;
      final existingUrls = _comics.map((comic) => comic.url).toSet();
      final newItems = items
          .where((comic) => existingUrls.add(comic.url))
          .toList();
      setState(() {
        _comics.addAll(newItems);
        _page = nextPage;
        _hasMore = items.isNotEmpty && newItems.isNotEmpty;
        _isLoading = false;
      });
      await _saveCache();
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
    _load();
  }

  Future<void> _saveCache() {
    return DataCache.write(_cacheKey, {
      'items': _comics.map((comic) => comic.toMap()).toList(),
      'page': _page,
      'hasMore': _hasMore,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _load(forceRefresh: true),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: widget.filtersVisible
                    ? ComicFilterPanel(
                        groups: databaseFilterGroups,
                        selectedValues: _selectedValues,
                        onSelected: _selectFilter,
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ),
            if (_comics.isNotEmpty) ComicGrid(_comics),
            if (_comics.isEmpty && _isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_comics.isEmpty && !_isLoading)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(
                  error: _error,
                  onRetry: () => _load(forceRefresh: true),
                ),
              ),
            if (_comics.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 72,
                  child: Center(
                    child: _isLoading
                        ? const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : _error != null
                        ? TextButton.icon(
                            onPressed: _loadNextPage,
                            icon: const Icon(Icons.refresh),
                            label: const Text('加载失败，点击重试'),
                          )
                        : !_hasMore
                        ? const Text('已经到底了')
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              error == null ? Icons.inbox_outlined : Icons.error_outline,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(error == null ? '没有找到符合条件的漫画' : '加载失败'),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
