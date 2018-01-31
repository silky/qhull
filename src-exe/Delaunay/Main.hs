module Main
  where
import           Delaunay.Examples
import qualified Data.IntMap.Strict  as IM
import           Delaunay
import           Delaunay.R
import           System.IO
import           Text.Show.Pretty
import ConvexHull

main :: IO ()
main = do

  tess <- delaunay rgg False False
  let f1 = _tiles tess IM.! 1
  hull <- convexHull rgg False False Nothing
  let f2 = _hfacets hull IM.! 1
  pPrint $ _family f1
  pPrint $ _family f2

  -- x <- randomInSphere 100
  -- tess <- delaunay x False
  -- let code = delaunay3rgl tess False True False Nothing
  -- writeFile "rgl/delaunay_sphere.R" code
