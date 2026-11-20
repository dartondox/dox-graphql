// The Star Wars schema of the GraphQL reference tests.
import 'package:dox_graphql/dox_graphql.dart';

abstract class Character {
  Character(this.id, this.name, this.friends, this.appearsIn);

  final String id;
  final String? name;
  final List<String> friends;
  final List<int> appearsIn;
}

class Human extends Character {
  Human(super.id, super.name, super.friends, super.appearsIn, this.homePlanet);

  final String? homePlanet;
}

class Droid extends Character {
  Droid(
    super.id,
    super.name,
    super.friends,
    super.appearsIn,
    this.primaryFunction,
  );

  final String? primaryFunction;
}

/// The data of the request. Resolvers read it from the context.
class StarWarsContext {
  final Map<String, Human> humans = <String, Human>{
    '1000': Human(
      '1000',
      'Luke Skywalker',
      <String>['1002', '1003', '2000', '2001'],
      <int>[4, 5, 6],
      'Tatooine',
    ),
    '1001': Human(
      '1001',
      'Darth Vader',
      <String>['1004'],
      <int>[4, 5, 6],
      'Tatooine',
    ),
    '1002': Human(
      '1002',
      'Han Solo',
      <String>['1000', '1003', '2001'],
      <int>[4, 5, 6],
      null,
    ),
    '1003': Human(
      '1003',
      'Leia Organa',
      <String>['1000', '1002', '2000', '2001'],
      <int>[4, 5, 6],
      'Alderaan',
    ),
    '1004': Human('1004', 'Wilhuff Tarkin', <String>['1001'], <int>[4], null),
  };

  final Map<String, Droid> droids = <String, Droid>{
    '2000': Droid(
      '2000',
      'C-3PO',
      <String>['1000', '1002', '1003', '2001'],
      <int>[4, 5, 6],
      'Protocol',
    ),
    '2001': Droid(
      '2001',
      'R2-D2',
      <String>['1000', '1002', '1003'],
      <int>[4, 5, 6],
      'Astromech',
    ),
  };

  Character? character(String id) => humans[id] ?? droids[id];

  /// Async on purpose, to test async resolvers.
  Future<List<Character?>> friendsOf(Character c) async => <Character?>[
    for (String id in c.friends) character(id),
  ];
}

final EnumType<int> episodeEnum = EnumType<int>('Episode', <EnumValue<int>>[
  EnumValue<int>('NEWHOPE', 4, description: 'Released in 1977.'),
  EnumValue<int>('EMPIRE', 5, description: 'Released in 1980.'),
  EnumValue<int>('JEDI', 6, description: 'Released in 1983.'),
], description: 'One of the films in the Star Wars Trilogy');

final InterfaceType characterInterface = InterfaceType(
  'Character',
  description: 'A character in the Star Wars Trilogy',
  fields: () => <Field<Object?, Object?>>[
    Field<Object?, Object?>(
      'id',
      graphqlString.nonNull,
      description: 'The id of the character.',
    ),
    Field<Object?, Object?>(
      'name',
      graphqlString,
      description: 'The name of the character.',
    ),
    Field<Object?, Object?>(
      'friends',
      characterInterface.list,
      description:
          'The friends of the character, or an empty list if they have '
          'none.',
    ),
    Field<Object?, Object?>(
      'appearsIn',
      episodeEnum.list,
      description: 'Which movies they appear in.',
    ),
    Field<Object?, Object?>(
      'secretBackstory',
      graphqlString,
      description: 'All secrets about their past.',
    ),
  ],
  resolveType: (Object value) => value is Human ? humanType : droidType,
);

