# Home

A package for controling chrome through the [devtools protocol](https://chromedevtools.github.io/devtools-protocol/).

## Installation

Since the package is currently unregistered

```julia
import Pkg
Pkg.add("https://github.com/onetonfoot/Headless.git")
```

Ensure you already have chrome installed.

## Getting Started

To open a instance of chrome with a single tab run.

```@setup abc
using Headless
```

```@repl abc
chrome = Headless.Chrome(headless=true, port=9522)
```