using JuMP
using SCIP

function Network_transshipment_problem_model(model, CITIES, Links, supply, demand, cost, capacity)
    @variable(model, Ship[i in CITIES, j in CITIES; (i, j) in Links], lower_bound = 0, upper_bound = capacity[findfirst(x -> x == (i,j), Links)])

    @objective(model, Min, sum(cost[k]*Ship[i,j] for i in CITIES for j in CITIES for k in 1:length(Links) if Links[k] == (i, j)))

    @constraint(model, [i in CITIES], supply[i] + sum(Ship[j,i] for j in CITIES if (j, i) in Links) == demand[i] + sum(Ship[i,j] for j in CITIES if (i, j) in Links))
    return model
end

function  data()
    CITIES = ["PITT", "NE", "SE", "BOS", "EWR", "BWI", "ATL", "MCO"]
    LINKS = [("PITT","NE") ("PITT","SE") ("NE","BOS") ("NE","EWR") ("NE","BWI") ("SE","EWR") ("SE","BWI") ("SE","ATL") ("SE","MCO")]
    C = 1:length(CITIES)
    L = [(i,j) for i in 1:length(CITIES) for j in 1:length(CITIES) if (CITIES[i], CITIES[j]) in LINKS]
    supply = [ifelse(CITIES[i] == "PITT", 450, 0) for i in C]
    demand = [ifelse(CITIES[i] == "BOS", 90, ifelse(CITIES[i] in ["EWR", "BWI"], 120, ifelse(CITIES[i] == "ATL", 70, ifelse(CITIES[i] == "MCO", 50, 0)))) for i in C]
    params_links = [
        2.5 250
        3.5 250
        1.7 100
        0.7 100
        1.3 100
        1.3 100
        0.8 100
        0.2 100
        2.1 100 
    ]
    return CITIES, LINKS, C, L, supply, demand, params_links[:,1], params_links[:,2]
end

function  startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)
    
    C, L, CITIES, LINKS, supply, demand, cost, capacity = data()
    model = Network_transshipment_problem_model(model, CITIES, LINKS, supply, demand, cost, capacity)
    optimize!(model)
    ship = value.(model[:Ship])
    assign_set = [(L[k] => ship[i,j]) for i in CITIES for j in CITIES for k in 1:length(LINKS) if  LINKS[k] == (i,j)]
end
startmodel()

# Solution
# ship = [
#     ("PITT", "NE") => 250.0
#     ("PITT", "SE") => 200.0
#     ("NE", "BOS") => 90.0
#     ("NE", "EWR") => 100.0
#     ("NE", "BWI") => 60.0
#     ("SE", "EWR") => 20.0
#     ("SE", "BWI") => 60.0
#     ("SE", "ATL") => 70.0
#     ("SE", "MCO") => 50.0
# ]