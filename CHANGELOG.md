# Changelog


## 0.2.0 - The Graph, Shapes and Tiled Release - 21 July 2022

Major additions/changes:
 - Added Tiled v1.9 map loading ([`nb.Map`][nb.Map]) ([#5][#5])
 - Added a graph/pathfinding class ([`nb.Graph`][nb.Graph])
 - Refactored and documented [`nb.shape`][nb.shape] package ([#8][#8])
 - Added functions to [`nb.phys.Collision`][nb.phys.Collision] for collision detection between [`nb.shape.Shape`][nb.shape.Shape]s

Other additions/changes:
 - Added the data structure [`nb.ds.Set`][nb.ds.Set]
 - Added [`nb.ext.SegmentExt.checkSeg`][nb.ext.SegmentExt.checkSeg] function
 - Added [`nb.ext.PointExt.getFarthestPoints`][nb.ext.PointExt.getFarthestPoints] function
 - Refactored and renamed `nb.ext.MathExt.getSupportPoint` to [`getFarthestPoints`][nb.ext.MathExt.getFarthestPoints]
 - [`nb.Manager`][nb.Manager]'s traces can now be disabled using [`nb.Manager.logging`][nb.Manager.logging]

Full Changelog: [`v0.1.2...v0.2.0`](https://github.com/NeroGM/NBase/compare/v0.1.2...v0.2.0)

---

### 0.1.2 - 13 July 2022

Summary:
 - Fix: haxelib.json now uses git dependencies
 - Fix: NFileSystem doesn't check for files on js when `serv` is not defined
 - Protected some variables

Full Changelog: [`v0.1.1...v0.1.2`](https://github.com/NeroGM/NBase/compare/v0.1.1...v0.1.2)

### 0.1.1 - 12 July 2022

Summary:
 - Edited md files
 - Protected some variables

Full Changelog: [`v0.1.0...v0.1.1`](https://github.com/NeroGM/NBase/compare/v0.1.0...v0.1.1)

---

## 0.1.0 - The First Release - 10 July 2022



[#5]: https://github.com/NeroGM/NBase/pull/5 "Pull Request #5"
[#8]: https://github.com/NeroGM/NBase/pull/8 "Pull Request #8"
[nb.ds.Set]: https://nerogm.github.io/NBase/tpl/documentation/nb/ds/Set.html "Go to API documentation"
[nb.ext.MathExt.getFarthestPoints]: https://nerogm.github.io/NBase/tpl/documentation/nb/ext/MathExt.html#getFarthestPoints "Go to API documentation"
[nb.ext.PointExt.getFarthestPoints]: https://nerogm.github.io/NBase/tpl/documentation/nb/ext/PointExt.html#getFarthestPoints "Go to API documentation"
[nb.ext.SegmentExt.checkSeg]: https://nerogm.github.io/NBase/tpl/documentation/nb/ext/SegmentExt.html#checkSeg "Go to API documentation"
[nb.Graph]: https://nerogm.github.io/NBase/tpl/documentation/nb/Graph.html "Go to API documentation"
[nb.Manager]: https://nerogm.github.io/NBase/tpl/documentation/nb/Manager.html "Go to API documentation"
[nb.Manager.logging]: https://nerogm.github.io/NBase/tpl/documentation/nb/Manager.html#logging "Go to API documentation"
[nb.Map]: https://nerogm.github.io/NBase/tpl/documentation/nb/Map.html "Go to API documentation"
[nb.phys.Collision]: https://nerogm.github.io/NBase/tpl/documentation/nb/phys/Collision.html "Go to API documentation"
[nb.shape.Shape]: https://nerogm.github.io/NBase/tpl/documentation/nb/shape/Shape.html "Go to API documentation"
[nb.shape]: https://nerogm.github.io/NBase/tpl/documentation/nb/shape/ "Go to API documentation"
