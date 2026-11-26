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

## 先頭と残りの等式を組み合わせる

`cong2` は、`a = a'` と `b = b'` から、同じ2引数関数について `f(a, b) = f(a', b')` を導く。ライフゲームでは `f` にビット列のコンストラクタを渡す。既存の列の証明で先頭ビットの一致を示し、帰納法で残りのビット列の一致を示して、この2つを結合する。

この組み合わせで `neighborhood_word_matches_reference` を証明した。左隣の最終ビットと右隣の先頭ビットを切り出す処理はBendに移った。ブラウザは区画の候補値と四辺までの距離を渡し、Bendが盤面外を死セルとして処理する。JavaScriptが用意した値は、引き続き盤面テストで確認する。
