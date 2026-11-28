import Base
import ../core/main.bend as Engine

# 盤面の幅にかかわらず、木のアドレスは1行を4区画として計算する。
type Words is Data:
  WordZero{}
  WordLeaf{bits: U32}
  WordBranch{lo: Words, hi: Words}

type Board is Data:
  Board{width: U32, height: U32, words: Words}

def pick_tree(take_lo: Bool, lo: Words, hi: Words) -> Words:
  match take_lo:
    case True{}: lo
    case False{}: hi

def read(+depth: Nat, tree: Words, +i: U32) -> U32:
  match depth:
    case 0n:
      match tree:
        case WordLeaf{bits}: bits
        case _: 0
    case 1n+k:
      match tree:
        case WordBranch{lo,hi}:
          read(k, pick_tree(U32.is_zero(U32.and(i, U32.shln(1,k))), lo, hi), i)
        case _: 0

def leaf(empty: Bool, bits: U32) -> Words:
  match empty:
    case True{}: WordZero{}
    case False{}: WordLeaf{bits}

def branch(lo: Words, hi: Words) -> Words:
  match lo hi:
    case WordZero{} WordZero{}: WordZero{}
    case l h: WordBranch{l,h}

def children(tree: Words) -> Words & Words:
  match tree:
    case WordBranch{lo,hi}: (lo,hi)
    case _: (WordZero{},WordZero{})

def write(+depth: Nat, +tree: Words, +i: U32, +bits: U32) -> Words:
  match depth:
    case 0n:
      leaf(U32.is_zero(bits), bits)
    case 1n+k:
      +lo = Pair.fst(Words, Words, children(tree))
      +hi = Pair.snd(Words, Words, children(tree))
      +left = U32.is_zero(U32.and(i, U32.shln(1,k)))
      +child = write(k, pick_tree(left, lo, hi), i, bits)
      branch(pick_tree(left, child, lo), pick_tree(left, hi, child))

def address(col: U32, y: U32) -> U32:
  (y * 4 + col : U32)

def empty(width: U32, height: U32) -> Board:
  Board{width, height, WordZero{}}

def get.in_bounds(inside: Bool, tree: Words, +x: U32, y: U32) -> U32:
  match inside:
    case False{}: 0
    case True{}:
      U32.and(U32.shrn(read(9n, tree, address(U32.shrn(x,5n), y)), U32.to_nat(U32.and(x,31))), 1)

def get(+board: Board, +x: U32, +y: U32) -> U32:
  Board{w,h,tree} = board
  get.in_bounds((x < w && y < h : U32), tree, x, y)

def bit_write(on: Bool, bits: U32, mask: U32) -> U32:
  match on:
    case True{}: U32.or(bits, mask)
    case False{}: U32.and(bits, U32.not(mask))

def paint.in_bounds(inside: Bool, +board: Board, +x: U32, y: U32, on: Bool) -> Board:
  match inside:
    case False{}: board
    case True{}:
      Board{w,h,+tree} = board
      +i = address(U32.shrn(x,5n), y)
      bits = bit_write(on, read(9n, tree, i), U32.shln(1, U32.to_nat(U32.and(x,31))))
      Board{w,h,write(9n, tree, i, bits)}

def paint(+board: Board, +x: U32, +y: U32, on: Bool) -> Board:
  Board{w,h,_} = board
  paint.in_bounds((x < w && y < h : U32), board, x, y, on)

def projected(tree: Words, i: U32) -> U32:
  read(9n, tree, U32.and(i,511))

def updated(+tree: Words, +w: U32, +h: U32, +col: U32, +y: U32) -> U32:
  +i = address(col,y)
  Engine.next_bounded(U32.to_nat(col), U32.to_nat((w - 1 - col : U32)),
    U32.to_nat(y), U32.to_nat((h - 1 - y : U32)),
    projected(tree, (i - 5 : U32)), projected(tree, (i - 4 : U32)), projected(tree, (i - 3 : U32)),
    projected(tree, (i - 1 : U32)), projected(tree, i), projected(tree, (i + 1 : U32)),
    projected(tree, (i + 3 : U32)), projected(tree, (i + 4 : U32)), projected(tree, (i + 5 : U32)))

def put_word(zero: Bool, out: Words, i: U32, bits: U32) -> Words:
  match zero:
    case True{}: out
    case False{}: write(9n, out, i, bits)

def row_step(+columns: Nat, +tree: Words, +w: U32, +h: U32, +y: U32, out: Words) -> Words:
  match columns:
    case 0n: out
    case 1n+k:
      +col = U32.from_nat(k)
      +bits = updated(tree,w,h,col,y)
      row_step(k, tree, w, h, y, put_word(U32.is_zero(bits),out,address(col,y),bits))

def rows_step(+rows: Nat, +tree: Words, +w: U32, +h: U32, out: Words) -> Words:
  match rows:
    case 0n: out
    case 1n+k:
      rows_step(k, tree, w, h, row_step(U32.to_nat(w),tree,w,h,U32.from_nat(k),out))

def advance(board: Board) -> Board:
  match board:
    case Board{+w,+h,tree}:
      Board{w,h,rows_step(U32.to_nat(h),tree,U32.shrn(w,5n),h,WordZero{})}

def row_copy(+columns: Nat, +tree: Words, +y: U32, out: Words) -> Words:
  match columns:
    case 0n: out
    case 1n+k:
      +i = address(U32.from_nat(k),y)
      +bits = read(9n,tree,i)
      row_copy(k,tree,y,put_word(U32.is_zero(bits),out,i,bits))

def rows_copy(+rows: Nat, +columns: Nat, +tree: Words, out: Words) -> Words:
  match rows:
    case 0n: out
    case 1n+k:
      rows_copy(k,columns,tree,row_copy(columns,tree,U32.from_nat(k),out))

def resize(board: Board, +new_width: U32, +new_height: U32) -> Board:
  match board:
    case Board{w,h,tree}:
      +columns = U32.to_nat(U32.shrn(U32.min(w,new_width),5n))
      Board{new_width,new_height,rows_copy(U32.to_nat(U32.min(h,new_height)),columns,tree,WordZero{})}

def glider(+w: U32, +h: U32) -> Board:
  +x = (U32.shr(w) - 1 : U32)
  +y = (U32.shr(h) - 1 : U32)
  a = paint(empty(w,h), (x + 1 : U32), y, True{})
  b = paint(a, (x + 2 : U32), (y + 1 : U32), True{})
  c = paint(b, x, (y + 2 : U32), True{})
  d = paint(c, (x + 1 : U32), (y + 2 : U32), True{})
  paint(d, (x + 2 : U32), (y + 2 : U32), True{})

def blinker(+w: U32, +h: U32) -> Board:
  +x = (U32.shr(w) - 1 : U32)
  +y = U32.shr(h)
  a = paint(empty(w,h),x,y,True{})
  b = paint(a,(x + 1 : U32),y,True{})
  paint(b,(x + 2 : U32),y,True{})

def block(+w: U32, +h: U32) -> Board:
  +x = (U32.shr(w) - 1 : U32)
  +y = (U32.shr(h) - 1 : U32)
  a = paint(empty(w,h),x,y,True{})
  b = paint(a,(x + 1 : U32),y,True{})
  c = paint(b,x,(y + 1 : U32),True{})
  paint(c,(x + 1 : U32),(y + 1 : U32),True{})
