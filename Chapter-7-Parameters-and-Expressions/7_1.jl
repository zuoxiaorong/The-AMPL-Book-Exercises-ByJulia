using JuMP
using SCIP

#Figure 4-1

function data()
    ORIG = 1:3              #GARY CLEV PITT
    DEST = 1:7              #FRA DET LAN WIN STL FRE LAF
    PROD = 1:3              #bands coils plate
    supply = [
        400 700 800
        800 1600 1800
        200 300 300
    ]
    demand = [
        300 300 100 75 650 225 250
        500 750 400 250 950 850 500
        100 100 0 50 200 100 250 
    ]
    limit = fill(625, length(ORIG), length(DEST))
    cost =[
        [
            30 10 8 10 11 71 6
            22 7 10 7 21 82 13
            19 11 12 10 25 83 15
        ],
        [
            39 14 11 14 16 82 8
            27 9 12 9 26 95 17
            24 14 17 13 28 99 20
        ],
        [
            41 15 12 16 17 86 8
            29 9 13 9 28 99 18
            26 14 17 13 31 104 20
        ]
    ]
    return ORIG, DEST, PROD, supply', demand', limit, cost
end

function str()
    ORIG = ["GARY", "CLEV", "PITT"]
    DEST = ["FRA", "DET", "LAN", "WIN", "STL", "FRE", "LAF"]
    PROD = ["bands", "coils", "plate"]
    return ORIG, DEST, PROD
end

function lpmodel(model, ORIG, DEST, PROD, supply, demand, limit, cost)
    @variable(model, Trans[ORIG,DEST,PROD], lower_bound = 0)

    @objective(model, Min, sum(cost[p][i,j]*Trans[i,j,p] for i in ORIG for j in DEST for p in PROD))
    @constraint(model, [i in ORIG, p in PROD], sum(Trans[i,j,p] for j in DEST) <= supply[i,p])
    @constraint(model, [j in DEST, p in PROD], sum(Trans[i,j,p] for i in ORIG) >= demand[j,p])
    @constraint(model, [i in ORIG, j in DEST], sum(Trans[i,j,p] for p in PROD) <= limit[i,j])
    return model
end

function startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)

    ORIG, DEST, PROD, supply, demand, limit, cost = data()
    model = lpmodel(model, ORIG, DEST, PROD, supply, demand, limit, cost)
    optimize!(model)
end

function exercise()
    ORIG, DEST, PROD, supply, demand, limit, cost = data()
    O, D, P = str()

    e1 = isempty(intersect(O,D))
    e2 = length(D) >length(O)
    e3 = all(x -> x <= 1000, [sum.(eachrow(demand))...])
    e4 = isequal([sum.(eachcol(demand))...], [sum.(eachcol(supply))...])
    e5 = isequal(sum(demand), sum(supply))
    e6 = isless([sum.(eachrow(supply))...], [sum.(eachrow(limit))...])
    e7 = isless([sum.(eachrow(demand))...], [sum.(eachcol(limit))...])
    return e1,e2,e3,e4,e5,e6,e7
end

# solution 
# true, true, false, true, true, true, true