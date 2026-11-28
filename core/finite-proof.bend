import Base
import ./main.bend as Life
import ./life-spec.bend as Spec
import ./proof-checks.bend as Checks
import ./proof-patterns.bend as Pattern

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

def bounded_update_matches_reference(+edges: Spec.EdgeDistances, +around: Spec.Neighborhood)
    -> {Spec.bounded_update(edges, around) == Spec.finite_reference(edges, around) : U32}:
  match edges around:
    case Spec.distances{left, right, up, down} Spec.neighborhood{tl, tc, tr, ml, mc, mr, bl, bc, br}:
      bounded_word_proof(left, right, up, down, tl, tc, tr, ml, mc, mr, bl, bc, br)
