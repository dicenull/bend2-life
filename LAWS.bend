import Base
import ./core/main.bend as Life
import ./core/life-spec.bend as Spec
import ./core/wrap.bend as Wrap
import ./core/wrap-spec.bend as Wrapped

law cell_follows_conway:
  for +alive: Bool
  for +neighbors: Nat
  {Life.next_cell(alive, neighbors) == Spec.conway_cell(alive, neighbors) : Bool}

# 四辺までの距離は、左右が32セル区画単位、上下が行単位。
law bounded_word_matches_dead_exterior:
  for +edges: Spec.EdgeDistances
  for +around: Spec.Neighborhood
  {Spec.bounded_update(edges, around) == Spec.finite_reference(edges, around) : U32}

# 左右は32セル区画、上下は行を単位に、反対端へつなぐ。
law wrapped_word_matches_opposite_edges:
  for +col: Wrap.Position
  for +row: Wrap.Position
  for +board: Wrap.Board
  {Wrap.update(col, row, board) == Wrapped.reference(col, row, board) : U32}
