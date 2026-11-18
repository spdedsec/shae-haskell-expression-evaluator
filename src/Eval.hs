{-# LANGUAGE LambdaCase #-}
-- | shae-haskell-expression-evaluator
-- |
-- A small recursive-descent expression evaluator written in authentic Haskell.
-- Supports integer and float literals, + - * /, parentheses, variables via
-- `let x = 5 in x + 3`, and reports division-by-zero / undefined-variable errors.
--
-- Build:   ghc -O2 -o eval src/Eval.hs
-- Run:     ./eval '1 + 2 * 3'
--          ./eval 'let x = 5 in x + 3'
--          echo '10 / 2' | ./eval
module Main where

import Control.Exception (catch, SomeException)
import Data.Char (isAlpha, isAlphaNum, isDigit, isSpace)
import System.Environment (getArgs)
import System.IO (hFlush, hPutStrLn, stderr, stdout)

-- ---------------------------------------------------------------------------
-- Values
-- ---------------------------------------------------------------------------

data Val
  = IntV Int
  | FloatV Double
  deriving (Eq)

instance Show Val where
  show (IntV n)     = show n
  show (FloatV d)   = show d

-- ---------------------------------------------------------------------------
-- Expressions
-- ---------------------------------------------------------------------------

data Expr
  = ELit Val
  | EVar String
  | EAdd Expr Expr
  | ESub Expr Expr
  | EMul Expr Expr
  | EDiv Expr Expr
  | ELet String Expr Expr

-- ---------------------------------------------------------------------------
-- Tokens
-- ---------------------------------------------------------------------------

data Tok
  = TNum Val
  | TOp Char
  | TLParen
  | TRParen
  | TLet
  | TIn
  | TEq
  | TId String
  deriving (Eq, Show)

-- ---------------------------------------------------------------------------
-- Tokenizer
-- ---------------------------------------------------------------------------

tokenize :: String -> [Tok]
tokenize [] = []
tokenize (c : cs)
  | isSpace c = tokenize cs
tokenize ('(' : cs) = TLParen : tokenize cs
tokenize (')' : cs) = TRParen : tokenize cs
tokenize ('+' : cs) = TOp '+' : tokenize cs
tokenize ('-' : cs) = TOp '-' : tokenize cs
tokenize ('*' : cs) = TOp '*' : tokenize cs
tokenize ('/' : cs) = TOp '/' : tokenize cs
tokenize ('=' : cs) = TEq : tokenize cs
tokenize s@(c : _) | isDigit c =
  let (num, rest) = span (\x -> isDigit x || x == '.') s
  in TNum (readNumber num) : tokenize rest
tokenize s@(c : _) | isAlpha c =
  let (word, rest) = span isAlphaNum s
  in case word of
       "let" -> TLet : tokenize rest
       "in"  -> TIn  : tokenize rest
       _     -> TId word : tokenize rest
tokenize (c : _) = error ("illegal character: " ++ [c])

readNumber :: String -> Val
readNumber s
  | '.' `elem` s = case reads s of
                     [(d, "")] -> FloatV d
                     _         -> error ("cannot parse number: " ++ s)
  | otherwise    = case reads s of
                     [(n, "")] -> IntV n
                     _         -> error ("cannot parse integer: " ++ s)

-- ---------------------------------------------------------------------------
-- Parser (recursive descent, Either for recoverable errors)
-- ---------------------------------------------------------------------------

type Parser a = [Tok] -> Either String (a, [Tok])

parseExpr :: Parser Expr
parseExpr ts = do
  (e, rest) <- parseTerm ts
  parseExprRest e rest

parseExprRest :: Expr -> [Tok] -> Either String (Expr, [Tok])
parseExprRest e (TOp op : rest) | op `elem` "+-" = do
  (r, rest2) <- parseTerm rest
  parseExprRest (binop op e r) rest2
parseExprRest e rest = Right (e, rest)

parseTerm :: Parser Expr
parseTerm ts = do
  (e, rest) <- parseFactor ts
  parseTermRest e rest

parseTermRest :: Expr -> [Tok] -> Either String (Expr, [Tok])
parseTermRest e (TOp op : rest) | op `elem` "*/" = do
  (r, rest2) <- parseFactor rest
  parseTermRest (binop op e r) rest2
parseTermRest e rest = Right (e, rest)

parseFactor :: Parser Expr
parseFactor (TNum v : rest) = Right (ELit v, rest)
parseFactor (TId x : rest)  = Right (EVar x, rest)
parseFactor (TLParen : rest) = do
  (e, rest2) <- parseExpr rest
  case rest2 of
    TRParen : rest3 -> Right (e, rest3)
    _               -> Left "expected ')'"
parseFactor (TLet : TId x : TEq : rest) = do
  (e1, rest2) <- parseExpr rest
  case rest2 of
    TIn : rest3 -> do
      (e2, rest4) <- parseExpr rest3
      Right (ELet x e1 e2, rest4)
    _ -> Left "expected 'in' after let binding"
parseFactor (TLet : _) = Left "malformed let expression"
parseFactor (t : _)    = Left ("unexpected token: " ++ show t)
parseFactor []         = Left "unexpected end of input"

binop :: Char -> Expr -> Expr -> Expr
binop '+' = EAdd
binop '-' = ESub
binop '*' = EMul
binop '/' = EDiv
binop _   = error ("unknown operator: impossible")

-- ---------------------------------------------------------------------------
-- Evaluation
-- ---------------------------------------------------------------------------

type Env = [(String, Val)]

eval :: Env -> Expr -> Either String Val
eval env (ELit v)          = Right v
eval env (EVar x)          = maybe (Left ("undefined variable: " ++ x)) Right (lookup x env)
eval env (EAdd a b)        = lift2 add env a b
eval env (ESub a b)        = lift2 sub env a b
eval env (EMul a b)        = lift2 mul env a b
eval env (EDiv a b)        = lift2 divV env a b
eval env (ELet x e body)   = do
  v <- eval env e
  eval ((x, v) : env) body

lift2 :: (Val -> Val -> Either String Val) -> Env -> Expr -> Expr -> Either String Val
lift2 op env a b = do
  va <- eval env a
  vb <- eval env b
  op va vb

add, sub, mul :: Val -> Val -> Either String Val
add (IntV a)   (IntV b)   = Right (IntV (a + b))
add (FloatV a) (FloatV b) = Right (FloatV (a + b))
add (IntV a)   (FloatV b) = Right (FloatV (fromIntegral a + b))
add (FloatV a) (IntV b)   = Right (FloatV (a + fromIntegral b))

sub (IntV a)   (IntV b)   = Right (IntV (a - b))
sub (FloatV a) (FloatV b) = Right (FloatV (a - b))
sub (IntV a)   (FloatV b) = Right (FloatV (fromIntegral a - b))
sub (FloatV a) (IntV b)   = Right (FloatV (a - fromIntegral b))

mul (IntV a)   (IntV b)   = Right (IntV (a * b))
mul (FloatV a) (FloatV b) = Right (FloatV (a * b))
mul (IntV a)   (FloatV b) = Right (FloatV (fromIntegral a * b))
mul (FloatV a) (IntV b)   = Right (FloatV (a * fromIntegral b))

divV :: Val -> Val -> Either String Val
divV (IntV a)   (IntV b)
  | b == 0      = Left "division by zero"
  | otherwise   = Right (FloatV (fromIntegral a / fromIntegral b))
divV (FloatV a) (FloatV b)
  | b == 0      = Left "division by zero"
  | otherwise   = Right (FloatV (a / b))
divV (IntV a)   (FloatV b)
  | b == 0      = Left "division by zero"
  | otherwise   = Right (FloatV (fromIntegral a / b))
divV (FloatV a) (IntV b)
  | b == 0      = Left "division by zero"
  | otherwise   = Right (FloatV (a / fromIntegral b))

-- ---------------------------------------------------------------------------
-- Entry point
-- ---------------------------------------------------------------------------

run :: String -> Either String Val
run src = do
  e <- parseSource src
  eval [] e

parseSource :: String -> Either String Expr
parseSource src =
  case parseExpr (tokenize src) of
    Right (e, []) -> Right e
    Right (_, rest) -> Left ("unexpected trailing input: " ++ show rest)
    Left err -> Left err

showResult :: Either String Val -> String
showResult = either ("Error: " ++) show

processLine :: String -> IO ()
processLine line =
  case run line of
    Right v -> putStrLn (show v)
    Left err -> hPutStrLn stderr ("Error: " ++ err)

main :: IO ()
main = do
  args <- getArgs
  case args of
    [] -> stdinLoop
    _  -> mapM_ (putStrLn . showResult . run) args

stdinLoop :: IO ()
stdinLoop = do
  hFlush stdout
  line <- hGetLineSafe
  case line of
    Nothing -> return ()
    Just l  -> processLine l >> stdinLoop

hGetLineSafe :: IO (Maybe String)
hGetLineSafe = catch (Just <$> getLine) handler
  where
    handler :: SomeException -> IO (Maybe String)
    handler _ = return Nothing
