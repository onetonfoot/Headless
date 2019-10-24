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
push!(LOAD_PATH,"../../src/")
using Headless
```

```@repl abc
chrome = Headless.Chrome(headless=true, port=9522)
```

Chrome should start with one tab, you can get the tab name with `tabnames`

```@repl abc
tabnames(chrome)
```

Tabs can be used execute commands such as navigating to a new page.

```@repl abc
using Headless.Protocol: Page
cmd = Page.navigate("https://www.google.com")
chrome[:tab1](cmd)
```

Finally to close the browser

```@repl abc
close(chrome)
```