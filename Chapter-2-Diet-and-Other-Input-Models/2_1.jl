using JuMP
using SCIP

function lpmodel(model)
    Nutr = 1:4      #calories   protein   calcium  vitamin A
    Food = 1:6      #bread meat potatoes cabbage milk gelatin required

    n_re = [3000, 70, 800, 500]

    amt = [
        1254 1457 318 46 309 1725 
        39 73 8 4 16 43
        418 41 42 141 536 0
        0 0 70 860 720 0
    ]

    cost = [0.30, 1.00, 0.05, 0.08, 0.23, 0.48]
    @variable(model, Buy[j in Food], lower_bound = 0, Int)

    @constraint(model, diet[i in Nutr], sum(amt[i,j]*Buy[j] for j in Food) >= n_re[i])

    @objective(model, Min, sum(cost[j]*Buy[j] for j in Food))

    return model
end

function startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4, limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)

    model = lpmodel(model)
    println(model)
    optimize!(model)                                                                                            
end
startmodel()

# solution
# 2-1  0.0  0.0  9.0  0.0  1.0  0.0
