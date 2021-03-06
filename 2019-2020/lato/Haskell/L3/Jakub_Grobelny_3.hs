-- Jakub Grobelny
-- Kurs języka Haskell
-- Lista 3, 27.03.2020

{-# LANGUAGE ViewPatterns         #-}
{-# LANGUAGE FlexibleInstances    #-}
{-# LANGUAGE IncoherentInstances  #-}
{-# LANGUAGE UndecidableInstances #-}

import Data.Function (on)

data BTree t a
    = Node (t a) a (t a)
    | Leaf

class BT t where
    toTree :: t a -> BTree t a

data UTree a 
    = UNode (UTree a) a (UTree a) 
    | ULeaf

instance BT UTree where
    toTree ULeaf = Leaf
    toTree (UNode l x r) = Node l x r

newtype Unbalanced a = Unbalanced { fromUnbalanced :: BTree Unbalanced a }

instance BT Unbalanced where
    toTree = fromUnbalanced

--------------------------------------------------------------------------------

-- Zadanie 1

treeSize :: BT t => t a -> Int
treeSize (toTree -> Leaf) = 0
treeSize (toTree -> Node l _ r) = 1 + treeSize l + treeSize r

treeLabels :: BT t => t a -> [a]
treeLabels (toTree -> Leaf) = []
treeLabels (toTree -> Node l a r) = treeLabels l ++ [a] ++ treeLabels r

treeFold :: BT t => (b -> a -> b -> b) -> b -> t a -> b
treeFold _ n (toTree -> Leaf) = n
treeFold f n (toTree -> Node l a r) = f (treeFold f n l) a (treeFold f n r)

--------------------------------------------------------------------------------

-- Zadanie 2

searchBT :: (Ord a, BT t) => a -> t a -> Maybe a
searchBT _ (toTree -> Leaf) = Nothing
searchBT val (toTree -> Node l a r)
    | val < a   = searchBT val l
    | val > a   = searchBT val r
    | otherwise = Just a

toUTree :: BT t => t a -> UTree a
toUTree (toTree -> Leaf) = ULeaf
toUTree (toTree -> Node l a r) = UNode (toUTree l) a (toUTree r)

toUnbalanced :: BT t => t a -> Unbalanced a
toUnbalanced (toTree -> Leaf) = Unbalanced Leaf
toUnbalanced (toTree -> Node l a r) = Unbalanced $ 
    Node (toUnbalanced l) a (toUnbalanced r)

--------------------------------------------------------------------------------

-- Zadanie 3

instance (BT t, Show a) => Show (t a) where
    show (toTree -> Leaf) = "-"
    show (toTree -> Node l a r) = show' l ++ " " ++ show a ++ " " ++ show' r
      where
        show' leaf@(toTree -> Leaf) = show leaf
        show' tree = "(" ++ show tree ++ ")"

--------------------------------------------------------------------------------

class BT t => BST t where
    node :: t a -> a -> t a -> t a
    leaf :: t a

instance BST UTree where
    node = UNode
    leaf = ULeaf

instance BST Unbalanced where
    node l x r = Unbalanced $ Node l x r
    leaf = Unbalanced Leaf

class Set s where
    empty  :: s a
    search :: Ord a => a -> s a -> Maybe a
    insert :: Ord a => a -> s a -> s a
    delMax :: Ord a => s a -> Maybe (a, s a)
    delete :: Ord a => a -> s a -> s a

--------------------------------------------------------------------------------

-- Zadanie 6

instance BST s => Set s where
    empty  = leaf

    search = searchBT
    
    insert a (toTree -> Leaf) = node leaf a leaf
    insert a tree@(toTree -> Node l v r)
        | a < v     = node (insert a l) v r
        | a > v     = node l v (insert a r)
        | otherwise = tree

    delMax (toTree -> Leaf) = Nothing
    delMax (toTree -> Node l v (toTree -> Leaf)) = Just (v, l)
    delMax (toTree -> Node l v r) = do
        (max, r') <- delMax r
        return (max, node l v r')

    delete a (toTree -> Leaf) = leaf
    delete a (toTree -> Node l v r)
        | a < v     = node (delete a l) v r
        | a > v     = node l v (delete a r)
        | otherwise = case delMax l of
            Just (max, l) -> node l max r
            Nothing       -> r

--------------------------------------------------------------------------------

data WBTree a
    = WBNode (WBTree a) a Int (WBTree a)
    | WBLeaf

wbsize :: WBTree a -> Int
wbsize (WBNode _ _ n _) = n
wbsize WBLeaf = 0

-- Zadanie 7

instance BT WBTree where
    toTree WBLeaf = Leaf
    toTree (WBNode l v _ r) = Node l v r

wbNode' :: WBTree a -> a -> WBTree a -> WBTree a
wbNode' l v r = WBNode l v (wbsize l + wbsize r + 1) r

wbRotateLeft :: WBTree a -> a -> WBTree a -> WBTree a
wbRotateLeft left val right@(WBNode rleft _ _ rright)
    | wbsize rleft < wbsize rright = singleLeft left val right
    | otherwise                    = doubleLeft left val right
  where
    singleLeft x a (WBNode y b _ z) = wbNode' (wbNode' x a y) b z
    doubleLeft x a (WBNode (WBNode y1 b _ y2) c _ z) =
        wbNode' (wbNode' x a y1) b (wbNode' y2 c z)

wbRotateRight :: WBTree a -> a -> WBTree a -> WBTree a
wbRotateRight left@(WBNode lleft _ _ lright) val right
    | wbsize lright < wbsize lleft = singleRight left val right
    | otherwise                    = doubleRight left val right
  where
    singleRight (WBNode x a _ y) b z = wbNode' x a (wbNode' y b z)
    doubleRight (WBNode x a _ (WBNode y1 b _ y2)) c z =
        wbNode' (wbNode' x a y1) b (wbNode' y2 c z)

instance BST WBTree where
    leaf = WBLeaf
    node l a r
        | lSize + rSize < 2 = wbNode' l a r
        | rSize > ratio * lSize = wbRotateLeft l a r
        | lSize > ratio * rSize = wbRotateRight l a r
        | otherwise = wbNode' l a r
      where
        ratio = 5
        lSize = wbsize l
        rSize = wbsize r

--------------------------------------------------------------------------------

-- pomocnicze funkcje do testowania drzew

listToBST :: (Ord a, BST t) => [a] -> (t a)
listToBST = foldr insert leaf

listFromBST :: (BST t) => (t a) -> [a]
listFromBST = treeFold (\l v r -> l ++ v : r) []

--------------------------------------------------------------------------------

-- Zadanie 8

data HBTree a
    = HBNode (HBTree a) a Int (HBTree a)
    | HBLeaf

instance BT HBTree where
    toTree HBLeaf = Leaf
    toTree (HBNode l v _ r) = Node l v r

hbheight :: HBTree a -> Int 
hbheight HBLeaf = 0
hbheight (HBNode _ _ h _) = h

hbNode' :: HBTree a -> a -> HBTree a -> HBTree a
hbNode' l v r = HBNode l v (1 + (max `on` hbheight) l r) r

-- rotacje takie jak w drzewach AVL
hbFixLeft :: HBTree a -> a -> HBTree a -> HBTree a
hbFixLeft left@(HBNode ll _ _ lr) val right
    | hbheight ll > hbheight lr = leftLeft left val right
    | otherwise                 = leftRight left val right
  where
    leftLeft (HBNode (HBNode t1 x _ t2) y _ t3) z t4 =
        hbNode' (hbNode' t1 x t2) y (hbNode' t3 z t4)
    leftRight (HBNode t1 y _ (HBNode t2 x _ t3)) z t4 =
        hbNode' (hbNode' t1 y t2) x (hbNode' t3 z t4)

hbFixRight :: HBTree a -> a -> HBTree a -> HBTree a
hbFixRight left val right@(HBNode rl _ _ rr)
    | hbheight rl > hbheight rr = rightLeft left val right
    | otherwise                 = rightRight left val right
  where
    rightLeft t1 z (HBNode t2 y _ (HBNode t3 x _ t4)) =
        hbNode' (hbNode' t1 z t2) y (hbNode' t3 x t4)
    rightRight t1 z (HBNode (HBNode t2 x _ t3) y _ t4) =
        hbNode' (hbNode' t1 z t2) x (hbNode' t3 y t4)

instance BST HBTree where
    leaf = HBLeaf
    node l a r
        | lh <= 1 && rh <= 1 = hbNode' l a r
        | lh > rh + 1 = hbFixLeft l a r
        | rh > lh + 1 = hbFixRight l a r
        | otherwise   = hbNode' l a r
      where
          lh = hbheight l
          rh = hbheight r