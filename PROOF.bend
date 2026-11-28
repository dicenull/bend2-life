import Base
import ./LAWS.bend as Laws
import ./core/life-spec.bend as Spec
import ./core/proof-checks.bend as Checks
import ./core/main.bend as Life
import ./core/proof-patterns.bend as Pattern

def Checks.underpopulation_zero(alive):
  {==}

def Checks.underpopulation_one(alive):
  {==}

def Checks.two_keeps_current_state(alive):
  {==}

def Checks.three_birth_or_survival(alive):
  {==}

def Checks.overcrowding(excess, alive):
  {==}

def Laws.cell_follows_conway(alive, neighbors):
  match neighbors:
    case 0n:
      Checks.underpopulation_zero(alive)
    case 1n:
      Checks.underpopulation_one(alive)
    case 2n:
      Checks.two_keeps_current_state(alive)
    case 3n:
      Checks.three_birth_or_survival(alive)
    case 4n+excess:
      Checks.overcrowding(excess, alive)

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

def Checks.word_matches_eight_neighbors(i, top, mid, bot, te, me, be):
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

def Checks.neighborhood_word_matches_reference(tl, tc, tr, ml, mc, mr, bl, bc, br):
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

def Checks.seam_block_is_still():
  {==}

def Checks.seam_blinker_turns_vertical():
  {==}

def Checks.seam_blinker_returns_after_two():
  {==}

def Checks.exterior_is_dead(candidate):
  {==}

def Checks.interior_is_unchanged(rest, candidate):
  {==}

def Checks.corner_requires_both_axes(v, h, candidate):
  match v h:
    case 0n _:
      {==}
    case 1n+vr 0n:
      {==}
    case 1n+vr 1n+hr:
      {==}

def clip_matches_spec(+distance: Nat, +word: U32)
    -> {Life.clip(distance, word) == Spec.dead_if_outside(distance, word) : U32}:
  match distance:
    case 0n:
      {==}
    case 1n+rest:
      {==}

def corner_matches_spec(+v: Nat, +h: Nat, +word: U32)
    -> {Life.clip(v, Life.clip(h, word)) == Spec.dead_if_outside(v, Spec.dead_if_outside(h, word)) : U32}:
  match v h:
    case 0n _:
      {==}
    case 1n+vr 0n:
      {==}
    case 1n+vr 1n+hr:
      {==}

type MaskInput is Data:
  keep{word: U32}
  side{distance: Nat, word: U32}
  corner{vertical: Nat, horizontal: Nat, word: U32}

def mask_impl(input: MaskInput) -> U32:
  match input:
    case keep{word}:
      word
    case side{distance, word}:
      Life.clip(distance, word)
    case corner{v, h, word}:
      Life.clip(v, Life.clip(h, word))

def mask_spec(input: MaskInput) -> U32:
  match input:
    case keep{word}:
      word
    case side{distance, word}:
      Spec.dead_if_outside(distance, word)
    case corner{v, h, word}:
      Spec.dead_if_outside(v, Spec.dead_if_outside(h, word))

def mask_agrees(+input: MaskInput) -> {mask_impl(input) == mask_spec(input) : U32}:
  match input:
    case keep{word}:
      {==}
    case side{distance, word}:
      clip_matches_spec(distance, word)
    case corner{v, h, word}:
      corner_matches_spec(v, h, word)

def reference_from_words(words: Pattern.Vec(U32, 9n)) -> U32:
  match words:
    case Pattern.VCons{tl, Pattern.VCons{tc, Pattern.VCons{tr,
         Pattern.VCons{ml, Pattern.VCons{mc, Pattern.VCons{mr,
         Pattern.VCons{bl, Pattern.VCons{bc, Pattern.VCons{br, Pattern.VNil{}}}}}}}}}}:
      Spec.neighborhood_reference(tl, tc, tr, ml, mc, mr, bl, bc, br)

def mask_inputs(+left: Nat, +right: Nat, +up: Nat, +down: Nat,
                       +tl: U32, +tc: U32, +tr: U32, +ml: U32, +mc: U32, +mr: U32,
                       +bl: U32, +bc: U32, +br: U32)
    -> Pattern.Vec(MaskInput, 9n):
  Pattern.VCons{corner{up, left, tl}, Pattern.VCons{side{up, tc}, Pattern.VCons{corner{up, right, tr},
    Pattern.VCons{side{left, ml}, Pattern.VCons{keep{mc}, Pattern.VCons{side{right, mr},
    Pattern.VCons{corner{down, left, bl}, Pattern.VCons{side{down, bc}, Pattern.VCons{corner{down, right, br}, Pattern.VNil{}}}}}}}}}}

def bounded_word_proof(+left: Nat, +right: Nat, +up: Nat, +down: Nat,
                       +tl: U32, +tc: U32, +tr: U32, +ml: U32, +mc: U32, +mr: U32,
                       +bl: U32, +bc: U32, +br: U32)
    -> {Life.next_bounded(left, right, up, down, tl, tc, tr, ml, mc, mr, bl, bc, br)
      == Spec.finite_reference(Spec.distances{left, right, up, down}, Spec.neighborhood{tl, tc, tr, ml, mc, mr, bl, bc, br}) : U32}:
  +inputs = mask_inputs(left, right, up, down, tl, tc, tr, ml, mc, mr, bl, bc, br)
  %Pattern.map_cong(~MaskInput, ~U32, ~mask_impl, ~mask_spec, ~mask_agrees, 9n, inputs) :
    {Life.next_bounded(left, right, up, down, tl, tc, tr, ml, mc, mr, bl, bc, br) == reference_from_words(_) : U32}
  Checks.neighborhood_word_matches_reference(
    Life.clip(up, Life.clip(left, tl)), Life.clip(up, tc), Life.clip(up, Life.clip(right, tr)),
    Life.clip(left, ml), mc, Life.clip(right, mr),
    Life.clip(down, Life.clip(left, bl)), Life.clip(down, bc), Life.clip(down, Life.clip(right, br)))

def Laws.bounded_word_matches_dead_exterior(edges, around):
  match edges around:
    case Spec.distances{left, right, up, down} Spec.neighborhood{tl, tc, tr, ml, mc, mr, bl, bc, br}:
      bounded_word_proof(left, right, up, down, tl, tc, tr, ml, mc, mr, bl, bc, br)