List<Field<T, StarWarsContext>> _characterFields<T extends Character>() {
  return <Field<T, StarWarsContext>>[
    Field<T, StarWarsContext>(
      'id',
      graphqlString.nonNull,
      resolve: (T c, ResolveInfo<StarWarsContext> i) => c.id,
    ),
    Field<T, StarWarsContext>(
      'name',
      graphqlString,
      resolve: (T c, ResolveInfo<StarWarsContext> i) => c.name,
    ),
    Field<T, StarWarsContext>(
      'friends',
      characterInterface.list,
      resolve: (T c, ResolveInfo<StarWarsContext> i) => i.context.friendsOf(c),
    ),
    Field<T, StarWarsContext>(
      'appearsIn',
      episodeEnum.list,
      resolve: (T c, ResolveInfo<StarWarsContext> i) => c.appearsIn,
    ),
    Field<T, StarWarsContext>(
      'secretBackstory',
      graphqlString,
      resolve: (T c, ResolveInfo<StarWarsContext> i) =>
          throw GraphQLError('secretBackstory is secret.'),
    ),
  ];
}

final ObjectType<Human, StarWarsContext> humanType =
    ObjectType<Human, StarWarsContext>(
      'Human',
      description: 'A humanoid creature in the Star Wars universe.',
      interfaces: <InterfaceType>[characterInterface],
      fields: () => <Field<Human, StarWarsContext>>[
        ..._characterFields<Human>(),
        Field<Human, StarWarsContext>(
          'homePlanet',
          graphqlString,
          description: 'The home planet of the human, or null if unknown.',
          resolve: (Human h, ResolveInfo<StarWarsContext> i) => h.homePlanet,
        ),
      ],
    );

final ObjectType<Droid, StarWarsContext> droidType =
    ObjectType<Droid, StarWarsContext>(
      'Droid',
      description: 'A mechanical creature in the Star Wars universe.',
      interfaces: <InterfaceType>[characterInterface],
      fields: () => <Field<Droid, StarWarsContext>>[
        ..._characterFields<Droid>(),
        Field<Droid, StarWarsContext>(
          'primaryFunction',
          graphqlString,
          description: 'The primary function of the droid.',
          resolve: (Droid d, ResolveInfo<StarWarsContext> i) =>
              d.primaryFunction,
        ),
      ],
    );

final ObjectType<Object?, StarWarsContext>
queryType = ObjectType<Object?, StarWarsContext>(
  'Query',
  fields: () => <Field<Object?, StarWarsContext>>[
    Field<Object?, StarWarsContext>(
      'hero',
      characterInterface,
      args: <Argument>[
        Argument(
          'episode',
          episodeEnum,
          description:
              'If omitted, returns the hero of the whole saga. If '
              'provided, returns the hero of that particular episode.',
        ),
      ],
      resolve: (Object? _, ResolveInfo<StarWarsContext> i) =>
          i.args.get<int>('episode') == 5
          ? i.context.humans['1000']
          : i.context.droids['2001'],
    ),
    Field<Object?, StarWarsContext>(
      'human',
      humanType,
      args: <Argument>[
        Argument('id', graphqlString.nonNull, description: 'id of the human'),
      ],
      resolve: (Object? _, ResolveInfo<StarWarsContext> i) =>
          i.context.humans[i.args.get<String>('id')],
    ),
    Field<Object?, StarWarsContext>(
      'droid',
      droidType,
      args: <Argument>[
        Argument('id', graphqlString.nonNull, description: 'id of the droid'),
      ],
      resolve: (Object? _, ResolveInfo<StarWarsContext> i) =>
          i.context.droids[i.args.get<String>('id')],
    ),
  ],
);

final Schema<StarWarsContext> starWarsSchema = Schema<StarWarsContext>(
  query: queryType,
);

final GraphQLExecutor<StarWarsContext> starWars =
    GraphQLExecutor<StarWarsContext>(starWarsSchema);

/// Runs a query on the Star Wars schema and gives the JSON response.
Future<Map<String, Object?>> runStarWars(
  String query, {
  Map<String, Object?> variables = const <String, Object?>{},
  String? operationName,
}) async {
  GraphQLResponse r = await starWars.execute(
    GraphQLRequest(query, variables: variables, operationName: operationName),
    context: StarWarsContext(),
  );
  return r.toJson();
}
