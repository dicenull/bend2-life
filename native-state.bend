import Base
import ./native-board.bend as Grid
import ./native-layout.bend as Layout

type Stroke is Data:
  Idle{}
  Drawing{on: Bool}

type State is Data:
  LifeState{board: Grid.Board, running: Bool, due: Nat, space_held: Bool, stroke: Stroke, zoom: U32}

def initial() -> State:
  LifeState{Grid.glider(96,56),False{},0n,False{},Idle{},1}

def halt(s: State) -> State:
  match s:
    case LifeState{b,_,_,held,_,z}:
      LifeState{b,False{},0n,held,Idle{},z}

def once(s: State) -> State:
  match s:
    case LifeState{b,_,_,held,_,z}:
      LifeState{Grid.advance(b),False{},0n,held,Idle{},z}

def toggle(s: State) -> State:
  match s:
    case LifeState{b,r,_,held,_,z}:
      LifeState{b,Bool.not(r),0n,held,Idle{},z}

def reset(code: U32, s: State) -> State:
  match code s:
    case 0 LifeState{Grid.Board{w,h,_},_,_,held,_,z}: LifeState{Grid.empty(w,h),False{},0n,held,Idle{},z}
    case 1 LifeState{Grid.Board{w,h,_},_,_,held,_,z}: LifeState{Grid.glider(w,h),False{},0n,held,Idle{},z}
    case 2 LifeState{Grid.Board{w,h,_},_,_,held,_,z}: LifeState{Grid.blinker(w,h),False{},0n,held,Idle{},z}
    case _ LifeState{Grid.Board{w,h,_},_,_,held,_,z}: LifeState{Grid.block(w,h),False{},0n,held,Idle{},z}

def size(code: U32, s: State) -> State:
  match code s:
    case 1 LifeState{b,_,_,held,_,z}: LifeState{Grid.resize(b,64,40),False{},0n,held,Idle{},z}
    case 2 LifeState{b,_,_,held,_,z}: LifeState{Grid.resize(b,96,56),False{},0n,held,Idle{},z}
    case _ LifeState{b,_,_,held,_,z}: LifeState{Grid.resize(b,128,72),False{},0n,held,Idle{},z}

def cycle_size(s: State) -> State:
  match s:
    case LifeState{Grid.Board{64,+h,+t},r,d,held,p,z}: size(2,LifeState{Grid.Board{64,h,t},r,d,held,p,z})
    case LifeState{Grid.Board{96,+h,+t},r,d,held,p,z}: size(3,LifeState{Grid.Board{96,h,t},r,d,held,p,z})
    case _: size(1,s)

def magnify(more: Bool, z: U32) -> U32:
  match more:
    case True{}: U32.min(4,U32.shl(z))
    case False{}: U32.max(1,U32.shr(z))

def zoom(more: Bool, s: State) -> State:
  match s:
    case LifeState{b,r,d,held,_,z}:
      LifeState{b,r,d,held,Idle{},magnify(more,z)}

def tool(i: U32, s: State) -> State:
  match i:
    case 0: toggle(s)
    case 1: once(s)
    case 2: reset(0,s)
    case 3: reset(1,s)
    case 4: cycle_size(s)
    case 5: zoom(False{},s)
    case _: zoom(True{},s)

def release(s: State) -> State:
  match s:
    case LifeState{b,r,d,h,_,z}: LifeState{b,r,d,h,Idle{},z}

def focus_lost(s: State) -> State:
  match s:
    case LifeState{b,r,d,_,_,z}: LifeState{b,r,d,False{},Idle{},z}

def space(down: Bool, s: State) -> State:
  match down s:
    case True{} LifeState{b,r,d,True{},p,z}: LifeState{b,r,d,True{},p,z}
    case True{} LifeState{b,r,_,False{},_,z}: LifeState{b,Bool.not(r),0n,True{},Idle{},z}
    case False{} LifeState{b,r,d,_,p,z}: LifeState{b,r,d,False{},p,z}

def key(code: U32, down: Bool, s: State) -> Maybe<State>:
  match code down:
    case 27 True{}: None{}
    case 32 d: Some{space(d,s)}
    case 63235 True{}: Some{once(s)}
    case 99 True{}: Some{reset(0,s)}
    case 103 True{}: Some{reset(1,s)}
    case 98 True{}: Some{reset(2,s)}
    case 111 True{}: Some{reset(3,s)}
    case 49 True{}: Some{size(1,s)}
    case 50 True{}: Some{size(2,s)}
    case 51 True{}: Some{size(3,s)}
    case 45 True{}: Some{zoom(False{},s)}
    case 43 True{}: Some{zoom(True{},s)}
    case 61 True{}: Some{zoom(True{},s)}
    case _ _: Some{s}

