import 'dart:convert';
import 'dart:io';

import 'package:dox_core/dox_core.dart';

import '../errors.dart';
import '../executor.dart';
import '../request.dart';
import 'graphql_context.dart';

/// Answers the GraphQL route, as the GraphQL-over-HTTP spec says.
///
/// - `POST` with a JSON body runs queries and mutations.
/// - `GET` with `query`, `variables`, `operationName` and `extensions` in
///   the URL runs queries only. A mutation gets 405.
/// - The answer is `application/graphql-response+json` when the client
///   accepts it, else `application/json`.
class GraphQLHttpHandler {
  GraphQLHttpHandler(
    this.executor, {
    required this.graphiql,
    required String path,
    this.logins = const <IAuthMiddleware>[],
  }) : _page = GraphiQLPage.html(path);

  final GraphQLExecutor<DoxGraphQLContext> executor;

  /// The auth middleware, in their optional form. Each request runs them
  /// only when a field needs the user.
  final List<IAuthMiddleware> logins;

  /// Send the GraphiQL page to a browser that asks for HTML.
  final bool graphiql;

  final String _page;

  static final ContentType _graphqlResponse = ContentType(
    'application',
    'graphql-response+json',
    charset: 'utf-8',
  );

  Future<DoxResponse> handle(DoxRequest req) async {
    String accept = req.header(HttpHeaders.acceptHeader) ?? '';
    // ponytail: a plain text check, q-values are not read. Add a real
    // Accept parser if a client sends `graphql-response+json;q=0`.
    bool newType = accept.contains('application/graphql-response+json');
    bool get = req.method == 'GET' || req.method == 'HEAD';

    GraphQLRequest request;
    try {
      if (get) {
        Map<String, String> params = req.uri.queryParameters;
        if (graphiql &&
            !params.containsKey('query') &&
            accept.contains('text/html')) {
          return response(_page).contentType(ContentType.html);
        }
        request = _fromQuery(params);
      } else {
        RequestBody body = req.requestBody;
        if (body.kind == BodyKind.invalidJson) {
          return _error(400, 'The body is not valid JSON.', newType);
        }
        // An empty JSON body has no kind: read the header for it.
        if (body.kind != BodyKind.json && !req.isJson()) {
          return _error(
            415,
            'Send the request as JSON, with Content-Type: application/json.',
            newType,
          );
        }
        Object? json = body.kind == BodyKind.json
            ? body.json
            : <String, Object?>{};
        if (json is! Map<String, Object?>) {
          return _error(400, 'The body must be a JSON object.', newType);
        }
        request = GraphQLRequest.fromJson(json);
      }
    } on GraphQLError catch (e) {
      return _error(400, e.message, newType);
    }

    GraphQLResponse result = await executor.execute(
      request,
      context: DoxGraphQLContext(req, Dox().ioc, login: logins),
      allowMutations: !get,
    );
    if (result.errors.any((GraphQLError e) => e is MutationNotAllowedError)) {
      return _error(
        405,
        'Mutations must be sent with POST.',
        newType,
      ).header(HttpHeaders.allowHeader, 'POST');
    }

    bool internal = false;
    for (GraphQLError e in result.errors) {
      Object? original = e.originalError;
      if (original == null) continue;
      internal = true;
      Dox().config.exceptionHandler.reportFor(
        req.httpRequest,
        original,
        e.stackTrace ?? StackTrace.empty,
      );
    }

    // With application/json the answer is always 200. With the new type,
    // a response with no data (a parse, validation or variable error)
    // gets an error status.
    int status = 200;
    if (newType && !result.hasData) status = internal ? 500 : 400;
    return _json(result.toJson(), status, newType);
  }

  /// A request from the URL of a GET.
  static GraphQLRequest _fromQuery(Map<String, String> params) {
    return GraphQLRequest.fromJson(<String, Object?>{
      'query': params['query'],
      'operationName': params['operationName'],
      'variables': _decode(params['variables'], 'variables'),
      'extensions': _decode(params['extensions'], 'extensions'),
    });
  }

  static Object? _decode(String? text, String name) {
    if (text == null || text.isEmpty) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      throw GraphQLError('The "$name" are not valid JSON.');
    }
  }

  static DoxResponse _error(int status, String message, bool newType) {
    return _json(
      GraphQLResponse.failed(<GraphQLError>[GraphQLError(message)]).toJson(),
      status,
      newType,
    );
  }

  static DoxResponse _json(
    Map<String, Object?> body,
    int status,
    bool newType,
  ) {
    return response(jsonEncode(body))
        .statusCode(status)
        .contentType(newType ? _graphqlResponse : ContentType.json);
  }
}

/// The GraphiQL page. It loads GraphiQL and React from jsDelivr, with
/// exact versions and SRI hashes, so a changed file does not run.
class GraphiQLPage {
  const GraphiQLPage._();

  static const String _cdn = 'https://cdn.jsdelivr.net/npm';

  /// The page for the endpoint at [path].
  static String html(String path) {
    // JSON is valid JavaScript; `<` is escaped so the text can not end the
    // script tag.
    String url = jsonEncode(path).replaceAll('<', r'\u003c');
    return '''
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>GraphiQL</title>
<style>body { margin: 0; } #graphiql { height: 100dvh; }</style>
<link rel="stylesheet" href="$_cdn/graphiql@4.1.2/graphiql.min.css" integrity="sha384-1el1QShFBnnXTx9x/Cprg82hZWKt0ry29OAYIXt05swbi0KcZDFoj0CWguMpopJr" crossorigin="anonymous">
<script src="$_cdn/react@18.3.1/umd/react.production.min.js" integrity="sha384-DGyLxAyjq0f9SPpVevD6IgztCFlnMF6oW/XQGmfe+IsZ8TqEiDrcHkMLKI6fiB/Z" crossorigin="anonymous"></script>
<script src="$_cdn/react-dom@18.3.1/umd/react-dom.production.min.js" integrity="sha384-gTGxhz21lVGYNMcdJOyq01Edg0jhn/c22nsx0kyqP0TxaV5WVdsSH1fSDUf5YJj1" crossorigin="anonymous"></script>
<script src="$_cdn/graphiql@4.1.2/graphiql.min.js" integrity="sha384-9XdHu7ajgGJziD4J1zNBKQ842Q/+zZfDv+ib1eMhZWBH6hPAs806x+Jbcf0yNO6B" crossorigin="anonymous"></script>
</head>
<body>
<div id="graphiql">Loading...</div>
<script>
const fetcher = GraphiQL.createFetcher({ url: $url });
ReactDOM.createRoot(document.getElementById('graphiql'))
  .render(React.createElement(GraphiQL, { fetcher: fetcher }));
</script>
</body>
</html>
''';
  }
}
