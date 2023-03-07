using JuMP
using SCIP

T = 4

# (a)
function a()
    model = Model(SCIP.Optimizer)
    @variable(model, x[1:T],lower_bound = 0)

    # @constraint(model, [i in 1:T], ifelse(i == 1, x[i], 2x[i]) <= 10)
    @constraint(model, [i in 1:T], ifelse(i == findfirst(x -> x == 1, 1:T), x[i], 2x[i]) <= 10)
    println(model)
end
test_v = [ifelse(t == 1, 1, 2) for t in 1:T]
test_v1 = [ifelse(t == findfirst(x -> x == 1, 1:T), 1, 2) for t in 1:T]

# (b) Figure 5-1
function b_model(model, MINREQ, MAXREQ, NUTR, FOOD, cost, f_min, f_max, n_min, n_max, amt, big_M)
    @variable(model, Buy[j in FOOD], lower_bound = f_min[j], upper_bound = f_max[j])

    @objective(model, Min, sum(cost[j]*Buy[j] for j in FOOD))
    # @constraint(model, [i in MINREQ], sum(amt[i,j] * Buy[j] for j in FOOD) >= n_min[i])
    # @constraint(model, [i in MAXREQ], sum(amt[i,j] * Buy[j] for j in FOOD) <= n_max[i])
    @constraint(model, [i in NUTR], ifelse(i in MINREQ, n_min[i], 0) <= sum(amt[i,j] * Buy[j] for j in FOOD) <= ifelse(i in MAXREQ, n_max[i], big_M))
end

# (c) Figure 4-1
function c_model(model, ORIG, DEST, PROD, supply, demand, limit, cost, BUY_ORIG, buy_supply, buy_cost)
    @variable(model, Trans[ORIG,DEST,PROD] >= 0)
    @variable(model, Buy[i in BUY_ORIG, p in PROD], lower_bound = 0, upper_bound = buy_supply[i,p])
    # @objective(model, Min, sum(cost[i,j,p] * Trans[i,j,p] for i in ORIG for j in DEST for p in PROD))
    @objective(model, Min, sum(cost[i,j,p] * Trans[i,j,p] for i in ORIG for j in DEST for p in PROD)+sum(buy_cost[i,p] * Buy[i,p] for i in BUY_ORIG for p in PROD))
    # @constraint(model, SUPPLY[i in ORIG, p in PROD], sum(Trans[i,j,p] for j in DEST) == supply[i,p])
    @constraint(model, SUPPLY[i in ORIG, p in PROD], sum(Trans[i,j,p] for j in DEST) == supply[i,p] + ifelse(i in BUY_ORIG, Buy[i,p], 0))
    @constraint(model, DEMAND[j in DEST, p in PROD], sum(Trans[i,j,p] for i in ORIG) == demand[j,p])
    @constraint(model, MULTI[i in ORIG, j in DEST], sum(Trans[i,j,p] for p in PROD) <= limit[i,j])
end

# (d) Figure 4-1
function c_model(model, ORIG, DEST, PROD, supply, demand, limit, cost, BUY_ORIG_links, buy_supply, buy_cost)
    @variable(model, Trans[ORIG,DEST,PROD] >= 0)
    @variable(model, Buy[i in ORIG, p in PROD;(i=>p) in BUY_ORIG_links], lower_bound = 0, upper_bound = buy_supply[i,p])
    # @objective(model, Min, sum(cost[i,j,p] * Trans[i,j,p] for i in ORIG for j in DEST for p in PROD))
    @objective(model, Min, sum(cost[i,j,p] * Trans[i,j,p] for i in ORIG for j in DEST for p in PROD)+sum(buy_cost[k] * Buy[i,p] for i in ORIG for p in PROD for k in 1:length(BUY_ORIG_links) if BUY_ORIG_links[k] == (i => p)))
    # @constraint(model, SUPPLY[i in ORIG, p in PROD], sum(Trans[i,j,p] for j in DEST) == supply[i,p])
    @constraint(model, SUPPLY[i in ORIG, p in PROD], sum(Trans[i,j,p] for j in DEST) == supply[i,p] + ifelse((i=>p) in BUY_ORIG_links, Buy[i,p], 0))
    @constraint(model, DEMAND[j in DEST, p in PROD], sum(Trans[i,j,p] for i in ORIG) == demand[j,p])
    @constraint(model, MULTI[i in ORIG, j in DEST], sum(Trans[i,j,p] for p in PROD) <= limit[i,j])
end