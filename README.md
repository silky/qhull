# qhull

Delaunay triangulation, Voronoi diagrams and convex hulls.
Based on the `qhull` C library.

## Delaunay tesselation

Consider this list of vertices (actually these are the vertices of a
polyhedron):

```haskell
vertices = [
            [ -5, -5,  16 ]  -- 0
          , [ -5,  8,   3 ]  -- 1
          , [  4, -1,   3 ]  -- 2
          , [  4, -5,   7 ]  -- 3
          , [  4, -1, -10 ]  -- 4
          , [  4, -5, -10 ]  -- 5
          , [ -5,  8, -10 ]  -- 6
          , [ -5, -5, -10 ]  -- 7
                           ]
```

The `delaunay` function splits the polyhedron into simplices, the tiles of the
tesselation:

```haskell
> d <- delaunay vertices False False
> _tiles d
fromList
  [ ( 0
    , Tile
        { _simplex =
            Simplex
              { _points =
                  fromList
                    [ ( 2 , [ 4.0 , -1.0 , 3.0 ] )
                    , ( 4 , [ 4.0 , -1.0 , -10.0 ] )
                    , ( 5 , [ 4.0 , -5.0 , -10.0 ] )
                    , ( 7 , [ -5.0 , -5.0 , -10.0 ] )
                    ]
              , _circumcenter =
                  [ -0.5000000000000009 , -3.0 , -3.499999999999999 ]
              , _circumradius = 8.154753215150047
              , _volume = 78.0
              }
        , _neighborsIds = fromList [ 1 , 3 ]
        , _facetsIds = fromList [ 0 , 1 , 2 , 3 ]
        , _family = Nothing
        , _toporiented = False
        }
    )
  , ( 1
    , Tile
        { _simplex =
  ......
```

The field `_tiles` is a map of `Tile` objects. The keys of the map are
the tiles identifiers. A `Tile` object has five fields:

-   `_simplex`, a `Simplex` object;

-   `_neighborsIds`, a set of tiles identifiers, the neighbors of the tile;

-   `facetsIds`, a set of facets identifiers, the facets of the tile;

-   `family`, two tiles of the same family share the same circumcenter;

-   `toporiented`, Boolean, whether the tile is top-oriented.

A `Simplex` object has four fields:

-   `_points`, the vertices of the simplex, actually a map of the vertices
identifiers to their coordinates

-   `_circumcenter`, the coordinates of the circumcenter of the simplex;

-   `_circumradius`, the circumradius;

-   `_volume`, the volume of the simplex (the area in dimension 2, the
  length in dimension 1).

Another field of the output of `delaunay` is `_tilefacets`:

```haskell
> _tilefacets d
fromList
  [ ( 0
    , TileFacet
        { _subsimplex =
            Simplex
              { _points =
                  fromList
                    [ ( 4 , [ 4.0 , -1.0 , -10.0 ] )
                    , ( 5 , [ 4.0 , -5.0 , -10.0 ] )
                    , ( 7 , [ -5.0 , -5.0 , -10.0 ] )
                    ]
              , _circumcenter = [ -0.5000000000000009 , -3.0 , -10.0 ]
              , _circumradius = 4.924428900898053
              , _volume = 36.0
              }
        , _facetOf = fromList [ 0 ]
        , _normal = [ 0.0 , 0.0 , -1.0 ]
        , _offset = -10.0
        }
    )
  , ( 1
    , TileFacet
        { _subsimplex =
  ......
```

This is a map of `TileFacet` objects. A tile facet is a subsimplex. The keys of
the map are the identifiers of the facets.
A `TileFacet` object has four fields: `_subsimplex`, a `Simplex` object,
`_facetOf`, the identifiers of the tiles this facet belongs to (a set of one
or two integers), `_normal`, the normal of the facet, and `offset`, the offset
of the facet.

Finally, the output of `delaunay` has a `_sites` field, the vertices with
additional information:

