import 'package:flutter/material.dart';
import 'package:mycomic/core/app_navigator.dart';
import 'package:mycomic/domain/comic_model.dart';
import 'package:mycomic/widget/my_comic_image.dart';

class ComicGrid extends StatelessWidget {
  final List<ComicModel> items;
  const ComicGrid(this.items, {super.key});

  @override
  Widget build(BuildContext context) {
    const crossAxisCount = 3;
    const spacing = 10.0;
    const padding = 10.0;
    const imageAspectRatio = 3 / 4;
    const titleSpacing = 7.0;
    const titleStyle = TextStyle(fontSize: 14);

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.crossAxisExtent -
            padding * 2 -
            spacing * (crossAxisCount - 1);
        final itemWidth = availableWidth / crossAxisCount;
        final imageHeight = itemWidth / imageAspectRatio;
        final titlePainter = TextPainter(
          text: const TextSpan(text: '示例', style: titleStyle),
          textScaler: MediaQuery.textScalerOf(context),
          textDirection: Directionality.of(context),
          maxLines: 1,
        )..layout(maxWidth: itemWidth);
        final itemHeight = imageHeight + titleSpacing + titlePainter.height;

        return SliverPadding(
          padding: const EdgeInsets.all(padding),
          sliver: SliverGrid.builder(
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              mainAxisExtent: itemHeight,
            ),
            itemBuilder: (context, index) => GestureDetector(
              onTap: () {
                debugPrint(items[index].url);
                AppNavigator.startComicDetail(context, items[index].url);
              },
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: imageAspectRatio,
                    child: MyComicImage(url: items[index].cover, radius: 6),
                  ),
                  const SizedBox(height: titleSpacing),
                  Text(
                    items[index].title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
