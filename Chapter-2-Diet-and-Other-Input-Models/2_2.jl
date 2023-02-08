using JuMP
using SCIP

function lpmodel(model)
    sports = 1:6                              #walking jogging swimming machine indoor pushback
    set = [1, 2, 4]                           #denoting exercise of walking jogging machine
    s_max = [5, 2, 3, 3.5, 3, 0.5]            #upperbound of 2-2(a) and 2-2(b)
    s_min = [1, 1, 1, 1, 0, 0]                #lowerbound of 2-2(b)

    s_ca = [100, 200, 300, 150, 300, 500]

    @variable(model, t[s in sports], lower_bound = s_min[s], upper_bound = s_max[s], Int)

    @constraint(model, sum(t[s]*s_ca[s] for s in sports) >= 2000)
    @constraint(model, sum(t[s] for s in set) <= 4)             #constraint for 2-2(b)

    @objective(model, Min, sum(t[s] for s in sports))

    return model
end

function startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4, limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)

    model = lpmodel(model)
    optimize!(model)                                                                                      
end
startmodel() 

# solution
# 2-2(a)  0.0  1.0  3.0  0.0  3.0  0.0; obj = 7
# 2-2(b)  1.0  1.0  3.0  1.0  3.0  0.0; obj = 9