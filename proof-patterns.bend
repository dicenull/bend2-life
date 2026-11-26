import Base

# Supply what to prove (P), a proof at zero, and how to advance it.
# The template arguments are fixed definitions, not an extensible tactic engine.
def nat_induction(~P: Nat -> Type, ~step: @+k: Nat -> P(k) -> P(1n+k), base: P(0n), +n: Nat) -> P(n):
  match n:
    case 0n:
      base
    case 1n+k:
      step(k, nat_induction(~P, ~step, base, k))

# Lift two independent equalities through the same two-argument function.
def cong2(-A: Type, -B: Type, -C: Type, -f: A -> B -> C,
          -a: A, -a2: A, -b: B, -b2: B, first: {a == a2 : A}, second: {b == b2 : B})
    -> {f(a, b) == f(a2, b2) : C}:
  %first : {f(a, b) == f(_, b2) : C}
  %second : {f(a, b) == f(a, _) : C}
  {==}
