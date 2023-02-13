using JuMP
using SCIP

function data_scenario()                # revenue per ton sold
    scenario_1 = [
        25 26 27 27
        30 35 37 39
    ]
    scenario_2 = [
        23 24 25 25
        30 33 35 36
    ]
    scenario_3 = [
        21 27 33 35
        30 32 33 33
    ]
    return scenario_1, scenario_2, scenario_3
end

function data()
    T = 1:4                             # number of weeks
    PROD = 1:2                          # bands coils;
    avail = [40, 40, 32, 40]            # hours available in week
    rate = [200, 140]                   # tons per hour produced
    inv0 = [10, 0]                      # initial inventory
    prodcost = [10, 11]                 # cost per ton produced
    invcost = [2.5, 3]                  # carrying cost/ton of inventory
    market = [
        6000 6000 4000 6500
        4000 2500 3500 4200    
    ]                                   # limit on tons sold in week
    return T, PROD, avail, rate, inv0, prodcost, invcost, market
end

function lpmodel(model, T, PROD, avail, rate, inv0, prodcost, invcost, market, revenue)
    @variable(model, Make[PROD,T] >= 0)
    @variable(model, Inv[PROD,T] >= 0)
    @variable(model, Sell[p in PROD, t in T], lower_bound = 0, upper_bound = market[p,t])

    @objective(model, Max, sum(revenue[p,t]*Sell[p,t] - prodcost[p]*Make[p,t] - invcost[p]*Inv[p,t] for p in PROD for t in T))
    @constraint(model, [t in T], sum((1/rate[p]) * Make[p,t] for p in PROD) <= avail[t])
    @constraint(model, [p in PROD], Inv[p,1] == inv0[p] + Make[p,1] - Sell[p,1])
    @constraint(model, [p in PROD, t in 2:length(T)], Make[p,t] + Inv[p,t-1] == Sell[p,t] + Inv[p,t])
    return model
end

function b_lpmodel(model, T, PROD, avail, rate, inv0, prodcost, invcost, market, revenue, S, prob)
    @variable(model, Make[PROD,T,S] >= 0)
    @variable(model, Inv[PROD,T,S] >= 0)
    @variable(model, Sell[p in PROD, t in T, s in S], lower_bound = 0, upper_bound = market[p,t])

    @objective(model, Max, sum(prob[s]*sum(revenue[s][p,t]*Sell[p,t,s] - prodcost[p]*Make[p,t,s] - invcost[p]*Inv[p,t,s] for p in PROD for t in T) for s in S))
    @constraint(model, [t in T, s in S], sum((1/rate[p]) * Make[p,t,s] for p in PROD) <= avail[t])
    @constraint(model, [p in PROD, s in S], Inv[p,1,s] == inv0[p] + Make[p,1,s] - Sell[p,1,s])
    @constraint(model, [p in PROD, t in 2:length(T), s in S], Make[p,t,s] + Inv[p,t-1,s] == Sell[p,t,s] + Inv[p,t,s])
    return model
end

function c_lpmodel(model, T, PROD, avail, rate, inv0, prodcost, invcost, market, revenue, S, prob)
    @variable(model, Make[PROD,T,S] >= 0)
    @variable(model, Inv[PROD,T,S] >= 0)
    @variable(model, Sell[p in PROD, t in T, s in S], lower_bound = 0, upper_bound = market[p,t])

    @objective(model, Max, sum(prob[s]*sum(revenue[s][p,t]*Sell[p,t,s] - prodcost[p]*Make[p,t,s] - invcost[p]*Inv[p,t,s] for p in PROD for t in T) for s in S))
    @constraint(model, [t in T, s in S], sum((1/rate[p]) * Make[p,t,s] for p in PROD) <= avail[t])
    @constraint(model, [p in PROD, s in S], Inv[p,1,s] == inv0[p] + Make[p,1,s] - Sell[p,1,s])
    @constraint(model, [p in PROD, t in 2:length(T), s in S], Make[p,t,s] + Inv[p,t-1,s] == Sell[p,t,s] + Inv[p,t,s])
    for p in PROD, s in 1:length(S)-1
        @constraints(model, begin
            Make[p,1,s] == Make[p,1,s+1]
            Sell[p,1,s] == Sell[p,1,s+1]
            Inv[p,1,s] == Inv[p,1,s+1] 
        end)
    end
    return model
end

function a_startmodel()
    scenario = data_scenario()
    T, PROD, avail, rate, inv0, prodcost, invcost, market = data()  

    for i in 1:3
        optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
        model = JuMP.direct_model(optimizer)
        set_time_limit_sec(model,100)
        revenue =  scenario[i]
        model  = lpmodel(model, T, PROD, avail, rate, inv0, prodcost, invcost, market, revenue)
        optimize!(model)
    end
end

function b_startmodel()
    # prob = [0.45, 0.35, 0.20]
    prob = [0.0001, 0.0001, 0.9998]
    S = 1:length(prob)
    if sum(prob) > 0.99999 && sum(prob) < 1.00001
        revenue = data_scenario()
        T, PROD, avail, rate, inv0, prodcost, invcost, market = data()  
        optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
        model = JuMP.direct_model(optimizer)
        set_time_limit_sec(model,100)
        model  = c_lpmodel(model, T, PROD, avail, rate, inv0, prodcost, invcost, market, revenue, S, prob)
        optimize!(model)
    end
end
b_startmodel() 

#  solution
# 4-5(a) obj = 5.15033000000000e+05, 4.62944285714286e+05, 5.49970000000000e+05
# 4-5(b) obj = 5.03789350000000e+05  | sum([5.15033000000000e+05, 4.62944285714286e+05, 5.49970000000000e+05]*prob[i] for i in 1:3) = 503789.3500000001
# 4-5(c) obj = 5.00740714285714e+05
# Make[:,1,:] = [
#     5990.0  5990.0  5990.0
#     1407.0  1407.0  1407.0
# ]
# 4-6(d) 514090.14285714284, 461833.0, 538793.0
#        504492.85714285716, 459644.28571428574, 549970.0