using JuMP
using SCIP

function Specialized_transshipment_model(model, D_CITY, W_CITY, DW_LINKS, p_supply, w_demand, pd_cost, pd_cap, dw_cost, dw_cap)
    @variable(model, PD_Ship[i in D_CITY], lower_bound = 0, upper_bound = pd_cap[i])
    @variable(model, DW_Ship[i in D_CITY, j in W_CITY; (i, j) in DW_LINKS], lower_bound = 0, upper_bound = dw_cap[findfirst(x -> x == (i,j), DW_LINKS)])
    
    @objective(model, Min, sum(pd_cost[i]*PD_Ship[i] for i in D_CITY) + sum(dw_cost[k]*DW_Ship[i,j] for (i,j) in DW_LINKS for k in 1:length(dw_cost) if (i,j) == DW_LINKS[k]))

    @constraint(model, sum(PD_Ship[i] for i in D_CITY) == p_supply)
    @constraint(model, [i in D_CITY], PD_Ship[i] == sum(DW_Ship[i,j] for j in W_CITY if (i,j) in DW_LINKS))
    @constraint(model, [j in W_CITY], sum(DW_Ship[i,j] for i in D_CITY if (i,j) in DW_LINKS) == w_demand[j])
    return model
end

function data()
    D_CITY = ["NE", "SE"]
    W_CITY = ["BOS", "EWR", "BWI", "ATL", "MCO"]
    DW_LINKS = [("NE","BOS"), ("NE","EWR"), ("NE","BWI"), ("SE","EWR"), ("SE","BWI"), ("SE","ATL"), ("SE","MCO")]
    D = 1:length(D_CITY)
    W = 1:length(W_CITY)
    LINKS = [(i,j) for i in D for j in W if (D_CITY[i], W_CITY[j]) in DW_LINKS]
    p_supply = 450 
    w_demand = [90, 120, 120, 70, 50]
    param_pd = [
        2.5 250
        3.5 250
    ]
    param_dw = [
        1.7 100
        0.7 100
        1.3 100
        1.3 100
        0.8 100
        0.2 100
        2.1 100
    ]
    return D_CITY, W_CITY, DW_LINKS, D, W, LINKS, p_supply, w_demand, param_pd[:,1], param_pd[:,2], param_dw[:,1], param_dw[:,2]
end

function  startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)
    
    D, W, Links, D_CITY, W_CITY, DW_LINKS, p_supply, w_demand, pd_cost, pd_cap, dw_cost, dw_cap = data()
    model = Specialized_transshipment_model(model, D_CITY, W_CITY, DW_LINKS, p_supply, w_demand, pd_cost, pd_cap, dw_cost, dw_cap)
    optimize!(model)
    pd_ship = value.(model[:PD_Ship])
    dw_ship = value.(model[:DW_Ship])
    assign_plan = [("PITT", D[i]) => pd_ship[i] for i in D_CITY]
    ship_plan = [(Links[k] => dw_ship[i,j]) for i in D_CITY for j in W_CITY for k in 1:length(DW_LINKS) if DW_LINKS[k] == (i,j)]
end
startmodel()
# solution obj = +1.81900000000000e+03
# pd_ship = [("PITT", "NE") => 250.0, ("PITT", "SE") => 200.0]
# dw_ship = [("NE", "BOS") => 90.0, ("NE", "EWR") => 100.0, ("NE", "BWI") => 60.0, ("SE", "EWR") => 20.0, ("SE", "BWI") => 60.0, ("SE", "ATL") => 70.0, ("SE", "MCO") => 50.0]