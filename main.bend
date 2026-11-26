# Conway's Game of Life: one U32 bitboard per row, bit 0 on the left.
# An absent row is 0. Shifts drop off-board bits rather than wrapping.
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

def bit(row: U32, mask: U32) -> U32:
  Bool.to_u32(U32.is_ne(U32.and(row, mask), 0))

def side_count(+row: U32, left: U32, right: U32) -> U32:
  U32.add(bit(row, left), bit(row, right))

def full_count(+row: U32, left: U32, center: U32, right: U32) -> U32:
  U32.add(side_count(row, left, right), bit(row, center))

def scan_row(fuel: Nat, +top: U32, +mid: U32, +bottom: U32, +mask: U32, acc: U32) -> U32:
  match fuel:
    case 0n:
      acc
    case 1n+rest:
      +left = U32.shr(mask)
      +right = U32.shl(mask)
      n = U32.add(U32.add(full_count(top, left, mask, right), side_count(mid, left, right)),
        full_count(bottom, left, mask, right))
      old = U32.is_ne(bit(mid, mask), 0)
      born = U32.mul(Bool.to_u32(next_cell(old, U32.to_nat(n))), mask)
      scan_row(rest, top, mid, bottom, right, U32.or(acc, born))

def next_row(top: U32, mid: U32, bottom: U32) -> U32:
  scan_row(32n, top, mid, bottom, 1, 0)
