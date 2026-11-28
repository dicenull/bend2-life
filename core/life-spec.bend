import Base
import ./main.bend as Life

def conway_cell(alive: Bool, neighbors: Nat) -> Bool:
  match neighbors:
    case 3n:
      True{}
    case 2n:
      alive
    case _:
      False{}

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

def word_reference(+i: Index(32n), top: U32, mid: U32, bot: U32,
                   +te: U32, +me: U32, +be: U32) -> Bool:
  match top mid bot:
    case U32{t} U32{m} U32{b}:
      reference(32n, i, t, m, b,
        at_word(Here{}, te), at_word(Here{}, me), at_word(Here{}, be),
        at_word(There{Here{}}, te), at_word(There{Here{}}, me), at_word(There{Here{}}, be))

def final_index(+n: Nat) -> Index(1n+n):
  match n:
    case 0n:
      Here{}
    case 1n+k:
      There{final_index(k)}

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

def dead_if_outside(distance: Nat, word: U32) -> U32:
  match distance:
    case 0n:
      0
    case 1n+rest:
      word

type EdgeDistances is Data:
  distances{left: Nat, right: Nat, up: Nat, down: Nat}

type Neighborhood is Data:
  neighborhood{
    tl: U32, tc: U32, tr: U32,
    ml: U32, mc: U32, mr: U32,
    bl: U32, bc: U32, br: U32
  }

def bounded_update(edges: EdgeDistances, around: Neighborhood) -> U32:
  match edges around:
    case distances{left, right, up, down} neighborhood{tl, tc, tr, ml, mc, mr, bl, bc, br}:
      Life.next_bounded(left, right, up, down, tl, tc, tr, ml, mc, mr, bl, bc, br)

def finite_reference(edges: EdgeDistances, around: Neighborhood) -> U32:
  match edges around:
    case distances{+left, +right, +up, +down} neighborhood{tl, tc, tr, ml, mc, mr, bl, bc, br}:
      neighborhood_reference(
        dead_if_outside(up, dead_if_outside(left, tl)), dead_if_outside(up, tc), dead_if_outside(up, dead_if_outside(right, tr)),
        dead_if_outside(left, ml), mc, dead_if_outside(right, mr),
        dead_if_outside(down, dead_if_outside(left, bl)), dead_if_outside(down, bc), dead_if_outside(down, dead_if_outside(right, br)))
