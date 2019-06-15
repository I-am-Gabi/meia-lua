import Tokens
import Expression 
import Memory
import ParserTokensNTerminal

import System.IO.Unsafe
import System.Environment


evaluateExpr :: Memory -> ExprTree -> (Memory, (Type, Value))
evaluateExpr memory exprTree = case exprTree of
    -- atomics
    AtomicToken a -> case a of
        IntLit _ v -> (memory, (IntType, Int v))
        FloatLit _ v -> (memory, (FloatType, Float v))
        StrLit _ v -> (memory, (StringType, String v))
        SymTrue _ -> (memory, (BoolType, Bool True))
        SymFalse _ -> (memory, (BoolType, Bool False))

assignToId :: Memory -> ExprTree -> ExprTree -> Memory
assignToId st id expr =  (st1, exprRes)
    where
        (st1, exprRes) = evaluateExpr st expr 


inicAnalisadorSemantico :: ExprTree -> IO()
inicAnalisadorSemantico tree = analisadorSemantico tree Memory[]

analisadorSemantico :: ExprTree -> Memory -> Memory
-- assign
analisadorSemantico (DoubleNode a c) st = assignToId st a c 

getInput :: String
getInput = unsafePerformIO (getLine)

getInputOfType :: Token -> (Type, Value)
getInputOfType (TypeInt _) = (IntType, Int value)
    where
        value = read getInput :: Int
getInputOfType (TypeFloat _) = (FloatType, Float value)
    where
        value = read getInput :: Float
getInputOfType (TypeString _) = (StringType, String value)
    where
        value = getInput :: String
getInputOfType _ = error "Operação de scan não permitida para esse tipo"


main :: IO ()
main = case unsafePerformIO (parser (getTokens "problem1.ml")) of
    { 
        Left err -> print err; 
        Right ans -> inicAnalisadorSemantico ans
    }