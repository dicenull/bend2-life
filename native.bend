import Base
import ./native-state.bend as Model
import ./native-view.bend as View

# Only the window adapter knows about the OS and the clock.
def resume(result: Maybe<Model.State> & Bool, window: Window, image: Image,
           more: Window -> Model.State -> Image -> IO(Unit)) -> IO(Unit):
  match result:
    case Tuple{None{},_}:
      do IO<Unit>:
        Unit <- IO.pure(Unit, Image.drop(image))
        Window.close(window)
    case Tuple{Some{s},False{}}:
      more(window,s,image)
    case Tuple{Some{+s},True{}}:
      do IO<Unit>:
        Unit <- IO.pure(Unit, Image.drop(image))
        more(window,s,View.render(s))

def present(shown: Window & Image & List<Event>, state: Model.State,
            more: Window -> Model.State -> Image -> IO(Unit)) -> IO(Unit):
  (window, image, events) = shown
  do IO<Unit>:
    now : Nat <- IO.now()
    resume(Model.finish_frame(now,Model.events_dirty(events,state,False{})),window,image,more)

# Use the standard window effects without requiring a GPU compiler.
def run(fuel: Nat, window: Window, state: Model.State, image: Image) -> IO(Unit):
  match fuel:
    case 0n: Window.close(window)
    case 1n+left:
      do IO<Unit>:
        shown : Window & Image & List<Event> <- Window.frame(window,image)
        present(shown,state,w => m => img => run(left,w,m,img))

def main() -> IO(Unit):
  do IO<Unit>:
    window : Window <- IO.try(Window, Window.open("Bend 2 Life",512,512))
    +initial : Model.State = Model.initial()
    run(4294967295n,window,initial,View.render(initial))
