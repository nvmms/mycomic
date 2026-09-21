import 'package:flutter/material.dart';
import 'package:mycomic/page/tab/database_tab_view.dart';
import 'package:mycomic/page/tab/home_tab_view.dart';
import 'package:mycomic/page/tab/ranking_tab_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;
  bool _filtersVisible = false;
  final PageController controller = PageController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text.rich(
          TextSpan(
            style: TextStyle(fontSize: 20),
            children: [
              TextSpan(text: "MY"),
              TextSpan(
                text: "COMIC",
                style: TextStyle(color: Color(0xffdc2626)),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.search)),
          IconButton(
            tooltip: _filtersVisible ? '收起筛选' : '展开筛选',
            onPressed: () => setState(() => _filtersVisible = !_filtersVisible),
            icon: Icon(
              _filtersVisible ? Icons.filter_alt_off : Icons.filter_alt,
            ),
          ),
        ],
      ),
      body: PageView(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => currentIndex = index),
        children: [
          HomeTabView(),
          DatabaseTabView(filtersVisible: currentIndex == 1 && _filtersVisible),
          RankingTabView(filtersVisible: currentIndex == 2 && _filtersVisible),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                '观看历史',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('我的收藏'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('设置'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "首页"),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: "资料库",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: "排行榜"),
        ],
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == currentIndex) return;
          controller.animateToPage(
            index,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          );
        },
      ),
    );
  }
}
