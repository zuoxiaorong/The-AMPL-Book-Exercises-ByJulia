using JuMP
using SCIP

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
end
startmodel() 

#  solution
# Figure 6-2  obj = 2.00500000000000e+05
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
