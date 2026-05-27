import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:xml/xml.dart';

void main() {
  runApp(const NewsReaderApp());
}

class NewsReaderApp extends StatelessWidget {
  const NewsReaderApp({super.key, NewsRepository? repository})
      : repository = repository ?? const MultiSourceNewsRepository();

  final NewsRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Noticias',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF005A9C)),
      ),
      home: NewsHomePage(repository: repository),
    );
  }
}

@immutable
class NewsArticle {
  const NewsArticle({
    required this.title,
    required this.url,
    required this.source,
    required this.createdAt,
    this.sourceUrl,
    this.summary,
    this.imageUrl,
  });

  final String title;
  final String url;
  final String source;
  final DateTime createdAt;
  final String? sourceUrl;
  final String? summary;
  final String? imageUrl;

  String get domain {
    final uri = Uri.tryParse(sourceUrl ?? url);
    return uri?.host.replaceFirst('www.', '') ?? 'desconhecido';
  }
}

enum NewsLanguage {
  ptBr(
    label: 'Portugues (Brasil)',
    flag: '🇧🇷',
  ),
  enUs(
    label: 'English (United States)',
    flag: '🇺🇸',
  ),
  esEs(
    label: 'Espanol (Espana)',
    flag: '🇪🇸',
  ),
  frFr(
    label: 'Francais (France)',
    flag: '🇫🇷',
  );

  const NewsLanguage({required this.label, required this.flag});

  final String label;
  final String flag;
}

enum NewsSortOption {
  newestFirst(label: 'Mais recentes'),
  oldestFirst(label: 'Mais antigas'),
  sourceAz(label: 'Fonte (A-Z)');

  const NewsSortOption({required this.label});

  final String label;
}

enum NewsTopic {
  all(label: 'Tudo', keywords: <String>[]),
  ai(
    label: 'IA',
    keywords: <String>[
      'ia',
      'inteligencia artificial',
      'artificial intelligence',
      'ai',
      'openai',
      'chatgpt',
      'llm',
      'generative ai',
      'modelo de linguagem',
      'machine learning',
    ],
  ),
  technology(
    label: 'Tecnologia',
    keywords: <String>[
      'tecnologia', 'tech', 'ia', 'ai', 'startup', 'software', 'apple', 'google',
      'microsoft', 'openai', 'chip', 'semicondutor', 'robot', 'gadget'
    ],
  ),
  business(
    label: 'Economia',
    keywords: <String>['economia', 'mercado', 'bolsa', 'dolar', 'juros', 'inflacao'],
  ),
  politics(
    label: 'Politica',
    keywords: <String>['politica', 'governo', 'congresso', 'senado', 'camara', 'eleicao'],
  ),
  world(
    label: 'Mundo',
    keywords: <String>['mundo', 'internacional', 'guerra', 'onu', 'diplomacia'],
  ),
  sports(
    label: 'Esportes',
    keywords: <String>[
      'esporte',
      'futebol',
      'nba',
      'nfl',
      'formula 1',
      'olimpiada',
      'tenis',
      'ufc'
    ],
  );

  const NewsTopic({required this.label, required this.keywords});

  final String label;
  final List<String> keywords;
}

class NewsFeedSource {
  const NewsFeedSource({
    required this.name,
    required this.url,
  });

  final String name;
  final String url;
}

abstract class NewsRepository {
  List<NewsFeedSource> availableSources(NewsLanguage language);

  Future<List<NewsArticle>> fetchTopStories({
    required NewsLanguage language,
    List<NewsFeedSource>? selectedSources,
    bool forceRefresh = false,
  });
}

class MultiSourceNewsRepository implements NewsRepository {
  const MultiSourceNewsRepository();

  static final http.Client _client = http.Client();
  static const Duration _cacheTtl = Duration(minutes: 2);
  static const Map<String, String> _requestHeaders = <String, String>{
    'User-Agent':
        'Mozilla/5.0 (compatible; NoticiasApp/1.0; +https://example.local)',
    'Accept': 'application/rss+xml, application/atom+xml, application/xml, text/xml, */*',
  };

