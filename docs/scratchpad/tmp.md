You can get the name of the tabs with

```jldoctest
tabnames(chrome)

# output

1-element Array{Symbol,1}:
 :tab1
```

To open a new tab run

```jldoctest
tab2 = opentab!(chrome, :tab2)

# output

tab
```

You can use tabs to excute commands

```
...
```

Finally to close the browser

```jldoctest
close(chrome)

# output

true
```