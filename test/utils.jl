using Base.Sys: islinux, isapple

function kill_port()

    cmd = if islinux()
        `lsof -i4`
    else
        `lsof -nP -i4`
    end

    try
        cmd = pipeline(cmd, `grep :9222`)
        result = read(cmd, String) |>  rstrip |> x -> split(x, "\n")

        for line in result
            pid = split(line)[2]
            run(`kill -9 $pid`)
            print("Killed $pid")
        end
    catch
        print("Nothing to kill")
    end
end

kill_port()
