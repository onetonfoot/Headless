import JSON

#Methods
struct Command
    id
    method
    params
end

function JSON.lower(cmd::Command)
    #needs to be changed
    params = filter(p ->  !isnothing(p[2]), cmd.params)
    Dict(:id     => cmd.id,
         :method => cmd.method,
         :params => params)
end
