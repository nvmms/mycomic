import 'package:flutter/material.dart';

class HomeGroupTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const HomeGroupTitle({super.key, required this.title, this.onTap});
  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 10),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            TextButton(onPressed: onTap, child: Text("查看更多")),
          ],
        ),
      ),
    );
  }
}
