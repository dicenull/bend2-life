import Base
import ./pattern-spec.bend as Fixtures
import ./proof-patterns.bend as Pattern
import ./main.bend as Life
import ./life-spec.bend as Spec

law underpopulation_zero:
  for alive: Bool
  {Life.next_cell(alive, 0n) == False{} : Bool}

def underpopulation_zero(alive):
  {==}

law underpopulation_one:
  for alive: Bool
  {Life.next_cell(alive, 1n) == False{} : Bool}

def underpopulation_one(alive):
  {==}

law two_keeps_current_state:
  for alive: Bool
  {Life.next_cell(alive, 2n) == alive : Bool}

def two_keeps_current_state(alive):
  {==}

law three_birth_or_survival:
  for alive: Bool
  {Life.next_cell(alive, 3n) == True{} : Bool}

def three_birth_or_survival(alive):
  {==}

law overcrowding:
  for excess: Nat
  for alive: Bool
  {Life.next_cell(alive, 4n+excess) == False{} : Bool}

def overcrowding(excess, alive):
  {==}

def Column(+n: Nat, +i: Spec.Index(n), +top: Word(n), +mid: Word(n), +bot: Word(n),
           +tw: Bool, +mw: Bool, +bw: Bool, +te: Bool, +me: Bool, +be: Bool) -> Type:
  {Spec.at(n, i, Life.scan(n, top, mid, bot, tw, mw, bw, te, me, be))
    == Spec.reference(n, i, top, mid, bot, tw, mw, bw, te, me, be) : Bool}

def Columns(k: Nat) -> Type:
  @+i: Spec.Index(1n+k) ->
  @+top: Word(1n+k) -> @+mid: Word(1n+k) -> @+bot: Word(1n+k) ->
  @tw: Bool -> @mw: Bool -> @bw: Bool -> @te: Bool -> @me: Bool -> @be: Bool ->
  Column(1n+k, i, top, mid, bot, tw, mw, bw, te, me, be)

def one_column(+i: Spec.Index(1n), +top: Word(1n), +mid: Word(1n), +bot: Word(1n),
               tw: Bool, mw: Bool, bw: Bool, te: Bool, me: Bool, be: Bool)
    -> Column(1n, i, top, mid, bot, tw, mw, bw, te, me, be):
  match i top mid bot:
    case Spec.Here{} WCon{tc,_} WCon{mc,_} WCon{bc,_}:
      {==}
    case Spec.There{j} _ _ _:
      match j:

def add_column(+k: Nat, previous: Columns(k),
               +i: Spec.Index(2n+k), +top: Word(2n+k), +mid: Word(2n+k), +bot: Word(2n+k),
               tw: Bool, mw: Bool, bw: Bool, te: Bool, me: Bool, be: Bool)
    -> Column(2n+k, i, top, mid, bot, tw, mw, bw, te, me, be):
  match i top mid bot:
    case Spec.Here{} WCon{tc,WCon{tn,_}} WCon{mc,WCon{mn,_}} WCon{bc,WCon{bn,_}}:
      {==}
    case Spec.There{j} WCon{tc,tr} WCon{mc,mr} WCon{bc,br}:
      previous(j, tr, mr, br, tc, mc, bc, te, me, be)

law word_matches_eight_neighbors:
  for +i: Spec.Index(32n)
  for +top: U32
  for +mid: U32
  for +bot: U32
  for +te: U32
  for +me: U32
  for +be: U32
  {Spec.at_word(i, Life.next_word(top, mid, bot, te, me, be))
    == Spec.word_reference(i, top, mid, bot, te, me, be) : Bool}

def word_matches_eight_neighbors(i, top, mid, bot, te, me, be):
  match top mid bot te me be:
    case U32{t} U32{m} U32{b}
         U32{WCon{tw,WCon{tr,_}}} U32{WCon{mw,WCon{mr,_}}} U32{WCon{bw,WCon{br,_}}}:
      Pattern.nat_induction(~Columns, ~add_column, one_column, 31n)(i, t, m, b, tw, mw, bw, tr, mr, br)

def Row(k: Nat) -> Type:
  @+top: Word(1n+k) -> @+mid: Word(1n+k) -> @+bot: Word(1n+k) ->
  @+tw: Bool -> @+mw: Bool -> @+bw: Bool -> @+te: Bool -> @+me: Bool -> @+be: Bool ->
  {Life.scan(1n+k, top, mid, bot, tw, mw, bw, te, me, be)
    == Spec.reference_row(1n+k, top, mid, bot, tw, mw, bw, te, me, be) : Word(1n+k)}

def row_base(+top: Word(1n), +mid: Word(1n), +bot: Word(1n),
             +tw: Bool, +mw: Bool, +bw: Bool, +te: Bool, +me: Bool, +be: Bool)
    -> {Life.scan(1n, top, mid, bot, tw, mw, bw, te, me, be)
        == Spec.reference_row(1n, top, mid, bot, tw, mw, bw, te, me, be) : Word(1n)}:
  match top mid bot:
    case WCon{t,_} WCon{m,_} WCon{b,_}:
      {==}

