import Base
import ./LAWS.bend as Laws
import ./core/proof-checks.bend as Checks
import ./core/finite-proof.bend as Finite

def Laws.cell_follows_conway(alive, neighbors):
  match neighbors:
    case 0n:
      Checks.underpopulation_zero(alive)
    case 1n:
      Checks.underpopulation_one(alive)
    case 2n:
      Checks.two_keeps_current_state(alive)
    case 3n:
      Checks.three_birth_or_survival(alive)
    case 4n+excess:
      Checks.overcrowding(excess, alive)

def Laws.bounded_word_matches_dead_exterior(edges, around):
  Finite.bounded_update_matches_reference(edges, around)
