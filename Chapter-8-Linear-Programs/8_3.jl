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
    # STORE = ["A&P", "JEWEL", "VONS"]
    cost = [
        3.19 2.59 2.29 2.89 1.89 1.99 1.99 2.49
        3.09 2.79 2.29 2.59 1.59 1.99 2.09 2.30
        2.59 2.99 2.49 2.69 1.99 2.29 2.00 2.69        
    ] 
    return  MINREQ, MAXREQ, NUTR, 1:size(food_params,1), food_params[:,2], food_params[:,3], nutr_params[:,1], nutr_params[:,2], amt', 1:size(cost,1), cost
end

function lpmodel(model, MINREQ, MAXREQ, NUTR, FOOD, f_min, f_max, n_min, n_max, amt, STORE, cost)
    @variable(model, Buy[j in FOOD], lower_bound = f_min[j], upper_bound = f_max[j])
    @variable(model, c[s in STORE])

    # @objective(model, Min, sum(sum(cost[s,j]*Buy[j] for j in FOOD) for s in STORE))
    # @objective(model, Min, sum(c[s] for s in STORE))
    @objective(model, Min, sum(Buy[j] for j in FOOD))
    @constraint(model, [s in STORE], sum(cost[s,j]*Buy[j] for j in FOOD) == c[s])
    @constraint(model, [i in MINREQ], sum(amt[i,j] * Buy[j] for j in FOOD) >= n_min[i])
    @constraint(model, [i in MAXREQ], sum(amt[i,j] * Buy[j] for j in FOOD) <= n_max[i])
    JuMP.set_start_value, (Buy, repeat([5],length(FOOD)))
    return model
end

function  startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)
    
    MINREQ, MAXREQ, NUTR, FOOD, f_min, f_max, n_min, n_max, amt, STORE, cost = data()
    model  = lpmodel(model, MINREQ, MAXREQ, NUTR, FOOD, f_min, f_max, n_min, n_max, amt, STORE, cost)
    optimize!(model)                                                                        
end
startmodel()
# solution obj = +2.28890674157303e+02 
# cost = [
#     74.2738202247191
#     75.0196629213483
#     79.59719101123595
# ]
# obj = +3.09253731343284e+01
# cost = [
#     78.20567164179104
#     77.06746268656715
#     81.11328358208955
# ]