def place(inside: Bool, start: Bool, +s: State, +x: U32, +y: U32) -> State:
  match inside start s:
    case True{} True{} LifeState{+b,_,_,held,_,z}:
      +on = U32.is_zero(Grid.get(b,x,y))
      LifeState{Grid.paint(b,x,y,on),False{},0n,held,Drawing{on},z}
    case True{} False{} LifeState{b,r,d,held,Drawing{+on},z}:
      LifeState{Grid.paint(b,x,y,on),r,d,held,Drawing{on},z}
    case _ _ _: s

def point_at(point: Maybe<Layout.Cell>, start: Bool, s: State) -> State:
  match point:
    case Some{Layout.CellAt{x,y}}: place(True{},start,s,x,y)
    case None{}: s

def pointer_at(start: Bool, x: U32, y: U32, +s: State) -> State:
  LifeState{Grid.Board{w,h,_},_,_,_,_,z} = s
  point_at(Layout.in_view(x,y,w,h,z),start,s)

def click(at: Maybe<U32>, +x: U32, +y: U32, s: State) -> State:
  match at:
    case Some{i}: tool(i,s)
    case None{}: pointer_at(True{},x,y,s)

def pointer(valid: Bool, start: Bool, x: F32, y: F32, s: State) -> State:
  match valid start:
    case True{} True{}:
      +tx = U32.shrn(F32.to_u32(x),2n)
      +ty = U32.shrn(F32.to_u32(y),2n)
      click(Layout.tool_at(tx,ty),tx,ty,s)
    case True{} False{}:
      pointer_at(False{}, U32.shrn(F32.to_u32(x),2n), U32.shrn(F32.to_u32(y),2n), s)
    case _ _: s

def valid_point(+x: F32, +y: F32) -> Bool:
  (x >= 0.0 && x < 512.0 && y >= 0.0 && y < 512.0 : F32)

def event(e: Event, s: State) -> Maybe<State>:
  match e:
    case Close{}: None{}
    case Key{code,down}: key(code,down,s)
    case Press{0,_,+x,+y,_,0,True{}}: Some{pointer(valid_point(x,y),True{},x,y,s)}
    case Press{0,_,_,_,_,0,False{}}: Some{release(s)}
    case Move{0,_,+x,+y,_}: Some{pointer(valid_point(x,y),False{},x,y,s)}
    case Lost{0}: Some{release(s)}
    case Focus{False{}}: Some{focus_lost(s)}
    case _: Some{s}

def due_step(ready: Bool, +now: Nat, s: State) -> State:
  match ready s:
    case True{} LifeState{b,r,_,held,p,z}:
      LifeState{Grid.advance(b),r,Nat.add(now,135n),held,p,z}
    case False{} _: s

def clock_step(+now: Nat, +s: State) -> State:
  LifeState{_,running,due,_,_,_} = s
  due_step(Bool.and(running,Nat.is_ge(now,due)),now,s)

def event_redraw(e: Event, stroke: Stroke) -> Bool:
  match e stroke:
    case Move{0,_,_,_,_} Drawing{_}: True{}
    case Press{0,_,_,_,_,0,True{}} _: True{}
    case Key{_,True{}} _: True{}
    case _ _: False{}

def repaint_for(+e: Event, +s: State, dirty: Bool) -> Maybe<State> & Bool:
  LifeState{_,_,_,_,p,_} = s
  (event(e,s), Bool.or(dirty,event_redraw(e,p)))

def advance_events(more: State -> Bool -> Maybe<State> & Bool, result: Maybe<State> & Bool) -> Maybe<State> & Bool:
  match result:
    case Tuple{Some{s},changed}: more(s,changed)
    case Tuple{None{},changed}: (None{},changed)

def events_dirty(es: List<Event>, s: State, dirty: Bool) -> Maybe<State> & Bool:
  match es:
    case []: (Some{s},dirty)
    case e <> rest:
      next = repaint_for(e,s,dirty)
      advance_events(s2 => changed => events_dirty(rest,s2,changed),next)

def due_for_redraw(now: Nat, s: State) -> Bool:
  LifeState{_,r,d,_,_,_} = s
  Bool.and(r,Nat.is_ge(now,d))

def finish_frame(+now: Nat, result: Maybe<State> & Bool) -> Maybe<State> & Bool:
  match result:
    case Tuple{None{},dirty}: (None{},dirty)
    case Tuple{Some{+s},dirty}:
      (Some{clock_step(now,s)},Bool.or(dirty,due_for_redraw(now,s)))