def row_extend(+k: Nat, previous: Row(k),
               +top: Word(2n+k), +mid: Word(2n+k), +bot: Word(2n+k),
               +tw: Bool, +mw: Bool, +bw: Bool, +te: Bool, +me: Bool, +be: Bool)
    -> {Life.scan(2n+k, top, mid, bot, tw, mw, bw, te, me, be)
        == Spec.reference_row(2n+k, top, mid, bot, tw, mw, bw, te, me, be) : Word(2n+k)}:
  match top mid bot:
    case WCon{+a,+t} WCon{+b,+m} WCon{+c,+d}:
      Pattern.cong2(Bool, Word(1n+k), Word(2n+k), h => t => WCon{h,t},
        Spec.at(2n+k, Spec.Here{}, Life.scan(2n+k, WCon{a,t}, WCon{b,m}, WCon{c,d}, tw, mw, bw, te, me, be)),
        Spec.reference(2n+k, Spec.Here{}, WCon{a,t}, WCon{b,m}, WCon{c,d}, tw, mw, bw, te, me, be),
        Life.scan(1n+k, t, m, d, a, b, c, te, me, be),
        Spec.reference_row(1n+k, t, m, d, a, b, c, te, me, be),
        Pattern.nat_induction(~Columns, ~add_column, one_column, 1n+k)(Spec.Here{}, WCon{a,t}, WCon{b,m}, WCon{c,d}, tw, mw, bw, te, me, be),
        previous(t, m, d, a, b, c, te, me, be))

def final_index_matches_last(+n: Nat, +w: Word(1n+n))
    -> {Spec.at(1n+n, Spec.final_index(n), w) == Life.last_bit(n, w) : Bool}:
  match n:
    case 0n:
      match w:
        case WCon{_,_}:
          {==}
    case 1n+k:
      match w:
        case WCon{_,tail}:
          final_index_matches_last(k, tail)

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
    == Spec.neighborhood_reference(tl, tc, tr, ml, mc, mr, bl, bc, br) : U32}

def neighborhood_word_matches_reference(tl, tc, tr, ml, mc, mr, bl, bc, br):
  match tl tc tr ml mc mr bl bc br:
    case U32{+l1} U32{+t} U32{WCon{+e1,_}}
         U32{+l2} U32{+m} U32{WCon{+e2,_}}
         U32{+l3} U32{+b} U32{WCon{+e3,_}}:
      +w1 = Spec.at(32n, Spec.final_index(31n), l1)
      +w2 = Spec.at(32n, Spec.final_index(31n), l2)
      +w3 = Spec.at(32n, Spec.final_index(31n), l3)
      %final_index_matches_last(31n, l1) :
        {U32{Life.scan(32n, t, m, b, _, Life.last_bit(31n, l2), Life.last_bit(31n, l3), e1, e2, e3)}
          == U32{Spec.reference_row(32n, t, m, b, w1, w2, w3, e1, e2, e3)} : U32}
      %final_index_matches_last(31n, l2) :
        {U32{Life.scan(32n, t, m, b, w1, _, Life.last_bit(31n, l3), e1, e2, e3)}
          == U32{Spec.reference_row(32n, t, m, b, w1, w2, w3, e1, e2, e3)} : U32}
      %final_index_matches_last(31n, l3) :
        {U32{Life.scan(32n, t, m, b, w1, w2, _, e1, e2, e3)}
          == U32{Spec.reference_row(32n, t, m, b, w1, w2, w3, e1, e2, e3)} : U32}
      Equal.cong(Word(32n), U32, w => U32{w},
        Life.scan(32n, t, m, b, w1, w2, w3, e1, e2, e3),
        Spec.reference_row(32n, t, m, b, w1, w2, w3, e1, e2, e3),
        Pattern.nat_induction(~Row, ~row_extend, row_base, 31n)(t, m, b, w1, w2, w3, e1, e2, e3))

law seam_block_is_still:
  {Fixtures.step(Fixtures.block()) == Fixtures.block() : Fixtures.Patch}

def seam_block_is_still():
  {==}

law seam_blinker_turns_vertical:
  {Fixtures.step(Fixtures.horizontal()) == Fixtures.vertical() : Fixtures.Patch}

def seam_blinker_turns_vertical():
  {==}

law seam_blinker_returns_after_two:
  {Fixtures.step(Fixtures.step(Fixtures.horizontal())) == Fixtures.horizontal() : Fixtures.Patch}

def seam_blinker_returns_after_two():
  {==}

law exterior_is_dead:
  for candidate: U32
  {Life.clip(0n, candidate) == 0 : U32}

def exterior_is_dead(candidate):
  {==}

law interior_is_unchanged:
  for rest: Nat
  for candidate: U32
  {Life.clip(1n+rest, candidate) == candidate : U32}

def interior_is_unchanged(rest, candidate):
  {==}

def corner_reference(vertical: Nat, horizontal: Nat, candidate: U32) -> U32:
  match vertical horizontal:
    case 0n _:
      0
    case 1n+v 0n:
      0
    case 1n+v 1n+h:
      candidate

law corner_requires_both_axes:
  for +v: Nat
  for +h: Nat
  for +candidate: U32
  {Life.clip(v, Life.clip(h, candidate)) == corner_reference(v, h, candidate) : U32}

def corner_requires_both_axes(v, h, candidate):
  match v h:
    case 0n _:
      {==}
    case 1n+vr 0n:
      {==}
    case 1n+vr 1n+hr:
      {==}
