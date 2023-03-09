using JuMP
using SCIP

function Specialized_transshipment_model(model, D_CITY, W_CITY, DW_LINKS, p_supply, w_demand, pd_cost, pd_cap, dw_cost, dw_cap, T, Inv0, inv_cost)
    @variable(model, PD_Ship[i in D_CITY, t in T], lower_bound = 0, upper_bound = pd_cap[i])
    @variable(model, DW_Ship[i in D_CITY, j in W_CITY, t in T; (i, j) in DW_LINKS], lower_bound = 0, upper_bound = dw_cap[findfirst(x -> x == (i,j), DW_LINKS)])
    @variable(model, Inv[i in D_CITY, t in T], lower_bound = 0)

    @objective(model, Min, sum(pd_cost[i]*PD_Ship[i,t]+inv_cost[i]*Inv[i,t] for i in D_CITY for t in T) + sum(dw_cost[k]*DW_Ship[i,j,t] for (i,j) in DW_LINKS for k in 1:length(dw_cost) for t in T if (i,j) == DW_LINKS[k]))
    @constraint(model, [t in T], sum(PD_Ship[i,t] for i in D_CITY) == p_supply[t])
    @constraint(model, [i in D_CITY], PD_Ship[i,1] + Inv0[i] == sum(DW_Ship[i,j,1] for j in W_CITY if (i,j) in DW_LINKS) + Inv[i,1])
    @constraint(model, [i in D_CITY, t in T; t >= 2], PD_Ship[i,t] + Inv[i,t-1] == sum(DW_Ship[i,j,t] for j in W_CITY if (i,j) in DW_LINKS) + Inv[i,t])
    @constraint(model, [j in W_CITY, t in T], sum(DW_Ship[i,j,t] for i in D_CITY if (i,j) in DW_LINKS) == w_demand[t,j])
    return model
end

function data()
    T = 1:5
    D_CITY = ["NE", "SE"]
    W_CITY = ["BOS", "EWR", "BWI", "ATL", "MCO"]
    DW_LINKS = [("NE","BOS"), ("NE","EWR"), ("NE","BWI"), ("SE","EWR"), ("SE","BWI"), ("SE","ATL"), ("SE","MCO")]
    D = 1:length(D_CITY)
    W = 1:length(W_CITY)
    LINKS = [(i,j) for i in D for j in W if (D_CITY[i], W_CITY[j]) in DW_LINKS]
    p_supply = [450, 450, 400, 250, 325] 
    w_demand = [
        50 90 95 50 20
        65 100 105 50 20
        70 100 110 50 25
        70 110 120 50 40
        80 115 120 55 45
    ]
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
    Inv0 = [200,75]
    inv_cost = [0.15 0.12]
    return D_CITY, W_CITY, DW_LINKS, D, W, LINKS, p_supply, w_demand, param_pd[:,1], param_pd[:,2], param_dw[:,1], param_dw[:,2], T, Inv0, inv_cost
end

function  startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)
    
    D, W, Links, D_CITY, W_CITY, DW_LINKS, p_supply, w_demand, pd_cost, pd_cap, dw_cost, dw_cap, T, Inv0, inv_cost = data()
    model = Specialized_transshipment_model(model, D_CITY, W_CITY, DW_LINKS, p_supply, w_demand, pd_cost, pd_cap, dw_cost, dw_cap, T, Inv0, inv_cost)
    optimize!(model)
    pd_ship = value.(model[:PD_Ship])
    dw_ship = value.(model[:DW_Ship])
    assign_plan = [("Week$(t)", "PITT", D[i]) => pd_ship[i,t] for i in D_CITY for t in T]
    println(assign_plan)
    ship_plan = [("Week$(t)", Links[k] => dw_ship[i,j,t]) for i in D_CITY for j in W_CITY for t in T for k in 1:length(DW_LINKS) if DW_LINKS[k] == (i,j)]
    println(ship_plan)
end
startmodel()
# solution
# (b) obj = +7.51880000000000e+03
# pd_ship = [
#     ("Week1", "PITT", "NE") => 250.0
#     ("Week2", "PITT", "NE") => 250.0
#     ("Week3", "PITT", "NE") => 250.0
#     ("Week4", "PITT", "NE") => 250.0
#     ("Week5", "PITT", "NE") => 250.0
#     ("Week1", "PITT", "SE") => 200.0
#     ("Week2", "PITT", "SE") => 200.0
#     ("Week3", "PITT", "SE") => 150.0
#     ("Week4", "PITT", "SE") => 0.0
#     ("Week5", "PITT", "SE") => 75.0
# ]
# dw_ship = [("Week1", ("NE", "BOS") => 50.0), ("Week2", ("NE", "BOS") => 65.0), ("Week3", ("NE", "BOS") => 70.0), ("Week4", ("NE", "BOS") => 70.0), ("Week5", ("NE", "BOS") => 80.0), ("Week1", ("NE", "EWR") => 90.0), ("Week2", ("NE", "EWR") => 100.0), ("Week3", ("NE", "EWR") => 100.0), ("Week4", ("NE", "EWR") => 100.0), ("Week5", ("NE", "EWR") => 100.0), ("Week1", ("NE", "BWI") => 95.0), ("Week2", ("NE", "BWI") => 100.0), ("Week3", ("NE", "BWI") => 45.0), ("Week4", ("NE", "BWI") => 20.0), ("Week5", ("NE", "BWI") => 20.0), ("Week1", ("SE", "EWR") => 0.0), ("Week2", ("SE", "EWR") => 0.0), ("Week3", ("SE", "EWR") => 0.0), ("Week4", ("SE", "EWR") => 10.0), ("Week5", ("SE", "EWR") => 15.0), ("Week1", ("SE", "BWI") => 0.0), ("Week2", ("SE", "BWI") => 5.0), ("Week3", ("SE", "BWI") => 65.0), ("Week4", ("SE", "BWI") => 100.0), ("Week5", ("SE", "BWI") => 100.0), ("Week1", ("SE", "ATL") => 50.0), ("Week2", ("SE", "ATL") => 50.0), ("Week3", ("SE", "ATL") => 50.0), ("Week4", ("SE", "ATL") => 50.0), ("Week5", ("SE", "ATL") => 55.0), ("Week1", ("SE", "MCO") => 20.0), ("Week2", ("SE", "MCO") => 20.0), ("Week3", ("SE", "MCO") => 25.0), ("Week4", ("SE", "MCO") => 40.0), ("Week5", ("SE", "MCO") => 45.0)]