  static final Map<NewsLanguage, List<NewsFeedSource>> _sourcesByLanguage =
      <NewsLanguage, List<NewsFeedSource>>{
    NewsLanguage.ptBr: <NewsFeedSource>[
      NewsFeedSource(name: 'G1', url: 'https://g1.globo.com/rss/g1/'),
      NewsFeedSource(
        name: 'UOL Noticias',
        url: 'https://rss.uol.com.br/feed/noticias.xml',
      ),
      NewsFeedSource(
        name: 'Folha',
        url: 'https://feeds.folha.uol.com.br/emcimadahora/rss091.xml',
      ),
      NewsFeedSource(
        name: 'Agencia Brasil',
        url: 'https://agenciabrasil.ebc.com.br/rss/geral/feed.xml',
      ),
      NewsFeedSource(
        name: 'CNN Brasil',
        url: 'https://www.cnnbrasil.com.br/feed/',
      ),
      NewsFeedSource(name: 'Canaltech', url: 'https://feeds.feedburner.com/canaltechbr'),
      NewsFeedSource(name: 'Olhar Digital', url: 'https://olhardigital.com.br/feed/'),
      NewsFeedSource(name: 'TecMundo', url: 'https://www.tecmundo.com.br/rss'),
      NewsFeedSource(name: 'Adrenaline', url: 'https://www.adrenaline.com.br/feed/'),
      NewsFeedSource(name: 'InfoMoney', url: 'https://www.infomoney.com.br/feed/'),
      NewsFeedSource(name: 'Exame', url: 'https://exame.com/feed/'),
    ],
    NewsLanguage.enUs: <NewsFeedSource>[
      NewsFeedSource(name: 'BBC', url: 'https://feeds.bbci.co.uk/news/rss.xml'),
      NewsFeedSource(name: 'NPR', url: 'https://feeds.npr.org/1001/rss.xml'),
      NewsFeedSource(
        name: 'The Guardian',
        url: 'https://www.theguardian.com/world/rss',
      ),
      NewsFeedSource(
        name: 'NYTimes World',
        url: 'https://rss.nytimes.com/services/xml/rss/nyt/World.xml',
      ),
      NewsFeedSource(
        name: 'Al Jazeera',
        url: 'https://www.aljazeera.com/xml/rss/all.xml',
      ),
      NewsFeedSource(name: 'TechCrunch', url: 'https://techcrunch.com/feed/'),
      NewsFeedSource(name: 'The Verge', url: 'https://www.theverge.com/rss/index.xml'),
      NewsFeedSource(name: 'Wired', url: 'https://www.wired.com/feed/rss'),
      NewsFeedSource(name: 'Ars Technica', url: 'https://feeds.arstechnica.com/arstechnica/index'),
      NewsFeedSource(name: 'Engadget', url: 'https://www.engadget.com/rss.xml'),
      NewsFeedSource(name: 'CNET', url: 'https://www.cnet.com/rss/news/'),
      NewsFeedSource(name: 'Reuters World', url: 'https://feeds.reuters.com/Reuters/worldNews'),
    ],
    NewsLanguage.esEs: <NewsFeedSource>[
      NewsFeedSource(
        name: 'El Pais',
        url: 'https://feeds.elpais.com/mrss-s/pages/ep/site/elpais.com/portada',
      ),
      NewsFeedSource(
        name: 'El Mundo',
        url: 'https://e00-elmundo.uecdn.es/elmundo/rss/portada.xml',
      ),
      NewsFeedSource(
        name: 'BBC Mundo',
        url: 'https://feeds.bbci.co.uk/mundo/rss.xml',
      ),
      NewsFeedSource(
        name: '20 Minutos',
        url: 'https://www.20minutos.es/rss/',
      ),
      NewsFeedSource(
        name: 'CNN Espanol',
        url: 'https://cnnespanol.cnn.com/feed/',
      ),
      NewsFeedSource(name: 'Xataka', url: 'https://www.xataka.com/feedburner.xml'),
      NewsFeedSource(name: 'Genbeta', url: 'https://www.genbeta.com/feedburner.xml'),
      NewsFeedSource(name: 'Hipertextual', url: 'https://hipertextual.com/feed'),
    ],
    NewsLanguage.frFr: <NewsFeedSource>[
      NewsFeedSource(name: 'Le Monde', url: 'https://www.lemonde.fr/rss/une.xml'),
      NewsFeedSource(name: 'France 24', url: 'https://www.france24.com/fr/rss'),
      NewsFeedSource(
        name: 'Le Figaro',
        url: 'https://www.lefigaro.fr/rss/figaro_actualites.xml',
      ),
      NewsFeedSource(
        name: 'Le Parisien',
        url: 'https://feeds.leparisien.fr/leparisien/rss',
      ),
      NewsFeedSource(
        name: 'Liberation',
        url: 'https://www.liberation.fr/arc/outboundfeeds/rss-all/',
      ),
      NewsFeedSource(name: 'Numerama', url: 'https://www.numerama.com/feed/'),
      NewsFeedSource(name: 'Les Numeriques', url: 'https://www.lesnumeriques.com/rss.xml'),
      NewsFeedSource(name: '01net', url: 'https://www.01net.com/rss/actualites/'),
    ],
  };

