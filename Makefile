# shae-haskell-expression-evaluator
# Build / test / release for the Haskell expression evaluator.
#
# Requires GHC (Glasgow Haskell Compiler). Not available locally; the
# GitHub Actions runner may provide it. See scripts/install.sh.

PROJECT   := shae-haskell-expression-evaluator
BIN       := eval
SRC       := src/Eval.hs
PREFIX    ?= /usr/local/bin

.PHONY: all build test clean install release help

all: build

build: $(BIN)

$(BIN): $(SRC)
	@if command -v ghc >/dev/null 2>&1; then \
		ghc -O2 -o $(BIN) $(SRC); \
	else \
		echo "error: ghc is required to build $(PROJECT)"; \
		echo "install it (see scripts/install.sh) or set PATH"; \
		exit 1; \
	fi

test: build
	@echo "--- smoke tests ---"
	@./$(BIN) '1 + 2' | grep -qx '3' || { echo "FAIL: 1 + 2"; exit 1; }
	@./$(BIN) 'let x = 5 in x + 3' | grep -qx '8' || { echo "FAIL: let"; exit 1; }
	@./$(BIN) '10 / 4' | grep -qx '2.5' || { echo "FAIL: 10 / 4"; exit 1; }
	@if ./$(BIN) '1 / 0' 2>&1 | grep -q "division by zero"; then echo "OK: div by zero"; else echo "FAIL: div by zero"; exit 1; fi
	@if ./$(BIN) 'y + 1' 2>&1 | grep -q "undefined variable"; then echo "OK: undefined var"; else echo "FAIL: undefined var"; exit 1; fi
	@echo "--- stdin mode ---"
	@printf '7 * 6\nlet n = 10 in n * 2\n' | ./$(BIN) | grep -qxE '42|20' || { echo "FAIL: stdin"; exit 1; }
	@echo "all tests passed"

clean:
	rm -f $(BIN) *.hi *.o

install: build
	install -m 0755 $(BIN) "$(PREFIX)/$(PROJECT)"
	@echo "installed $(PROJECT) to $(PREFIX)/$(PROJECT)"

release: build
	@echo "Release artifacts are produced by .github/workflows/release.yml on tag push."
	@echo "Binary: $(BIN)"

help:
	@echo "Targets: build test clean install release"
