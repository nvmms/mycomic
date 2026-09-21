import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

class MyComicImage extends StatelessWidget {
  final String url;
  final double? radius;
  final BorderRadiusGeometry? borderRadius;
  const MyComicImage({
    super.key,
    required this.url,
    this.radius = 0,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius != null
          ? borderRadius!
          : radius != null
          ? BorderRadius.circular(radius!)
          : BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: url,
        httpHeaders: {
          "dnt": "1",
          "referer": "https://mycomic.com/",
          "sec-ch-ua":
              "\"Microsoft Edge\";v=\"153\", \"Not_A Brand\";v=\"8\", \"Chromium\";v=\"153\"",
          "sec-ch-ua-mobile": "?1",
          "sec-ch-ua-platform": "\"iOS\"",
          "user-agent":
              "Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Mobile/15E148 Safari/604.1",
        },
      ),
    );
  }
}
