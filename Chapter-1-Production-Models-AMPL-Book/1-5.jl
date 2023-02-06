using JuMP
using SCIP

function lpmodel(model)
    items = 1:6                     #denoting TV, radio, camera, CD, VCR, camcorder

    params = [
        50 35 8 20
        15 5 1 50
        85 4 2 20
        40 3 1 30
        50 15 5 30
        120 20 4 15
    ]
    value, weight, volume, available = params[:,1], params[:,2], params[:,3], params[:,4]

    max_weight = 500
    max_volume = 300
    @variable(model, x[i in items], lower_bound = 0, upper_bound = available[i], Int)

    @constraint(model, sum(x[i]*weight[i] for i in items) <= max_weight)
    @constraint(model, sum(x[i]*volume[i] for i in items) <= max_volume)

    @objective(model, Max, sum(x[i]*value[i] for i in items))
    # @objective(model, Max, sum(Make[c] for c in cars))
    return model
end

function startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4, limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)

    model = lpmodel(model)
    println(model)
    optimize!(model)

    # println(value.(model[:x]))
    # X = Vector(value.(model[:Make]))
    # profit = [200, 500, 700]
    # println(sum(X[i]*profit[i] for i in 1:3))
                                                                                                                                                     
end
startmodel()

# solution
# 1-5(b)   0.0   0.0  20.0  30.0  2.0  15.0 obj = 4800
