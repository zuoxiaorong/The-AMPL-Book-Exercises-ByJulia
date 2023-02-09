using JuMP
using SCIP

function data()
    ORIG = 1:2                  #Seattle and San Diego
    DEST = 1:3                  #New York, Chicago, and Topeka
    distance = [
        2500 1700 1800
        2500 1800 1400
    ]
    cost_perunit = 90
    cost = distance ./ (1000*cost_perunit)
    supply = [350, 600]
    demand = [325, 300, 275]
    return ORIG, DEST,supply, demand, cost
end    

function lpmodel(model, ORIG, DEST,supply, demand, cost)
    @variable(model, Trans[ORIG,DEST], lower_bound = 0)
    @objective(model, Min, sum(cost[i,j]*Trans[i,j] for i in ORIG for j in DEST))
    @constraint(model, [i in ORIG], sum(Trans[i,j] for j in DEST) <= supply[i])
    @constraint(model, [j in DEST], sum(Trans[i,j] for i in ORIG) >= demand[j])
    return model
end

function  startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)

    ORIG, DEST,supply, demand, cost = data()
    model  = lpmodel(model, ORIG, DEST,supply, demand, cost)
    optimize!(model)                                                                  
end
startmodel() 

#  solution
# 3-1  obj = 18.972
# Trans = [
#     0.0  300.0    0.0
#     325.0    0.0  275.0
# ]