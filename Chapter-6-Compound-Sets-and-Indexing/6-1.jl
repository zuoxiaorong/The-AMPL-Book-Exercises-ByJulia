using JuMP
using SCIP

function data()
    ORIG = 1:3              #GARY CLEV PITT
    DEST = 1:7              #FRA DET LAN WIN STL FRE LAF
    PROD = 1:3              #bands coils plate
    
    avail = [20, 15, 20]
    demand =[
        300 300 100 75 650 225 250
        500 750 400 250 950 850 500
        100 100 0 50 200 100 250    
    ]
    rate = [
        200 190 230
        140 130 160
        160 160 170
    ]
    make_cost = [
        180 190 190
        170 170 180
        180 185 185    
    ]
    cost = [
        30 10 8 10 11 71 6
        22 7 10 7 21 82 13
        19 11 12 10 25 83 15        
        39 14 11 14 16 82 8
        27 9 12 9 26 95 17
        24 14 17 13 28 99 20
        41 15 12 16 17 86 8
        29 9 13 9 28 99 18
        26 14 17 13 31 104 20
    ]
    trans_cost = cat(cost[1:3,:], cost[4:6,:], cost[7:9,:], dims = 3)
    return ORIG, DEST, PROD, avail, demand', rate', make_cost', trans_cost
end

function str()
    O = ["GARY", "CLEV", "PITT"]
    D = ["FRA", "DET", "LAN", "WIN", "STL", "FRE", "LAF"]
    P = ["bands", "coils", "plate"]
    return O,D,P
end    


function lpmodel(model, ORIG, DEST, PROD, avail, demand, rate, make_cost, trans_cost)
    @variable(model, Make[ORIG,PROD], lower_bound = 0)
    @variable(model, Trans[ORIG,DEST,PROD], lower_bound = 0)

    @objective(model, Min, sum(make_cost[i,p] * Make[i,p] for i in ORIG for p in PROD) + sum(trans_cost[i,j,p] * Trans[i,j,p] for i in ORIG for j in DEST for p in PROD))

    @constraint(model, Time[i in ORIG], sum((1/rate[i,p])*Make[i,p] for p in PROD) <= avail[i])
    @constraint(model, Supply[i in ORIG, p in PROD], sum(Trans[i,j,p] for j in DEST) == Make[i,p])
    @constraint(model, Demand[j in DEST, p in PROD], sum(Trans[i,j,p] for i in ORIG) == demand[j,p])
    return model
end

function model()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)

    ORIG, DEST, PROD, avail, demand, rate, make_cost, trans_cost = data()
    model = lpmodel(model, ORIG, DEST, PROD, avail, demand, rate, make_cost, trans_cost)
    optimize!(model) 
    production = value.(model[:Make])
    ship_production = value.(model[:Trans])
    return production, ship_production
end

function a()
    O,D,P = str()
    ORIG, DEST, PROD, avail, demand, rate, make_cost, trans_cost = data()
    # Links = []
    # map(x -> push!(Links, D[x[1][1]] => P[x[1][2]]), eachrow(findall(x -> x > 500, demand)))
    # map(x -> push!(Links, O[x[1][1]] => P[x[1][2]]), eachrow(findall(x -> x > 150, rate)))
    # map(x -> push!(Links, (O[x[1][1]],D[x[1][2]],P[x[1][3]])), eachrow(findall(x -> x <= 10, trans_cost)))
    # map(x -> push!(Links, (O[x[1][1]],D[x[1][2]])), eachrow(findall(x -> x <= 10, trans_cost[:,2,:])))
    # map(x -> push!(Links, (O[x[1][1]], P[x[1][2]])), eachrow(findall(x -> x <= 30000, rate.*make_cost)))
    # Links = [(O[i], D[j], P[p]) for i in ORIG, j in DEST, p in PROD if trans_cost[i,j,p] >= 0.15*make_cost[i,p]]
    # Links = [(O[i], D[j], P[p]) for i in ORIG, j in DEST, p in PROD if trans_cost[i,j,p] >= 0.15*make_cost[i,p] && trans_cost[i,j,p] <= 0.25*make_cost[i,p]]
end

