import Base
import ./wrap.bend as Wrap
import ./wrap-spec.bend as Spec
import ./proof-checks.bend as Checks
import ./proof-patterns.bend as Pattern

def axis_agrees(+pos: Wrap.Position) -> {Wrap.axis_at(pos) == Spec.axis_reference(pos) : Wrap.Axis}:
  match pos:
    case Wrap.position{0n, 0n}:
      {==}
    case Wrap.position{0n, 1n+rest}:
      {==}
    case Wrap.position{1n+prev, 0n}:
      {==}
    case Wrap.position{1n+prev, 1n+rest}:
      {==}

def window_agrees(+x: Wrap.Axis, +y: Wrap.Axis, +board: Wrap.Board)
    -> {Wrap.update_at(x, y, board) == Spec.reference_at(x, y, board) : U32}:
  match x y:
    case Wrap.axis{+west, +col, +east} Wrap.axis{+north, +row, +south}:
      Checks.neighborhood_word_matches_reference(
        Wrap.word_at(board, west, north), Wrap.word_at(board, col, north), Wrap.word_at(board, east, north),
        Wrap.word_at(board, west, row), Wrap.word_at(board, col, row), Wrap.word_at(board, east, row),
        Wrap.word_at(board, west, south), Wrap.word_at(board, col, south), Wrap.word_at(board, east, south))

def update_matches_reference(+col: Wrap.Position, +row: Wrap.Position, +board: Wrap.Board)
    -> {Wrap.update(col, row, board) == Spec.reference(col, row, board) : U32}:
  +x = Wrap.axis_at(col)
  +y = Wrap.axis_at(row)
  +rx = Spec.axis_reference(col)
  +ry = Spec.axis_reference(row)
  Equal.trans(U32, Wrap.update_at(x, y, board), Wrap.update_at(rx, ry, board), Spec.reference_at(rx, ry, board),
    Pattern.cong2(Wrap.Axis, Wrap.Axis, U32, a => b => Wrap.update_at(a, b, board),
      x, rx, y, ry, axis_agrees(col), axis_agrees(row)),
    window_agrees(rx, ry, board))
