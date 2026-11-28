import Base
import ./life-spec.bend as Spec
import ./wrap.bend as Wrap

def axis_reference(pos: Wrap.Position) -> Wrap.Axis:
  match pos:
    case Wrap.position{0n, 0n}:
      Wrap.axis{0n, 0n, 0n}
    case Wrap.position{0n, 1n+last_minus_one}:
      Wrap.axis{1n+last_minus_one, 0n, 1n}
    case Wrap.position{1n++prev, 0n}:
      Wrap.axis{prev, 1n+prev, 0n}
    case Wrap.position{1n++prev, 1n+rest}:
      Wrap.axis{prev, 1n+prev, 2n+prev}

def reference_at(x: Wrap.Axis, y: Wrap.Axis, +board: Wrap.Board) -> U32:
  match x y:
    case Wrap.axis{+west, +col, +east} Wrap.axis{+north, +row, +south}:
      Spec.neighborhood_reference(
        Wrap.word_at(board, west, north), Wrap.word_at(board, col, north), Wrap.word_at(board, east, north),
        Wrap.word_at(board, west, row), Wrap.word_at(board, col, row), Wrap.word_at(board, east, row),
        Wrap.word_at(board, west, south), Wrap.word_at(board, col, south), Wrap.word_at(board, east, south))

def reference(col: Wrap.Position, row: Wrap.Position, +board: Wrap.Board) -> U32:
  reference_at(axis_reference(col), axis_reference(row), board)
