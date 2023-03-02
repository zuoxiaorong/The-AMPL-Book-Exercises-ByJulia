using JuMP
using SCIP

function data()
    T = 1:4
    PROD = 1:2                  #bands coils
    AREAS = [[1,2], [1,2,3]]    #bans:east north; coils:east, west, export
    avail = [40, 40, 32, 40]
    rate = [200, 140]
    inv0 = [10, 0]
    prodcost = [10, 11]
    invcost = [2.5, 3]
    revenue = [[25 26 27 27; 26.5 27.5 28 28.5],[30 35 37 39; 29 32 33 35; 25 25 25 28]]
    market = [[2000 2000 1500 2000; 4000 4000 2500 4500],[1000 800 1000 1100; 2000 1200 2000 2300; 1000 500 500 800]]
    return T, PROD, AREAS, avail, rate, inv0, prodcost, invcost, revenue, market
end   

function LPmodel(model, T, PROD, AREAS, avail, rate, inv0, prodcost, invcost, revenue, market)
    @variable(model, Make[PROD, T], lower_bound = 0)
    @variable(model, Inv[PROD, T], lower_bound = 0)
    @variable(model, Sell[p in PROD, a in AREAS[p],t in T], lower_bound = 0, upper_bound = market[p][a,t])
    
    @objective(model, Max, sum(sum(revenue[p][a,t]*Sell[p,a,t]-prodcost[p]*Make[p,t]-invcost[p]*Inv[p,t] for a in AREAS[p]) for p in PROD for t in T))

    @constraint(model, [t in T], sum(Make[p,t]/rate[p] for p in PROD) <= avail[t])
    @constraint(model, [p in PROD], Inv[p,1] == inv0[p])
    @constraint(model, [p in PROD, t in 2:length(T)], Inv[p,t] == Inv[p,t-1] + Make[p,t] - sum(Sell[p,a,t] for a in AREAS[p]))
    return model
end

function  startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)
    T, PROD, AREAS, avail, rate, inv0, prodcost, invcost, revenue, market = data()
    model  = LPmodel(model, T, PROD, AREAS, avail, rate, inv0, prodcost, invcost, revenue, market)
    optimize!(model)   
    make = value.(model[:Make])  
    inv = value.(model[:Inv])
    sell = value.(model[:Sell])
    return make, inv, sell
end

function str()
    P = ["bands", "coils"]
    A = [["east", "north"], ["east", "west", "export"]]
    return P, A
end 

function exercise()
    P, A = str()
    T, PROD, AREAS, avail, rate, inv0, prodcost, invcost, revenue, market = data()

    make, inv, sell = startmodel()
    # Sets = intersect(Vector.(A)...)
    # Sets = [(P[p], A[p][a], "week$(t)") for p in PROD for a in AREAS[p] for t in T if sell[p,a,t] == market[p][a,t]]
    # Sets = [(P[p], "week$(t)") for p in PROD for t in T if sum(sell[p,a,t] for a in AREAS[p]) >= 6000]
end

#  solution
# ["east"]
# [("bands", "east", "week1"), ("bands", "east", "week2"), ("bands", "east", "week3"), ("bands", "east", "week4"), ("bands", "north", "week1"), ("bands", "north", "week2"), ("bands", "north", "week3"), ("bands", "north", "week4"), ("coils", "east", "week1"), ("coils", "east", "week2"), ("coils", "east", "week3"), ("coils", "west", "week1"), ("coils", "export", "week1")]
# [("bands", "week1"), ("bands", "week2"), ("bands", "week4")]