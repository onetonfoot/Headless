
#userfull for debugging
function kill_port()
    cmd = read(`lsof -i4`,String) |>
    x -> split(x, "\n") |>
    x -> filter(l -> occursin("9222",l) && occursin("chrome",l), x) .|>
    split .|> x -> x[2] .|> pid -> `kill -9 $pid` |>
    run
end

kill_port()
