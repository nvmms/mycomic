import 'package:flutter/material.dart';

class ComicFilterGroup {
  const ComicFilterGroup(this.title, this.queryKey, this.options);

  final String title;
  final String queryKey;
  final List<ComicFilterOption> options;
}

class ComicFilterOption {
  const ComicFilterOption(this.label, this.value);

  final String label;
  final String? value;
}

class ComicFilterPanel extends StatelessWidget {
  const ComicFilterPanel({
    super.key,
    required this.groups,
    required this.selectedValues,
    required this.onSelected,
  });

  final List<ComicFilterGroup> groups;
  final Map<String, String?> selectedValues;
  final void Function(ComicFilterGroup group, String? value) onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      elevation: 1,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 0, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final group in groups)
                SizedBox(
                  height: 46,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 68,
                        child: Text(
                          group.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(right: 12),
                          itemCount: group.options.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final option = group.options[index];
                            return ChoiceChip(
                              label: Text(option.label),
                              selected:
                                  selectedValues[group.queryKey] ==
                                  option.value,
                              showCheckmark: false,
                              visualDensity: VisualDensity.compact,
                              onSelected: (_) =>
                                  onSelected(group, option.value),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

const allComicFilterOption = ComicFilterOption('所有', null);

const comicAttributeFilterGroups = <ComicFilterGroup>[
  ComicFilterGroup('地区', 'filter[country]', [
    allComicFilterOption,
    ComicFilterOption('日本', 'japan'),
    ComicFilterOption('港台', 'hongkong'),
    ComicFilterOption('欧美', 'europe'),
    ComicFilterOption('内地', 'china'),
    ComicFilterOption('韩国', 'korea'),
    ComicFilterOption('其他', 'other'),
  ]),
  ComicFilterGroup('类型', 'filter[tag]', [
    allComicFilterOption,
    ComicFilterOption('魔幻', 'mohuan'),
    ComicFilterOption('魔法', 'mofa'),
    ComicFilterOption('热血', 'rexue'),
    ComicFilterOption('冒险', 'maoxian'),
    ComicFilterOption('悬疑', 'xuanyi'),
    ComicFilterOption('侦探', 'zhentan'),
    ComicFilterOption('爱情', 'aiqing'),
    ComicFilterOption('校园', 'xiaoyuan'),
    ComicFilterOption('搞笑', 'gaoxiao'),
    ComicFilterOption('四格', 'sige'),
    ComicFilterOption('科幻', 'kehuan'),
    ComicFilterOption('神鬼', 'shengui'),
    ComicFilterOption('舞蹈', 'wudao'),
    ComicFilterOption('音乐', 'yinyue'),
    ComicFilterOption('百合', 'baihe'),
    ComicFilterOption('后宫', 'hougong'),
    ComicFilterOption('机战', 'jizhan'),
    ComicFilterOption('格斗', 'gedou'),
    ComicFilterOption('恐怖', 'kongbu'),
    ComicFilterOption('萌系', 'mengxi'),
    ComicFilterOption('武侠', 'wuxia'),
    ComicFilterOption('社会', 'shehui'),
    ComicFilterOption('历史', 'lishi'),
    ComicFilterOption('耽美', 'danmei'),
    ComicFilterOption('励志', 'lizhi'),
    ComicFilterOption('职场', 'zhichang'),
    ComicFilterOption('生活', 'shenghuo'),
    ComicFilterOption('治愈', 'zhiyu'),
    ComicFilterOption('伪娘', 'weiniang'),
    ComicFilterOption('黑道', 'heidao'),
    ComicFilterOption('战争', 'zhanzheng'),
    ComicFilterOption('竞技', 'jingji'),
    ComicFilterOption('体育', 'tiyu'),
    ComicFilterOption('美食', 'meishi'),
    ComicFilterOption('腐女', 'funv'),
    ComicFilterOption('宅男', 'zhainan'),
    ComicFilterOption('推理', 'tuili'),
    ComicFilterOption('杂志', 'zazhi'),
  ]),
  ComicFilterGroup('受众', 'filter[audience]', [
    allComicFilterOption,
    ComicFilterOption('少女', 'shaonv'),
    ComicFilterOption('少年', 'shaonian'),
    ComicFilterOption('青年', 'qingnian'),
    ComicFilterOption('儿童', 'ertong'),
    ComicFilterOption('通用', 'tongyong'),
  ]),
  ComicFilterGroup('年份', 'filter[year]', [
    allComicFilterOption,
    ComicFilterOption('2026', '2026'),
    ComicFilterOption('2025', '2025'),
    ComicFilterOption('2024', '2024'),
    ComicFilterOption('2023', '2023'),
    ComicFilterOption('2022', '2022'),
    ComicFilterOption('2021', '2021'),
    ComicFilterOption('2020', '2020'),
    ComicFilterOption('2019', '2019'),
    ComicFilterOption('2018', '2018'),
    ComicFilterOption('2017', '2017'),
    ComicFilterOption('2016', '2016'),
    ComicFilterOption('2015', '2015'),
    ComicFilterOption('2014', '2014'),
    ComicFilterOption('2013', '2013'),
    ComicFilterOption('2012', '2012'),
    ComicFilterOption('2011', '2011'),
    ComicFilterOption('2010', '2010'),
    ComicFilterOption('00年代', '200x'),
    ComicFilterOption('90年代', '199x'),
    ComicFilterOption('80年代', '198x'),
    ComicFilterOption('70年代或更早', '197x'),
  ]),
  ComicFilterGroup('进度', 'filter[end]', [
    allComicFilterOption,
    ComicFilterOption('连载中', '0'),
    ComicFilterOption('已完结', '1'),
  ]),
];

const databaseFilterGroups = <ComicFilterGroup>[
  ComicFilterGroup('排序', 'sort', [
    ComicFilterOption('最新上架', null),
    ComicFilterOption('最近更新', '-update'),
    ComicFilterOption('最高人气', '-views'),
  ]),
  ...comicAttributeFilterGroups,
];

const rankingFilterGroups = <ComicFilterGroup>[
  ComicFilterGroup('排序', 'sort', [
    ComicFilterOption('日排行', null),
    ComicFilterOption('周排行', '-week'),
    ComicFilterOption('月排行', '-month'),
    ComicFilterOption('历史排行', '-views'),
  ]),
  ...comicAttributeFilterGroups,
];
