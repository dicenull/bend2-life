import Base

def nat_induction(~P: Nat -> Type, ~step: @+k: Nat -> P(k) -> P(1n+k), base: P(0n), +n: Nat) -> P(n):
  match n:
    case 0n:
      base
    case 1n+k:
      step(k, nat_induction(~P, ~step, base, k))

def cong2(-A: Type, -B: Type, -C: Type, -f: A -> B -> C,
          -a: A, -a2: A, -b: B, -b2: B, first: {a == a2 : A}, second: {b == b2 : B})
    -> {f(a, b) == f(a2, b2) : C}:
  %first : {f(a, b) == f(_, b2) : C}
  %second : {f(a, b) == f(a, _) : C}
  {==}

def Vec(-A: Data, n: Nat) -> Data:
  match n:
    case 0n:
      VectorNil
    case 1n+k:
      VectorCons<A, k>

type VectorNil is Data:
  VNil{}

type VectorCons<-A: Data, -k: Nat> is Data:
  VCons{head: A, tail: Vec(A, k)}

def vec_map(~A: Data, ~B: Data, ~f: A -> B, n: Nat, xs: Vec(A, n)) -> Vec(B, n):
  match n:
    case 0n:
      VNil{}
    case 1n+k:
      match xs:
        case VCons{head, tail}:
          VCons{f(head), vec_map(~A, ~B, ~f, k, tail)}

def map_cong(~A: Data, ~B: Data, ~f: A -> B, ~g: A -> B,
             ~same: @+x: A -> {f(x) == g(x) : B},
             +n: Nat, +xs: Vec(A, n))
    -> {vec_map(~A, ~B, ~f, n, xs) == vec_map(~A, ~B, ~g, n, xs) : Vec(B, n)}:
  match n:
    case 0n:
      {==}
    case 1n+k:
      match xs:
        case VCons{+head, +tail}:
          %same(head) : {VCons{f(head), vec_map(~A, ~B, ~f, k, tail)} == VCons{_, vec_map(~A, ~B, ~g, k, tail)} : Vec(B, 1n+k)}
          %map_cong(~A, ~B, ~f, ~g, ~same, k, tail) : {VCons{f(head), vec_map(~A, ~B, ~f, k, tail)} == VCons{f(head), _} : Vec(B, 1n+k)}
          {==}
