import 'package:flutter/material.dart';
import 'package:mycomic/domain/comic_model.dart';
import 'package:mycomic/service/api.dart';
import 'package:mycomic/widget/comic_grid.dart';

class DatabaseTabView extends StatefulWidget {
  const DatabaseTabView({super.key});

  @override
  State<DatabaseTabView> createState() => _DatabaseTabViewState();
}

class _DatabaseTabViewState extends State<DatabaseTabView> {
  final _scrollController = ScrollController();
  final _selectedValues = <String, String?>{};
  final _comics = <ComicModel>[];

  bool _filtersVisible = true;
  bool _isLoading = false;
  bool _hasMore = true;
  Object? _error;
  int _page = 1;
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    for (final group in _filterGroups) {
      _selectedValues[group.queryKey] = null;
    }
    _scrollController.addListener(_onScroll);
    _reload();
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

  Future<void> _reload() async {
    final generation = ++_requestGeneration;
    setState(() {
      _comics.clear();
      _page = 1;
      _hasMore = true;
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await Api.comics(_buildUri(1));
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _comics.addAll(items);
        _hasMore = items.isNotEmpty;
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
    } catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  void _selectFilter(_FilterGroup group, String? value) {
    if (_selectedValues[group.queryKey] == value) return;
    _selectedValues[group.queryKey] = value;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('漫画资料库'),
        actions: [
          IconButton(
            tooltip: _filtersVisible ? '收起筛选' : '展开筛选',
            onPressed: () => setState(() => _filtersVisible = !_filtersVisible),
            icon: Icon(
              _filtersVisible ? Icons.filter_alt_off : Icons.filter_alt,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _filtersVisible
                    ? _FilterDrawer(
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
                child: _EmptyState(error: _error, onRetry: _reload),
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

class _FilterDrawer extends StatelessWidget {
  const _FilterDrawer({required this.selectedValues, required this.onSelected});

  final Map<String, String?> selectedValues;
  final void Function(_FilterGroup group, String? value) onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLow,
      elevation: 1,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 0, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final group in _filterGroups)
                _FilterRow(
                  group: group,
                  selectedValue: selectedValues[group.queryKey],
                  onSelected: (value) => onSelected(group, value),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.group,
    required this.selectedValue,
    required this.onSelected,
  });

  final _FilterGroup group;
  final String? selectedValue;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Row(
        children: [
          SizedBox(
            width: 68,
            child: Text(
              group.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 12),
              itemCount: group.options.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final option = group.options[index];
                return ChoiceChip(
                  label: Text(option.label),
                  selected: selectedValue == option.value,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => onSelected(option.value),
                );
              },
            ),
          ),
        ],
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

class _FilterGroup {
  const _FilterGroup(this.title, this.queryKey, this.options);

  final String title;
  final String queryKey;
  final List<_FilterOption> options;
}

class _FilterOption {
  const _FilterOption(this.label, this.value);

  final String label;
  final String? value;
}

const _all = _FilterOption('所有', null);

const _filterGroups = <_FilterGroup>[
  _FilterGroup('排序', 'sort', [
    _FilterOption('最新上架', null),
    _FilterOption('最近更新', '-update'),
    _FilterOption('最高人气', '-views'),
  ]),
  _FilterGroup('地区', 'filter[country]', [
    _all,
    _FilterOption('日本', 'japan'),
    _FilterOption('港台', 'hongkong'),
    _FilterOption('欧美', 'europe'),
    _FilterOption('内地', 'china'),
    _FilterOption('韩国', 'korea'),
    _FilterOption('其他', 'other'),
  ]),
  _FilterGroup('类型', 'filter[tag]', [
    _all,
    _FilterOption('魔幻', 'mohuan'),
    _FilterOption('魔法', 'mofa'),
    _FilterOption('热血', 'rexue'),
    _FilterOption('冒险', 'maoxian'),
    _FilterOption('悬疑', 'xuanyi'),
    _FilterOption('侦探', 'zhentan'),
    _FilterOption('爱情', 'aiqing'),
    _FilterOption('校园', 'xiaoyuan'),
    _FilterOption('搞笑', 'gaoxiao'),
    _FilterOption('四格', 'sige'),
    _FilterOption('科幻', 'kehuan'),
    _FilterOption('神鬼', 'shengui'),
    _FilterOption('舞蹈', 'wudao'),
    _FilterOption('音乐', 'yinyue'),
    _FilterOption('百合', 'baihe'),
    _FilterOption('后宫', 'hougong'),
    _FilterOption('机战', 'jizhan'),
    _FilterOption('格斗', 'gedou'),
    _FilterOption('恐怖', 'kongbu'),
    _FilterOption('萌系', 'mengxi'),
    _FilterOption('武侠', 'wuxia'),
    _FilterOption('社会', 'shehui'),
    _FilterOption('历史', 'lishi'),
    _FilterOption('耽美', 'danmei'),
    _FilterOption('励志', 'lizhi'),
    _FilterOption('职场', 'zhichang'),
    _FilterOption('生活', 'shenghuo'),
    _FilterOption('治愈', 'zhiyu'),
    _FilterOption('伪娘', 'weiniang'),
    _FilterOption('黑道', 'heidao'),
    _FilterOption('战争', 'zhanzheng'),
    _FilterOption('竞技', 'jingji'),
    _FilterOption('体育', 'tiyu'),
    _FilterOption('美食', 'meishi'),
    _FilterOption('腐女', 'funv'),
    _FilterOption('宅男', 'zhainan'),
    _FilterOption('推理', 'tuili'),
    _FilterOption('杂志', 'zazhi'),
  ]),
  _FilterGroup('受众', 'filter[audience]', [
    _all,
    _FilterOption('少女', 'shaonv'),
    _FilterOption('少年', 'shaonian'),
    _FilterOption('青年', 'qingnian'),
    _FilterOption('儿童', 'ertong'),
    _FilterOption('通用', 'tongyong'),
  ]),
  _FilterGroup('年份', 'filter[year]', [
    _all,
    _FilterOption('2026', '2026'),
    _FilterOption('2025', '2025'),
    _FilterOption('2024', '2024'),
    _FilterOption('2023', '2023'),
    _FilterOption('2022', '2022'),
    _FilterOption('2021', '2021'),
    _FilterOption('2020', '2020'),
    _FilterOption('2019', '2019'),
    _FilterOption('2018', '2018'),
    _FilterOption('2017', '2017'),
    _FilterOption('2016', '2016'),
    _FilterOption('2015', '2015'),
    _FilterOption('2014', '2014'),
    _FilterOption('2013', '2013'),
    _FilterOption('2012', '2012'),
    _FilterOption('2011', '2011'),
    _FilterOption('2010', '2010'),
    _FilterOption('00年代', '200x'),
    _FilterOption('90年代', '199x'),
    _FilterOption('80年代', '198x'),
    _FilterOption('70年代或更早', '197x'),
  ]),
  _FilterGroup('进度', 'filter[end]', [
    _all,
    _FilterOption('连载中', '0'),
    _FilterOption('已完结', '1'),
  ]),
];
