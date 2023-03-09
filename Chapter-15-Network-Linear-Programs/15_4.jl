using JuMP
using SCIP

function Network_transshipment_problem_model(model, CITIES, Links, supply, demand, cost, capacity)
    @variable(model, Ship[i in CITIES, j in CITIES; (i, j) in Links], lower_bound = 0, upper_bound = capacity[findfirst(x -> x == (i,j), Links)])

    @objective(model, Min, sum(cost[k]*Ship[i,j] for i in CITIES for j in CITIES for k in 1:length(Links) if Links[k] == (i, j)))

    @constraint(model, [i in CITIES], supply[i] + sum(Ship[j,i] for j in CITIES if (j, i) in Links) == demand[i] + sum(Ship[i,j] for j in CITIES if (i, j) in Links))
    return model
end

function  a_data()                  #The transportation problem of Figure 3-1.
    CITIES = ["GARY", "CLEV", "PITT", "FRA", "DET", "LAN", "WIN", "STL", "FRE", "LAF"]
    LINKS = [("GARY", "FRA"), ("GARY", "DET"), ("GARY", "LAN"), ("GARY", "WIN"), ("GARY", "STL"), ("GARY", "FRE"), ("GARY", "LAF"), ("CLEV", "FRA"), ("CLEV", "DET"), ("CLEV", "LAN"), ("CLEV", "WIN"), ("CLEV", "STL"), ("CLEV", "FRE"), ("CLEV", "LAF"), ("PITT", "FRA"), ("PITT", "DET"), ("PITT", "LAN"), ("PITT", "WIN"), ("PITT", "STL"), ("PITT", "FRE"), ("PITT", "LAF")]
    C = 1:length(CITIES)
    L = [(i,j) for i in 1:length(CITIES) for j in 1:length(CITIES) if (CITIES[i], CITIES[j]) in LINKS]
    supply = [ifelse(CITIES[i] == "GARY", 1400, ifelse(CITIES[i] == "CLEV", 2600, ifelse(CITIES[i] == "PITT", 2900, 0))) for i in C]
    demand = [0, 0, 0, 900, 1200, 600, 400, 1700, 1100, 1000]
    cost = [39, 14, 11, 14, 16, 82, 8, 27, 9, 12, 9, 26, 95, 17, 24, 14, 17, 13, 28, 99, 20]
    return CITIES, LINKS, C, L, supply, demand, cost, fill(9999, length(cost))
end

function  b_data()                  #The assignment problem of Figure 3-2.
    ORIG = ["Coullard", "Daskin", "Hazen", "Hopp", "Iravani", "Linetsky", "Mehrotra", "Nelson", "Smilowitz", "Tamhane", "White"]
    DEST = ["C118", "C138", "C140", "C246", "C250", "C251", "D237", "D239", "D241", "M233", "M239"]
    O_D_cost = [
        6 9 8 7 11 10 4 5 3 2 1
        11 8 7 6 9 10 1 5 4 2 3
        9 10 11 1 5 6 2 7 8 3 4
        11 9 8 10 6 5 1 7 4 2 3
        3 2 8 9 10 11 1 5 4 6 7
        11 9 10 5 3 4 6 7 8 1 2
        6 11 10 9 8 7 1 2 5 4 3
        11 5 4 6 7 8 1 9 10 2 3
        11 9 10 8 6 5 7 3 4 1 2
        5 6 9 8 4 3 7 10 11 2 1
        11 9 8 4 6 5 3 10 7 2 1
    ]
    CITIES = union(ORIG, DEST)
    LINKS = [(i, j) for i in ORIG for j in DEST]
    C = 1:length(CITIES)
    L = [(i,j) for i in 1:length(CITIES) for j in 1:length(CITIES) if (CITIES[i], CITIES[j]) in LINKS]
    supply = [ifelse(i <= length(ORIG), 1, 0) for i in 1:length(C)]
    demand = [ifelse(i > length(ORIG), 1, 0) for i in 1:length(C)]
    cost = [O_D_cost[i,j] for i in 1:length(ORIG) for j in 1:length(DEST)]
    return CITIES, LINKS, C, L, supply, demand, cost, fill(9999, length(cost))
end

function c_data()                   #The maximum flow problem of Figure 15-6.
    CITIES = ["a", "b", "c", "d", "e", "f", "g"]
    LINKS = [("a", "b"), ("a", "c"), ("b", "d"), ("b", "e"), ("c", "d"), ("c", "f"), ("d", "e"), ("d", "f"), ("e", "g"), ("f", "g")]
    C = 1:length(CITIES)
    L = [(i,j) for i in 1:length(CITIES) for j in 1:length(CITIES) if (CITIES[i], CITIES[j]) in LINKS]
    supply = [ifelse(CITIES[i] == "a", 150, 0) for i in C]
    demand = [ifelse(CITIES[i] == "g", 140, 0) for i in C]
    cost = ones(length(C))
    cap = [50, 100, 40, 20, 60, 20, 50, 60, 70, 70]
    return CITIES, LINKS, C, L, supply, demand, cost, cap
