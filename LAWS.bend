# Conway B3/S23: cases cover all natural neighbor counts.
import Base
import ./main.bend as Life

law underpopulation_zero:
  for alive: Bool
  {Life.next_cell(alive, 0n) == False{} : Bool}

law underpopulation_one:
  for alive: Bool
  {Life.next_cell(alive, 1n) == False{} : Bool}

law two_keeps_current_state:
  for alive: Bool
  {Life.next_cell(alive, 2n) == alive : Bool}

law three_birth_or_survival:
  for alive: Bool
  {Life.next_cell(alive, 3n) == True{} : Bool}

law overcrowding:
  for excess: Nat
  for alive: Bool
  {Life.next_cell(alive, 4n+excess) == False{} : Bool}

# Words store the lowest-index cell first. Read the final constructor,
# independently of the shift/mask used to write the high bit.
def last_bit(n: Nat, w: Word(1n+n)) -> Bool:
  match n:
    case 0n:
      match w:
        case WCon{b, _}:
          b
    case 1n+k:
      match w:
        case WCon{_, t}:
          last_bit(k, t)

def east_bit(w: U32) -> Bool:
  match w:
    case U32{bits}:
      last_bit(31n, bits)

def count_bit(word: U32, mask: U32) -> U32:
  Bool.to_u32(U32.is_ne(U32.and(word, mask), 0))

# 3 cells above + 2 beside + 3 below; the middle cell is not counted.
# Masks 2^30 and 2^31 pick the last two cells of this word.
# Mask 2 picks the westernmost cell of the right-hand word from each edge.
def east_reference(+top: U32, +mid: U32, +bottom: U32, te: U32, me: U32, be: U32) -> Bool:
  above = U32.add(U32.add(count_bit(top, 1073741824), count_bit(top, 2147483648)), count_bit(te, 2))
  beside = U32.add(count_bit(mid, 1073741824), count_bit(me, 2))
  below = U32.add(U32.add(count_bit(bottom, 1073741824), count_bit(bottom, 2147483648)), count_bit(be, 2))
  Life.next_cell(U32.is_ne(U32.and(mid, 2147483648), 0), U32.to_nat(U32.add(U32.add(above, beside), below)))

law east_seam_matches_neighbors:
  for +top: U32
  for +mid: U32
  for +bottom: U32
  for +te: U32
  for +me: U32
  for +be: U32
  {east_bit(Life.next_word(top, mid, bottom, te, me, be)) == east_reference(top, mid, bottom, te, me, be) : Bool}
