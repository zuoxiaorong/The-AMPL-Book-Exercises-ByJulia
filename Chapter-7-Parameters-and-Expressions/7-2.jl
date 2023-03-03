using JuMP
using SCIP

#Figure 4-4 multiperiod production model

function data()
    T = 4
    PROD = 1:2
    avail = [40, 40, 32, 40]
    rate = [200, 140]
    inv0 = [10, 0]
    prodcost = [10, 11]
    invcost = [2.5, 3]
    revenue = [
        25 26 27 27
        30 35 37 39
    ]
    market = [
        6000 6000 4000 6500
        4000 2500 3500 4200
    ]
    return T, PROD, avail, rate, inv0, prodcost, invcost, revenue, market
end

function str()
    PROD = ["bands", "coils"]
    return PROD
end

function lpmodel(model, T, PROD, avail, rate, inv0, prodcost, invcost, market, revenue)
    @variable(model, Make[PROD,1:T] >= 0)
    @variable(model, Inv[PROD,1:T] >= 0)
    @variable(model, Sell[p in PROD, t in 1:T], lower_bound = 0, upper_bound = market[p,t])

    @objective(model, Max, sum(revenue[p,t]*Sell[p,t] - prodcost[p]*Make[p,t] - invcost[p]*Inv[p,t] for p in PROD for t in 1:T))
    @constraint(model, [t in 1:T], sum((1/rate[p]) * Make[p,t] for p in PROD) <= avail[t])
    @constraint(model, [p in PROD], Inv[p,1] == inv0[p] + Make[p,1] - Sell[p,1])
    @constraint(model, [p in PROD, t in 2:T], Make[p,t] + Inv[p,t-1] == Sell[p,t] + Inv[p,t])
    return model
end


function startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)

    T, PROD, avail, rate, inv0, prodcost, invcost, revenue, market = data()
    model = lpmodel(model, T, PROD, avail, rate, inv0, prodcost, invcost, market, revenue)
    optimize!(model)
end

function exercise()
    T, PROD, avail, rate, inv0, prodcost, invcost, revenue, market = data()
    P = str()

    e1 = T >= 1
    e2 = isless(inv0, [sum.(eachrow(market))...])
    e3 = all(invcost .<= 0.1 .* revenue)
    e4 = all(x -> x >= 24 && x <= 40, avail)&&all(x -> x <= 8, abs.(diff(avail)))
    e5 = all(x -> x >= 0, diff(revenue, dims=2))
    return e1,e2,e3,e4,e5
end

# solution
# true, true, true, true, true