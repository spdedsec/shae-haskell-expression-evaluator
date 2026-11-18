# shae-haskell-expression-evaluator

A small recursive-descent arithmetic expression evaluator written in authentic
Haskell. Parses and evaluates expressions with integer and float literals,
`+ - * /`, parentheses, and `let`-bound variables. Reports division-by-zero
and undefined-variable errors.

Built to the [SHAE Field Manual design system] (see `DESIGN.md`).

[SHAE Field Manual design system]: ../shared/design-system.md

## Requirements

- **GHC** (Glasgow Haskell Compiler) — not installed locally. The GitHub
  Actions runner may provide it; otherwise install it yourself (see
  `scripts/install.sh`).

## Install

```bash
./scripts/install.sh
# or, with a custom prefix:
PREFIX=~/.local/bin ./scripts/install.sh
```

Equivalent manual steps:

```bash
ghc -O2 -o eval src/Eval.hs
install -m 0755 eval /usr/local/bin/shae-haskell-expression-evaluator
```

## Usage

Evaluate an expression passed as an argument:

```bash
shae-haskell-expression-evaluator '1 + 2 * 3'
# 7
shae-haskell-expression-evaluator 'let x = 5 in x + 3'
# 8
shae-haskell-expression-evaluator '10 / 4'
# 2.5
```

Read expressions from stdin (one per line):

```bash
printf '7 * 6\nlet n = 10 in n * 2\n' | shae-haskell-expression-evaluator
# 42
# 20
```

### Error handling

```bash
shae-haskell-expression-evaluator '1 / 0'
# Error: division by zero
shae-haskell-expression-evaluator 'y + 1'
# Error: undefined variable: y
```

## Build & test

```bash
make build   # compile with ghc
make test    # run smoke tests (requires ghc)
make clean   # remove build artifacts
```

## Design

Documentation and help output follow the SHAE field manual: warm paper ground
`#F2EEE5`, ink `#191712`, oxide signal `#B3341B`, JetBrains Mono for code,
0px radius, 1px borders, no gradients/glass/shadows/pills. See `DESIGN.md`.

## License

MIT. See `LICENSE`.
