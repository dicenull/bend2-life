# ライフゲーム / Bend 2

Conwayのライフゲーム。Web版とMac版は、盤面を1世代進める [Bend 2の実装](core/main.bend) を共有します。

## 起動

- **Web:** リポジトリを取得して [`web/index.html`](web/index.html) をブラウザで開きます。
- **Mac:** Bend 2とXcode Command Line Toolsを用意して、リポジトリ直下で実行します。

```sh
./desktop/build-native.sh
open 'desktop/.build/Bend 2 Life.app'
```

## LAW

[`LAWS.bend`](LAWS.bend) の2本を [`PROOF.bend`](PROOF.bend) で検証します。

[証明とテストの分け方](docs/proof-vs-tests.md) · [証明パターン](docs/proof-patterns.md)

## ビルドと検証

[Bend 2.0.40](https://github.com/bendlang/bend/tree/6180be5b21c4af6895395b27ad3cde026909364e) とNode.jsを使用します。

```sh
bend PROOF.bend
node web/build.mjs
node web/test.mjs
node desktop/native-test.mjs
```

生成コードに含まれるBendランタイムのライセンスは [`BEND-LICENSE.txt`](BEND-LICENSE.txt) を参照。

## BendTTカーネルでの再検証

Lean 4.34.0を用意して、独立したBendTTカーネルで再検証します。

```sh
bend PROOF.bend --verdict
```
