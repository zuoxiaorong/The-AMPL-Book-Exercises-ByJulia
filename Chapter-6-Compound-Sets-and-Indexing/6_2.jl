using JuMP
using SCIP

# trasportation problem

function data()
    ORIG = 1:3                  #machine
    DEST = 1:7                  #part
    Links = [
        1 => 2,
        1 => 3,
        1 => 5,
        1 => 7,
        2 => 1,
        2 => 2,
        2 => 3,
        2 => 4,
        2 => 5,
        2 => 7,
        3 => 1,
        3 => 3,
        3 => 5,
        3 => 6
    ]
    cost = [14, 11, 16, 8, 27, 9, 12, 9, 26, 17, 24, 13, 28, 99]
    supply = [1400, 2600, 2900]
    demand = [900, 1200, 600, 400, 1700, 1100, 1000]
    return ORIG, DEST, Links, supply, demand, cost
end  

function str()
    O = ["GARY", "CLEV", "PITT"]
    D = ["FRA", "DET", "LAN", "WIN", "STL", "FRE", "LAF"]
    return O,D
end    
                               
function lpmodel(model, ORIG, DEST, Links, supply, demand, cost)
    @variable(model, Trans[i=ORIG,j=DEST;(i => j) in Links], lower_bound = 0)
    @objective(model, Min, sum(cost[k]*Trans[i,j] for i in ORIG for j in DEST for k in 1:length(Links) if Links[k] == (i => j)))
    @constraint(model, [i in ORIG], sum(Trans[i,j] for j in DEST if (i => j) in Links) <= supply[i])
    @constraint(model, [j in DEST], sum(Trans[i,j] for i in ORIG if (i => j) in Links) >= demand[j])
    return model
end

function  startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)
    
    ORIG, DEST, Links, supply, demand, cost = data()
    model  = lpmodel(model, ORIG, DEST, Links, supply, demand, cost)
    optimize!(model)
    ship_production = value.(model[:Trans])
    return ship_production
end

function a()
    O,D = str()
    ORIG, DEST, Links, supply, demand, cost = data()
    arcs = startmodel()         

    # Sets = [(O[Links[k][1]], D[Links[k][2]]) for k in 1:length(cost) if cost[k] <= 10]
    # Sets = [(O[Links[k][1]], D[Links[k][2]]) for k in 1:length(cost) if O[Links[k][1]] == "GARY"]
    # Sets = [(O[Links[k][1]], D[Links[k][2]]) for k in 1:length(cost) if D[Links[k][2]] == "FRE"]
    # Sets = [(O[i],D[j]) for i in ORIG, j in DEST if (i => j) in Links && arcs[i,j] > 0]
    # Sets = [D[j] for j in DEST if sum(cost[k]*arcs[i,j] for i in ORIG for k in 1:length(Links) if (i => j) == Links[k]) >= 20000]
end

function b()
    O,D = str()
    ORIG, DEST, Links, supply, demand, cost = data()
    arcs = startmodel()         

    # Sets = unique([D[j] for i in ORIG, j in DEST, k in 1:length(Links) if (i => j) == Links[k] && cost[k] >= 20])
    # Sets = [(D[j],O[i]) for i in ORIG, j in DEST if (i => j) in Links && arcs[i,j] > 0]
end

#  solution
# (a)
# [("GARY", "LAF"), ("CLEV", "DET"), ("CLEV", "WIN")]
# [("GARY", "DET"), ("GARY", "LAN"), ("GARY", "STL"), ("GARY", "LAF")]
# [("PITT", "FRE")]
# [("PITT", "FRA"), ("CLEV", "DET"), ("PITT", "LAN"), ("CLEV", "WIN"), ("GARY", "STL"), ("PITT", "STL"), ("PITT", "FRE"), ("CLEV", "LAF")]
# [("CLEV", "DET"), ("CLEV", "WIN"), ("CLEV", "LAF")]
# ["FRA", "STL", "FRE"]
# (b)
# ["FRA", "STL", "FRE"]
# [("FRA", "PITT"), ("DET", "CLEV"), ("LAN", "PITT"), ("WIN", "CLEV"), ("STL", "GARY"), ("STL", "PITT"), ("FRE", "PITT"), ("LAF", "CLEV")]