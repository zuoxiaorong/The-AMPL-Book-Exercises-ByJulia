using JuMP
using SCIP

function Shortest_path_model(model, INTER, ROADS, entr, exit, time)
    @variable(model, Use[i in INTER, j in INTER; (i, j) in ROADS], lower_bound = 0)

    @objective(model, Min, sum(time[k]*Use[i,j] for i in INTER for j in INTER for k in 1:length(time) if (i,j) == ROADS[k]))
    @constraint(model, sum(Use[i,j] for (i,j) in ROADS if i == entr) == 1)
    @constraint(model, [k in setdiff(INTER, [entr,exit])],  sum(Use[i,k] for i in INTER if (i,k) in ROADS ) == sum(Use[k,j] for j in INTER if (k,j) in ROADS ))
    return model
end

function data()
    INTER = ["a", "b", "c", "d", "e", "f", "g"]
    entr = "a"
    exit = "g"
    ROADS = [("a", "b"), ("a", "c"), ("b", "d"), ("b", "e"), ("c", "d"), ("c", "f"), ("d", "e"), ("d", "f"), ("e", "g"), ("f", "g")]
    time =[50, 100, 40, 20, 60, 20, 50, 60, 70, 70]
    I = 1:length(INTER)
    LINKS = [(i,j) for i in 1:length(INTER) for j in 1:length(INTER) if (INTER[i], INTER[j]) in ROADS]
    EN_num = findfirst(x -> x == entr, INTER)
    EX_num = findfirst(x -> x == exit, INTER)
    return INTER, ROADS, I, LINKS, EN_num, EX_num, time
end


function  startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)
    
    I, R, INTER, ROADS, entr, exit, time = data()
    model = Shortest_path_model(model, INTER, ROADS, entr, exit, time)
    optimize!(model)
    ship = value.(model[:Use])
    assign_set = [(I[i] => I[j]) for (i, j) in ROADS if  ship[i,j] == 1]
end
startmodel()

# solution 
# obj = +1.40000000000000e+02
# path = ["a" => "b", "b" => "e", "e" => "g"]