import 'package:flutter/material.dart';
import 'package:mycomic/core/app_navigator.dart';
import 'package:mycomic/domain/comic_model.dart';
import 'package:mycomic/page/comic_detail_page.dart';
import 'package:mycomic/widget/my_comic_image.dart';

class ComicGrid extends StatelessWidget {
  final List<ComicModel> items;
  const ComicGrid(this.items, {super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsetsGeometry.all(10),
      sliver: SliverGrid.builder(
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          mainAxisExtent: 171,
        ),
        itemBuilder: (context, index) => GestureDetector(
          onTap: () {
            debugPrint(items[index].url);
            AppNavigator.startCoimcDetail(items[index].url);
          },
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 3 / 4,
                child: MyComicImage(url: items[index].cover, radius: 6),
              ),
              SizedBox(height: 7),
              Text(
                items[index].title,
                style: TextStyle(overflow: TextOverflow.ellipsis, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
