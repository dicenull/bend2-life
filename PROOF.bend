import Base
import ./LAWS.bend as Laws
import ./main.bend as Life
import ./proof-patterns.bend as Pattern

def Laws.underpopulation_zero(alive):
  {==}

def Laws.underpopulation_one(alive):
  {==}

def Laws.two_keeps_current_state(alive):
  {==}

def Laws.three_birth_or_survival(alive):
  {==}

def Laws.overcrowding(excess, alive):
  {==}

def Column(+n: Nat, +i: Laws.Index(n), +top: Word(n), +mid: Word(n), +bot: Word(n),
           +tw: Bool, +mw: Bool, +bw: Bool, +te: Bool, +me: Bool, +be: Bool) -> Type:
  {Laws.at(n, i, Life.scan(n, top, mid, bot, tw, mw, bw, te, me, be))
    == Laws.reference(n, i, top, mid, bot, tw, mw, bw, te, me, be) : Bool}

# k counts additional columns after the first; there is no query at width zero.
def Columns(k: Nat) -> Type:
  @+i: Laws.Index(1n+k) ->
  @+top: Word(1n+k) -> @+mid: Word(1n+k) -> @+bot: Word(1n+k) ->
  @tw: Bool -> @mw: Bool -> @bw: Bool -> @te: Bool -> @me: Bool -> @be: Bool ->
  Column(1n+k, i, top, mid, bot, tw, mw, bw, te, me, be)

def one_column(+i: Laws.Index(1n), +top: Word(1n), +mid: Word(1n), +bot: Word(1n),
               tw: Bool, mw: Bool, bw: Bool, te: Bool, me: Bool, be: Bool)
    -> Column(1n, i, top, mid, bot, tw, mw, bw, te, me, be):
  match i top mid bot:
    case Laws.Here{} WCon{tc,_} WCon{mc,_} WCon{bc,_}:
      {==}
    case Laws.There{j} _ _ _:
      match j:

def add_column(+k: Nat, previous: Columns(k),
               +i: Laws.Index(2n+k), +top: Word(2n+k), +mid: Word(2n+k), +bot: Word(2n+k),
               tw: Bool, mw: Bool, bw: Bool, te: Bool, me: Bool, be: Bool)
    -> Column(2n+k, i, top, mid, bot, tw, mw, bw, te, me, be):
  match i top mid bot:
    case Laws.Here{} WCon{tc,WCon{tn,_}} WCon{mc,WCon{mn,_}} WCon{bc,WCon{bn,_}}:
      {==}
    case Laws.There{j} WCon{tc,tr} WCon{mc,mr} WCon{bc,br}:
      previous(j, tr, mr, br, tc, mc, bc, te, me, be)

def Laws.word_matches_eight_neighbors(i, top, mid, bot, te, me, be):
  match top mid bot te me be:
    case U32{t} U32{m} U32{b}
         U32{WCon{tw,WCon{tr,_}}} U32{WCon{mw,WCon{mr,_}}} U32{WCon{bw,WCon{br,_}}}:
      Pattern.nat_induction(~Columns, ~add_column, one_column, 31n)(i, t, m, b, tw, mw, bw, tr, mr, br)
