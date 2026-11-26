import Base
import ./native-board.bend as Grid
import ./native-layout.bend as Layout
import ./native-state.bend as Model

# Center a 5 x 5 glyph at 2x scale inside each 14 x 14 tile button.
def icon(i: U32, running: Bool, width: U32) -> U32:
  match i running width:
    case 0 True{} _: 29224827
    case 0 False{} _: 1309921
    case 1 _ _: 18472561
    case 2 _ _: 15018990
    case 3 _ _: 22036484
    case 5 _ _: 31744
    case 6 _ _: 4357252
    case 4 _ 64: 32641220
    case 4 _ 96: 32553487
    case _ _ _: 16267791

def glyph_on(inside: Bool, glyph: U32, x: U32, y: U32) -> Bool:
  match inside:
    case False{}: False{}
    case True{}:
      shift = (5 * U32.shr((y - 6 : U32)) + U32.shr((x - 2 : U32)) : U32)
      U32.is_ne(U32.and(U32.shrn(glyph, U32.to_nat(shift)),1),0)

def icon_ink(i: U32, z: U32) -> U32:
  match i z:
    case 5 1: 7762030
    case 6 4: 7762030
    case _ _: 16763543

def button_face(+i: U32, +lx: U32, +y: U32, running: Bool, width: U32, z: U32) -> U32:
  face = Bool.pick(U32, (U32.is_eq(lx,0) || U32.is_eq(lx,13) || U32.is_eq(y,4) || U32.is_eq(y,17)), 4015707, 2435391)
  on = glyph_on(Layout.in_area(lx,y,2,6,10,10), icon(i,running,width),lx,y)
  Bool.pick(U32,on,icon_ink(i,z),face)

def header(at: Maybe<U32>, x: U32, +y: U32, running: Bool, width: U32, z: U32) -> U32:
  match at:
    case Some{+i}: button_face(i,(x - Layout.tool_start(i) : U32),y,running,width,z)
    case None{}: Bool.pick(U32,U32.is_eq(y,22),4015707,1185563)

def cell_phase(alive: U32, x: U32, y: U32) -> U32:
  match alive:
    case 0: Bool.pick(U32,U32.is_zero(U32.and(U32.xor(x,y),1)), 1909042, 2040885)
    case _: 16759152

def cell(at: Maybe<Layout.Cell>, board: Grid.Board) -> U32:
  match at:
    case None{}: 1185563
    case Some{Layout.CellAt{+x,+y}}: cell_phase(Grid.get(board,x,y),x,y)

def color(+x: U32, +y: U32, s: Model.State) -> U32:
  Model.LifeState{+board,r,_,_,_,+z} = s
  Grid.Board{+w,h,_} = board
  Bool.pick(U32, (y < 23 : U32),
    header(Layout.tool_at(x,y),x,y,r,w,z),
    cell(Layout.in_view(x,y,w,h,z),board))

def outside(x: U32, y: U32, size: U32, s: Model.State) -> Bool:
  Model.LifeState{Grid.Board{w,h,_},_,_,_,_,z} = s
  Layout.outside_board(x,y,size,w,h,z)

def draw(+depth: Nat, skip: Bool, +x: U32, +y: U32, +s: Model.State) -> Image:
  match depth skip:
    case _ True{}:
      Pix{1185563}
    case 0n False{}:
      Pix{color(x,y,s)}
    case 1n+k False{}:
      +half = U32.shln(1,k)
      +x1 = (x + half : U32)
      +y1 = (y + half : U32)
      Qua{draw(k,outside(x,y,half,s),x,y,s), draw(k,outside(x1,y,half,s),x1,y,s),
          draw(k,outside(x,y1,half,s),x,y1,s), draw(k,outside(x1,y1,half,s),x1,y1,s)}

def render(s: Model.State) -> Image:
  draw(7n,False{},0,0,s)
