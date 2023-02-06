using JuMP
using SCIP

function lpmodel(model)
    cars = 1:3                      #denoting T、C、L

    fuel = [50, 30, 20]

    params = [
        1 200 10
        2 500 20
        3 700 15
    ]
    time, profit, orders = params[:,1], params[:,2], params[:,3]
    avail = 120+10
    average  = 35

    @variable(model, Make[c in cars], lower_bound = orders[c], Int)

    @constraint(model, sum(time[c]*Make[c] for c in cars) <= avail)
    @constraint(model, sum(fuel[c]*Make[c] for c in cars) >= average*sum(Make[c] for c in cars))

    @objective(model, Max, sum(Make[c]*profit[c] for c in cars))
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
    println(value.(model[:Make]))
    # X = Vector(value.(model[:Make]))
    # profit = [200, 500, 700]
    # println(sum(X[i]*profit[i] for i in 1:3))
                                                                                                                                                     
end
startmodel()

# solution
# 1-4(c)  11.0  32.0  15.0, obj = 28700
# 1-4(d)  35.0  20.0  15.0, obj = 27500
# 1-4(f)  25.0  25.0  15.0, obj = 28000
# 1-4(f)  25.0  30.0  15.0, obj = 30500