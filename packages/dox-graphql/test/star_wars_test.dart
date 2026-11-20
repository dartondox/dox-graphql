import 'package:test/test.dart';

import 'star_wars.dart';

void main() {
  group('Star Wars query tests', () {
    test('hero name', () async {
      expect(
        await runStarWars('query HeroNameQuery { hero { name } }'),
        <String, Object?>{
          'data': <String, Object?>{
            'hero': <String, Object?>{'name': 'R2-D2'},
          },
        },
      );
    });

    test('id and friends of R2-D2', () async {
      expect(
        await runStarWars('''
          query HeroNameAndFriendsQuery {
            hero { id name friends { name } }
          }
        '''),
        <String, Object?>{
          'data': <String, Object?>{
            'hero': <String, Object?>{
              'id': '2001',
              'name': 'R2-D2',
              'friends': <Object?>[
                <String, Object?>{'name': 'Luke Skywalker'},
                <String, Object?>{'name': 'Han Solo'},
                <String, Object?>{'name': 'Leia Organa'},
              ],
            },
          },
        },
      );
    });

    test('friends of friends', () async {
      Map<String, Object?> r = await runStarWars('''
        query NestedQuery {
          hero {
            name
            friends { name appearsIn friends { name } }
          }
        }
      ''');
      Map<String, Object?> hero =
          (r['data'] as Map<String, Object?>)['hero'] as Map<String, Object?>;
      List<Object?> friends = hero['friends'] as List<Object?>;
      expect(friends.first, <String, Object?>{
        'name': 'Luke Skywalker',
        'appearsIn': <Object?>['NEWHOPE', 'EMPIRE', 'JEDI'],
        'friends': <Object?>[
          <String, Object?>{'name': 'Han Solo'},
          <String, Object?>{'name': 'Leia Organa'},
          <String, Object?>{'name': 'C-3PO'},
          <String, Object?>{'name': 'R2-D2'},
        ],
      });
    });

    test('argument and variable', () async {
      expect(
        await runStarWars(
          r'query FetchSomeIDQuery($someId: String!) { human(id: $someId) { name } }',
          variables: <String, Object?>{'someId': '1002'},
        ),
        <String, Object?>{
          'data': <String, Object?>{
            'human': <String, Object?>{'name': 'Han Solo'},
          },
        },
      );
    });

    test('unknown id gives null', () async {
      expect(
        await runStarWars('{ human(id: "not a valid id") { name } }'),
        <String, Object?>{
          'data': <String, Object?>{'human': null},
        },
      );
    });

    test('enum argument', () async {
      expect(
        await runStarWars('{ hero(episode: EMPIRE) { name } }'),
        <String, Object?>{
          'data': <String, Object?>{
            'hero': <String, Object?>{'name': 'Luke Skywalker'},
          },
        },
      );
    });

    test('aliases', () async {
      expect(
        await runStarWars('''
          query { luke: human(id: "1000") { name } leia: human(id: "1003") { name } }
        '''),
        <String, Object?>{
          'data': <String, Object?>{
            'luke': <String, Object?>{'name': 'Luke Skywalker'},
            'leia': <String, Object?>{'name': 'Leia Organa'},
          },
        },
      );
    });

    test('fragments', () async {
      expect(
        await runStarWars('''
          query UseFragment {
            luke: human(id: "1000") { ...HumanFragment }
            leia: human(id: "1003") { ...HumanFragment }
          }
          fragment HumanFragment on Human { name homePlanet }
        '''),
        <String, Object?>{
          'data': <String, Object?>{
            'luke': <String, Object?>{
              'name': 'Luke Skywalker',
              'homePlanet': 'Tatooine',
            },
            'leia': <String, Object?>{
              'name': 'Leia Organa',
              'homePlanet': 'Alderaan',
            },
          },
        },
      );
    });

    test('__typename and inline fragments on an interface', () async {
      expect(
        await runStarWars('''
          {
            hero { __typename name ... on Droid { primaryFunction } }
            empire: hero(episode: EMPIRE) { __typename ... on Human { homePlanet } }
          }
        '''),
        <String, Object?>{
          'data': <String, Object?>{
            'hero': <String, Object?>{
              '__typename': 'Droid',
              'name': 'R2-D2',
              'primaryFunction': 'Astromech',
            },
            'empire': <String, Object?>{
              '__typename': 'Human',
              'homePlanet': 'Tatooine',
            },
          },
        },
      );
    });

    test('error on a nullable field, with path and location', () async {
      expect(
        await runStarWars('''
query HeroNameQuery {
  hero {
    name
    friends {
      name
      secretBackstory
    }
  }
}
'''),
        <String, Object?>{
          'errors': <Object?>[
            for (int i = 0; i < 3; i++)
              <String, Object?>{
                'message': 'secretBackstory is secret.',
                'locations': <Object?>[
                  <String, int>{'line': 6, 'column': 7},
                ],
                'path': <Object>['hero', 'friends', i, 'secretBackstory'],
              },
          ],
          'data': <String, Object?>{
            'hero': <String, Object?>{
              'name': 'R2-D2',
              'friends': <Object?>[
                <String, Object?>{
                  'name': 'Luke Skywalker',
                  'secretBackstory': null,
                },
                <String, Object?>{'name': 'Han Solo', 'secretBackstory': null},
                <String, Object?>{
                  'name': 'Leia Organa',
                  'secretBackstory': null,
                },
              ],
            },
          },
        },
      );
    });

    test('validation: unknown field', () async {
      Map<String, Object?> r = await runStarWars(
        '{ hero { favoriteSpaceship } }',
      );
      expect(r.containsKey('data'), isFalse);
      expect(r['errors'], <Object?>[
        <String, Object?>{
          'message':
              'Cannot query field "favoriteSpaceship" on type "Character".',
          'locations': <Object?>[
            <String, int>{'line': 1, 'column': 10},
          ],
        },
      ]);
    });

    test('validation: a field on an interface that only a type has', () async {
      Map<String, Object?> r = await runStarWars(
        '{ hero { name primaryFunction } }',
      );
      expect(
        ((r['errors'] as List<Object?>).single
            as Map<String, Object?>)['message'],
        'Cannot query field "primaryFunction" on type "Character".',
      );
    });
  });
}
