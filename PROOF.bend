import Base
import ./LAWS.bend as Laws
import ./main.bend as Life

def Laws.underpopulation_zero(alive):
  {==}

def Laws.underpopulation_one(alive):
  {==}

def Laws.two_keeps_current_state(alive):
  {==}

def Laws.three_birth_or_survival(alive):
  {==}

def Laws.overcrowding(excess, alive):
  {==}

# Low mask: n leading (low-order) ones, then a zero.
def low_mask(n: Nat) -> Word(1n+n):
  match n:
    case 0n:
      WCon{False{}, WNil{}}
    case 1n+k:
      WCon{True{}, low_mask(k)}

# High bit: n leading (low-order) zeros, then b.
def high_word(n: Nat, b: Bool) -> Word(1n+n):
  match n:
    case 0n:
      WCon{b, WNil{}}
    case 1n+k:
      WCon{False{}, high_word(k, b)}

def last_after_pack(+n: Nat, w: Word(1n+n), +b: Bool) -> {Laws.last_bit(n, Word.or(1n+n, Word.and(1n+n, w, low_mask(n)), high_word(n, b))) == b : Bool}:
  match n:
    case 0n:
      match w b:
        case WCon{False{}, _} False{}:
          {==}
        case WCon{False{}, _} True{}:
          {==}
        case WCon{True{}, _} False{}:
          {==}
        case WCon{True{}, _} True{}:
          {==}
    case 1n+k:
      match w:
        case WCon{_, t}:
          last_after_pack(k, t, b)

def east_after_pack(w: U32, +b: Bool) -> {Laws.east_bit(Life.pack_east(w, b)) == b : Bool}:
  match w b:
    case U32{bits} False{}:
      last_after_pack(31n, bits, False{})
    case U32{bits} True{}:
      last_after_pack(31n, bits, True{})

def Laws.east_seam_matches_neighbors(top, mid, bottom, te, me, be):
  east_after_pack(Life.scan_word(31n, Life.lanes_for(top, te), Life.lanes_for(mid, me), Life.lanes_for(bottom, be), 1, 0),
    Life.next_east(top, mid, bottom, te, me, be))
