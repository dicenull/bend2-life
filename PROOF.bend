import Base
import ./LAWS.bend as Laws
import ./main.bend as Life

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

# Here: inspect the current column and its right neighbor (or the boundary).
# There: slide one column and apply the induction hypothesis to the tails.
def every_column(+n: Nat, +i: Laws.Index(n), +top: Word(n), +mid: Word(n), +bot: Word(n),
                 tw: Bool, mw: Bool, bw: Bool, te: Bool, me: Bool, be: Bool)
    -> {Laws.at(n, i, Life.scan(n, top, mid, bot, tw, mw, bw, te, me, be))
        == Laws.reference(n, i, top, mid, bot, tw, mw, bw, te, me, be) : Bool}:
  match n:
    case 0n:
      match i:
    case 1n:
      match i top mid bot:
        case Laws.Here{} WCon{tc,_} WCon{mc,_} WCon{bc,_}:
          {==}
        case Laws.There{j} _ _ _:
          match j:
    case 2n+r:
      match i top mid bot:
        case Laws.Here{} WCon{tc,WCon{tn,_}} WCon{mc,WCon{mn,_}} WCon{bc,WCon{bn,_}}:
          {==}
        case Laws.There{j} WCon{tc,tr} WCon{mc,mr} WCon{bc,br}:
          every_column(1n+r, j, tr, mr, br, tc, mc, bc, te, me, be)

def Laws.word_matches_eight_neighbors(i, top, mid, bot, te, me, be):
  match top mid bot te me be:
    case U32{t} U32{m} U32{b}
         U32{WCon{tw,WCon{tr,_}}} U32{WCon{mw,WCon{mr,_}}} U32{WCon{bw,WCon{br,_}}}:
      every_column(32n, i, t, m, b, tw, mw, bw, tr, mr, br)
