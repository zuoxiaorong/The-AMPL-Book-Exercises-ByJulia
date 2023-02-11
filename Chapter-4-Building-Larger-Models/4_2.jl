using JuMP
using SCIP

function Transportation_diet_combination_model(model, ORIG, DEST, FOOD, NUTR, supply, demand_min, demand_max, cost, amt)
    @variable(model, Trans[ORIG,DEST,FOOD], lower_bound = 0)

    @objective(model, Min, sum(cost[i,j,f]*Trans[i,j,f] for i in ORIG for j in DEST for f in FOOD))
    @constraint(model, [i in ORIG, f in FOOD], sum(Trans[i,j,f] for j in DEST) <= supply[i,f])
    @constraint(model, [j in DEST, n in NUTR], demand_min[j,n] <= sum(Trans[i,j,f]*amt[f,n] for i in ORIG for f in FOOD) <= demand_max[j,n])
    return model
end