import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mycomic/core/app_navigator.dart';
import 'package:mycomic/domain/home_model.dart';
import 'package:mycomic/domain/rank_model.dart';

class RankPageView extends StatefulWidget {
  const RankPageView(this.home, {super.key});

  final HomeModel home;

  @override
  State<RankPageView> createState() => _RankPageViewState();
}

class _RankPageViewState extends State<RankPageView> {
  static const _itemHeight = 52.0;

  final PageController _pageController = PageController(viewportFraction: 0.8);

  List<({String title, List<RankModel> items})> get _pages => [
    (title: '最近更新', items: widget.home.recentRanking),
    (title: '日排行', items: widget.home.dailyRanking),
    (title: '周排行', items: widget.home.weeklyRanking),
    (title: '历史排行', items: widget.home.historicalRanking),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    final longestPage = pages.fold<int>(
      0,
      (length, page) => math.max(length, page.items.length),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        height: longestPage * _itemHeight + 30,
        child: PageView.builder(
          controller: _pageController,
          padEnds: false,
          itemCount: pages.length,
          itemBuilder: (context, pageIndex) {
            final items = pages[pageIndex].items;
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pages[pageIndex].title,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                ...List.generate(
                  items.length,
                  (index) => SizedBox(
                    height: _itemHeight,
                    child: _RankTile(rank: index + 1, item: items[index]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RankTile extends StatelessWidget {
  const _RankTile({required this.rank, required this.item});

  final int rank;
  final RankModel item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: () => AppNavigator.startComicDetail(context, item.url),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '$rank',
                style: TextStyle(
                  color: rank <= 3 ? colorScheme.primary : colorScheme.outline,
                  fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Expanded(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (item.chapter.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                item.chapter,
                style: TextStyle(color: colorScheme.primary, fontSize: 12),
              ),
            ],
            if (item.date.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                item.date,
                style: TextStyle(color: colorScheme.outline, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