```haskell
> _sites d
fromList
  [ ( 0
    , Site
        { _point = [ -5.0 , -5.0 , 16.0 ]
        , _neighsitesIds = fromList [ 1 , 3 , 7 ]
        , _neighfacetsIds = fromList [ 15 , 16 , 17 ]
        , _neightilesIds = fromList [ 5 ]
        }
    )
  , ( 1
    , Site
  ......
```

This is a map of `Site` objects. The keys of the map are the identifiers of
the vertices. A `Site` object has four fields:

-   `_point`, the coordinates of the vertex;

-   `_neighsitesIds`, the identifiers of the connected vertices;

-   `_neighfacetsIds`, a set of integers, the identifiers of the facets the
vertex belongs to;

-   `_neightilesIds`, the set of the identifiers of the tiles the vertex belongs
to.

[![rgg.gif](https://s13.postimg.org/6h1r72k3r/rgg.gif)](https://postimg.org/image/ojutyafyb/)


## Voronoi diagrams

The library allows to get the Voronoi diagram of a list of sites (vertices)
from the Delaunay tesselation. Here is a 3D example.

```haskell
centricCuboctahedron :: [[Double]]
centricCuboctahedron = [[i,j,0] | i <- [-1,1], j <- [-1,1]] ++
                       [[i,0,j] | i <- [-1,1], j <- [-1,1]] ++
                       [[0,i,j] | i <- [-1,1], j <- [-1,1]] ++
                       [[0,0,0]]
import Delaunay
import Voronoi3D
d <- delaunay centricCuboctahedron False False
v = voronoi3 d
```

In some circumstances, one has to run the Delaunay tesselation including the
degenerate tiles in order to get the correct Voronoi diagram, that is to say
`delaunay vertices False True`.

The output of `voronoi3` is a list of Voronoi cells given as pairs, each pair
consisting of a site and a list of edges.
This is the cell of the center `[0, 0, 0]`:

```haskell
> last v
( [ 0.0 , 0.0 , 0.0 ]
, [ Edge3 ( ( -0.5 , -0.5 , 0.5 ) , ( 0.0 , 0.0 , 1.0 ) )
  , Edge3 ( ( -0.5 , -0.5 , 0.5 ) , ( 0.0 , -1.0 , 0.0 ) )
  , Edge3 ( ( -0.5 , -0.5 , 0.5 ) , ( -1.0 , 0.0 , 0.0 ) )
  , Edge3 ( ( -0.5 , 0.5 , 0.5 ) , ( 0.0 , 0.0 , 1.0 ) )
  , Edge3 ( ( -0.5 , 0.5 , 0.5 ) , ( 0.0 , 1.0 , 0.0 ) )
  , Edge3 ( ( -0.5 , 0.5 , 0.5 ) , ( -1.0 , 0.0 , 0.0 ) )
  , Edge3 ( ( 0.5 , -0.5 , 0.5 ) , ( 0.0 , 0.0 , 1.0 ) )
  , Edge3 ( ( 0.5 , -0.5 , 0.5 ) , ( 0.0 , -1.0 , 0.0 ) )
  , Edge3 ( ( 0.5 , -0.5 , 0.5 ) , ( 1.0 , 0.0 , 0.0 ) )
  , Edge3 ( ( 0.5 , 0.5 , 0.5 ) , ( 0.0 , 0.0 , 1.0 ) )
  , Edge3 ( ( 0.5 , 0.5 , 0.5 ) , ( 0.0 , 1.0 , 0.0 ) )
  , Edge3 ( ( 0.5 , 0.5 , 0.5 ) , ( 1.0 , 0.0 , 0.0 ) )
  , Edge3 ( ( -0.5 , -0.5 , -0.5 ) , ( 0.0 , 0.0 , -1.0 ) )
  , Edge3 ( ( -0.5 , -0.5 , -0.5 ) , ( 0.0 , -1.0 , 0.0 ) )
  , Edge3 ( ( -0.5 , -0.5 , -0.5 ) , ( -1.0 , 0.0 , 0.0 ) )
  , Edge3 ( ( -0.5 , 0.5 , -0.5 ) , ( 0.0 , 0.0 , -1.0 ) )
  , Edge3 ( ( -0.5 , 0.5 , -0.5 ) , ( 0.0 , 1.0 , 0.0 ) )
  , Edge3 ( ( -0.5 , 0.5 , -0.5 ) , ( -1.0 , 0.0 , 0.0 ) )
  , Edge3 ( ( 0.5 , -0.5 , -0.5 ) , ( 0.0 , 0.0 , -1.0 ) )
  , Edge3 ( ( 0.5 , -0.5 , -0.5 ) , ( 0.0 , -1.0 , 0.0 ) )
  , Edge3 ( ( 0.5 , -0.5 , -0.5 ) , ( 1.0 , 0.0 , 0.0 ) )
  , Edge3 ( ( 0.5 , 0.5 , -0.5 ) , ( 0.0 , 0.0 , -1.0 ) )
  , Edge3 ( ( 0.5 , 0.5 , -0.5 ) , ( 0.0 , 1.0 , 0.0 ) )
  , Edge3 ( ( 0.5 , 0.5 , -0.5 ) , ( 1.0 , 0.0 , 0.0 ) )
  ]
)
```

This is a bounded cell: it has finite edges only. The other ones are not
bounded, they have infinite edges:

```haskell
> head v
( [ -1.0 , -1.0 , 0.0 ]
, [ Edge3 ( ( -0.5 , -0.5 , 0.5 ) , ( 0.0 , -1.0 , 0.0 ) )
  , Edge3 ( ( -0.5 , -0.5 , 0.5 ) , ( -1.0 , 0.0 , 0.0 ) )
  , IEdge3
      ( ( -0.5 , -0.5 , 0.5 )
      , ( -0.5773502691896258 , -0.5773502691896258 , 0.5773502691896258 )
      )
  , Edge3 ( ( -0.5 , -0.5 , -0.5 ) , ( 0.0 , -1.0 , 0.0 ) )
  , Edge3 ( ( -0.5 , -0.5 , -0.5 ) , ( -1.0 , 0.0 , 0.0 ) )
  , IEdge3
      ( ( -0.5 , -0.5 , -0.5 )
      , ( -0.5773502691896258 , -0.5773502691896258 , -0.5773502691896258 )
      )
  , IEdge3 ( ( -1.0 , 0.0 , 0.0 ) , ( 1.0 , 0.0 , 0.0 ) )
  , IEdge3 ( ( 0.0 , -1.0 , 0.0 ) , ( 0.0 , -1.0 , 0.0 ) )
  ]
)
```

[![voronoi_cuboctahedron.gif](https://s13.postimg.org/6e0vngu1j/voronoi_cuboctahedron.gif)](https://postimg.org/image/ceykkjgnn/)


## Convex hull

The `convexHull` function of the `ConvexHull` module generates the convex hull
of a list of points.

```haskell
import ConvexHull
import ConvexHull.Examples -- for the function randomInCube
points <- randomInCube 100 -- 100 random points in a cube
hull <- convexHull points False False Nothing
```

The vertices of the convex hull are stored in the field `_hvertices`:

```haskell
> _hvertices hull
fromList
  [ ( 3
    , Vertex
        { _point =
            [ 0.7872072051657094 , 0.450772463858757 , 1.9900427529711773e-2 ]
        , _neighfacets = fromList [ 42 , 43 , 47 , 48 ]
        , _neighvertices = fromList [ 1 , 11 , 64 , 88 ]
        , _neighridges = fromList [ 70 , 71 , 72 , 77 ]
        }
    )
  , ( 6
    , Vertex
  ......
```

The edges in the field `_hedges`:

```haskell
> _hedges hull
fromList
  [ ( Pair 14 70
    , ( [ 0.9215432980174852 , 0.8554065771602318 , 0.9842902519648512 ]
      , [ 0.9497713758656887 , 0.998006476041318 , 0.7243639875028591 ]
      )
    )
  , ( Pair 84 99
  ......
```

The facets in the field `_hfacets`:

```haskell
> _hfacets hull
fromList
  [ ( 0
    , Facet
        { _fvertices =
            fromList
              [ ( 4
                , [ 1.5757133629105136e-3
                  , 0.6442797662244039
                  , 0.7058559215899725
                  ]
                )
              , ( 67
                , [ 2.7500520534961326e-2
                  , 0.37516259577251554
                  , 0.7331611715042575
                  ]
                )
              , ( 77
                , [ 3.46399386146774e-2
                  , 5.575911794526589e-2
                  , 0.46787034305814157
                  ]
                )
              ]
        , _fridges =
            fromList
              [ ( 0
                , Ridge
                    { _rvertices =
                        fromList
                          [ ( 4
                            , [ 1.5757133629105136e-3
                              , 0.6442797662244039
                              , 0.7058559215899725
                              ]
                            )
                          , ( 77
                            , [ 3.46399386146774e-2
                              , 5.575911794526589e-2
                              , 0.46787034305814157
                              ]
                            )
                          ]
                    , _ridgeOf = fromList [ 0 , 4 ]
                    }
                )
              , ( 1
                , Ridge
                    { _rvertices =
                        fromList
                          [ ( 4
                            , [ 1.5757133629105136e-3
                              , 0.6442797662244039
                              , 0.7058559215899725
                              ]
                            )
                          , ( 67
                            , [ 2.7500520534961326e-2
                              , 0.37516259577251554
                              , 0.7331611715042575
                              ]
                            )
                          ]
                    , _ridgeOf = fromList [ 0 , 2 ]
                    }
                )
              , ( 2
                , Ridge
                    { _rvertices =
                        fromList
                          [ ( 67
                            , [ 2.7500520534961326e-2
                              , 0.37516259577251554
                              , 0.7331611715042575
                              ]
                            )
                          , ( 77
                            , [ 3.46399386146774e-2
                              , 5.575911794526589e-2
                              , 0.46787034305814157
                              ]
                            )
                          ]
                    , _ridgeOf = fromList [ 0 , 1 ]
                    }
                )
              ]
        , _centroid =
            [ 2.1238724170849748e-2 , 0.3584004933140618 , 0.6356291453841239 ]
        , _normal =
            [ -0.9930268604214181
            , -8.766369712550202e-2
            , 7.882087723357102e-2
            ]
        , _offset = 2.40848904384814e-3
        , _area = 4.0339144929987907e-2
        , _neighbors = fromList [ 1 , 2 , 4 ]
        , _family = None
        , _fedges =
            fromList
              [ ( Pair 4 67
                , ( [ 1.5757133629105136e-3
                    , 0.6442797662244039
                    , 0.7058559215899725
                    ]
                  , [ 2.7500520534961326e-2
                    , 0.37516259577251554
                    , 0.7331611715042575
                    ]
                  )
                )
              , ( Pair 67 77
                , ( [ 2.7500520534961326e-2
                    , 0.37516259577251554
                    , 0.7331611715042575
                    ]
                  , [ 3.46399386146774e-2
                    , 5.575911794526589e-2
                    , 0.46787034305814157
                    ]
                  )
                )
              , ( Pair 4 77
                , ( [ 1.5757133629105136e-3
                    , 0.6442797662244039
                    , 0.7058559215899725
                    ]
                  , [ 3.46399386146774e-2
                    , 5.575911794526589e-2
                    , 0.46787034305814157
                    ]
                  )
                )
              ]
        }
    )
  , ( 1
    , Facet
  ......
```

[![convexhull02.gif](https://s17.postimg.org/zbl78b1bz/convexhull02.gif)](https://postimg.org/image/80zw0dyez/)