  static final Map<String, _CachedNews> _cache = <String, _CachedNews>{};

  @override
  List<NewsFeedSource> availableSources(NewsLanguage language) {
    return List<NewsFeedSource>.unmodifiable(
      _sourcesByLanguage[language] ?? const <NewsFeedSource>[],
    );
  }

  @override
  Future<List<NewsArticle>> fetchTopStories({
    required NewsLanguage language,
    List<NewsFeedSource>? selectedSources,
    bool forceRefresh = false,
  }) async {
    final defaultSources = _sourcesByLanguage[language] ?? const <NewsFeedSource>[];
    final effectiveSources =
        (selectedSources == null || selectedSources.isEmpty) ? defaultSources : selectedSources;

    if (effectiveSources.isEmpty) {
      throw const NewsFetchException('Nenhuma fonte configurada para este idioma.');
    }

    final cacheKey = _cacheKey(language, effectiveSources);
    final now = DateTime.now();
    final cached = _cache[cacheKey];
    final hasValidCache =
        cached != null && now.difference(cached.timestamp) < _cacheTtl;

    if (!forceRefresh && hasValidCache) {
      return cached.articles;
    }

    final List<List<NewsArticle>> collected = await Future.wait(
      effectiveSources.map(_fetchSourceSafely),
    );

    if (kDebugMode) {
      for (var i = 0; i < effectiveSources.length; i++) {
        debugPrint(
          'Fonte ${effectiveSources[i].name}: ${collected[i].length} itens parseados',
        );
      }
    }

    final merged = _mergeAndSort(collected.expand((List<NewsArticle> part) => part));

    if (kDebugMode) {
      debugPrint('Total consolidado para ${language.name}: ${merged.length} itens');
    }

    if (merged.isEmpty) {
      final diagnostics = List<String>.generate(
        effectiveSources.length,
        (int i) => '${effectiveSources[i].name}: ${collected[i].length}',
      ).join(' | ');
      throw NewsFetchException(
        'Nao foi possivel carregar noticias das fontes deste idioma. '
        'Diagnostico: $diagnostics',
      );
    }

    _cache[cacheKey] = _CachedNews(articles: merged, timestamp: now);
    return merged;
  }

  String _cacheKey(NewsLanguage language, List<NewsFeedSource> sources) {
    final orderedUrls = sources
        .map((NewsFeedSource source) => source.url)
        .toList(growable: false)
      ..sort();
    return '${language.name}|${orderedUrls.join(',')}';
  }

  Future<List<NewsArticle>> _fetchSourceSafely(NewsFeedSource source) async {
    try {
      final requestUri = kIsWeb
          ? Uri.parse(
              'https://api.allorigins.win/raw?url=${Uri.encodeComponent(source.url)}',
            )
          : Uri.parse(source.url);
      final requestHeaders = kIsWeb ? const <String, String>{} : _requestHeaders;
      final response = await _client.get(
            requestUri,
            headers: requestHeaders,
          ).timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw const NewsFetchException('Tempo esgotado.'),
          );

      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint(
            'Feed ${source.name} retornou status ${response.statusCode}: ${source.url}',
          );
        }
        return const <NewsArticle>[];
      }

      return _parseFeedPayload(
        <String, String>{
          'xml': response.body,
          'sourceName': source.name,
          'sourceUrl': source.url,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Falha ao carregar ${source.name} (${source.url}): $e');
      }
      return const <NewsArticle>[];
    }
  }

  List<NewsArticle> _mergeAndSort(Iterable<NewsArticle> input) {
    final Set<String> seen = <String>{};
    final List<NewsArticle> merged = <NewsArticle>[];

    for (final article in input) {
      final key = _normalizeUrl(article.url);
      if (key.isEmpty || !seen.add(key)) {
        continue;
      }
      merged.add(article);
    }

    merged.sort((NewsArticle a, NewsArticle b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }

  String _normalizeUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return '';
    final cleaned = uri.replace(fragment: '');
    return cleaned.toString();
  }
}

