import 'package:flutter/material.dart';
import 'package:mycomic/domain/home_model.dart';
import 'package:mycomic/service/api.dart';
import 'package:mycomic/service/data_cache.dart';
import 'package:mycomic/widget/comic_grid.dart';
import 'package:mycomic/widget/home_group_title.dart';
import 'package:mycomic/widget/rank_page_view.dart';

class HomeTabView extends StatefulWidget {
  const HomeTabView({super.key});

  @override
  State<HomeTabView> createState() => _HomeTabViewState();
}

class _HomeTabViewState extends State<HomeTabView> {
  HomeModel? homeModel;
  Object? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await DataCache.read('home');
      if (!mounted) return;
      if (cached != null) {
        setState(() => homeModel = HomeModel.fromMap(cached));
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final value = await Api.homeData();
      if (!mounted) return;
      setState(() {
        homeModel = value;
        _isLoading = false;
      });
      await DataCache.write('home', value.toMap());
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) {
          if (homeModel == null) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return Center(
              child: TextButton(
                onPressed: () => _load(forceRefresh: true),
                child: Text(_error == null ? '暂无数据' : '加载失败，点击重试'),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => _load(forceRefresh: true),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (_isLoading)
                  const SliverToBoxAdapter(child: LinearProgressIndicator()),
                ComicGrid(homeModel!.popular),
                HomeGroupTitle(title: "为您推荐"),
                ComicGrid(homeModel!.recommended),
                SliverToBoxAdapter(child: RankPageView(homeModel!)),
                HomeGroupTitle(title: "最近更新"),
                ComicGrid(homeModel!.recentUpdates),
                HomeGroupTitle(title: "最新上架"),
                ComicGrid(homeModel!.latestReleases),
              ],
            ),
          );
        },
      ),
    );
  }
}
