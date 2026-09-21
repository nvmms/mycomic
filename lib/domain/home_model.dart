import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:mycomic/domain/comic_model.dart';
import 'package:mycomic/domain/rank_model.dart';

class HomeModel {
  final List<ComicModel> popular;
  final List<ComicModel> recommended;
  final List<RankModel> recentRanking;
  final List<RankModel> dailyRanking;
  final List<RankModel> weeklyRanking;
  final List<RankModel> historicalRanking;
  final List<ComicModel> recentUpdates;
  final List<ComicModel> latestReleases;

  const HomeModel({
    required this.popular,
    required this.recommended,
    required this.recentRanking,
    required this.dailyRanking,
    required this.weeklyRanking,
    required this.historicalRanking,
    required this.recentUpdates,
    required this.latestReleases,
  });

  factory HomeModel.fromHtml(String html) {
    final document = html_parser.parseFragment(html);
    final container = document.querySelector('div.space-y-12');

    if (container == null) {
      throw const FormatException('无法从 HTML 中找到首页模块');
    }

    final modules = container.children;
    if (modules.length < 5) {
      throw FormatException('首页模块数量不足：${modules.length}');
    }

    final rankingCells = modules[2].querySelectorAll(
      'tbody tr td[data-flux-cell]',
    );
    if (rankingCells.length < 4) {
      throw FormatException('排行榜列数量不足：${rankingCells.length}');
    }

    return HomeModel(
      popular: ComicModel.listFromElement(modules[0]),
      recommended: ComicModel.listFromElement(modules[1]),
      recentRanking: RankModel.listFromCell(rankingCells[0]),
      dailyRanking: RankModel.listFromCell(rankingCells[1]),
      weeklyRanking: RankModel.listFromCell(rankingCells[2]),
      historicalRanking: RankModel.listFromCell(rankingCells[3]),
      recentUpdates: ComicModel.listFromElement(modules[3]),
      latestReleases: ComicModel.listFromElement(modules[4]),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'popular': popular.map((comic) => comic.toMap()).toList(),
      'recommended': recommended.map((comic) => comic.toMap()).toList(),
      'recentRanking': recentRanking.map((rank) => rank.toMap()).toList(),
      'dailyRanking': dailyRanking.map((rank) => rank.toMap()).toList(),
      'weeklyRanking': weeklyRanking.map((rank) => rank.toMap()).toList(),
      'historicalRanking': historicalRanking
          .map((rank) => rank.toMap())
          .toList(),
      'recentUpdates': recentUpdates.map((comic) => comic.toMap()).toList(),
      'latestReleases': latestReleases.map((comic) => comic.toMap()).toList(),
    };
  }

  @override
  String toString() => jsonEncode(toMap());
}
