# 証明パターン

[What is Bend2?](https://bend2.dev/notes/what-is-bend2/) にある「小さい入力の証明を帰納法の仮定として使う」書き方を、`proof-patterns.bend` の `nat_induction` に切り出した。自動で証明を探す仕組みではなく、再利用できる普通のBendの定義。

- `~P`: 「各 `n` で何を証明するか」を表す型。
- `base`: `P(0)` の証明。
- `~step`: `P(k)` の証明を受け取り、`P(k+1)` の証明を返す関数。

`PROOF.bend` では `P(k)` を「幅 `k+1` の全列が参照版と一致する」にした。幅1の証明 `one_column` と、列を増やす証明 `add_column` を渡し、`k=31` で幅32を得る。ここでは `P(k)` 自体が「任意の列と入力に対して」を含む。盤面の仕様は `LAWS.bend`、走査の実装は `main.bend` のまま。

## 別の例：どんな自然数も0を足せば元の値

リポジトリ直下に次を `example.bend` として置き、`bend example.bend` で確認できる。

```text
import Base
import ./proof-patterns.bend as Pattern

def KeepsValue(n: Nat) -> Type:
  {Nat.add(n, 0n) == n : Nat}

def at_zero() -> KeepsValue(0n):
  {==}

def one_more(+n: Nat, previous: KeepsValue(n)) -> KeepsValue(1n+n):
  Equal.cong(Nat, Nat, k => 1n+k, Nat.add(n, 0n), n, previous)

law add_zero:
  for +n: Nat
  KeepsValue(n)

def add_zero(n):
  Pattern.nat_induction(~KeepsValue, ~one_more, at_zero(), n)
```
