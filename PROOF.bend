import Base
import ./LAWS.bend as Laws
import ./main.bend as Life
import ./proof-patterns.bend as Pattern

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

def Column(+n: Nat, +i: Laws.Index(n), +top: Word(n), +mid: Word(n), +bot: Word(n),
           +tw: Bool, +mw: Bool, +bw: Bool, +te: Bool, +me: Bool, +be: Bool) -> Type:
  {Laws.at(n, i, Life.scan(n, top, mid, bot, tw, mw, bw, te, me, be))
    == Laws.reference(n, i, top, mid, bot, tw, mw, bw, te, me, be) : Bool}

# k counts additional columns after the first; there is no query at width zero.
def Columns(k: Nat) -> Type:
  @+i: Laws.Index(1n+k) ->
  @+top: Word(1n+k) -> @+mid: Word(1n+k) -> @+bot: Word(1n+k) ->
  @tw: Bool -> @mw: Bool -> @bw: Bool -> @te: Bool -> @me: Bool -> @be: Bool ->
  Column(1n+k, i, top, mid, bot, tw, mw, bw, te, me, be)

def one_column(+i: Laws.Index(1n), +top: Word(1n), +mid: Word(1n), +bot: Word(1n),
               tw: Bool, mw: Bool, bw: Bool, te: Bool, me: Bool, be: Bool)
    -> Column(1n, i, top, mid, bot, tw, mw, bw, te, me, be):
  match i top mid bot:
    case Laws.Here{} WCon{tc,_} WCon{mc,_} WCon{bc,_}:
      {==}
    case Laws.There{j} _ _ _:
      match j:

def add_column(+k: Nat, previous: Columns(k),
               +i: Laws.Index(2n+k), +top: Word(2n+k), +mid: Word(2n+k), +bot: Word(2n+k),
               tw: Bool, mw: Bool, bw: Bool, te: Bool, me: Bool, be: Bool)
    -> Column(2n+k, i, top, mid, bot, tw, mw, bw, te, me, be):
  match i top mid bot:
    case Laws.Here{} WCon{tc,WCon{tn,_}} WCon{mc,WCon{mn,_}} WCon{bc,WCon{bn,_}}:
      {==}
    case Laws.There{j} WCon{tc,tr} WCon{mc,mr} WCon{bc,br}:
      previous(j, tr, mr, br, tc, mc, bc, te, me, be)

def Laws.word_matches_eight_neighbors(i, top, mid, bot, te, me, be):
  match top mid bot te me be:
    case U32{t} U32{m} U32{b}
         U32{WCon{tw,WCon{tr,_}}} U32{WCon{mw,WCon{mr,_}}} U32{WCon{bw,WCon{br,_}}}:
      Pattern.nat_induction(~Columns, ~add_column, one_column, 31n)(i, t, m, b, tw, mw, bw, tr, mr, br)

def Row(k: Nat) -> Type:
  @+top: Word(1n+k) -> @+mid: Word(1n+k) -> @+bot: Word(1n+k) ->
  @+tw: Bool -> @+mw: Bool -> @+bw: Bool -> @+te: Bool -> @+me: Bool -> @+be: Bool ->
  {Life.scan(1n+k, top, mid, bot, tw, mw, bw, te, me, be)
    == Laws.reference_row(1n+k, top, mid, bot, tw, mw, bw, te, me, be) : Word(1n+k)}

def row_base(+top: Word(1n), +mid: Word(1n), +bot: Word(1n),
             +tw: Bool, +mw: Bool, +bw: Bool, +te: Bool, +me: Bool, +be: Bool)
    -> {Life.scan(1n, top, mid, bot, tw, mw, bw, te, me, be)
        == Laws.reference_row(1n, top, mid, bot, tw, mw, bw, te, me, be) : Word(1n)}:
  match top mid bot:
    case WCon{t,_} WCon{m,_} WCon{b,_}:
      {==}

