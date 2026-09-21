import 'package:flutter/material.dart';
import 'package:mycomic/domain/home_model.dart';
import 'package:mycomic/service/api.dart';
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
  @override
  void initState() {
    super.initState();
    Api.homeData().then((value) {
      if (!mounted) return;
      setState(() => homeModel = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) {
          if (homeModel == null) {
            return Center(child: Text("加载中..."));
          }
          return CustomScrollView(
            slivers: [
              ComicGrid(homeModel!.popular),
              HomeGroupTitle(title: "为您推荐"),
              ComicGrid(homeModel!.recommended),
              SliverToBoxAdapter(child: RankPageView(homeModel!)),
              HomeGroupTitle(title: "最近更新"),
              ComicGrid(homeModel!.recentUpdates),
              HomeGroupTitle(title: "最新上架"),
              ComicGrid(homeModel!.latestReleases),
            ],
          );
        },
      ),
    );
  }
}
