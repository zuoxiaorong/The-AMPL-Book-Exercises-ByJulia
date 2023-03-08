using JuMP
using SCIP

function  data()
    CITIES = ["A", "B", "C", "D", "E", "F"]
    LINKS = [("A","B") ("A","C") ("B","C") ("B","D") ("B","E") ("C","E") ("D","E") ("D","F") ("E","F")]
    C = 1:length(CITIES)
    L = [(i,j) for i in 1:length(CITIES) for j in 1:length(CITIES) if (CITIES[i], CITIES[j]) in LINKS]
    supply = [ifelse(CITIES[i] == "A", 100, ifelse(CITIES[i] == "B", 50, 0)) for i in C]
    demand = [ifelse(CITIES[i] == "E", 30, ifelse(CITIES[i] == "F", 120, 0)) for i in C]
    params_links = [
        13 80
        12 80
        1  80
        6  80
        9  80
        7  80
        4  80
        13 80
        12 80 
    ]
    return CITIES, LINKS, C, L, supply, demand, params_links[:,1], params_links[:,2]
end

function Network_transshipment_problem_model(model, CITIES, Links, supply, demand, cost, capacity)
    @variable(model, Ship[i in CITIES, j in CITIES; (i, j) in Links], lower_bound = 0, upper_bound = capacity[findfirst(x -> x == (i,j), Links)])

    @objective(model, Min, sum(cost[k]*Ship[i,j] for i in CITIES for j in CITIES for k in 1:length(Links) if Links[k] == (i, j)))

    @constraint(model, [i in CITIES], supply[i] + sum(Ship[j,i] for j in CITIES if (j, i) in Links) == demand[i] + sum(Ship[i,j] for j in CITIES if (i, j) in Links))
    return model
end

function  newdata()
    CITIES = ["A", "B", "C", "D", "E", "F"]
    LINKS = [("A","B") ("A","C") ("B","C") ("B","D") ("B","E") ("C","E") ("D","E") ("D","F") ("E","F")]
    C = 1:length(CITIES)
    supply = [ifelse(CITIES[i] == "A", 100, ifelse(CITIES[i] == "B", 50, 0)) for i in C]
    demand = [ifelse(CITIES[i] == "E", 30, ifelse(CITIES[i] == "F", 120, 0)) for i in C]
    cost = [
        0  13 12 0  0  0
        0  0  1  6  9  0
        0  0  0  0  7  0
        0  0  0  0  4  13
        0  0  0  0  0  12
        0  0  0  0  0  0
    ]
    capacity = 80
    return CITIES, LINKS, C, supply, demand, cost, capacity
end

function Network_transshipment_problem_newmodel(model, CITIES, supply, demand, cost, capacity)
    @variable(model, Ship[i in CITIES, j in CITIES], lower_bound = 0, upper_bound = capacity)

    @objective(model, Min, sum(cost[i,j]*Ship[i,j] for i in CITIES for j in CITIES))

    @constraint(model, [i in CITIES, j in CITIES; cost[i,j] == 0], Ship[i,j] == 0)
    @constraint(model, [i in CITIES], supply[i] + sum(Ship[j,i] for j in CITIES) == demand[i] + sum(Ship[i,j] for j in CITIES))
    return model
end

function startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)
    
    C, L, CITIES, LINKS, supply, demand, cost, capacity = data()
    model = Network_transshipment_problem_model(model, CITIES, LINKS, supply, demand, cost, capacity)
    optimize!(model)
    ship = value.(model[:Ship])
    assign_set = [(L[k] => ship[i,j]) for i in CITIES for j in CITIES for k in 1:length(LINKS) if  LINKS[k] == (i,j)]
end

function startnewmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)
    
    C, L, CITIES, supply, demand, cost, capacity = newdata()
    model = Network_transshipment_problem_newmodel(model, CITIES, supply, demand, cost, capacity)
    optimize!(model)
    ship = value.(model[:Ship])
    assign_set = [((C[i], C[j]) => ship[i,j]) for i in CITIES for j in CITIES if ship[i,j] != 0]
end
startnewmodel()

# Solution
# (a) obj = +3.71000000000000e+03
# [("A", "B") => 20.0, ("A", "C") => 80.0, ("B", "C") => 0.0, ("B", "D") => 70.0, ("B", "E") => 0.0, ("C", "E") => 80.0, ("D", "E") => 0.0, ("D", "F") => 70.0, ("E", "F") => 50.0]
# (b) obj = +3.71000000000000e+03
# [("A", "B") => 20.0, ("A", "C") => 80.0, ("B", "D") => 70.0, ("C", "E") => 80.0, ("D", "F") => 70.0, ("E", "F") => 50.0]
