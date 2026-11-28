import Base
import ./main.bend as Life

def Board() -> Data:
  List<&2, List<&2, U32>>

def word_at(board: Board, x: Nat, y: Nat) -> U32:
  row = Maybe.default(&2, List<&2, U32>, List.get(&2, List<&2, U32>, board, y), [])
  Maybe.default(&2, U32, List.get(&2, U32, row, x), 0)

type Position is Data:
  position{before: Nat, after: Nat}

type Axis is Data:
  axis{previous: Nat, current: Nat, next: Nat}

def axis_at(pos: Position) -> Axis:
  match pos:
    case position{+before, +after}:
      axis{Life.wrap_before(before, after), before, Life.wrap_after(before, after)}

def update_at(x: Axis, y: Axis, +board: Board) -> U32:
  match x y:
    case axis{+west, +col, +east} axis{+north, +row, +south}:
      Life.next_neighborhood(
        word_at(board, west, north), word_at(board, col, north), word_at(board, east, north),
        word_at(board, west, row), word_at(board, col, row), word_at(board, east, row),
        word_at(board, west, south), word_at(board, col, south), word_at(board, east, south))

def update(col: Position, row: Position, +board: Board) -> U32:
  update_at(axis_at(col), axis_at(row), board)
