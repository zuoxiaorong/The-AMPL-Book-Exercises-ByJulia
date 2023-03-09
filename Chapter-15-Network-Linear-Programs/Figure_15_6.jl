using JuMP
using SCIP

function Maximum_traffic_flow_model(model, INTER, ROADS, entr, exit, cap)
    @variable(model, Traff[i in INTER, j in INTER; (i, j) in ROADS], lower_bound = 0, upper_bound = cap[findfirst(x -> x == (i,j), ROADS)])

    @objective(model, Max, sum(Traff[i,j] for (i,j) in ROADS if i == entr))
    @constraint(model, [k in setdiff(INTER, [entr,exit])],  sum(Traff[i,k] for i in INTER if (i,k) in ROADS ) == sum(Traff[k,j] for j in INTER if (k,j) in ROADS ))
    return model
end

function data()
    INTER = ["a", "b", "c", "d", "e", "f", "g"]
    entr = "a"
    exit = "g"
    ROADS = [("a", "b"), ("a", "c"), ("b", "d"), ("b", "e"), ("c", "d"), ("c", "f"), ("d", "e"), ("d", "f"), ("e", "g"), ("f", "g")]
    cap =[50, 100, 40, 20, 60, 20, 50, 60, 70, 70]
    I = 1:length(INTER)
    LINKS = [(i,j) for i in 1:length(INTER) for j in 1:length(INTER) if (INTER[i], INTER[j]) in ROADS]
    EN_num = findfirst(x -> x == entr, INTER)
    EX_num = findfirst(x -> x == exit, INTER)
    return INTER, ROADS, I, LINKS, EN_num, EX_num, cap
end

function new_data()
    INTER = ["a", "b", "c", "d", "e", "f", "g"]
    entr = ["a"]
    exit = ["g"]
    ROADS = [("a", "b"), ("a", "c"), ("b", "d"), ("b", "e"), ("c", "d"), ("c", "f"), ("d", "e"), ("d", "f"), ("e", "g"), ("f", "g")]
    cap =[50, 100, 40, 20, 60, 20, 50, 60, 70, 70]
    I = 1:length(INTER)
    LINKS = [(i,j) for i in 1:length(INTER) for j in 1:length(INTER) if (INTER[i], INTER[j]) in ROADS]
    EN_num = [findfirst(x -> x == entr[i], INTER) for i in 1:length(entr)]
    EX_num = [findfirst(x -> x == exit[i], INTER) for i in 1:length(exit)]
    return INTER, ROADS, I, LINKS, EN_num, EX_num, cap
end

function new_Maximum_traffic_flow_model(model, INTER, ROADS, entr, exit, cap)
    @variable(model, Traff[i in INTER, j in INTER; (i, j) in ROADS], lower_bound = 0, upper_bound = cap[findfirst(x -> x == (i,j), ROADS)])

    @objective(model, Max, sum(Traff[i,j] for (i,j) in ROADS if i in entr && (j in entr) == false))
    @constraint(model, [k in setdiff(INTER, union(entr,exit))],  sum(Traff[i,k] for i in INTER if (i,k) in ROADS ) == sum(Traff[k,j] for j in INTER if (k,j) in ROADS ))
    return model
end

function  startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)
    
    I, R, INTER, ROADS, entr, exit, time = new_data()
    model = new_Maximum_traffic_flow_model(model, INTER, ROADS, entr, exit, time)
    optimize!(model)
    ship = value.(model[:Traff])
    assign_set = [(R[k] => ship[i,j]) for i in INTER for j in INTER for k in 1:length(ROADS) if ROADS[k] == (i,j)]
end
startmodel()

# solution 
# obj = +1.30000000000000e+02
# Flow = [
#     ("a", "b") => 50.0
#     ("a", "c") => 80.0
#     ("b", "d") => 30.0
#     ("b", "e") => 20.0
#     ("c", "d") => 60.0
#     ("c", "f") => 20.0
#     ("d", "e") => 40.0
#     ("d", "f") => 50.0
#     ("e", "g") => 60.0
#     ("f", "g") => 70.0
# ]