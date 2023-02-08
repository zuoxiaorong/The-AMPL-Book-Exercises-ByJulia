using JuMP
using SCIP

function lpmodel(model)
    days = 1:7
    weekend = 6:7
    weekday = 1:5
    e_min = [45, 45, 40, 50, 65, 35, 35]
    num_ava = 100

    @variable(model, x[1:num_ava], Bin)
    @variable(model, y[1:num_ava, days], Bin)
    # @constraint(model, [i in 1:num_ava, j in days], y[i,j] <= x[i])
    @constraint(model, [t in days], sum(y[i,t] for i in 1:num_ava) >= e_min[t])
    @constraint(model, [i in 1:num_ava], sum(y[i,t] for t in weekday) == 4*x[i])
    @constraint(model, [i in 1:num_ava], sum(y[i,t] for t in weekend) == 1*x[i])

    @objective(model, Min, sum(x[i] for i in 1:num_ava))

    return model
end

function startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4, limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)
    
    model = lpmodel(model)
    # println(model)
    optimize!(model)                                                                        
end
startmodel() 

# solution
# 2-5(a)  obj = 70
