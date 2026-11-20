## Unreleased

- New: `GraphQLOrm.many` loads a list relation with
  `LIMIT maxRelationRows + 1`. The limit is `GraphQLConfig.maxRelationRows`
  (50,000 by default) for all parents at one level. A batch with more
  rows gives an error, and the full table is never read into memory.
- First version: list, find, relations in batches (one query per
  relation and level, with a DataLoader of the request), and the find
  that the writes of `@GraphQLType(dto: ...)` models use.
