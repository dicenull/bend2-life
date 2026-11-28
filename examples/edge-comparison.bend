import Base
import ../core/main.bend as Life
import ../core/wrap.bend as Wrap

type Comparison is Data:
  result{dead_exterior: U32, wraparound: U32}

def compare_left_at(+y: Nat, +below: Nat, axis: Wrap.Axis, +board: Wrap.Board) -> Comparison:
  match axis:
    case Wrap.axis{+north, +mid, +south}:
      result{
        Life.next_bounded(0n, 1n, y, below,
          0, Wrap.word_at(board, 0n, north), Wrap.word_at(board, 1n, north),
          0, Wrap.word_at(board, 0n, mid), Wrap.word_at(board, 1n, mid),
          0, Wrap.word_at(board, 0n, south), Wrap.word_at(board, 1n, south)),
        Wrap.update(Wrap.position{0n, 1n}, Wrap.position{y, below}, board)}

def compare_left_word(+y: Nat, +below: Nat, board: Wrap.Board) -> Comparison:
  compare_left_at(y, below, Wrap.axis_at(Wrap.position{y, below}), board)

def horizontal_blinker() -> Wrap.Board:
  [[0, 0], [0, 0], [3, 2147483648], [0, 0], [0, 0]]

def vertical_blinker() -> Wrap.Board:
  [[2, 0], [2, 0], [0, 0], [0, 0], [2, 0]]

def three_corners() -> Wrap.Board:
  [[0, 2147483648], [0, 0], [0, 0], [0, 0], [1, 2147483648]]

law horizontal_blinker_turns_at_left_edge:
  {[
    compare_left_word(1n, 3n, horizontal_blinker()),
    compare_left_word(2n, 2n, horizontal_blinker()),
    compare_left_word(3n, 1n, horizontal_blinker())
  ] == [result{0, 1}, result{0, 1}, result{0, 1}] : List<&2, Comparison>}

def horizontal_blinker_turns_at_left_edge():
  {==}

law vertical_blinker_turns_at_top_edge:
  {compare_left_word(0n, 4n, vertical_blinker()) == result{0, 7} : Comparison}

def vertical_blinker_turns_at_top_edge():
  {==}

law opposite_corner_contributes_to_birth:
  {compare_left_word(0n, 4n, three_corners()) == result{0, 1} : Comparison}

def opposite_corner_contributes_to_birth():
  {==}
