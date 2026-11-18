# shae-haskell-expression-evaluator (Español)

Un evaluador de expresiones recursivo de descenso escrito en Haskell auténtico.
Analiza y evalúa expresiones aritméticas con literales enteros y flotantes,
`+ - * /`, paréntesis y variables vinculadas con `let`. Reporta errores de
división entre cero y variable indefinida.

## Requisitos

- **GHC** (Glasgow Haskell Compiler) — no instalado localmente. Consulte
  `scripts/install.sh`.

## Instalación

```bash
./scripts/install.sh
```

## Uso

```bash
shae-haskell-expression-evaluator '1 + 2 * 3'
# 7
shae-haskell-expression-evaluator 'let x = 5 in x + 3'
# 8
printf '7 * 6\n' | shae-haskell-expression-evaluator
# 42
```

### Manejo de errores

```bash
shae-haskell-expression-evaluator '1 / 0'
# Error: division by zero
shae-haskell-expression-evaluator 'y + 1'
# Error: undefined variable: y
```

## Compilación y pruebas

```bash
make build
make test
make clean
```

## Diseño

Según el manual de campo SHAE: papel `#F2EEE5`, tinta `#191712`, señal óxido
`#B3341B`, JetBrains Mono para código, sin gradientes/vidrio/sombras.
Véase `DESIGN.md`.

## Licencia

MIT. Véase `LICENSE`.
