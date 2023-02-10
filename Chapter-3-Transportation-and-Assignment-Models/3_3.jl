using JuMP
using SCIP

function a_data()
    ORIG = 1:3                  #GARY, CLEV, PITT
    DEST = 1:7                  #FRA, DET, LAN, WIN, STL, FRE, LAF
    cost = [
        39 14 11 14 16 82 8
        27 9 12 9 26 95 17
        24 14 17 13 28 99 20
    ]
    supply = [1400, 2600, 2900]
    demand = [900, 1200, 600, 400, 1700, 1100, 1000]
    supply_pct = 0.5 .* supply
    demand_pct = 0.85 .* demand
    return ORIG, DEST,supply, demand, cost, supply_pct, demand_pct
end    

function b_data()
    ORIG = 1:2                  #MIDTWN, HAMLTN index by i 
    DEST = 1:3                  #GARY, CLEV, PITT index by j
    DEST2 = 1:7                 #FRA, DET, LAN, WIN, STL, FRE, LAF index by k
    cost1 = [
        12 8 17
        10 5 13
    ]
    cost2 = [
        39 14 11 14 16 82 8
        27 9 12 9 26 95 17
        24 14 17 13 28 99 20
    ]

    supply = [2700, 4200]
    demand = [1400, 2600, 2900]
    supply2 = [1400, 2600, 2900]
    demand2 = [900, 1200, 600, 400, 1700, 1100, 1000]
    supply_pct = supply
    demand_pct = 0.85 .* demand
    supply_pct2 = 0.5 .* supply2
    demand_pct2 = 0.85 .* demand2
    return ORIG, DEST, DEST2, cost1, cost2, supply, demand, supply2, demand2, supply_pct, demand_pct, supply_pct2, demand_pct2
end

function b_lpmodel(model, ORIG, DEST, DEST2, cost1, cost2, supply, demand, supply2, demand2, supply_pct, demand_pct, supply_pct2, demand_pct2)
    @variable(model, Trans1[ORIG,DEST], lower_bound = 0)
    @variable(model, Trans2[DEST, DEST2], lower_bound = 0)
    @objective(model, Min, sum(cost1[i,j]*Trans1[i,j] for i in ORIG for j in DEST) + sum(cost2[j,k]*Trans2[j,k] for j in DEST for k in DEST2))
    @constraint(model, [i in ORIG], sum(Trans1[i,j] for j in DEST) == supply[i])
    @constraint(model, [j in DEST], sum(Trans1[i,j] for i in ORIG) == demand[j])
    @constraint(model, [j in DEST], sum(Trans2[j,k] for k in DEST2) == supply2[j])
    @constraint(model, [k in DEST2], sum(Trans2[j,k] for j in DEST) == demand2[k])
    @constraint(model, [i in ORIG, j in DEST], Trans1[i,j] <= supply_pct[i])
    @constraint(model, [i in ORIG, j in DEST], Trans1[i,j] <= demand_pct[j])
    @constraint(model, [j in DEST, k in DEST2], Trans2[j,k] <= supply_pct2[j])
    @constraint(model, [j in DEST, k in DEST2], Trans2[j,k] <= demand_pct2[k])
    return model
end

function lpmodel(model, ORIG, DEST,supply, demand, cost, supply_pct, demand_pct)
    @variable(model, Trans[ORIG,DEST], lower_bound = 0)
    @objective(model, Min, sum(cost[i,j]*Trans[i,j] for i in ORIG for j in DEST))
    @constraint(model, [i in ORIG], sum(Trans[i,j] for j in DEST) == supply[i])
    @constraint(model, [j in DEST], sum(Trans[i,j] for i in ORIG) == demand[j])
    @constraint(model, [i in ORIG, j in DEST], Trans[i,j] <= supply_pct[i])
    @constraint(model, [i in ORIG, j in DEST], Trans[i,j] <= demand_pct[j])
    return model
end

function  startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)
    
    ORIG, DEST, DEST2, cost1, cost2, supply, demand, supply2, demand2, supply_pct, demand_pct, supply_pct2, demand_pct2 = b_data()
    model = b_lpmodel(model, ORIG, DEST, DEST2, cost1, cost2, supply, demand, supply2, demand2, supply_pct, demand_pct, supply_pct2, demand_pct2)
    optimize!(model)
println(value.(model[:Trans1]))
println(value.(model[:Trans2]))                                                                    
end
startmodel() 

#  solution
# Figure 3-1  obj = 196200
# Trans = [
#     0.0     0.0    0.0    0.0   300.0  1100.0    0.0
#     0.0  1200.0  600.0  400.0     0.0     0.0  400.0
#   900.0     0.0    0.0    0.0  1400.0     0.0  600.0
# ]
# 3-3(a) obj = 199210
# Trans = [
#     0.0     0.0    0.0    0.0   255.0  700.0  445.0
#     135.0  1020.0  510.0  340.0     0.0  400.0  195.0
#     765.0   180.0   90.0   60.0  1445.0    0.0  360.0
# ]
# 3-3(b) obj = 271255
# Trans1 = [
#     1190.0  1075.0   435.0
#     210.0  1525.0  2465.0
# ]
# Trans2 = [
#     0.0     0.0    0.0    0.0   255.0  700.0  445.0
#     135.0  1020.0  510.0  340.0     0.0  400.0  195.0
#     765.0   180.0   90.0   60.0  1445.0    0.0  360.0
# ]
        