class _CachedNews {
  const _CachedNews({required this.articles, required this.timestamp});

  final List<NewsArticle> articles;
  final DateTime timestamp;
}

List<NewsArticle> _parseFeedPayload(Map<String, String> payload) {
  final rawXml = payload['xml'] ?? '';
  final sourceName = payload['sourceName'] ?? 'Fonte desconhecida';
  final sourceUrl = payload['sourceUrl'];

  if (rawXml.isEmpty) {
    return const <NewsArticle>[];
  }

  try {
    final XmlDocument xml = XmlDocument.parse(rawXml);

    final List<NewsArticle> fromItems = xml
        .findAllElements('item')
        .map((XmlElement item) => _parseRssItem(item, sourceName, sourceUrl))
        .whereType<NewsArticle>()
        .toList(growable: false);

    if (fromItems.isNotEmpty) {
      return fromItems;
    }

    return xml
        .findAllElements('entry')
        .map((XmlElement entry) => _parseAtomEntry(entry, sourceName, sourceUrl))
        .whereType<NewsArticle>()
        .toList(growable: false);
  } catch (_) {
    return const <NewsArticle>[];
  }
}

NewsArticle? _parseRssItem(
  XmlElement item,
  String defaultSource,
  String? defaultSourceUrl,
) {
  final title = item.getElement('title')?.innerText.trim() ?? '';
  final url = (item.getElement('link')?.innerText.trim().isNotEmpty ?? false)
      ? item.getElement('link')!.innerText.trim()
      : item.getElement('guid')?.innerText.trim() ?? '';
  final summaryRaw = _elementTextByLocalNames(
    item,
    <String>{'description', 'encoded', 'summary', 'content'},
  );
  final imageUrl = _imageUrlFromFeedItem(item) ?? _imageUrlFromHtml(summaryRaw);

  if (title.isEmpty || url.isEmpty) {
    return null;
  }

  final sourceNode = item.getElement('source');
  final source = (sourceNode?.innerText.trim().isNotEmpty ?? false)
      ? sourceNode!.innerText.trim()
      : defaultSource;
  final sourceUrl = sourceNode?.getAttribute('url') ?? defaultSourceUrl;

  final pubDate = item.getElement('pubDate')?.innerText.trim() ?? '';
  final createdAt = _parseFlexibleDate(pubDate);

  return NewsArticle(
    title: title,
    url: url,
    source: source,
    sourceUrl: sourceUrl,
    createdAt: createdAt,
    summary: _cleanFeedText(summaryRaw),
    imageUrl: imageUrl,
  );
}

NewsArticle? _parseAtomEntry(
  XmlElement entry,
  String defaultSource,
  String? defaultSourceUrl,
) {
  final title = entry.getElement('title')?.innerText.trim() ?? '';
  final linkNode = entry
      .findElements('link')
      .firstWhere(
        (XmlElement link) =>
            link.getAttribute('rel') == null || link.getAttribute('rel') == 'alternate',
        orElse: () => XmlElement(XmlName('link')),
      );
  final url = (linkNode.getAttribute('href') ?? linkNode.innerText).trim();
  final summaryRaw = _elementTextByLocalNames(
    entry,
    <String>{'summary', 'content', 'description'},
  );
  final imageUrl = _imageUrlFromFeedItem(entry) ?? _imageUrlFromHtml(summaryRaw);

  if (title.isEmpty || url.isEmpty) {
    return null;
  }

  final source = entry
          .findElements('source')
          .map((XmlElement source) => source.getElement('title')?.innerText.trim())
          .firstWhere((String? value) => (value ?? '').isNotEmpty, orElse: () => null) ??
      defaultSource;

  final createdAt = _parseFlexibleDate(
    entry.getElement('updated')?.innerText.trim() ??
        entry.getElement('published')?.innerText.trim() ??
        '',
  );

  return NewsArticle(
    title: title,
    url: url,
    source: source,
    sourceUrl: defaultSourceUrl,
    createdAt: createdAt,
    summary: _cleanFeedText(summaryRaw),
    imageUrl: imageUrl,
  );
}

