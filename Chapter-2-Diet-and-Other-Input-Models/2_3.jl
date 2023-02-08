using JuMP
using SCIP

function a_lpmodel(model)
    Sugars = 1:7                              #A:G
    orgin = 1:3

    obj = [52, 56, 59]
    c = [
        10 10 20 30 40 20 60
        30 40 40 20 60 70 10
        60 50 40 50 0 10 30
    ]
    cost = [10, 11, 12, 13, 14, 12, 15]

    @variable(model, Buy[s in Sugars], lower_bound = 0)

    @constraint(model, [j in orgin], sum(Buy[s]*c[j,s]/100 for s in Sugars) == obj[j])

    @objective(model, Min, sum(cost[s]*Buy[s] for s in Sugars))

    return model
end

function b_lpmodel(model)
    Sugars = 1:7                              #A:G
    orgin = 1:3

    obj = [52, 56, 59]
    c = [
        10 10 20 30 40 20 60
        30 40 40 20 60 70 10
        60 50 40 50 0 10 30
    ]
    cost = [10, 11, 12, 13, 14, 12, 15]

    @variable(model, Buy[s in Sugars], lower_bound = 10)

    @constraint(model, [j in orgin], sum(Buy[s]*c[j,s]/100 for s in Sugars) == obj[j])

    @objective(model, Min, sum(cost[s]*Buy[s] for s in Sugars))

    return model
end

function c_lpmodel(model)
    Sugars = 1:7                              #A:G
    orgin = 1:3

    obj = [52, 56, 59]
    c = [
        10 10 20 30 40 20 60
        30 40 40 20 60 70 10
        60 50 40 50 0 10 30
    ]
    cost = [10, 11, 12, 13, 14, 12, 15]

    @variable(model, Buy[s in Sugars], lower_bound = 0)

    @constraint(model, sum(Buy[s] for s in Sugars) == 1)
    @constraint(model, [j in orgin], 0.30 <= sum(Buy[s]*c[j,s]/100 for s in Sugars) <= 0.37)

    @objective(model, Min, sum(cost[s]*Buy[s] for s in Sugars))

    return model
end

function startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4, limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)

    model = c_lpmodel(model)
    optimize!(model)                                                                        
end
startmodel() 

# solution
# 2-3(a)  60.00000000000001  0.0  0.0  0.0  0.0  45.49999999999999  61.49999999999998; obj = 2068.5
# 2-3(b)  43.63636363636364  10.0 10.0 10.0 10.0 30.95454545454545  52.40909090909089; obj = 2094.0
# 2-3(c)  0.3999999999999999 0.0 0.0 0.0 0.0 0.2500000000000002 0.3499999999999999; obj = 1.225