def row_extend(+k: Nat, previous: Row(k),
               +top: Word(2n+k), +mid: Word(2n+k), +bot: Word(2n+k),
               +tw: Bool, +mw: Bool, +bw: Bool, +te: Bool, +me: Bool, +be: Bool)
    -> {Life.scan(2n+k, top, mid, bot, tw, mw, bw, te, me, be)
        == Laws.reference_row(2n+k, top, mid, bot, tw, mw, bw, te, me, be) : Word(2n+k)}:
  match top mid bot:
    case WCon{+a,+t} WCon{+b,+m} WCon{+c,+d}:
      Pattern.cong2(Bool, Word(1n+k), Word(2n+k), h => t => WCon{h,t},
        Laws.at(2n+k, Laws.Here{}, Life.scan(2n+k, WCon{a,t}, WCon{b,m}, WCon{c,d}, tw, mw, bw, te, me, be)),
        Laws.reference(2n+k, Laws.Here{}, WCon{a,t}, WCon{b,m}, WCon{c,d}, tw, mw, bw, te, me, be),
        Life.scan(1n+k, t, m, d, a, b, c, te, me, be),
        Laws.reference_row(1n+k, t, m, d, a, b, c, te, me, be),
        Pattern.nat_induction(~Columns, ~add_column, one_column, 1n+k)(Laws.Here{}, WCon{a,t}, WCon{b,m}, WCon{c,d}, tw, mw, bw, te, me, be),
        previous(t, m, d, a, b, c, te, me, be))

def final_index_matches_last(+n: Nat, +w: Word(1n+n))
    -> {Laws.at(1n+n, Laws.final_index(n), w) == Life.last_bit(n, w) : Bool}:
  match n:
    case 0n:
      match w:
        case WCon{_,_}:
          {==}
    case 1n+k:
      match w:
        case WCon{_,tail}:
          final_index_matches_last(k, tail)

def Laws.neighborhood_word_matches_reference(tl, tc, tr, ml, mc, mr, bl, bc, br):
  match tl tc tr ml mc mr bl bc br:
    case U32{+l1} U32{+t} U32{WCon{+e1,_}}
         U32{+l2} U32{+m} U32{WCon{+e2,_}}
         U32{+l3} U32{+b} U32{WCon{+e3,_}}:
      +w1 = Laws.at(32n, Laws.final_index(31n), l1)
      +w2 = Laws.at(32n, Laws.final_index(31n), l2)
      +w3 = Laws.at(32n, Laws.final_index(31n), l3)
      %final_index_matches_last(31n, l1) :
        {U32{Life.scan(32n, t, m, b, _, Life.last_bit(31n, l2), Life.last_bit(31n, l3), e1, e2, e3)}
          == U32{Laws.reference_row(32n, t, m, b, w1, w2, w3, e1, e2, e3)} : U32}
      %final_index_matches_last(31n, l2) :
        {U32{Life.scan(32n, t, m, b, w1, _, Life.last_bit(31n, l3), e1, e2, e3)}
          == U32{Laws.reference_row(32n, t, m, b, w1, w2, w3, e1, e2, e3)} : U32}
      %final_index_matches_last(31n, l3) :
        {U32{Life.scan(32n, t, m, b, w1, w2, _, e1, e2, e3)}
          == U32{Laws.reference_row(32n, t, m, b, w1, w2, w3, e1, e2, e3)} : U32}
      Equal.cong(Word(32n), U32, w => U32{w},
        Life.scan(32n, t, m, b, w1, w2, w3, e1, e2, e3),
        Laws.reference_row(32n, t, m, b, w1, w2, w3, e1, e2, e3),
        Pattern.nat_induction(~Row, ~row_extend, row_base, 31n)(t, m, b, w1, w2, w3, e1, e2, e3))

def Laws.seam_block_is_still():
  {==}

def Laws.seam_blinker_turns_vertical():
  {==}

def Laws.seam_blinker_returns_after_two():
  {==}

def Laws.exterior_is_dead(candidate):
  {==}

def Laws.interior_is_unchanged(rest, candidate):
  {==}

def Laws.corner_requires_both_axes(v, h, candidate):
  match v h:
    case 0n _:
      {==}
    case 1n+vr 0n:
      {==}
    case 1n+vr 1n+hr:
      {==}

def Laws.bounded_word_matches_dead_exterior(left, right, up, down, tl, tc, tr, ml, mc, mr, bl, bc, br):
  Laws.neighborhood_word_matches_reference(
    Life.clip(up, Life.clip(left, tl)), Life.clip(up, tc), Life.clip(up, Life.clip(right, tr)),
    Life.clip(left, ml), mc, Life.clip(right, mr),
    Life.clip(down, Life.clip(left, bl)), Life.clip(down, bc), Life.clip(down, Life.clip(right, br)))
