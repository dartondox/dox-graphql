## Unreleased

- New: `GraphQLOrm.many` loads a list relation with
  `LIMIT maxRelationRows + 1`. `maxRelationRows` is 10,000. A batch with
  more rows gives an error, and the full table is never read into
  memory. Use a resolver with pages for a larger relation.
- First version: list, find, relations in batches (one query per
  relation and level, with a DataLoader of the request), and the find
  that the writes of `@GraphQLType(dto: ...)` models use.
