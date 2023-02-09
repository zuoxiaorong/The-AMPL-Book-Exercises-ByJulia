using JuMP
using SCIP

function lpmodel(model)
    budget = 1000_000
    pweek_aval = 100

    cost_TV = 20_000
    num_TV = 1800_000
    pw_TV = 1
    
    cost_mag = 10_000
    num_mag = 1000_000
    pw_mag = 3

    cost_Ra = 2_000
    num_Ra = 0.25*1000_000
    pw_Ra = 1

    @variable(model, x_TV, lower_bound = 10, Int)
    @variable(model, x_mag, lower_bound = 2, Int)
    @variable(model, x_Ra, lower_bound = 0, upper_bound = 120, Int)
    
    @constraint(model, cost_TV*x_TV + cost_mag*x_mag + cost_Ra*x_Ra <= budget)
    @constraint(model, pw_TV*x_TV + pw_mag*x_mag + pw_Ra*x_Ra <= pweek_aval)

    @objective(model, Max, x_TV*num_TV + x_mag*num_mag + x_Ra*num_Ra)
    return model
end

function startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4, limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)

    model = lpmodel(model)
    optimize!(model)

    println("x_TV = ",value.(model[:x_TV]))
    println("x_mag = ",value.(model[:x_mag]))
    println("x_Ra = ", value.(model[:x_Ra]))
end
startmodel()

# solution
# 1-1(a) x_TV = 40.0 x_mag = 20.0
# 1-1(b) x_TV = 40.0 x_mag = 20.0
# 1-1(c) X_Ra = 44.0 x_mag = 2.0  x_Ra = 50.0
# 1-1(d) X_Ra = 44.0 x_mag = 2.0  x_Ra = 50.0 (not change)

