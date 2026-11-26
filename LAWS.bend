# Conway B3/S23: cases cover all natural neighbor counts.
import Base
import ./pattern-spec.bend as Pattern
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

# A valid column: proof callers cannot select a bit outside the word.
type Index.More<-n: Nat> is Data:
  Here{}
  There{rest: Index(n)}

def Index(n: Nat) -> Data:
  match n:
    case 0n:
      Empty
    case 1n+k:
      Index.More<k>

def at(+n: Nat, index: Index(n), row: Word(n)) -> Bool:
  match n:
    case 0n:
      match index:
    case 1n+k:
      match index row:
        case Here{} WCon{b, _}:
          b
        case There{j} WCon{_, t}:
          at(k, j, t)

def west_of(+n: Nat, index: Index(n), row: Word(n), west: Bool) -> Bool:
  match n:
    case 0n:
      match index:
    case 1n+k:
      match index row:
        case Here{} WCon{_, _}:
          west
        case There{j} WCon{b, t}:
          west_of(k, j, t, b)

def right_lookup(+n: Nat, row: Word(n), east: Bool) -> Bool:
  match n:
    case 0n:
      east
    case 1n+k:
      at(1n+k, Here{}, row)

def east_of(+n: Nat, index: Index(n), row: Word(n), +east: Bool) -> Bool:
  match n:
    case 0n:
      match index:
    case 1n+k:
      match index row:
        case Here{} WCon{_, t}:
          right_lookup(k, t, east)
        case There{j} WCon{_, t}:
          east_of(k, j, t, east)

# One column, specified by individual cell lookups instead of an output scan.
def reference(+n: Nat, +i: Index(n), +top: Word(n), +mid: Word(n), +bot: Word(n),
              tw: Bool, mw: Bool, bw: Bool, te: Bool, me: Bool, be: Bool) -> Bool:
  nw = Bool.to_u32(west_of(n, i, top, tw))
  nc = Bool.to_u32(at(n, i, top))
  ne = Bool.to_u32(east_of(n, i, top, te))
  w = Bool.to_u32(west_of(n, i, mid, mw))
  e = Bool.to_u32(east_of(n, i, mid, me))
  sw = Bool.to_u32(west_of(n, i, bot, bw))
  sc = Bool.to_u32(at(n, i, bot))
  se = Bool.to_u32(east_of(n, i, bot, be))
  above = U32.add(U32.add(nw, nc), ne)
  beside = U32.add(w, e)
  below = U32.add(U32.add(sw, sc), se)
  Life.next_cell(at(n, i, mid), U32.to_nat(U32.add(U32.add(above, beside), below)))

def at_word(i: Index(32n), word: U32) -> Bool:
  match word:
    case U32{bits}:
      at(32n, i, bits)

# Packed edge words supply their western boundary at bit 0 and eastern
# boundary at bit 1. No other edge-word bits are part of the specification.
def word_reference(+i: Index(32n), top: U32, mid: U32, bot: U32,
                   +te: U32, +me: U32, +be: U32) -> Bool:
  match top mid bot:
    case U32{t} U32{m} U32{b}:
      reference(32n, i, t, m, b,
        at_word(Here{}, te), at_word(Here{}, me), at_word(Here{}, be),
        at_word(There{Here{}}, te), at_word(There{Here{}}, me), at_word(There{Here{}}, be))

law word_matches_eight_neighbors:
  for +i: Index(32n)
  for +top: U32
  for +mid: U32
  for +bot: U32
  for +te: U32
  for +me: U32
  for +be: U32
  {at_word(i, Life.next_word(top, mid, bot, te, me, be))
    == word_reference(i, top, mid, bot, te, me, be) : Bool}

def final_index(+n: Nat) -> Index(1n+n):
  match n:
    case 0n:
      Here{}
    case 1n+k:
      There{final_index(k)}

# Build the reference row from per-column observations. No output bit from the
# implementation scan is used. After a head, its cell becomes the west input.
def reference_row(+n: Nat, top: Word(n), mid: Word(n), bot: Word(n),
                  tw: Bool, mw: Bool, bw: Bool, +te: Bool, +me: Bool, +be: Bool) -> Word(n):
  match n:
    case 0n:
      WNil{}
    case 1n+k:
      match top mid bot:
        case WCon{+a,+t} WCon{+b,+m} WCon{+c,+d}:
          WCon{reference(1n+k, Here{}, WCon{a,t}, WCon{b,m}, WCon{c,d}, tw, mw, bw, te, me, be),
            reference_row(k, t, m, d, a, b, c, te, me, be)}

def neighborhood_reference(tl: U32, tc: U32, tr: U32, ml: U32, mc: U32, mr: U32,
                           bl: U32, bc: U32, br: U32) -> U32:
  match tc mc bc:
    case U32{t} U32{m} U32{b}:
      U32{reference_row(32n, t, m, b,
        at_word(final_index(31n), tl), at_word(final_index(31n), ml), at_word(final_index(31n), bl),
        at_word(Here{}, tr), at_word(Here{}, mr), at_word(Here{}, br))}

law neighborhood_word_matches_reference:
  for +tl: U32
  for +tc: U32
  for +tr: U32
  for +ml: U32
  for +mc: U32
  for +mr: U32
  for +bl: U32
  for +bc: U32
  for +br: U32
  {Life.next_neighborhood(tl, tc, tr, ml, mc, mr, bl, bc, br)
    == neighborhood_reference(tl, tc, tr, ml, mc, mr, bl, bc, br) : U32}

# Probe patterns after one and two generations, as in the upstream benchmark.
law seam_block_is_still:
  {Pattern.step(Pattern.block()) == Pattern.block() : Pattern.Patch}

law seam_blinker_turns_vertical:
  {Pattern.step(Pattern.horizontal()) == Pattern.vertical() : Pattern.Patch}

law seam_blinker_returns_after_two:
  {Pattern.step(Pattern.step(Pattern.horizontal())) == Pattern.horizontal() : Pattern.Patch}
