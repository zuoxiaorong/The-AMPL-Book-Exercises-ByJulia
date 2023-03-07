using JuMP
using SCIP

function a()
    # subject to Inv_Limit {p in PROD, t in 1..T}:Inv[p,t] <= min {tt in 1..T} Make[p,tt];
    @constraint(model, [p in PROD, t in 1:T, tt in 1:T], Inv[p,t] <= Make[p,tt])
end

function b()
    # subject to Max_Change {t in 1..T}: abs(sum {p in PROD} Inv[p,t-1] - sum {p in PROD} Inv[p,t]) <= max_change;
    @constraints(model, begin
        [t in 1:T], sum(Inv[p,t-1] for p in PROD) <= sum(Inv[p,t] for p in PROD) + max_change 
        [t in 1:T], - sum(Inv[p,t-1] for p in PROD) <= sum(Inv[p,t] for p in PROD) + max_change 
    end)
end

function c()
    # subject to Max_Inv_Ratio {t in 1..T}: (sum {p in PROD} Inv[p,t]) / (sum {p in PROD} Make[p,t]) <= max_inv_ratio;
    @constraint(model, [t in 1:T], sum(Inv[p,t] for p in PROD) <= max_inv_ratio*sum(Make[p,t] for p in PROD))
end

function d()
    @constraint(model, [p in PROD, t in 1:T, tt in 1:T], Inv[p,t] >= Make[p,tt])
    @constraints(model, begin
        [t in 1:T], sum(Inv[p,t-1] for p in PROD) >= sum(Inv[p,t] for p in PROD) + min_change 
        [t in 1:T], - sum(Inv[p,t-1] for p in PROD) >= sum(Inv[p,t] for p in PROD) + min_change 
    end)
    # subject to Max_Inv_Ratio {t in 1..T}: (sum {p in PROD} Inv[p,t]) / (sum {p in PROD} Make[p,t]) = Ratio[t]
end