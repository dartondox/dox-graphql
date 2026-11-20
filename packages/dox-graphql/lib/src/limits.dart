import 'package:gql/ast.dart';
import 'package:meta/meta.dart';

/// Cheap checks that keep a hostile query from using up the stack.
@internal
final class QueryLimits {
  const QueryLimits._();

  static const int _braceL = 0x7B; // {
  static const int _braceR = 0x7D; // }
  static const int _parenL = 0x28; // (
  static const int _parenR = 0x29; // )
  static const int _bracketL = 0x5B; // [
  static const int _bracketR = 0x5D; // ]
  static const int _quote = 0x22; // "
  static const int _backslash = 0x5C; // \
  static const int _hash = 0x23; // #
  static const int _newline = 0x0A;
  static const int _return = 0x0D;

  /// The deepest nesting of `{`, `(` and `[` in the query text, outside
  /// strings and comments. It runs before the parser, so a very deep query
  /// never reaches the recursive parser.
  static int textNesting(String text) {
    int depth = 0;
    int max = 0;
    int i = 0;
    int length = text.length;
    while (i < length) {
      int c = text.codeUnitAt(i);
      if (c == _hash) {
        while (i < length &&
            text.codeUnitAt(i) != _newline &&
            text.codeUnitAt(i) != _return) {
          i++;
        }
        continue;
      }
      if (c == _quote) {
        i = _skipString(text, i);
        continue;
      }
      if (c == _braceL || c == _parenL || c == _bracketL) {
        depth++;
        if (depth > max) max = depth;
      } else if (c == _braceR || c == _parenR || c == _bracketR) {
        depth--;
      }
      i++;
    }
    return max;
  }

  /// The index after the string that starts at [start].
  static int _skipString(String text, int start) {
    int length = text.length;
    bool block = text.startsWith('"""', start);
    int i = start + (block ? 3 : 1);
    while (i < length) {
      int c = text.codeUnitAt(i);
      if (block) {
        if (c == _backslash && text.startsWith(r'\"""', i)) {
          i += 4;
          continue;
        }
        if (text.startsWith('"""', i)) return i + 3;
      } else {
        if (c == _backslash) {
          i += 2;
          continue;
        }
        if (c == _quote) return i + 1;
        // A plain string ends at the line end: the parser reports it.
        if (c == _newline || c == _return) return i;
      }
      i++;
    }
    return length;
  }

  /// The deepest nesting of selection sets in any operation, with
  /// fragments expanded. `{ a }` is 1 and `{ a { b } }` is 2. Fragment
  /// cycles must be rejected before (validation does that).
  static int selectionDepth(DocumentNode document) {
    Map<String, FragmentDefinitionNode> fragments =
        <String, FragmentDefinitionNode>{
          for (DefinitionNode d in document.definitions)
            if (d is FragmentDefinitionNode) d.name.value: d,
        };
    Map<String, int> memo = <String, int>{};
    int max = 0;
    for (DefinitionNode d in document.definitions) {
      if (d is OperationDefinitionNode) {
        int depth = 1 + _depth(d.selectionSet, fragments, memo);
        if (depth > max) max = depth;
      }
    }
    return max;
  }

  /// The depth below [set]: 0 when no field in it has a sub selection.
  static int _depth(
    SelectionSetNode set,
    Map<String, FragmentDefinitionNode> fragments,
    Map<String, int> memo,
  ) {
    int max = 0;
    for (SelectionNode s in set.selections) {
      int d = switch (s) {
        FieldNode(:SelectionSetNode? selectionSet) =>
          selectionSet == null ? 0 : 1 + _depth(selectionSet, fragments, memo),
        InlineFragmentNode(:SelectionSetNode selectionSet) => _depth(
          selectionSet,
          fragments,
          memo,
        ),
        FragmentSpreadNode(:NameNode name) => _fragmentDepth(
          name.value,
          fragments,
          memo,
        ),
        _ => 0,
      };
      if (d > max) max = d;
    }
    return max;
  }

  static int _fragmentDepth(
    String name,
    Map<String, FragmentDefinitionNode> fragments,
    Map<String, int> memo,
  ) {
    int? known = memo[name];
    if (known != null) return known;
    FragmentDefinitionNode? f = fragments[name];
    if (f == null) return 0;
    memo[name] = 0; // a guard; cycles are rejected before
    return memo[name] = _depth(f.selectionSet, fragments, memo);
  }

  /// The number of fields the largest operation selects, with fragments
  /// expanded: a fragment spread twice counts twice. Each fragment is
  /// counted once and reused, and counts stop growing at [cap], so this is
  /// cheap even when the expanded query is huge. Fragment cycles must be
  /// rejected before.
  static int fieldCount(DocumentNode document, int cap) {
    Map<String, FragmentDefinitionNode> fragments =
        <String, FragmentDefinitionNode>{
          for (DefinitionNode d in document.definitions)
            if (d is FragmentDefinitionNode) d.name.value: d,
        };
    Map<String, int> memo = <String, int>{};
    int max = 0;
    for (DefinitionNode d in document.definitions) {
      if (d is OperationDefinitionNode) {
        int count = _count(d.selectionSet, fragments, memo, cap);
        if (count > max) max = count;
      }
    }
    return max;
  }

  static int _count(
    SelectionSetNode set,
    Map<String, FragmentDefinitionNode> fragments,
    Map<String, int> memo,
    int cap,
  ) {
    int total = 0;
    for (SelectionNode s in set.selections) {
      total += switch (s) {
        FieldNode(:SelectionSetNode? selectionSet) =>
          1 +
              (selectionSet == null
                  ? 0
                  : _count(selectionSet, fragments, memo, cap)),
        InlineFragmentNode(:SelectionSetNode selectionSet) => _count(
          selectionSet,
          fragments,
          memo,
          cap,
        ),
        FragmentSpreadNode(:NameNode name) => _fragmentCount(
          name.value,
          fragments,
          memo,
          cap,
        ),
        _ => 0,
      };
      if (total > cap) return cap + 1;
    }
    return total;
  }

  static int _fragmentCount(
    String name,
    Map<String, FragmentDefinitionNode> fragments,
    Map<String, int> memo,
    int cap,
  ) {
    int? known = memo[name];
    if (known != null) return known;
    FragmentDefinitionNode? f = fragments[name];
    if (f == null) return 0;
    memo[name] = 0; // a guard; cycles are rejected before
    return memo[name] = _count(f.selectionSet, fragments, memo, cap);
  }
}
