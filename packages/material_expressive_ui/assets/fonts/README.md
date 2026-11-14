# Fonts

Built by `tools/expressive_tokens/fonts/build.py` from pinned upstream bytes
(`sources.json`: URL + SHA-256; wave decision E7). Never edit them by hand;
`fonts.test.ts` holds each to the bytes `fonts.json` records.

| File | What | Licence |
| --- | --- | --- |
| `RobotoFlex.ttf` | Roboto Flex, Latin + Latin-ext, variable `wght` + `opsz`, hinting dropped (≤ 400 KB) | OFL-1.1, `LICENSES/RobotoFlex-OFL-1.1.txt` |
| `MaterialSymbolsRounded.ttf` | Material Symbols Rounded, the `symbols.txt` subset, variable `FILL` (wght 400, GRAD 0, opsz 24 pinned) | Apache-2.0, `LICENSES/MaterialSymbols-Apache-2.0.txt` |

Notices: `../../THIRD_PARTY_NOTICES/`. Roboto Flex only: never Google Sans,
Product Sans or Google Symbols (CONTRACT §6).
