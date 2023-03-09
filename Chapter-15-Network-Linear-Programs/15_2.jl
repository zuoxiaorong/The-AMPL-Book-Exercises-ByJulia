using JuMP
using SCIP

function Shortest_path_model(model, INTER, ROADS, entr, exit, time)
    @variable(model, Use[i in INTER, j in INTER; (i, j) in ROADS], lower_bound = 0)

    @objective(model, Min, sum(time[k]*Use[i,j] for i in INTER for j in INTER for k in 1:length(time) if (i,j) == ROADS[k]))
    @constraint(model, sum(Use[i,j] for (i,j) in ROADS if i == entr) == 1)
    @constraint(model, [k in setdiff(INTER, [entr,exit])],  sum(Use[i,k] for i in INTER if (i,k) in ROADS )  == sum(Use[k,j] for j in INTER if (k,j) in ROADS ))
    return model
end

function a_data()
    INTER = ["A", "B", "C", "D", "E", "F"]
    entr = "A"
    exit = "F"
    ROADS = [("A","B") ("A","C") ("B","C") ("B","D") ("B","E") ("C","E") ("D","E") ("D","F") ("E","F")]
    time = [13, 12, 1, 6, 9, 7, 4, 13, 12]
    I = 1:length(INTER)
    LINKS = [(i,j) for i in 1:length(INTER) for j in 1:length(INTER) if (INTER[i], INTER[j]) in ROADS]
    EN_num = findfirst(x -> x == entr, INTER)
    EX_num = findfirst(x -> x == exit, INTER)
    return INTER, ROADS, I, LINKS, EN_num, EX_num, time
end

function Maximum_traffic_flow_model(model, INTER, ROADS, entr, exit, cap)
    @variable(model, Traff[i in INTER, j in INTER; (i, j) in ROADS], lower_bound = 0, upper_bound = cap[findfirst(x -> x == (i,j), ROADS)])

    @objective(model, Max, sum(Traff[i,j] for (i,j) in ROADS if i in entr && (j in entr) == false))
    @constraint(model, [k in setdiff(INTER, union(entr,exit))],  sum(Traff[i,k] for i in INTER if (i,k) in ROADS ) == sum(Traff[k,j] for j in INTER if (k,j) in ROADS ))
    return model
end

function b_data()
    INTER = ["A", "B", "C", "D", "E", "F"]
    entr = ["A"]
    exit = ["F"]
    ROADS = [("A","B") ("A","C") ("B","C") ("B","D") ("B","E") ("C","E") ("D","E") ("D","F") ("E","F")]
    cap = [13, 12, 1, 6, 9, 7, 4, 13, 12]
    I = 1:length(INTER)
    LINKS = [(i,j) for i in 1:length(INTER) for j in 1:length(INTER) if (INTER[i], INTER[j]) in ROADS]
    EN_num = [findfirst(x -> x == entr[i], INTER) for i in 1:length(entr)]
    EX_num = [findfirst(x -> x == exit[i], INTER) for i in 1:length(exit)]
    return INTER, ROADS, I, LINKS, EN_num, EX_num, cap
end

function c_data()
    INTER = ["A", "B", "C", "D", "E", "F"]
    entr = ["A", "B"]
    exit = ["E", "F"]
    ROADS = [("A","B") ("A","C") ("B","C") ("B","D") ("B","E") ("C","E") ("D","E") ("D","F") ("E","F")]
    cap = [13, 12, 1, 6, 9, 7, 4, 13, 12]
    I = 1:length(INTER)
    LINKS = [(i,j) for i in 1:length(INTER) for j in 1:length(INTER) if (INTER[i], INTER[j]) in ROADS]
    EN_num = [findfirst(x -> x == entr[i], INTER) for i in 1:length(entr)]
    EX_num = [findfirst(x -> x == exit[i], INTER) for i in 1:length(exit)]
    return INTER, ROADS, I, LINKS, EN_num, EX_num, cap
end

function  startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)
    
    I, R, INTER, ROADS, entr, exit, cap = b_data()
    model = Maximum_traffic_flow_model(model, INTER, ROADS, entr, exit, cap)
    optimize!(model)
    # ship = value.(model[:Use])
    # assign_set = [(I[i] => I[j]) for (i, j) in ROADS if  ship[i,j] == 1]                                                      #(a)
    ship = value.(model[:Traff])
    assign_set = [(R[k] => ship[i,j]) for i in INTER for j in INTER for k in 1:length(ROADS) if ROADS[k] == (i,j)]            #(b) & (c)
    println(assign_set)
end
startmodel()

# solution 
# (a) obj = +3.10000000000000e+01
# path = ["A" => "C", "C" => "E", "E" => "F"]
# (b) obj = +1.80000000000000e+01
# Flow = [("A", "B") => 11.0, ("A", "C") => 7.0, ("B", "C") => 0.0, ("B", "D") => 6.0, ("B", "E") => 5.0, ("C", "E") => 7.0, ("D", "E") => 0.0, ("D", "F") => 6.0, ("E", "F") => 12.0]
# (c) obj = +2.20000000000000e+01
# Flow = [("A", "B") => 13.0, ("A", "C") => 7.0, ("B", "C") => 0.0, ("B", "D") => 6.0, ("B", "E") => 9.0, ("C", "E") => 7.0, ("D", "E") => -0.0, ("D", "F") => 6.0, ("E", "F") => -0.0]
