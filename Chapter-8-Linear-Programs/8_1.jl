using JuMP
using SCIP

function data()                            #BEEF CHK FISH HAM MCH MTL SPG TUR
    MINREQ = [1, 3, 4, 2, 6]               #A B1 B2 C CAL
    MAXREQ = [1, 5, 6]                     #A NA CAL
    NUTR = 1:6                             #A C B1 B2 NA CAL
    food_params = [
        3.19 2 10
        2.59 2 10
        2.29 2 10
        2.89 2 10
        1.89 2 10
        1.99 2 10
        1.99 2 10
        2.49 2 10
    ]
    nutr_params = [
        700 20000
        700 missing
        0 missing
        0 missing
        missing 50000
        16000 24000
    ]
    amt = [
        60 20 10 15 938 295
        8 0 20 20 2180 770
        8 10 15 10 945 440
        40 40 35 10 278 430
        15 35 15 15 1182 315
        70 30 15 15 896 400
        25 50 25 15 1329 370
        60 20 15 10 1397 450 
    ]
    return  MINREQ, MAXREQ, NUTR, 1:size(food_params,1), food_params[:,1], food_params[:,2], food_params[:,3], nutr_params[:,1], nutr_params[:,2], amt'
end

function lpmodel(model, MINREQ, MAXREQ, NUTR, FOOD, cost, f_min, f_max, n_min, n_max, amt)
    @variable(model, Buy[j in FOOD], lower_bound = f_min[j], upper_bound = f_max[j])

    @objective(model, Min, sum(cost[j]*Buy[j] for j in FOOD))
    @constraint(model, [i in MINREQ], sum(amt[i,j] * Buy[j] for j in FOOD) >= n_min[i])
    @constraint(model, [i in MAXREQ], sum(amt[i,j] * Buy[j] for j in FOOD) <= n_max[i])
    JuMP.set_start_value, (Buy, repeat([5],length(FOOD)))
    return model
end

function  startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)
    
    MINREQ, MAXREQ, NUTR, FOOD, cost, f_min, f_max, n_min, n_max, amt = data()
    model  = lpmodel(model, MINREQ, MAXREQ, NUTR, FOOD, cost, f_min, f_max, n_min, n_max, amt)
    optimize!(model)                
    println(value.(model[:Buy]))                                                         
end
startmodel() 
# solution not change
# obj = +7.42738202247191e+01
# Buy = [
#     2.0
#     10.0
#     2.0
#     2.0
#     2.0
#     6.235955056179777
#     5.258426966292134
#     2.0
# ]