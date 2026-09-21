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
  final PageController controller = PageController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => currentIndex = index),
        children: const [HomeTabView(), DatabaseTabView(), RankingTabView()],
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