String _elementTextByLocalNames(XmlElement root, Set<String> localNames) {
  for (final element in root.children.whereType<XmlElement>()) {
    if (localNames.contains(element.name.local.toLowerCase())) {
      final value = element.innerText.trim();
      if (value.isNotEmpty) return value;
    }
  }
  return '';
}

String? _imageUrlFromFeedItem(XmlElement root) {
  for (final element in root.children.whereType<XmlElement>()) {
    final local = element.name.local.toLowerCase();
    if (local == 'enclosure') {
      final type = (element.getAttribute('type') ?? '').toLowerCase();
      final url = (element.getAttribute('url') ?? '').trim();
      if (url.isNotEmpty && (type.isEmpty || type.startsWith('image/'))) return url;
    }

    if (local == 'content' || local == 'thumbnail') {
      final url =
          (element.getAttribute('url') ?? element.getAttribute('href') ?? '').trim();
      if (url.isNotEmpty) return url;
    }

    if (local == 'image') {
      final nested = element
          .children
          .whereType<XmlElement>()
          .firstWhere(
            (XmlElement child) => child.name.local.toLowerCase() == 'url',
            orElse: () => XmlElement(XmlName('url')),
          )
          .innerText
          .trim();
      if (nested.isNotEmpty) return nested;
    }
  }
  return null;
}

