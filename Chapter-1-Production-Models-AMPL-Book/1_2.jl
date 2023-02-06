
using JuMP
using SCIP

function lpmodel(model)
    prod = 1:3                      #denoting bands、coils、plate
    stage = 1:3                     #denoting reheat、roll、finishing

    m = [2, 2, 3]                   #stages of product

    rate = [
        200 200 99999
        200 140 99999
        200 160 150
    ]

    # rate = [
    #     200 200 Inf
    #     200 140 Inf
    #     200 160 150
    # ]

    params = [
        25 1000 6000
        30 500 4000
        29 750 3500
    ]
    profit, commit, market = params[:,1], params[:,2], params[:,3]

    s = [0.4, 0.1, 0.4]
    # s = [0.5, 0.1, 0.5]
    avail = [35, 40, 20]
    max_weight = 6500

    @variable(model, Make[p in prod], lower_bound = commit[p], upper_bound = market[p])
    # @variable(model, Make[p in prod], upper_bound = market[p])

    @constraint(model, [s in stage], sum(1/rate[p,s]*Make[p] for p in prod if m[p] >= s) <= avail[s])
    @constraint(model, sum(Make[p] for p in prod) <= max_weight)
    @constraint(model, [p in prod], Make[p] >= s[p]*sum(Make[p1] for p1 in prod))

    @objective(model, Max, sum(Make[p]*profit[p] for p in prod))
    # @objective(model, Max, sum(Make[p] for p in prod))
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
                                                                                                                                                     
end
startmodel()

# solution
# 原问题： 3357.1428571428546、500.0、3142.857142857145
# 1-2(a) 3357.1428571428546、500.0、3142.857142857145 （not change）
# 1-2(b) 
#if constraint (sum(1/rate[p,s]*Make[p] for p in prod) == avail[s])) status = infeasible
#if constraint (sum(1/rate[p,s]*Make[p] for p in prod) <= avail[s])) status = optimal       1541.666666666667、1458.333333333333、3500.0                                                                                                                                                                                                                  
# 1-2(c)  5750.0 500.0 750.0
# 1-2(d) 0.4 0.1 0.4  2600.0 1300.0  2600.0
#        0.5 0.1 0.5  0.0  0.0  0.0
# 1-2(e)  2600.0  1300.0  2600.0



