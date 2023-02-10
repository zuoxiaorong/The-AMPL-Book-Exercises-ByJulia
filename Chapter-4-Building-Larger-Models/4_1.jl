using JuMP
using SCIP

function Multiperiod_transportation_model(model, ORIG, DEST, PROD, T, supply, demand, invcost)
    @variable(model, Trans[ORIG,DEST,PROD,T], lower_bound = 0)
    @variable(model, Inv[ORIG,PROD,T], lower_bound = 0)

    @objective(model, Min, sum(trans_cost[i,j,p]*Trans[i,j,p,t] + invcost[i,p]*Inv[i,p,t] for i in ORIG for j in DEST for p in PROD for t in T))
    @constraint(model, [j in DEST, p in PROD, t in T], sum(Trans[i,j,p,t] for i in ORIG) == demand[j,p,t])
    @constraint(model, [i in ORIG, p in PROD], Inv[i,p,1] = supply[i,p] - sum(Trans[i,j,p,1] for j in DEST))
    @constraint(model, [i in ORIG, p in PROD, t in 2:length(T)], Inv[i,p,t] = inv[i,p,t-1] - sum(Trans[i,j,p,1] for j in DEST))
    return model
end