String _cleanFeedText(String input) {
  if (input.isEmpty) return '';

  final withoutTags = input.replaceAll(RegExp(r'<[^>]+>'), ' ');
  final decoded = withoutTags
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');

  return decoded.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String? _imageUrlFromHtml(String input) {
  if (input.isEmpty) return null;
  final match = RegExp(
    "<img[^>]+src=['\\\"]([^'\\\"]+)['\\\"]",
    caseSensitive: false,
  ).firstMatch(input);
  return match?.group(1)?.trim();
}

DateTime _parseFlexibleDate(String value) {
  if (value.isEmpty) return DateTime.now();

  final iso = DateTime.tryParse(value);
  if (iso != null) return iso.toLocal();

  try {
    return HttpDate.parse(value).toLocal();
  } catch (_) {
    return DateTime.now();
  }
}

class NewsFetchException implements Exception {
  const NewsFetchException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NewsController extends ChangeNotifier {
  NewsController({required NewsRepository repository}) : _repository = repository;

  final NewsRepository _repository;

  static const int _pageSize = 12;

  bool isLoading = false;
  bool isRefreshing = false;
  DateTime? lastUpdatedAt;
  String? error;
  NewsLanguage language = NewsLanguage.ptBr;
  NewsSortOption sortOption = NewsSortOption.newestFirst;
  NewsTopic topic = NewsTopic.all;

  final List<NewsArticle> _allArticles = <NewsArticle>[];
  final List<NewsArticle> _visibleArticles = <NewsArticle>[];
  final Map<NewsLanguage, Set<String>> _disabledSourceUrlsByLanguage =
      <NewsLanguage, Set<String>>{};

  UnmodifiableListView<NewsArticle> get visibleArticles =>
      UnmodifiableListView<NewsArticle>(_visibleArticles);

  bool get canLoadMore {
    final filtered = _processedArticles;
    return _visibleArticles.length < filtered.length;
  }

  List<NewsFeedSource> get currentSources => _repository.availableSources(language);
  int get enabledSourceCount =>
      currentSources.where((NewsFeedSource source) => isSourceEnabled(source)).length;
  List<NewsTopic> get availableTopics => NewsTopic.values;
  UnmodifiableListView<NewsArticle> get highlightArticles {
    final ranked = List<NewsArticle>.from(_filteredByTopic)
      ..sort(
        (NewsArticle a, NewsArticle b) =>
            _importanceScore(b).compareTo(_importanceScore(a)),
      );
    return UnmodifiableListView<NewsArticle>(ranked.take(5).toList(growable: false));
  }

  bool isSourceEnabled(NewsFeedSource source) {
    final disabled = _disabledSourceUrlsByLanguage[language] ?? const <String>{};
    return !disabled.contains(source.url);
  }

  Future<bool> setSourceEnabled(NewsFeedSource source, bool enabled) async {
    final allSources = _repository.availableSources(language);
    final disabled =
        _disabledSourceUrlsByLanguage.putIfAbsent(language, () => <String>{});

    final currentlyEnabledCount =
        allSources.where((NewsFeedSource item) => !disabled.contains(item.url)).length;

    if (!enabled && currentlyEnabledCount <= 1 && !disabled.contains(source.url)) {
      return false;
    }

    if (enabled) {
      disabled.remove(source.url);
    } else {
      disabled.add(source.url);
    }

    await loadInitial();
    return true;
  }

  Future<void> loadInitial() async {
    if (isLoading) return;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final fetched = await _repository.fetchTopStories(
        language: language,
        selectedSources: _enabledSourcesForLanguage(language),
      );
      _allArticles
        ..clear()
        ..addAll(fetched);
      lastUpdatedAt = DateTime.now();
      _resetVisible();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (isRefreshing) return;
    isRefreshing = true;
    error = null;
    notifyListeners();

    try {
      final fetched = await _repository.fetchTopStories(
        language: language,
        selectedSources: _enabledSourcesForLanguage(language),
        forceRefresh: true,
      );
      _allArticles
        ..clear()
        ..addAll(fetched);
      lastUpdatedAt = DateTime.now();
      _resetVisible();
    } catch (e) {
      error = e.toString();
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> setLanguage(NewsLanguage nextLanguage) async {
    if (nextLanguage == language) return;
    language = nextLanguage;
    await loadInitial();
  }

  void setSortOption(NewsSortOption nextOption) {
    if (sortOption == nextOption) return;
    sortOption = nextOption;
    _resetVisible();
    notifyListeners();
  }

  void setTopic(NewsTopic nextTopic) {
    if (topic == nextTopic) return;
    topic = nextTopic;
    _resetVisible();
    notifyListeners();
  }

  void loadMore() {
    if (!canLoadMore || isLoading || isRefreshing) return;
    final filtered = _processedArticles;
    final nextEnd = (_visibleArticles.length + _pageSize).clamp(0, filtered.length);
    _visibleArticles
      ..clear()
      ..addAll(filtered.take(nextEnd));
    notifyListeners();
  }

  List<NewsArticle> get _processedArticles {
    final filtered = List<NewsArticle>.from(_filteredByTopic);

    switch (sortOption) {
      case NewsSortOption.newestFirst:
        filtered.sort(
          (NewsArticle a, NewsArticle b) => b.createdAt.compareTo(a.createdAt),
        );
        break;
      case NewsSortOption.oldestFirst:
        filtered.sort(
          (NewsArticle a, NewsArticle b) => a.createdAt.compareTo(b.createdAt),
        );
        break;
      case NewsSortOption.sourceAz:
        filtered.sort((NewsArticle a, NewsArticle b) {
          final bySource = a.source.toLowerCase().compareTo(b.source.toLowerCase());
          if (bySource != 0) return bySource;
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
    }

    return filtered;
  }

  List<NewsArticle> get _filteredByTopic {
    if (topic == NewsTopic.all) {
      return List<NewsArticle>.from(_allArticles);
    }

    return _allArticles.where((NewsArticle article) {
      final text = '${article.title} ${article.summary ?? ''}'.toLowerCase();
      return topic.keywords.any((String keyword) => _matchesTopicKeyword(text, keyword));
    }).toList(growable: false);
  }

  bool _matchesTopicKeyword(String text, String keyword) {
    final cleanKeyword = keyword.trim().toLowerCase();
    if (cleanKeyword.isEmpty) return false;

    if (cleanKeyword.contains(' ')) {
      return text.contains(cleanKeyword);
    }

    if (cleanKeyword.length <= 3) {
      final escaped = RegExp.escape(cleanKeyword);
      final pattern = RegExp('(^|[^a-z0-9])$escaped([^a-z0-9]|\$)');
      return pattern.hasMatch(text);
    }

    return text.contains(cleanKeyword);
  }

  double _importanceScore(NewsArticle article) {
    final ageHours = DateTime.now().difference(article.createdAt).inMinutes / 60.0;
    final freshness = 120.0 - ageHours.clamp(0, 120);
    final text = '${article.title} ${article.summary ?? ''}'.toLowerCase();

    var keywordBoost = 0.0;
    const hotKeywords = <String>[
      'urgente', 'ao vivo', 'breaking', 'alerta', 'ultima hora', 'agora',
      'crise', 'guerra', 'eleicao', 'recorde', 'acidente', 'tecnologia', 'ia', 'ai'
    ];
    for (final keyword in hotKeywords) {
      if (text.contains(keyword)) {
        keywordBoost += 8;
      }
    }

    return freshness + keywordBoost;
  }

  void _resetVisible() {
    final filtered = _processedArticles;
    final end = filtered.length < _pageSize ? filtered.length : _pageSize;
    _visibleArticles
      ..clear()
      ..addAll(filtered.take(end));
  }

      List<NewsFeedSource> _enabledSourcesForLanguage(NewsLanguage selectedLanguage) {
      final allSources = _repository.availableSources(selectedLanguage);
      final disabled =
        _disabledSourceUrlsByLanguage[selectedLanguage] ?? const <String>{};
      return allSources
        .where((NewsFeedSource source) => !disabled.contains(source.url))
        .toList(growable: false);
      }

  @override
  void dispose() {
    super.dispose();
  }
}

class NewsHomePage extends StatefulWidget {
  const NewsHomePage({super.key, required this.repository});

  final NewsRepository repository;

  @override
  State<NewsHomePage> createState() => _NewsHomePageState();
}

class _NewsHomePageState extends State<NewsHomePage> {
  late final NewsController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = NewsController(repository: widget.repository)..loadInitial();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent * 0.82;
    if (_scrollController.position.pixels >= threshold) {
      _controller.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? child) {
              return PopupMenuButton<NewsLanguage>(
                tooltip: 'Selecionar idioma',
                initialValue: _controller.language,
                onSelected: _controller.setLanguage,
                itemBuilder: (BuildContext context) {
                  return NewsLanguage.values
                      .map(
                        (NewsLanguage language) => PopupMenuItem<NewsLanguage>(
                          value: language,
                          child: Row(
                            children: <Widget>[
                              Text(language.flag),
                              const SizedBox(width: 8),
                              Expanded(child: Text(language.label)),
                            ],
                          ),
                        ),
                      )
                      .toList(growable: false);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Text(
                      _controller.language.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Atualizar noticias',
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _controller.refresh();
              if (!context.mounted) return;
              final text = _controller.error == null
                  ? 'Noticias atualizadas agora'
                  : 'Falha ao atualizar: ${_controller.error}';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(text)),
              );
            },
          ),
          IconButton(
            tooltip: 'Configurar fontes',
            icon: const Icon(Icons.tune),
            onPressed: _openSourcesSheet,
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? child) {
              return PopupMenuButton<NewsSortOption>(
                tooltip: 'Ordenar noticias',
                initialValue: _controller.sortOption,
                onSelected: _controller.setSortOption,
                itemBuilder: (BuildContext context) {
                  return NewsSortOption.values
                      .map(
                        (NewsSortOption option) => PopupMenuItem<NewsSortOption>(
                          value: option,
                          child: Text(option.label),
                        ),
                      )
                      .toList(growable: false);
                },
                icon: const Icon(Icons.sort),
              );
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          if (_controller.isLoading) {
            return const _LoadingView();
          }

          if (_controller.error != null && _controller.visibleArticles.isEmpty) {
            return _ErrorView(
              message: _controller.error!,
              onRetry: _controller.loadInitial,
            );
          }

          final articles = _controller.visibleArticles;
          final highlights = _controller.highlightArticles;
          if (articles.isEmpty) {
            return const Center(child: Text('Nenhuma noticia encontrada.'));
          }

          final highlightedUrls = highlights.map((NewsArticle item) => item.url).toSet();
          final feedArticles = articles
              .where((NewsArticle item) => !highlightedUrls.contains(item.url))
              .toList(growable: false);
          final hasLoadingItem = _controller.canLoadMore;
          final totalCount = 1 + feedArticles.length + (hasLoadingItem ? 1 : 0);

          return Stack(
            children: <Widget>[
              RefreshIndicator(
                onRefresh: _controller.refresh,
                child: ListView.separated(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: totalCount,
                  separatorBuilder: (BuildContext context, int index) =>
                      const Divider(height: 1),
                  itemBuilder: (BuildContext context, int index) {
                    if (index == 0) {
                      return _HighlightsAndTopicsSection(
                        controller: _controller,
                        highlights: highlights,
                      );
                    }

                    final articleIndex = index - 1;
                    if (articleIndex >= feedArticles.length) {
                      return const Padding(
                        padding: EdgeInsets.all(18),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final article = feedArticles[articleIndex];
                    return _NewsTile(article: article);
                  },
                ),
              ),
              if (_controller.isRefreshing)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.92),
                      child: const _LoadingView(),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openSourcesSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _SourcesSheet(controller: _controller);
      },
    );
  }
}

class _SourcesSheet extends StatelessWidget {
  const _SourcesSheet({required this.controller});

  final NewsController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          final sources = controller.currentSources;

          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.62,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    'Fontes (${controller.language.flag})  •  ${controller.enabledSourceCount}/${sources.length} ativas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (sources.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('Nenhuma fonte disponivel para este idioma.'),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: sources.length,
                      itemBuilder: (BuildContext context, int index) {
                        final source = sources[index];
                        final enabled = controller.isSourceEnabled(source);
                        return SwitchListTile(
                          value: enabled,
                          title: Text(source.name),
                          subtitle: Text(
                            Uri.tryParse(source.url)?.host ?? source.url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onChanged: (bool value) {
                            unawaited(_handleToggle(context, source, value));
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleToggle(
    BuildContext context,
    NewsFeedSource source,
    bool value,
  ) async {
    final ok = await controller.setSourceEnabled(source, value);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mantenha pelo menos uma fonte ativa.')),
      );
    }
  }
}

class _NewsTile extends StatelessWidget {
  const _NewsTile({required this.article});

  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext context) => _ArticleDetailsPage(article: article),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                article.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${article.source}  •  ${_relativeTime(article.createdAt)}  •  ${article.domain}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if ((article.summary ?? '').isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  article.summary!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inHours < 1) return '${diff.inMinutes} min';
    if (diff.inDays < 1) return '${diff.inHours} h';
    return '${diff.inDays} d';
  }
}

class _HighlightsAndTopicsSection extends StatelessWidget {
  const _HighlightsAndTopicsSection({
    required this.controller,
    required this.highlights,
  });

  final NewsController controller;
  final UnmodifiableListView<NewsArticle> highlights;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Destaques do momento',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 190,
            child: ListView.separated(
              primary: false,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              itemCount: highlights.length,
              separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 10),
              itemBuilder: (BuildContext context, int index) {
                return _HighlightCard(article: highlights[index]);
              },
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.availableTopics.map((NewsTopic topic) {
              return ChoiceChip(
                label: Text(topic.label),
                selected: controller.topic == topic,
                onSelected: (_) => controller.setTopic(topic),
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.article});

  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 265,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) => _ArticleDetailsPage(article: article),
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.primary,
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Em alta',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      article.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.source,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                        fontSize: 12,
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

class _ArticleDetailsPage extends StatelessWidget {
  const _ArticleDetailsPage({required this.article});

  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Noticia'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            article.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            '${article.source}  •  ${article.domain}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            (article.summary ?? '').isNotEmpty
                ? article.summary!
                : 'Resumo nao disponivel para esta noticia.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _openInBrowser(context, article.url),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Abrir materia completa no site'),
          ),
        ],
      ),
    );
  }

  Future<void> _openInBrowser(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel abrir o link.')),
      );
    }
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.wifi_off, size: 38),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (BuildContext context, int index) => const ListTile(
        leading: CircleAvatar(radius: 18),
        title: _BarPlaceholder(widthFactor: 0.95),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 8),
          child: _BarPlaceholder(widthFactor: 0.55),
        ),
      ),
    );
  }
}

class _BarPlaceholder extends StatelessWidget {
  const _BarPlaceholder({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
