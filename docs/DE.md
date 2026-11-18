# shae-haskell-expression-evaluator (Deutsch)

Ein kleiner rekursiver Ausdrucksauswerter in echtem Haskell. Parst und
wertet arithmetische Ausdrücke mit Ganzzahl- und Gleitkommaliteralen, `+
- * /`, Klammern und `let`-gebundenen Variablen aus. Meldet
Division-durch-Null-und undefinierte-Variablen-Fehler.

## Anforderungen

- **GHC** (Glasgow Haskell Compiler) — nicht lokal installiert. Siehe
  `scripts/install.sh`.

## Installation

```bash
./scripts/install.sh
```

## Verwendung

```bash
shae-haskell-expression-evaluator '1 + 2 * 3'
# 7
shae-haskell-expression-evaluator 'let x = 5 in x + 3'
# 8
printf '7 * 6\n' | shae-haskell-expression-evaluator
# 42
```

## Fehlerbehandlung

```bash
shae-haskell-expression-evaluator '1 / 0'
# Error: division by zero
shae-haskell-expression-evaluator 'y + 1'
# Error: undefined variable: y
```

## Build & Test

```bash
make build
make test
make clean
```

## Design

Entsprechend dem SHAE Field Manual: Papier `#F2EEE5`, Tinte `#191712`,
Oxid-Signal `#B3341B`, JetBrains Mono für Code, keine Gradiente/Glas/Schatten.
Siehe `DESIGN.md`.

## Lizenz

MIT. Siehe `LICENSE`.
