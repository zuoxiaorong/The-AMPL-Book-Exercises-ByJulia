using JuMP
using SCIP

function data()
    ORIG = 1:3                  #machine
    DEST = 1:7                  #part
    PROD = 1                    #products
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
    ROUTES = [(i,j,k) for (i,j) in Links for k in PROD]
   
    cost = [14, 11, 16, 8, 27, 9, 12, 9, 26, 17, 24, 13, 28, 99]
    supply = [1400, 2600, 2900]
    demand = [900, 1200, 600, 400, 1700, 1100, 1000]
    limit = [
        3000 3000 3000 3000 3000 3000 3000
        3000 3000 3000 3000 3000 3000 3000
        3000 3000 3000 3000 3000 3000 3000
    ]
    supply_all = supply
    return ORIG, DEST, PROD, ROUTES, cost, supply, demand, limit, supply_all
end    
                               
function lpmodel(model, ORIG, DEST, PROD, ROUTES, cost, supply, demand, limit, supply_all)
    @variable(model, Trans[i=ORIG,j=DEST,k=PROD;(i,j,k) in ROUTES], lower_bound = 0)
    @objective(model, Min, sum(cost[n]*Trans[i,j,k] for i in ORIG for j in DEST for k in PROD for n in 1:length(ROUTES) if ROUTES[n] == (i,j,k)))
    @constraint(model, [i in ORIG, k in PROD], sum(Trans[i,j,k] for j in DEST if (i,j,k) in ROUTES) <= supply[i,k])
    @constraint(model, [j in DEST, k in PROD], sum(Trans[i,j,k] for i in ORIG if (i,j,k) in ROUTES) >= demand[j,k])
    @constraint(model, [i in ORIG, j in DEST], sum(Trans[i,j,k] for k in PROD if (i,j,k) in ROUTES) <= limit[i,j])
    @constraint(model, [i in ORIG], sum(Trans[i,j,k] for j in DEST for k in PROD if (i,j,k) in ROUTES) <= supply_all[i])
    return model
end

function  startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)
    
    ORIG, DEST, PROD, ROUTES, cost, supply, demand, limit, supply_all = data()
    model  = lpmodel(model, ORIG, DEST, PROD, ROUTES, cost, supply, demand, limit, supply_all)
    optimize!(model)    
end
startmodel() 

#  solution
# Section 6-3  obj = 2.00500000000000e+05    #The solution is same with Figure 6-2
# Trans = [
#     [1, 2]  =  0.0
#     [1, 3]  =  0.0
#     [1, 5]  =  1400.0
#     [1, 7]  =  0.0
#     [2, 1]  =  0.0
#     [2, 2]  =  1200.0
#     [2, 3]  =  0.0
#     [2, 4]  =  400.0
#     [2, 5]  =  0.0
#     [2, 7]  =  1000.0
#     [3, 1]  =  900.0
#     [3, 3]  =  600.0
#     [3, 5]  =  300.0
#     [3, 6]  =  1100.0
# ]
