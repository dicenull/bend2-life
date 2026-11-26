import Base

# The window is 512 px square. The view and hit testing share 4 px tiles.
def in_area(+x: U32, +y: U32, +left: U32, +top: U32, w: U32, h: U32) -> Bool:
  (x >= left && x < left + w && y >= top && y < top + h : U32)

def tool_start(i: U32) -> U32:
  match i:
    case 6: 113
    case n: (4 + 17 * n : U32)

def tool_at(+x: U32, +y: U32) -> Maybe<U32>:
  +i = U32.div((x - 4 : U32), 17)
  regular = Bool.pick(Maybe<U32>, ((i < 6 : U32) && in_area(x,y,tool_start(i),4,14,14)), Some{i}, None{})
  Bool.pick(Maybe<U32>, in_area(x,y,tool_start(6),4,14,14), Some{6}, regular)

# Tile-space viewport, centered at (64, 65). Zoom affects presentation only.
type Cell is Data:
  CellAt{x: U32, y: U32}

def half_span(count: U32, zoom: U32) -> U32:
  U32.shr((count * zoom : U32))

def sample_axis(pos: U32, center: U32, count: U32, +zoom: U32) -> U32:
  U32.div((pos + half_span(count,zoom) - center : U32), zoom)

def in_view(+x: U32, +y: U32, +w: U32, +h: U32, +zoom: U32) -> Maybe<Cell>:
  +cx = sample_axis(x,64,w,zoom)
  +cy = sample_axis(y,65,h,zoom)
  Bool.pick(Maybe<Cell>,(x < 128 && y >= 23 && y < 107 && cx < w && cy < h : U32),
    Some{CellAt{cx,cy}},None{})

# Skip quadtree nodes that cannot intersect the visible board.
def outside_board(+x: U32, +y: U32, +size: U32, w: U32, h: U32, +zoom: U32) -> Bool:
  +hw = half_span(w,zoom)
  +hh = half_span(h,zoom)
  +left = (64 - U32.min(64,hw) : U32)
  +top = U32.max(23,(65 - U32.min(65,hh) : U32))
  +right = U32.min(128,(64 + hw : U32))
  +bottom = U32.min(107,(65 + hh : U32))
  (y >= 23 && (x + size <= left || x >= right || y + size <= top || y >= bottom) : U32)
