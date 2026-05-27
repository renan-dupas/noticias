import 'package:flutter_test/flutter_test.dart';

import 'package:leitornoticias_temp/main.dart';

class _FakeRepository implements NewsRepository {
  NewsLanguage? lastLanguage;

  @override
  List<NewsFeedSource> availableSources(NewsLanguage language) {
    return const <NewsFeedSource>[
      NewsFeedSource(name: 'Fonte Teste', url: 'https://example.com/feed.xml'),
    ];
  }

  @override
  Future<List<NewsArticle>> fetchTopStories({
    required NewsLanguage language,
    List<NewsFeedSource>? selectedSources,
    bool forceRefresh = false,
  }) async {
    lastLanguage = language;
    return <NewsArticle>[
      NewsArticle(
        title: 'Noticia de teste',
        url: 'https://example.com/noticia',
        source: 'Fonte Teste',
        createdAt: DateTime(2026, 1, 1),
      ),
    ];
  }
}

void main() {
  testWidgets('Renderiza lista de noticias com dados carregados',
      (WidgetTester tester) async {
    final fakeRepository = _FakeRepository();

    await tester.pumpWidget(
      NewsReaderApp(repository: fakeRepository),
    );

    await tester.pumpAndSettle();

    expect(find.text('Leitor de Noticias'), findsOneWidget);
    expect(find.text('Noticia de teste'), findsOneWidget);
    expect(find.textContaining('Fonte Teste'), findsOneWidget);
    expect(fakeRepository.lastLanguage, NewsLanguage.ptBr);
  });
}
