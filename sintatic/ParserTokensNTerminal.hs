module ParserTokensNTerminal where

import Tokens
import Expression
import ParserTokens
import Text.Parsec
import Control.Monad.IO.Class

import System.IO.Unsafe
import Memory

-- parsers nao terminais
--         ParsecT  input  state       output
program :: ParsecT [Token] Memory IO (ExprTree)
program = do
        a <- stmts
        eof
        return (SingleNode a)

stmts :: ParsecT [Token] Memory IO (ExprTree)
stmts = try (
    do
        a <- basicStmt
        b <- stmts
        return (DoubleNode a b)
    ) <|> try (
    do
        a <- basicStmt
        return (SingleNode a)
    )

basicStmt :: ParsecT [Token] Memory IO (ExprTree)
basicStmt = try (
    -- print
    do
        first <- printToken
        things <- listParam
        colon <- semiColonToken
        return (SingleNode things)
    ) <|> try (
    do
        first <- assign
        return first
    )

listParam :: ParsecT [Token] Memory IO(ExprTree)
listParam = try (
  -- param, ... , param
  do
    a <- exprNv1
    b <- commaToken
    c <- listParam
    return (DoubleNode a c)
  ) <|> (
  -- param
  do
    a <- exprNv1
    return (SingleNode a)
  )

assign :: ParsecT [Token] Memory IO(ExprTree)
assign = do
        a <- idToken
        b <- attribToken
        c <- expression
        colon <- semiColonToken
        return (DoubleNode (makeToken a) c)

-- Expressions
-- Nv1 : + e -
-- Nv2 : * e /
-- Nv3 : ^
-- Nv4 : Parenteshis ( )
expression :: ParsecT [Token] Memory IO(ExprTree)
expression = try (
    do
        a <- exprNv1
        return a
    ) <|> try (
    do
        b <- exprAtomic
        return (SingleNode b)
    )

-- una expression
exprAtomic :: ParsecT [Token] Memory IO(ExprTree)
exprAtomic = try (
    -- StringAtomic
    do
        a <- strLitToken
        return (AtomicToken a)
    ) <|> try (
    -- FloatAtomic
    do
        a <- floatLitToken
        return (AtomicToken a)
    ) <|> try (
    -- IntAtomic
    do
        a <- intLitToken
        return (AtomicToken a)
    )

-- Nv1 : + e -
exprNv1 :: ParsecT [Token] Memory IO(ExprTree)
exprNv1 = try (
    do
        a <- openParenthToken
        internalContent <- exprNv1
        b <- closeParenthToken
        operator <- operatorNv1
        c <- exprNv1
        return (TripleNode internalContent operator c)
    ) <|> try (
    do
        a <- exprNv2
        operator <- operatorNv1
        b <- exprNv1
        return (TripleNode a operator b)
    ) <|> (
    do
        a <- exprNv2
        return a
    )

operatorNv1 :: ParsecT [Token] Memory IO(ExprTree)
operatorNv1 = (
    do
        sym <- symOpPlusToken
        return (makeToken sym)
    ) <|> (do
        sym <- symOpMinusToken
        return (makeToken sym)
    )

-- Nv2 : * e /
exprNv2 :: ParsecT [Token] Memory IO(ExprTree)
exprNv2 = try (
    do
        a <- openParenthToken
        internalContent <- exprNv1
        b <- closeParenthToken
        operator <- operatorNv2
        c <- exprNv2
        return (TripleNode internalContent operator c)
    ) <|> try (
    do
        a <- exprNv3
        operator <- operatorNv2
        b <- exprNv2
        return (TripleNode a operator b)
    ) <|> (
    do
        a <- exprNv3
        return a
    )

operatorNv2 :: ParsecT [Token] Memory IO(ExprTree)
operatorNv2 = (
    do
        sym <- symOpMultToken
        return (makeToken sym)
    ) <|> (do
        sym <- symOpDivToken
        return (makeToken sym)
    )

-- Nv3 : ^
exprNv3 :: ParsecT [Token] Memory IO(ExprTree)
exprNv3 = try (
    do
        a <- openParenthToken
        internalContent <- exprNv1
        b <- closeParenthToken
        operator <- operatorNv3
        c <- exprNv3
        return (TripleNode internalContent operator c)
    ) <|> try (
    do
        a <- exprNv4
        operator <- operatorNv3
        b <- exprNv3
        return (TripleNode a operator b)
    ) <|> (
    do
        a <- exprNv4
        return a
    )

operatorNv3 :: ParsecT [Token] Memory IO(ExprTree)
operatorNv3 = (
    do
        sym <- symOpExpToken
        return (makeToken sym)
    )

-- ( )
exprNv4 :: ParsecT [Token] Memory IO(ExprTree)
exprNv4 = try (
    do
        a <- openParenthToken
        meio <- exprNv1
        b <- closeParenthToken
        return meio
    ) <|> try  (
    do
        a <- exprAtomic
        return a
    ) <|> try  (
    do
        id <- idToken
        return (makeToken id)
    )

memory_assign :: Variable -> Memory -> Memory
memory_assign symbol (Memory [] io) = Memory [symbol] io
memory_assign (Variable (Id pos1 id1, v1)) (Memory((Variable (Id pos2 id2, v2)) : t) io) =
                                if id1 == id2 then append_memory (Variable(Id pos2 id2, v1)) (Memory t io)
                                else append_memory (Variable (Id pos2 id2, v2)) (memory_assign (Variable (Id pos1 id1, v1)) (Memory t io))

append_memory :: Variable -> Memory -> Memory
append_memory variable (Memory [] io) = Memory [variable] io
append_memory variable (Memory variables io) = Memory (variable : variables) io

lookUpVariable :: String -> Memory -> Variable
lookUpVariable id1 (Memory((Variable (Id pos2 id2, v2)) : t) io) =
                                if id1 == id2 then return (Variable(Id pos2 id2, v2))
                                else lookUpVariable id1 (Memory t io)
lookUpVariable id1 (Memory [] io) =  error "Variavel não encontrada"

parser :: [Token] -> IO (Either ParseError ExprTree)
parser tokens = runParserT program (Memory [] (return())) "Error message" tokens

--main :: IO ()
--main = case unsafePerformIO (parser (getTokens "problem1.ml")) of
--    {
--        Left err -> print err;
--        Right ans -> print ans
--    }