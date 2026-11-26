# Conway's Game of Life: bit 0 is the leftmost cell in each U32 word.
# Edges pack west keep-alive in bit 0 and east keep-alive in bit 1.
import Base

def next_cell(alive: Bool, neighbors: Nat) -> Bool:
  match neighbors:
    case 0n:
      False{}
    case 1n:
      False{}
    case 2n:
      alive
    case 3n:
      True{}
    case 4n+excess:
      False{}

type Lanes is Data:
  lanes{west: U32, center: U32, east: U32}

def bit(row: U32, mask: U32) -> U32:
  Bool.to_u32(U32.is_ne(U32.and(row, mask), 0))

def lanes_for(+word: U32, +edge: U32) -> Lanes:
  west = U32.or(U32.shl(word), U32.and(edge, 1))
  east = U32.or(U32.shr(word), U32.shln(U32.and(U32.shr(edge), 1), 31n))
  lanes{west, word, east}

def full_count(row: Lanes, +mask: U32) -> U32:
  match row:
    case lanes{w,c,e}:
      U32.add(U32.add(bit(w, mask), bit(c, mask)), bit(e, mask))

def scan_word(fuel: Nat, +top: Lanes, +mid: Lanes, +bottom: Lanes, +mask: U32, acc: U32) -> U32:
  match fuel:
    case 0n:
      acc
    case 1n+rest:
      match mid:
        case lanes{+w,+c,+e}:
          n = U32.add(U32.add(full_count(top, mask), U32.add(bit(w, mask), bit(e, mask))),
            full_count(bottom, mask))
          old = U32.is_ne(bit(c, mask), 0)
          born = U32.mul(Bool.to_u32(next_cell(old, U32.to_nat(n))), mask)
          scan_word(rest, top, lanes{w,c,e}, bottom, U32.shl(mask), U32.or(acc, born))

# Bit 31 is computed directly: columns 30/31 in this word and column 0
# of the next word (edge bit 1). The lower scan cannot supply bit 31.
def east_row_count(+row: U32, edge: U32) -> U32:
  U32.add(U32.add(bit(row, 1073741824), bit(row, 2147483648)), bit(edge, 2))

def next_east(top: U32, +mid: U32, bottom: U32, te: U32, me: U32, be: U32) -> Bool:
  n = U32.add(U32.add(east_row_count(top, te), U32.add(bit(mid, 1073741824), bit(me, 2))), east_row_count(bottom, be))
  next_cell(U32.is_ne(U32.and(mid, 2147483648), 0), U32.to_nat(n))

def pack_east(low: U32, east: Bool) -> U32:
  U32.or(U32.and(low, 2147483647), U32.shln(Bool.to_u32(east), 31n))

def next_word(+top: U32, +mid: U32, +bottom: U32, +top_edge: U32, +mid_edge: U32, +bottom_edge: U32) -> U32:
  low = scan_word(31n, lanes_for(top, top_edge), lanes_for(mid, mid_edge), lanes_for(bottom, bottom_edge), 1, 0)
  pack_east(low, next_east(top, mid, bottom, top_edge, mid_edge, bottom_edge))

def next_row(top: U32, mid: U32, bottom: U32) -> U32:
  next_word(top, mid, bottom, 0, 0, 0)
