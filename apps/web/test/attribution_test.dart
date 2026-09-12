import 'package:emotely_web/attribution.dart';
import 'package:test/test.dart';

void main() {
  group('sourceFrom', () {
    test('utm_source, medium and campaign become one slash-separated tag', () {
      expect(
        sourceFrom(
          query: '?utm_source=linkedin&utm_medium=post&utm_campaign=launch',
          referrer: '',
        ),
        'linkedin/post/launch',
      );
    });

    test('a bare utm_source stands alone', () {
      expect(sourceFrom(query: '?utm_source=blog', referrer: ''), 'blog');
    });

    test('without UTM the referrer host is the source', () {
      expect(
        sourceFrom(query: '', referrer: 'https://news.ycombinator.com/item'),
        'news.ycombinator.com',
      );
    });

    test('without UTM or referrer it is a plain landing', () {
      expect(sourceFrom(query: '', referrer: ''), 'landing');
    });

    test('the tag is lowercased, trimmed and never longer than the column', () {
      final long = 'a' * 100;
      final tag = sourceFrom(query: '?utm_source= $long ', referrer: '');
      expect(tag, hasLength(64));
      expect(
        sourceFrom(query: '?utm_source=LinkedIn', referrer: ''),
        'linkedin',
      );
    });

    test('junk in the parameters cannot smuggle anything odd into the tag', () {
      expect(
        sourceFrom(query: '?utm_source=<script>&utm_medium=a b', referrer: ''),
        'script/a-b',
      );
    });
  });
}
