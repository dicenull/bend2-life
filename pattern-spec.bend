import Base
import ./main.bend as Life

# A finite 64 x 5 patch, with dead cells outside. Every row straddles a seam.
type Band is Data:
  band{left: U32, right: U32}

type Patch is Data:
  patch{a: Band, b: Band, c: Band, d: Band, e: Band}

def blank() -> Band:
  band{0, 0}

def step_band(above: Band, middle: Band, below: Band) -> Band:
  match above middle below:
    case band{+tl,+tr} band{+ml,+mr} band{+bl,+br}:
      band{Life.next_neighborhood(0, tl, tr, 0, ml, mr, 0, bl, br),
           Life.next_neighborhood(tl, tr, 0, ml, mr, 0, bl, br, 0)}

def step(p: Patch) -> Patch:
  match p:
    case patch{+a,+b,+c,+d,+e}:
      patch{step_band(blank(), a, b), step_band(a, b, c), step_band(b, c, d),
            step_band(c, d, e), step_band(d, e, blank())}

def block() -> Patch:
  # x = 31, 32; y = 2, 3.
  patch{blank(), blank(), band{2147483648, 1}, band{2147483648, 1}, blank()}

def horizontal() -> Patch:
  # x = 30, 31, 32; y = 2.
  patch{blank(), blank(), band{3221225472, 1}, blank(), blank()}

def vertical() -> Patch:
  # x = 31; y = 1, 2, 3.
  patch{blank(), band{2147483648, 0}, band{2147483648, 0}, band{2147483648, 0}, blank()}
