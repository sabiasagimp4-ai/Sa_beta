# Sa_beta — ロマン

YMM4向け実験的画像処理プラグイン。1つのエフェクト内に2方式。

- **色彩地層**：明暗を層へ分割し、層ごとに変位。RGBの分離と虹色の断面発光。
- **輪郭干渉**：16方向×16距離の明暗差が波源となる、減衰するRGB干渉波。局所的な波の足し引きから発光模様を作る。物理的な回折の再現ではなく表現用。

## 導入

1. [Actions](https://github.com/sabiasagimp4-ai/Sa_beta/actions) の **YMM4 build** で成功した実行を開く。
2. Artifactsの **SaBetaYmm** をダウンロードし、外側のZIPと内側のSaBetaYmm.zipを展開。
3. YMM4を終了し、`SaBetaYmm` フォルダーを `YukkuriMovieMaker/user/plugin/` に置く。
4. YMM4を再起動。画像・動画アイテムの映像エフェクト → フィルタ → **Sa_beta ロマン**。
5. 「方式」を選び、「広がり」「層数・波数」「色の分離」「発光」を調整。「位相」にキーフレームを付けると動く。

数値スライダーは全てアニメーション対応。過去フレームを保持せずシーク順序に依存しない。EXO/AviUtl出力には非対応。

## パラメータ

|名前|範囲|地層|干渉|
|---|---|---|---|
|適用量|0–100%|原画との混合|原画との混合|
|広がり|0–512px|層の最大変位|波を探す距離|
|層数・波数|0.25–64|明暗の層密度|半径内の振動回数|
|色の分離|0–150|RGBサンプルのずれ(px)|波の色位相差＋原画減光|
|発光|0–4|断面の明るさ|干渉模様の明るさ|
|位相|−1000–1000|層と変位の進行|波の進行|
|方向|−360–360°|変位の方向|探索方向の回転|

干渉は重い実験実装（1画素につき最大257サンプル）。高波数では16段の探索が粗くなり、意図的にざらついた模様が出る。上限設定は画質保証ではなく探索用。高解像度・多重適用ではGPU負荷が高い。まず小さいプレビューで調整。

入力のアルファを保持し、フレーム外の色は端を延長して取得する。出力の領域は拡張しない。透明部分には発光を描かない。色処理は入力sRGB相当の表示色空間で行う。

## GitHubビルド

Sa_aohue のYMM版（参照コミット `e3d077f9b4711ac8e7c2268ba777c9a4eac697c6`）と同じ方式：Windows runner → .NET 10 → 公式YMM4 Liteから参照DLL取得 → Windows SDK `fxc`でHLSLコンパイル → DLLにシェーダー埋め込み → ZIP artifact。

`main`へのpush、PR、手動実行でビルド。最新YMM4 Liteを取得するため、将来のホストAPI変更によりビルドが失敗する可能性がある。ホストDLLは配布しない。

ローカルではWindows / .NET 10 SDK / Windows SDK / YMM4が必要：

```powershell
dotnet build ymm/SaBetaYmm.csproj -c Release "-p:YMM4DirPath=C:\YMM4\" "-p:FxcPath=C:\path\to\fxc.exe" "-p:D2DIncludePath=C:\path\to\WindowsSDK\um"
```

## 比較画像の再現

`ymm/Shaders/RomanCore.hlsli`をHLSLとC++で共有。別実装の近似ではなく、同じ処理本体をCPU上で実行する。GPUのテクスチャ補間精度・浮動小数点丸めはCPUと多少異なりうる。YMM4実機スクリーンショットではない。

```bash
python -m pip install numpy pillow
g++ -O3 -std=c++17 -fopenmp -shared -fPIC tests/reference.cpp -o tests/reference.so
OMP_NUM_THREADS=8 python tests/test_core.py
OMP_NUM_THREADS=8 python tests/render.py input.png outputs
```

12設定の原寸PNGと比較一覧、正確なパラメータJSONを出力する。JSONの適用量は0–1、方向はラジアン。YMM UIへの入力時は適用量×100、方向×180/πに換算。提供画像そのものはリポジトリに含めない。

## 検証範囲

共有コア：ゼロ適用、透明画像、アルファ保持、数値上限、1px画像、再実行の一致、単色の不要な波がないことを検証。Windows CIはホスト参照を使ったC#ビルド・HLSLビルド・座標入力と定数配置を検証。YMM4実機での操作・再生速度は別途確認が必要。

## v0.1.1 軽量化

輪郭干渉の方向ベクトルと波係数を、画素ごとではなくホスト側でパラメータ変更時に計算・キャッシュする。サンプル数（16×16）、位置、波形、加算順、アルファ処理は維持。定数バッファは48→560バイト。画素数に比例する追加バッファや過去フレームは使わない。

色彩地層の画像処理は変更なし。最適化前の共有コアは `tests/baseline/RomanCore.hlsli`（8522642）に凍結。比較テストは通常の85項目に加え、54条件で最適化前との数値差を検証する。

CPU基準レンダーでは添付画像の12設定で浮動小数点出力の差0を確認。GPU側の三角関数をCPUのMathFへ移したため、実GPUとのビット単位一致は保証しない。浮動小数点・三角関数実装による微小差はありうる。YMM4実機のGPU速度と画像差は未測定。CPU測定値の詳細は `docs/optimization.md`。
