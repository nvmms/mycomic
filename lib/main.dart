import 'package:flutter/material.dart';
import 'package:mycomic/domain/home_model.dart';
import 'package:mycomic/service/home.dart';
import 'package:mycomic/widget/comic_grid.dart';
import 'package:mycomic/widget/home_group_title.dart';
import 'package:mycomic/widget/rank_page_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  HomeModel? homeModel;
  @override
  void initState() {
    super.initState();
    Home.list().then((value) {
      if (!mounted) return;
      setState(() => homeModel = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () {}, icon: Icon(Icons.menu)),
        title: Text("MYCOMIC"),
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.search))],
      ),
      body: Builder(
        builder: (context) {
          if (homeModel == null) {
            return Center(child: Text("加载中..."));
          }
          return CustomScrollView(
            slivers: [
              ComicGrid(homeModel!.popular),
              // SliverToBoxAdapter(child: Text("为您推荐")),
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
