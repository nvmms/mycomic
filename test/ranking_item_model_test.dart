import 'package:flutter_test/flutter_test.dart';
import 'package:mycomic/domain/ranking_item_model.dart';

void main() {
  test('parses ranking table rows including duplicated mobile chapter cell', () {
    const html = '''
      <table><tbody><tr>
        <td>1</td>
        <td><a href="https://mycomic.com/cn/comics/42">测试漫画</a></td>
        <td><a>作者甲</a>, <a>作者乙</a></td>
        <td><a href="https://mycomic.com/cn/chapters/7">第7话</a></td>
        <td><a href="https://mycomic.com/cn/chapters/7">第7话</a></td>
        <td>2026-09-21</td>
        <td>4.50</td>
      </tr></tbody></table>
    ''';

    final item = RankingItemModel.listFromHtml(html).single;
    expect(item.rank, 1);
    expect(item.title, '测试漫画');
    expect(item.authors, '作者甲, 作者乙');
    expect(item.chapter, '第7话');
    expect(item.updatedAt, '2026-09-21');
    expect(item.score, '4.50');
  });
}