end

function d_data()                   #The shortest path problem of Figure 15-7.
    CITIES = ["a", "b", "c", "d", "e", "f", "g"]
    LINKS = [("a", "b"), ("a", "c"), ("b", "d"), ("b", "e"), ("c", "d"), ("c", "f"), ("d", "e"), ("d", "f"), ("e", "g"), ("f", "g")]
    C = 1:length(CITIES)
    L = [(i,j) for i in 1:length(CITIES) for j in 1:length(CITIES) if (CITIES[i], CITIES[j]) in LINKS]
    supply = [ifelse(CITIES[i] == "a", 1, 0) for i in C]
    demand = [ifelse(CITIES[i] == "g", 1, 0) for i in C]
    cost =[50, 100, 40, 20, 60, 20, 50, 60, 70, 70]
    return CITIES, LINKS, C, L, supply, demand, cost, fill(1, length(cost))
end

function new_Network_transshipment_problem_model(model, CITIES, Links, supply, demand, cost, capacity)
    @variable(model, Ship[i in CITIES, j in CITIES; (i, j) in Links], lower_bound = 0, upper_bound = capacity[findfirst(x -> x == (i,j), Links)])
    @variable(model, a, lower_bound = 0, upper_bound = 150)             #define total supply
    @objective(model, Max, sum(Ship[i,j] for i in CITIES for j in CITIES if (i, j) in Links && i == 1))

    @constraint(model, [i in CITIES], ifelse(i == 1, a, 0) + sum(Ship[j,i] for j in CITIES if (j, i) in Links) == ifelse(i == length(CITIES), a, 0) + sum(Ship[i,j] for j in CITIES if (i, j) in Links))
    return model
end
    
function  startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)
    
    C, L, CITIES, LINKS, supply, demand, cost, capacity = c_data()
    model = new_Network_transshipment_problem_model(model, CITIES, LINKS, supply, demand, cost, capacity)
    optimize!(model)
    ship = value.(model[:Ship])
    assign_set = [(L[k] => ship[i,j]) for i in CITIES for j in CITIES for k in 1:length(LINKS) if  LINKS[k] == (i,j) && ship[i,j] > 0]          #(a)||(d)
    # assign_set = [(L[k] => cost[k]) for i in CITIES for j in CITIES for k in 1:length(LINKS) if  LINKS[k] == (i,j) && ship[i,j] > 0]          #(b)
    # assign_set = [(L[k] => cost[k]) for i in CITIES for j in CITIES for k in 1:length(LINKS) if  LINKS[k] == (i,j) && ship[i,j] > 0]          #(d)
end
startmodel()

# solution
# (a) obj = +1.96200000000000e+05
# ship = [
#     ("GARY", "STL") => 300.0
#     ("GARY", "FRE") => 1100.0
#     ("CLEV", "DET") => 1200.0
#     ("CLEV", "LAN") => 600.0
#     ("CLEV", "WIN") => 400.0
#     ("CLEV", "LAF") => 400.0
#     ("PITT", "FRA") => 900.0
#     ("PITT", "STL") => 1400.0
#     ("PITT", "LAF") => 600.0
# ]
# (b) obj = +2.80000000000000e+01
# ship = [
#     ("Coullard", "C118") => 6
#     ("Daskin", "D241") => 4
#     ("Hazen", "C246") => 1
#     ("Hopp", "D237") => 1
#     ("Iravani", "C138") => 2
#     ("Linetsky", "C250") => 3
#     ("Mehrotra", "D239") => 2
#     ("Nelson", "C140") => 4
#     ("Smilowitz", "M233") => 1
#     ("Tamhane", "C251") => 3
#     ("White", "M239") => 1
# ]
# (c) obj = +1.30000000000000e+02
# flow = [
#     ("a", "b") => 50.0
#     ("a", "c") => 80.0
#     ("b", "d") => 30.0
#     ("b", "e") => 20.0
#     ("c", "d") => 60.0
#     ("c", "f") => 20.0
#     ("d", "e") => 40.0
#     ("d", "f") => 50.0
#     ("e", "g") => 60.0
#     ("f", "g") => 70.0
# ]
# (d) obj = +1.40000000000000e+02
# path = [
#     ("a", "b") => 50
#     ("b", "e") => 20
#     ("e", "g") => 70
# ]