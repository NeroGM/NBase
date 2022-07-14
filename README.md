[![License: CC0-1.0](https://img.shields.io/github/license/NeroGM/NBase?color=e6e6e6&label=License&logo=creative-commons&logoColor=ffffff)](https://creativecommons.org/publicdomain/zero/1.0/)
[![Haxelib](https://img.shields.io/github/v/release/NeroGM/NBase?color=ea8220&label=Haxelib&logo=haxe)](https://lib.haxe.org/p/NBase/)
[![Build Test: Javascript](https://github.com/NeroGM/NBase/actions/workflows/build_js.yml/badge.svg)](https://github.com/NeroGM/NBase/actions/workflows/build_js.yml)

<p align="center"><img src="https://svgshare.com/i/j2Z.svg" alt="NBase Logo" width="50%"/></p>

NBase is a game framework/engine built on top of [Heaps](https://heaps.io). Heaps is the engine behind cross-platform games like Dead Cells, Evoland, Northgard and Dune.

[Introduction](https://github.com/NeroGM/NBase/wiki/Introduction) - [Supported Platforms](https://github.com/NeroGM/NBase/wiki/Supported-platforms)

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

Compile your app using the corresponding `haxe compile_X.hxml`. For example, use `haxe compile_js.hxml` to build a javascript file, then launch `"build/js/index.html"`.

Or you can run and debug directly from VS Code if your `".vscode/launch.json"` is correctly configured.

## Learn

[API Documentation](https://nerogm.github.io/NBase/tpl/documentation/nb/index.html) | [NBase Wiki](https://github.com/NeroGM/NBase/wiki) | [Heaps Wiki](https://github.com/HeapsIO/heaps/wiki)

## Follow & Support

[Twitter](https://twitter.com/Nero__GM) | [Patreon](https://www.patreon.com/NeroGM) | [Ko-fi](https://ko-fi.com/nerogm)

## Community

[![Haxe Discord](https://img.shields.io/discord/162395145352904705?label=Haxe%20Discord&logo=discord)](https://discordapp.com/invite/sWCGm33)
[![NeroGM's Discord](https://img.shields.io/discord/770699254611836939?label=NeroGM's%20Discord&logo=discord)](https://discord.gg/yb2Ej6YsE3)