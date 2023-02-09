using JuMP
using SCIP

function data_a()
    ORIG = 1:3                  #machine
    DEST = 1:6                  #part
    cost = [
        3 3 2 5 2 1
        4 1 1 2 2 1
        2 2 5 1 1 2
    ]
    supply = [90, 50, 160]
    demand = [10, 40, 60, 20, 20, 30]
    return ORIG, DEST,supply, demand, cost
end    

function data_b()
    ORIG = 1:3                  #machine
    DEST = 1:6                  #part
    cost = [
        3 3 2 5 2 1
        4 1 1 2 2 1
        2 2 5 1 1 2
    ]
    supply = [90, 50, 160]
    demand = [10, 40, 60, 20, 20, 30]
    return ORIG, DEST,supply, demand, cost
end  

function data_c()
    ORIG = 1:3                  #machine
    DEST = 1:6                  #part
    cost = [
        1.3 1.3 1.2 1.5 1.2 1.1
        1.4 1.1 1.1 1.2 1.2 1.1
        1.2 1.2 1.5 1.1 1.1 1.2
    ]
    supply = [50, 90, 175]
    demand = [10, 40, 60, 20, 20, 30]
    return ORIG, DEST,supply, demand, cost
end  

function lpmodel(model, ORIG, DEST,supply, demand, cost)
    @variable(model, Trans[ORIG,DEST], lower_bound = 0)
    @objective(model, Min, sum(cost[i,j]*Trans[i,j] for i in ORIG for j in DEST))
    @constraint(model, [i in ORIG], sum(Trans[i,j] for j in DEST) <= supply[i])
    @constraint(model, [j in DEST], sum(Trans[i,j] for i in ORIG) >= demand[j])
    return model
end

function lpmodel_c(model, ORIG, DEST,supply, demand, cost)
    @variable(model, Trans[ORIG,DEST], lower_bound = 0, Int)
    @objective(model, Min, sum(cost[i,j]*Trans[i,j] for i in ORIG for j in DEST))
    @constraint(model, [i in ORIG], sum(Trans[i,j]*cost[i,j] for j in DEST) <= supply[i])
    @constraint(model, [j in DEST], sum(Trans[i,j] for i in ORIG) >= demand[j])
    return model
end

function  startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)
    
    ORIG, DEST,supply, demand, cost = data_c()
    model  = lpmodel_c(model, ORIG, DEST,supply, demand, cost)
    optimize!(model)                                                                   
end
startmodel() 

#  solution
# 3-2(a)  obj = 260
# Trans = [
#     0.0   0.0  30.0   0.0   0.0  30.0
#     0.0   0.0  30.0   0.0   0.0   0.0
#    10.0  40.0   0.0  20.0  20.0   0.0
# ]
# 3-2(b)  obj = 240
# Trans = [
#     0.0   0.0  10.0   0.0   0.0  30.0
#     0.0   0.0  50.0   0.0   0.0   0.0
#    10.0  40.0   0.0  20.0  20.0   0.0
# ]
# 3-2(c.d)  obj = 200.9
# Trans = [
#     0.0   0.0   0.0   0.0   0.0  30.0
#     0.0  21.0  60.0   0.0   0.0   0.0
#    10.0  19.0   0.0  20.0  20.0   0.0
# ]