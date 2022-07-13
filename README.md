[![License: CC0-1.0](https://img.shields.io/github/license/NeroGM/NBase?color=e6e6e6&label=License)](https://creativecommons.org/publicdomain/zero/1.0/)
[![Haxelib](https://img.shields.io/github/v/release/NeroGM/NBase?color=ea8220&label=Haxelib)](https://lib.haxe.org/p/NBase/)
[![Build Test: Javascript](https://github.com/NeroGM/NBase/actions/workflows/build_js.yml/badge.svg)](https://github.com/NeroGM/NBase/actions/workflows/build_js.yml)

<p align="center"><img src="https://svgshare.com/i/j2Y.svg" alt="NBase Logo" width="50%"/></p>

NBase is a framework/engine built on top of [Heaps](https://heaps.io).

## Installation

You must have [Haxe](https://haxe.org) installed.

Install NBase:
```
haxelib install NBase
```

To make desktop apps [get a release of HashLink](https://github.com/HaxeFoundation/hashlink/releases). If you can't find Linux/Mac releases, check [the latest release](https://github.com/HaxeFoundation/hashlink/releases/tag/latest).

Put the release in a folder so that your project can find the executable. (See `".vscode/launch.json"`.)

Install hashlink dependencies:
```
haxelib install hlopenal
haxelib install hlsdl
haxelib install hldx
```

## Quick start a project

To create a project folder quickly, in your projects folder, use: 
```
haxelib run nbase [ProjectName]
```

## Compilation

Compile your app using the corresponding `haxe compile_X.hxml`. For example, use `haxe compile_js.hxml` for javascript build.

See that you're "launch.json" file is correctly configured to run and debug directly from VS Code.

## Links

[NBase Documentation](https://nerogm.github.io/NBase/tpl/documentation/nb/index.html) | [Heaps Wiki](https://github.com/HeapsIO/heaps/wiki)

[The Haxe Discord](https://discordapp.com/invite/0uEuWH3spjck73Lo) | [My Discord](https://discord.gg/yb2Ej6YsE3) | [Twitter](https://twitter.com/home) | [Patreon](https://www.patreon.com/NeroGM) | [Ko-fi](https://ko-fi.com/nerogm)