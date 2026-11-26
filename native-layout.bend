import Base

# The window is 512 px square. The view and hit testing share 4 px tiles.
def board_x(w: U32) -> U32:
  U32.shr((128 - w : U32))

def board_y(h: U32) -> U32:
  (29 + U32.shr((72 - h : U32)) : U32)

def in_area(+x: U32, +y: U32, +left: U32, +top: U32, w: U32, h: U32) -> Bool:
  (x >= left && x < left + w && y >= top && y < top + h : U32)

def tool_start(i: U32) -> U32:
  (4 + 20 * i : U32)

def tool_at(+x: U32, +y: U32) -> Maybe<U32>:
  +i = U32.div((x - 4 : U32), 20)
  Bool.pick(Maybe<U32>, ((i < 5 : U32) && in_area(x,y,tool_start(i),4,14,14)), Some{i}, None{})
