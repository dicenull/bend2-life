# 各U32の最下位ビットが区画の左端。
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


def first_or(n: Nat, row: Word(n), east: Bool) -> Bool:
  match n:
    case 0n:
      east
    case 1n+k:
      match row:
        case WCon{b, _}:
          b

def count_three(w: Bool, c: Bool, e: Bool) -> U32:
  U32.add(U32.add(Bool.to_u32(w), Bool.to_u32(c)), Bool.to_u32(e))

def scan(+n: Nat, top: Word(n), mid: Word(n), bot: Word(n),
         tw: Bool, mw: Bool, bw: Bool, +te: Bool, +me: Bool, +be: Bool) -> Word(n):
  match n:
    case 0n:
      WNil{}
    case 1n+k:
      match top mid bot:
        case WCon{+tc,+tr} WCon{+mc,+mr} WCon{+bc,+br}:
          above = count_three(tw, tc, first_or(k, tr, te))
          beside = U32.add(Bool.to_u32(mw), Bool.to_u32(first_or(k, mr, me)))
          below = count_three(bw, bc, first_or(k, br, be))
          alive = next_cell(mc, U32.to_nat(U32.add(U32.add(above, beside), below)))
          WCon{alive, scan(k, tr, mr, br, tc, mc, bc, te, me, be)}

type Edge is Data:
  edges{west: Bool, east: Bool}

# 境界値のビット0が左隣、ビット1が右隣。
def decode_edge_bits(w: Word(32n)) -> Edge:
  match w:
    case WCon{west, WCon{east, _}}:
      edges{west, east}

def decode_edge(w: U32) -> Edge:
  match w:
    case U32{bits}:
      decode_edge_bits(bits)

def scan_word(top: Word(32n), mid: Word(32n), bot: Word(32n), te: Edge, me: Edge, be: Edge) -> U32:
  match te me be:
    case edges{tw,tr} edges{mw,mr} edges{bw,br}:
      U32{scan(32n, top, mid, bot, tw, mw, bw, tr, mr, br)}

def next_word(top: U32, mid: U32, bot: U32, te: U32, me: U32, be: U32) -> U32:
  match top mid bot:
    case U32{t} U32{m} U32{b}:
      scan_word(t, m, b, decode_edge(te), decode_edge(me), decode_edge(be))

def next_row(top: U32, mid: U32, bottom: U32) -> U32:
  next_word(top, mid, bottom, 0, 0, 0)

def last_bit(n: Nat, word: Word(1n+n)) -> Bool:
  match n:
    case 0n:
      match word:
        case WCon{b, _}:
          b
    case 1n+k:
      match word:
        case WCon{_, tail}:
          last_bit(k, tail)

def neighbor_edge(left: U32, right: U32) -> Edge:
  match left right:
    case U32{l} U32{r}:
      edges{last_bit(31n, l), first_or(32n, r, False{})}

def next_neighborhood(tl: U32, tc: U32, tr: U32, ml: U32, mc: U32, mr: U32, bl: U32, bc: U32, br: U32) -> U32:
  match tc mc bc:
    case U32{t} U32{m} U32{b}:
      scan_word(t, m, b, neighbor_edge(tl, tr), neighbor_edge(ml, mr), neighbor_edge(bl, br))

def clip(distance: Nat, candidate: U32) -> U32:
  match distance:
    case 0n:
      0
    case 1n+rest:
      candidate

def next_bounded(+left: Nat, +right: Nat, +up: Nat, +down: Nat,
                 tl: U32, tc: U32, tr: U32, ml: U32, mc: U32, mr: U32,
                 bl: U32, bc: U32, br: U32) -> U32:
  next_neighborhood(
    clip(up, clip(left, tl)), clip(up, tc), clip(up, clip(right, tr)),
    clip(left, ml), mc, clip(right, mr),
    clip(down, clip(left, bl)), clip(down, bc), clip(down, clip(right, br)))
