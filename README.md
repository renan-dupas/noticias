# Leitor de Noticias (Flutter)

Aplicativo Flutter de leitura de noticias com foco em desempenho e UX.

## O que foi otimizado

- Cache em memoria com TTL para evitar requisicoes repetidas.
- Parse de JSON em isolate (`compute`) para reduzir travamentos de UI.
- Paginacao incremental (lazy loading) na lista.
- Busca local com debounce.
- Pull-to-refresh.
- Cache de imagens de favicon com `cached_network_image`.
- Tratamento de erros de rede e timeout.

## Fonte de dados

As noticias sao carregadas da API publica do Hacker News (Algolia):

- `https://hn.algolia.com/api/v1/search?tags=front_page`

## Como executar

1. Instalar dependencias:
	- `flutter pub get`
2. Rodar o app:
	- `flutter run`
3. Rodar testes:
	- `flutter test`

## Estrutura principal

- `lib/main.dart`: app, modelo, repositorio, controller e UI.
- `test/widget_test.dart`: teste smoke com repositorio fake (sem internet).
