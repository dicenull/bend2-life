import Base
import ./native-board.bend as Grid
import ./native-layout.bend as Layout

type Stroke is Data:
  Idle{}
  Drawing{on: Bool}

type State is Data:
  LifeState{board: Grid.Board, running: Bool, due: Nat, space_held: Bool, stroke: Stroke}

def initial() -> State:
  LifeState{Grid.glider(96,56),False{},0n,False{},Idle{}}

def halt(s: State) -> State:
  match s:
    case LifeState{b,_,_,held,_}:
      LifeState{b,False{},0n,held,Idle{}}

def once(s: State) -> State:
  match s:
    case LifeState{b,_,_,held,_}:
      LifeState{Grid.advance(b),False{},0n,held,Idle{}}

def toggle(s: State) -> State:
  match s:
    case LifeState{b,r,_,held,_}:
      LifeState{b,Bool.not(r),0n,held,Idle{}}

def reset(code: U32, s: State) -> State:
  match code s:
    case 0 LifeState{Grid.Board{w,h,_},_,_,held,_}: LifeState{Grid.empty(w,h),False{},0n,held,Idle{}}
    case 1 LifeState{Grid.Board{w,h,_},_,_,held,_}: LifeState{Grid.glider(w,h),False{},0n,held,Idle{}}
    case 2 LifeState{Grid.Board{w,h,_},_,_,held,_}: LifeState{Grid.blinker(w,h),False{},0n,held,Idle{}}
    case _ LifeState{Grid.Board{w,h,_},_,_,held,_}: LifeState{Grid.block(w,h),False{},0n,held,Idle{}}

def size(code: U32, s: State) -> State:
  match code s:
    case 1 LifeState{b,_,_,held,_}: LifeState{Grid.resize(b,64,40),False{},0n,held,Idle{}}
    case 2 LifeState{b,_,_,held,_}: LifeState{Grid.resize(b,96,56),False{},0n,held,Idle{}}
    case _ LifeState{b,_,_,held,_}: LifeState{Grid.resize(b,128,72),False{},0n,held,Idle{}}

def cycle_size(s: State) -> State:
  match s:
    case LifeState{Grid.Board{64,+h,+t},r,d,held,p}: size(2,LifeState{Grid.Board{64,h,t},r,d,held,p})
    case LifeState{Grid.Board{96,+h,+t},r,d,held,p}: size(3,LifeState{Grid.Board{96,h,t},r,d,held,p})
    case _: size(1,s)

def tool(i: U32, s: State) -> State:
  match i:
    case 0: toggle(s)
    case 1: once(s)
    case 2: reset(0,s)
    case 3: reset(1,s)
    case _: cycle_size(s)

def release(s: State) -> State:
  match s:
    case LifeState{b,r,d,h,_}: LifeState{b,r,d,h,Idle{}}

def focus_lost(s: State) -> State:
  match s:
    case LifeState{b,r,d,_,_}: LifeState{b,r,d,False{},Idle{}}

def space(down: Bool, s: State) -> State:
  match down s:
    case True{} LifeState{b,r,d,True{},p}: LifeState{b,r,d,True{},p}
    case True{} LifeState{b,r,_,False{},_}: LifeState{b,Bool.not(r),0n,True{},Idle{}}
    case False{} LifeState{b,r,d,_,p}: LifeState{b,r,d,False{},p}

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
    case _ _: Some{s}

def place(inside: Bool, start: Bool, +s: State, +x: U32, +y: U32) -> State:
  match inside start s:
    case True{} True{} LifeState{+b,_,_,held,_}:
      +on = U32.is_zero(Grid.get(b,x,y))
      LifeState{Grid.paint(b,x,y,on),False{},0n,held,Drawing{on}}
    case True{} False{} LifeState{b,r,d,held,Drawing{+on}}:
      LifeState{Grid.paint(b,x,y,on),r,d,held,Drawing{on}}
    case _ _ _: s

def pointer_at(start: Bool, +x: U32, +y: U32, +s: State) -> State:
  LifeState{Grid.Board{w,h,_},_,_,_,_} = s
  +left = Layout.board_x(w)
  +top = Layout.board_y(h)
  place(Layout.in_area(x,y,left,top,w,h), start, s, (x - left : U32), (y - top : U32))

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
    case True{} LifeState{b,r,_,held,p}:
      LifeState{Grid.advance(b),r,Nat.add(now,135n),held,p}
    case False{} _: s

def clock_step(+now: Nat, +s: State) -> State:
  LifeState{_,running,due,_,_} = s
  due_step(Bool.and(running,Nat.is_ge(now,due)),now,s)

def event_redraw(e: Event, stroke: Stroke) -> Bool:
  match e stroke:
    case Move{0,_,_,_,_} Drawing{_}: True{}
    case Press{0,_,_,_,_,0,True{}} _: True{}
    case Key{_,True{}} _: True{}
    case _ _: False{}

def repaint_for(+e: Event, +s: State, dirty: Bool) -> Maybe<State> & Bool:
  LifeState{_,_,_,_,p} = s
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
  LifeState{_,r,d,_,_} = s
  Bool.and(r,Nat.is_ge(now,d))

def finish_frame(+now: Nat, result: Maybe<State> & Bool) -> Maybe<State> & Bool:
  match result:
    case Tuple{None{},dirty}: (None{},dirty)
    case Tuple{Some{+s},dirty}:
      (Some{clock_step(now,s)},Bool.or(dirty,due_for_redraw(now,s)))
