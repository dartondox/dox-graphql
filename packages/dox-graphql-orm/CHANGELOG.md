## Unreleased

- New: `GraphQLOrm.paginate` for `@GraphQLPaginate`. It uses `paginate`
  of dox_orm: one count query and one page query. A `first` above 100,
  or a `first` or `page` below 1, is an error.
- New: `GraphQLOrm.paginatorInfo`, the shared `PaginatorInfo` type.
  `firstItem` and `lastItem` are null on an empty page.
- Exports `Pagination` of dox_orm, for the generated paginator types.

- Fix: `GraphQLOrm.relation` gives null for a relation with no related
  row when the model field is `late` and not nullable. Before, the
  client got an internal server error.
- New: `GraphQLOrm.many` loads a list relation with
  `LIMIT maxRelationRows + 1`. The limit is `GraphQLConfig.maxRelationRows`
  (50,000 by default) for all parents at one level. A batch with more
  rows gives an error, and the full table is never read into memory.
- First version: list, find, relations in batches (one query per
  relation and level, with a DataLoader of the request), and the find
  that the writes of `@GraphQLCreate` and `@GraphQLUpdate` models use.
