{-# LANGUAGE ForeignFunctionInterface #-}
module Delaunay.CDelaunay
  ( cTesselationToTesselation
  , c_tesselation )
  where
import           Control.Monad              ((<$!>))
import qualified Data.HashMap.Strict.InsOrd as H
import           Data.IntMap.Strict         (fromAscList, (!))
import qualified Data.IntSet                as IS
import           Data.List
import           Data.Tuple.Extra           (both, fst3, snd3, thd3, (&&&))
import           Delaunay.Types
import           Foreign
import           Foreign.C.Types
import           Qhull.Types

#include "delaunay.h"

data CSite = CSite {
    __id :: CUInt
  , __neighsites :: Ptr CUInt
  , __nneighsites :: CUInt
  , __neighridgesids :: Ptr CUInt
  , __nneighridges :: CUInt
  , __neightiles :: Ptr CUInt
  , __nneightiles :: CUInt
}

instance Storable CSite where
    sizeOf    __ = #{size SiteT}
    alignment __ = #{alignment SiteT}
    peek ptr = do
      id'              <- #{peek SiteT, id} ptr
      neighsites'      <- #{peek SiteT, neighsites} ptr
      nneighsites'     <- #{peek SiteT, nneighsites} ptr
      neighridgesids'  <- #{peek SiteT, neighridgesids} ptr
      nneighridges'    <- #{peek SiteT, nneighridges} ptr
      neightiles'      <- #{peek SiteT, neightiles} ptr
      nneightiles'     <- #{peek SiteT, nneightiles} ptr
      return CSite { __id             = id'
                   , __neighsites     = neighsites'
                   , __nneighsites    = nneighsites'
                   , __neighridgesids = neighridgesids'
                   , __nneighridges   = nneighridges'
                   , __neightiles     = neightiles'
                   , __nneightiles    = nneightiles'
                  }
    poke ptr (CSite r1 r2 r3 r4 r5 r6 r7)
      = do
          #{poke SiteT, id} ptr r1
          #{poke SiteT, neighsites} ptr r2
          #{poke SiteT, nneighsites} ptr r3
          #{poke SiteT, neighridgesids} ptr r4
          #{poke SiteT, nneighridges} ptr r5
          #{poke SiteT, neightiles} ptr r6
          #{poke SiteT, nneightiles} ptr r7

cSiteToSite :: [[Double]] -> CSite -> IO (Int, Site, [(Int,Int)])
cSiteToSite sites csite = do
  let id'          = fromIntegral $ __id csite
      nneighsites  = fromIntegral $ __nneighsites csite
      nneighridges = fromIntegral $ __nneighridges csite
      nneightiles  = fromIntegral $ __nneightiles csite
      point        = sites !! id'
  neighsites <- (<$!>) (map fromIntegral)
                       (peekArray nneighsites (__neighsites csite))
  neighridges <- (<$!>) (map fromIntegral)
                        (peekArray nneighridges (__neighridgesids csite))
  neightiles <- (<$!>) (map fromIntegral)
                       (peekArray nneightiles (__neightiles csite))
  return ( id'
         , Site {
                  _point          = point
                , _neighsitesIds  = IS.fromAscList neighsites
                , _neighfacetsIds = IS.fromAscList neighridges
                , _neightilesIds  = IS.fromAscList neightiles
                }
         , map (\j -> (id', j)) (filterAscList id' neighsites) )
  where
    filterAscList :: Int -> [Int] -> [Int]
    filterAscList n list =
      let i = findIndex (>n) list in
      if isJust i
        then drop (fromJust i) list
        else []

data CSimplex = CSimplex {
    __sitesids :: Ptr CUInt
  , __center :: Ptr CDouble
  , __radius :: CDouble
  , __volume :: CDouble
}

instance Storable CSimplex where
    sizeOf    __ = #{size SimplexT}
    alignment __ = #{alignment SimplexT}
    peek ptr = do
      sitesids'    <- #{peek SimplexT, sitesids} ptr
      center'      <- #{peek SimplexT, center} ptr
      radius'      <- #{peek SimplexT, radius} ptr
      volume'      <- #{peek SimplexT, volume} ptr
      return CSimplex { __sitesids    = sitesids'
                      , __center      = center'
                      , __radius      = radius'
                      , __volume      = volume'
                    }
    poke ptr (CSimplex r1 r2 r3 r4)
      = do
          #{poke SimplexT, sitesids} ptr r1
          #{poke SimplexT, center} ptr r2
          #{poke SimplexT, radius} ptr r3
          #{poke SimplexT, volume} ptr r4

cSimplexToSimplex :: [[Double]] -> Int -> CSimplex -> IO Simplex
cSimplexToSimplex sites simplexdim csimplex = do
  let radius      = cdbl2dbl $ __radius csimplex
      volume      = cdbl2dbl $ __volume csimplex
      dim         = length (head sites)
  sitesids <- (<$!>) (map fromIntegral)
                     (peekArray simplexdim (__sitesids csimplex))
  let points = fromAscList
               (zip sitesids (map ((!!) sites) sitesids))
  center <- (<$!>) (map cdbl2dbl) (peekArray dim (__center csimplex))
  return Simplex { _vertices'    = points
                 , _circumcenter = center
                 , _circumradius = radius
                 , _volume'      = volume }
  where
    cdbl2dbl :: CDouble -> Double
    cdbl2dbl x = if isNaN x then 0/0 else realToFrac x

data CSubTile = CSubTile {
    __id' :: CUInt
  , __subsimplex :: CSimplex
  , __ridgeOf1 :: CUInt
  , __ridgeOf2 :: CInt
  , __normal :: Ptr CDouble
  , __offset :: CDouble
}

instance Storable CSubTile where
    sizeOf    __ = #{size SubTileT}
    alignment __ = #{alignment SubTileT}
    peek ptr = do
      id'       <- #{peek SubTileT, id} ptr
      simplex'  <- #{peek SubTileT, simplex} ptr
      ridgeOf1' <- #{peek SubTileT, ridgeOf1} ptr
      ridgeOf2' <- #{peek SubTileT, ridgeOf2} ptr
      normal'   <- #{peek SubTileT, normal} ptr
      offset'   <- #{peek SubTileT, offset} ptr
      return CSubTile { __id'        = id'
                      , __subsimplex = simplex'
                      , __ridgeOf1   = ridgeOf1'
                      , __ridgeOf2   = ridgeOf2'
                      , __normal     = normal'
                      , __offset     = offset' }
    poke ptr (CSubTile r1 r2 r3 r4 r5 r6)
      = do
          #{poke SubTileT, id} ptr r1
          #{poke SubTileT, simplex} ptr r2
          #{poke SubTileT, ridgeOf1} ptr r3
          #{poke SubTileT, ridgeOf2} ptr r4
          #{poke SubTileT, normal} ptr r5
          #{poke SubTileT, offset} ptr r6

cSubTiletoTileFacet :: [[Double]] -> CSubTile -> IO (Int, TileFacet)
cSubTiletoTileFacet points csubtile = do
  let dim        = length (head points)
      ridgeOf1   = fromIntegral $ __ridgeOf1 csubtile
      ridgeOf2   = fromIntegral $ __ridgeOf2 csubtile
      ridgeOf    = if ridgeOf2 == -1 then [ridgeOf1] else [ridgeOf1, ridgeOf2]
      id'        = fromIntegral $ __id' csubtile
      subsimplex = __subsimplex csubtile
      offset     = realToFrac $ __offset csubtile
  simplex <- cSimplexToSimplex points dim subsimplex
  normal <- (<$!>) (map realToFrac) (peekArray dim (__normal csubtile))
  return (id', TileFacet { _subsimplex = simplex
                         , _facetOf    = IS.fromAscList ridgeOf
                         , _normal'    = normal
                         , _offset'    = offset })

data CTile = CTile {
    __id'' :: CUInt
  , __simplex :: CSimplex
  , __neighbors :: Ptr CUInt
  , __nneighbors :: CUInt
  , __ridgesids :: Ptr CUInt
  , __nridges :: CUInt
  , __family :: CInt
  , __orientation :: CInt
}

instance Storable CTile where
    sizeOf    __ = #{size TileT}
    alignment __ = #{alignment TileT}
    peek ptr = do
      id'         <- #{peek TileT, id} ptr
      simplex'    <- #{peek TileT, simplex} ptr
      neighbors'  <- #{peek TileT, neighbors} ptr
      nneighbors' <- #{peek TileT, nneighbors} ptr
      ridgesids'  <- #{peek TileT, ridgesids} ptr
      nridges'    <- #{peek TileT, nridges} ptr
      family'     <- #{peek TileT, family} ptr
      orient      <- #{peek TileT, orientation} ptr
      return CTile { __id''        = id'
                   , __simplex     = simplex'
                   , __neighbors   = neighbors'
                   , __nneighbors  = nneighbors'
                   , __ridgesids   = ridgesids'
                   , __nridges     = nridges'
                   , __family      = family'
                   , __orientation = orient
                  }
    poke ptr (CTile r1 r2 r3 r4 r5 r6 r7 r8)
      = do
          #{poke TileT, id} ptr r1
          #{poke TileT, simplex} ptr r2
          #{poke TileT, neighbors} ptr r3
          #{poke TileT, nneighbors} ptr r4
          #{poke TileT, ridgesids} ptr r5
          #{poke TileT, nridges} ptr r6
          #{poke TileT, family} ptr r7
          #{poke TileT, orientation} ptr r8

cTileToTile :: [[Double]] -> CTile -> IO (Int, Tile)
cTileToTile points ctile = do
  let id'        = fromIntegral $ __id'' ctile
      csimplex   = __simplex ctile
      nneighbors = fromIntegral $ __nneighbors ctile
      nridges    = fromIntegral $ __nridges ctile
      family     = __family ctile
      orient     = __orientation ctile
      dim        = length (head points)
  simplex <- cSimplexToSimplex points (dim+1) csimplex
  neighbors <- (<$!>) (map fromIntegral)
                      (peekArray nneighbors (__neighbors ctile))
  ridgesids <- (<$!>) (map fromIntegral)
                      (peekArray nridges (__ridgesids ctile))
  return (id', Tile {  _simplex      = simplex
                     , _neighborsIds = IS.fromAscList neighbors
                     , _facetsIds    = IS.fromAscList ridgesids
                     , _family'      = if family == -1
                                        then None
                                        else Family (fromIntegral family)
                     , _toporiented  = orient == 1 })

data CTesselation = CTesselation {
    __sites :: Ptr CSite
  , __tiles :: Ptr CTile
  , __ntiles :: CUInt
  , __subtiles :: Ptr CSubTile
  , __nsubtiles :: CUInt
}

instance Storable CTesselation where
    sizeOf    __ = #{size TesselationT}
    alignment __ = #{alignment TesselationT}
    peek ptr = do
      sites'     <- #{peek TesselationT, sites} ptr
      tiles'     <- #{peek TesselationT, tiles} ptr
      ntiles'    <- #{peek TesselationT, ntiles} ptr
      subtiles'  <- #{peek TesselationT, subtiles} ptr
      nsubtiles' <- #{peek TesselationT, nsubtiles} ptr
      return CTesselation {
                     __sites     = sites'
                   , __tiles     = tiles'
                   , __ntiles    = ntiles'
                   , __subtiles  = subtiles'
                   , __nsubtiles = nsubtiles'
                  }
    poke ptr (CTesselation r1 r2 r3 r4 r5)
      = do
          #{poke TesselationT, sites} ptr r1
          #{poke TesselationT, tiles} ptr r2
          #{poke TesselationT, ntiles} ptr r3
          #{poke TesselationT, subtiles} ptr r4
          #{poke TesselationT, nsubtiles} ptr r5

foreign import ccall unsafe "tesselation" c_tesselation
  :: Ptr CDouble -- sites
  -> CUInt       -- dim
  -> CUInt       -- nsites
  -> CUInt       -- 0/1, point at infinity
  -> CUInt       -- 0/1, include degenerate
  -> CDouble     -- volume threshold
  -> Ptr CUInt   -- exitcode
  -> IO (Ptr CTesselation)

cTesselationToTesselation :: [[Double]] -> CTesselation -> IO Tesselation
cTesselationToTesselation vertices ctess = do
  let ntiles    = fromIntegral $ __ntiles ctess
      nsubtiles = fromIntegral $ __nsubtiles ctess
      nsites    = length vertices
  sites''    <- peekArray nsites (__sites ctess)
  tiles''    <- peekArray ntiles (__tiles ctess)
  subtiles'' <- peekArray nsubtiles (__subtiles ctess)
  sites'     <- mapM (cSiteToSite vertices) sites''
  let sites = fromAscList (map (fst3 &&& snd3) sites')
      edgesIndices = concatMap thd3 sites'
      edges = map (toPair &&& both (_point . ((!) sites))) edgesIndices
  tiles'     <- mapM (cTileToTile vertices) tiles''
  subtiles'  <- mapM (cSubTiletoTileFacet vertices) subtiles''
  return Tesselation
         { _sites      = sites
         , _tiles      = fromAscList tiles'
         , _tilefacets = fromAscList subtiles'
         , _edges'     = H.fromList edges }
  where
    toPair (i,j) = Pair i j
