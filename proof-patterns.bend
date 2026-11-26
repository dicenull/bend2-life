import Base

# Supply what to prove (P), a proof at zero, and how to advance it.
# The template arguments are fixed definitions, not an extensible tactic engine.
def nat_induction(~P: Nat -> Type, ~step: @+k: Nat -> P(k) -> P(1n+k), base: P(0n), +n: Nat) -> P(n):
  match n:
    case 0n:
      base
    case 1n+k:
      step(k, nat_induction(~P, ~step, base, k))
