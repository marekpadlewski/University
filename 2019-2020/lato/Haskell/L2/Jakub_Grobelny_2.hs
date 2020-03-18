-- Jakub Grobelny
-- Kurs języka Haskell
-- Lista 2, 20.03.2020

-- Zadanie 1
{-# LANGUAGE ParallelListComp #-}

subseqC :: [a] -> [[a]]
subseqC [] = [[]]
subseqC (x:xs) = concat [[x:ys, ys] | ys <- subseqC xs]

ipermC :: [a] -> [[a]]
ipermC [] = [[]]
ipermC (x:xs) = concat [insert x ys | ys <- ipermC xs]
  where
    insert :: a -> [a] -> [[a]]
    insert x [] = [[x]]
    insert x ys'@(y:ys) = (x:ys') : [ y : zs | zs <- insert x ys]

spermC :: [a] -> [[a]]
spermC [] = [[]]
spermC xs = [y:zs | (y, ys) <- select xs, zs <- spermC ys]
  where
    select :: [a] -> [(a, [a])]
    select [x] = [(x, [])]
    select (x:xs) = (x, xs) : [(y, x:ys) | (y, ys) <- select xs]

qsortC :: Ord a => [a] -> [a]
qsortC [] = []
qsortC (x:xs) = [y | y <- xs, y < x] ++ [x] ++ [y | y <- xs, y >= x]

zipC :: [a] -> [b] -> [(a,b)]
zipC xs ys = [(x, y) | x <- xs | y <- ys]

-- Zadanie 3
data Combinator 
    = S 
    | K 
    | Combinator :$ Combinator

infixl :$

instance Show Combinator where
    show S = "S"
    show K = "K"
    show (lhs :$ rhs@(_:$_)) = show lhs ++ "(" ++ show rhs ++ ")"
    show (lhs :$ rhs)        = show lhs ++ show rhs

-- Zadanie 5
data BST a
    = NodeBST (BST a) a (BST a)
    | EmptyBST
    deriving Show

searchBST :: Ord a => a -> BST a -> Maybe a
searchBST _ EmptyBST = Nothing
searchBST a (NodeBST left val right)
    | a == val  = Just a
    | a <  val  = searchBST a left
    | otherwise = searchBST a right

insertBST :: Ord a => a -> BST a -> BST a
insertBST a EmptyBST = NodeBST EmptyBST a EmptyBST
insertBST a tree@(NodeBST left val right)
    | a == val  = tree
    | a <  val  = NodeBST (insertBST a left) val right
    | otherwise = NodeBST left val (insertBST a right)

-- Zadanie 6
deleteMaxBST :: Ord a => BST a -> (BST a, a)
deleteMaxBST EmptyBST = error "deleteMaxBST: empty tree!"
deleteMaxBST (NodeBST left val EmptyBST) = (left, val)
deleteMaxBST (NodeBST left val right) = (NodeBST left val right', max)
  where
    (right', max) = deleteMaxBST right

deleteBST :: Ord a => a -> BST a -> BST a
deleteBST _ EmptyBST = EmptyBST
deleteBST a (NodeBST EmptyBST val right)
    | a == val  = right
    | otherwise = NodeBST EmptyBST val $ deleteBST a right
deleteBST a (NodeBST left val right)
    | a < val   = NodeBST (deleteBST a left) val right
    | a > val   = NodeBST left val (deleteBST a right)
    | otherwise = NodeBST left' max right
  where
    (left', max) = deleteMaxBST left