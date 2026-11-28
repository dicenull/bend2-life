import Base
import ./pattern-spec.bend as Pattern
import ./main.bend as Life
import ./life-spec.bend as Spec

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

law seam_block_is_still:
  {Pattern.step(Pattern.block()) == Pattern.block() : Pattern.Patch}

law seam_blinker_turns_vertical:
  {Pattern.step(Pattern.horizontal()) == Pattern.vertical() : Pattern.Patch}

law seam_blinker_returns_after_two:
  {Pattern.step(Pattern.step(Pattern.horizontal())) == Pattern.horizontal() : Pattern.Patch}

law exterior_is_dead:
  for candidate: U32
  {Life.clip(0n, candidate) == 0 : U32}

law interior_is_unchanged:
  for rest: Nat
  for candidate: U32
  {Life.clip(1n+rest, candidate) == candidate : U32}

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