function b()
    O,D,P = str()
    ORIG, DEST, PROD, avail, demand, rate, make_cost, trans_cost = data()   
    production, ship_production = model()
 
    # (b)
    # Links = [(O[i], P[p]) for i in ORIG, p in PROD if production[i,p] >= 1000]
    # Links = [(O[i], D[j], P[p]) for i in ORIG, j in DEST, p in PROD if ship_production[i,j,p] != 0]
    # Links = [(O[i], P[p]) for i in ORIG, p in PROD if production[i,p]/rate[i,p] >= 10]
    # Links = [(O[i], P[p]) for i in ORIG, p in PROD if production[i,p]/rate[i,p] >= 0.25*avail[i]]
    # Links = [(O[i], P[p]) for i in ORIG, p in PROD if sum(ship_production[i,:,p]) >= 1000]
end

# solution
# (a)
# Any["GARY" => "bands", "CLEV" => "bands", "PITT" => "bands", "PITT" => "coils", "GARY" => "plate", "CLEV" => "plate", "PITT" => "plate"]
# Any[("GARY", "DET", "bands"), ("CLEV", "DET", "bands"), ("GARY", "LAN", "bands"), ("CLEV", "LAN", "bands"), ("GARY", "WIN", "bands"), ("CLEV", "WIN", "bands"), ("PITT", "WIN", "bands"), ("GARY", "LAF", "bands"), ("CLEV", "DET", "coils"), ("CLEV", "WIN", "coils"), ("GARY", "LAF", "coils"), ("CLEV", "DET", "plate"), ("CLEV", "WIN", "plate"), ("GARY", "LAF", "plate")]
# Any[("GARY", "FRA"), ("CLEV", "FRA"), ("CLEV", "DET"), ("CLEV", "LAN")]
# Any[("GARY", "coils"), ("CLEV", "coils"), ("PITT", "coils"), ("GARY", "plate"), ("CLEV", "plate")]
# [("GARY", "FRA", "bands"), ("GARY", "FRE", "bands"), ("CLEV", "FRE", "bands"), ("PITT", "FRE", "bands"), ("GARY", "FRA", "coils"), ("CLEV", "FRA", "coils"), ("CLEV", "STL", "coils"), ("PITT", "STL", "coils"), ("GARY", "FRE", "coils"), ("CLEV", "FRE", "coils"), ("PITT", "FRE", "coils"), ("GARY", "FRA", "plate"), ("CLEV", "FRA", "plate"), ("CLEV", "STL", "plate"), ("PITT", "STL", "plate"), ("GARY", "FRE", "plate"), ("CLEV", "FRE", "plate"), ("PITT", "FRE", "plate")]
# [("GARY", "FRA", "bands"), ("GARY", "FRA", "coils"), ("CLEV", "FRA", "coils"), ("CLEV", "STL", "coils"), ("PITT", "STL", "coils"), ("GARY", "FRA", "plate"), ("CLEV", "FRA", "plate"), ("CLEV", "STL", "plate"), ("PITT", "STL", "plate")]
# (b)
# [("GARY", "bands"), ("GARY", "coils"), ("CLEV", "coils")]
# [("PITT", "FRA", "bands"), ("PITT", "DET", "bands"), ("GARY", "LAN", "bands"), ("PITT", "LAN", "bands"), ("PITT", "WIN", "bands"), ("GARY", "STL", "bands"), ("GARY", "FRE", "bands"), ("GARY", "LAF", "bands"), ("PITT", "FRA", "coils"), ("CLEV", "DET", "coils"), ("CLEV", "LAN", "coils"), ("CLEV", "WIN", "coils"), ("GARY", "STL", "coils"), ("CLEV", "STL", "coils"), ("GARY", "FRE", "coils"), ("CLEV", "LAF", "coils"), ("PITT", "FRA", "plate"), ("PITT", "DET", "plate"), ("PITT", "WIN", "plate"), ("GARY", "STL", "plate"), ("GARY", "FRE", "plate"), ("PITT", "LAF", "plate")]
# [("GARY", "coils"), ("CLEV", "coils")]
# [("GARY", "bands"), ("GARY", "coils"), ("CLEV", "coils")]
# [("GARY", "bands"), ("GARY", "coils"), ("CLEV", "coils")]