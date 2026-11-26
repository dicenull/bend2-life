# Conway B3/S23: cases cover all natural neighbor counts.
import Base
import ./main.bend as Life

law underpopulation_zero:
  for alive: Bool
  {Life.next_cell(alive, 0n) == False{} : Bool}

law underpopulation_one:
  for alive: Bool
  {Life.next_cell(alive, 1n) == False{} : Bool}

law two_keeps_current_state:
  for alive: Bool
  {Life.next_cell(alive, 2n) == alive : Bool}

law three_birth_or_survival:
  for alive: Bool
  {Life.next_cell(alive, 3n) == True{} : Bool}

law overcrowding:
  for excess: Nat
  for alive: Bool
  {Life.next_cell(alive, 4n+excess) == False{} : Bool}
