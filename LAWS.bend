import Base
import ./core/main.bend as Life
import ./core/life-spec.bend as Spec

law cell_follows_conway:
  for +alive: Bool
  for +neighbors: Nat
  {Life.next_cell(alive, neighbors) == Spec.conway_cell(alive, neighbors) : Bool}

# 四辺までの距離は、左右が32セル区画単位、上下が行単位。
law bounded_word_matches_dead_exterior:
  for +edges: Spec.EdgeDistances
  for +around: Spec.Neighborhood
  {Spec.bounded_update(edges, around) == Spec.finite_reference(edges, around) : U32}
