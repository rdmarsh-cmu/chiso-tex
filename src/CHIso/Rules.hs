{-- 
Copyright 2013 Robert Marsh <rdmarsh2@gmail.com>
Licensed under the Apache License, Version 2.0
    http://www.apache.org/licenses/LICENSE-2.0
--}       


module CHIso.Rules where
import CHIso.Syntax
import Data.List

data Rule = Rule [Prop] Prop String [Rule] deriving Show

data Mode = MLft | MRgt
data Assoc = Lft | Rgt

render :: Rule -> Mode -> Bool -> String
render (Rule g p label prems) mode end =
  let
    labelType =
      case (end, mode) of
        (True, MLft) -> "Left"
        (True, MRgt) -> "Right"
        (False, MLft) -> "left"
        (False, MRgt) -> "right"
    ctx = intercalate ", " $ map renderProp g
    prop = renderProp p
    conclusion = ctx ++ " \\vdash " ++ prop
    prems' = case mode of 
        MLft -> zip prems $ True : (repeat False)
        MRgt -> snd $ mapAccumR (\b x -> (False, (x, b))) True prems
    premises = intercalate " \\and\n" $ map (\(r, end') -> render r mode end') prems'
  in "\\inferrule*[" ++ labelType ++ "=" ++ label ++ "]{" ++ premises ++ " }\n{" ++ conclusion ++ "}"

renderProp = renderProp' 0

renderProp' :: Int -> Prop -> String
renderProp' _ (PVar s) = s
renderProp' i (PAnd p1 p2) =  renderBinProp i 0 Rgt p1 " \\wedge " p2
renderProp' i (POr p1 p2) = renderBinProp i 0 Rgt p1" \\vee " p2
renderProp' i (PImp p1 p2) = renderBinProp i 1 Rgt p1 " \\rightarrow " p2
renderProp' _ (PNeg p) = "\\neg " ++ (renderProp' 2 p)

renderBinProp :: Int -> Int -> Assoc -> Prop -> String -> Prop -> String
renderBinProp outer prec assoc p1 s p2 =
  let
    paren = if (outer > prec) then (\x -> concat ["(", x, ")"]) else (\x -> x)
    (precl, precr) = case assoc of 
      Lft -> (prec, prec + 1)
      Rgt -> (prec + 1, prec)
    p1' = renderProp' precl p1
    p2' = renderProp' precr p2
  in
    paren $ p1' ++ s ++ p2'
