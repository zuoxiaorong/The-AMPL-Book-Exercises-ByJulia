using JuMP
using SCIP

function assignment_problem_model(model, PEOPLE, PROJECT, cost)
    @variable(model, Assign[i in PEOPLE, j in PROJECT], lower_bound = 0, upper_bound = 1)

    @objective(model, Min, sum(cost[i,j]*Assign[i,j] for i in PEOPLE for j in PROJECT))

    @constraint(model, [i in PEOPLE], sum(Assign[i,j] for j in PROJECT) == 1)
    @constraint(model, [j in PROJECT], 3 <= sum(Assign[i,j] for i in PEOPLE) <= 4)
    return model
end

function c_assignment_problem_model(model, PEOPLE, PROJECT, cost, car_bin, car_limit)
    @variable(model, Assign[i in PEOPLE, j in PROJECT], lower_bound = 0, upper_bound = 1)

    @objective(model, Min, sum(cost[i,j]*Assign[i,j] for i in PEOPLE for j in PROJECT))

    @constraint(model, [i in PEOPLE], sum(Assign[i,j] for j in PROJECT) == 1)
    @constraint(model, [j in PROJECT], 3 <= sum(Assign[i,j] for i in PEOPLE) <= 4)
    @constraint(model, [j in PROJECT], sum(Assign[i,j]*car_bin[i] for i in PEOPLE) >= car_limit[j])
    return model
end

function  data() 
    PEOPLE = ["Allen", "Black", "Chung", "Clark", "Conners", "Cumming", "Demming", "Eng", "Farmer", "Forest", "Goodman", "Harris", "Holmes", "Johnson", "Knorr", "Manheim", "Morris", "Nathan", "Neuman", "Patrick", "Rollins", "Schuman", "Silver", "Stein", "Stock", "Truman", "Wolman", "Young"]
    PROJECT = ["A", "ED", "EZ", "G", "H1", "H2", "RB", "SC"]
    cost = [
        1 3 4 7 7 5 2 6
        6 4 2 5 5 7 1 3
        6 2 3 1 1 7 5 4
        7 6 1 2 2 3 5 4
        7 6 1 3 3 4 5 2
        6 7 4 2 2 3 5 1
        2 5 4 6 6 1 3 7
        4 7 2 1 1 6 3 5
        7 6 5 2 2 1 3 4
        6 7 2 5 5 1 3 4
        7 6 2 4 4 5 1 3
        4 7 5 3 3 1 2 6
        6 7 4 2 2 3 5 1
        7 2 4 6 6 5 3 1
        7 4 1 2 2 5 6 3
        4 7 2 1 1 3 6 5
        7 5 4 6 6 3 1 2
        4 7 5 6 6 3 1 2
        7 5 4 6 6 3 1 2
        1 7 5 4 4 2 3 6
        6 2 3 1 1 7 5 4
        4 7 3 5 5 1 2 6
        4 7 3 1 1 2 5 6
        6 4 2 5 5 7 1 3
        5 2 1 6 6 7 4 3
        6 3 2 7 7 5 1 4
        6 7 4 2 2 3 5 1
        1 3 4 7 7 6 2 5
    ]
    PE = 1:length(PEOPLE)
    PR = 1:length(PROJECT)
    return PEOPLE, PROJECT, PE, PR, cost
end

function car_data(PEOPLE)
    car_peo = ["Chung", "Eng", "Manheim", "Nathan", "Rollins", "Demming", "Holmes", "Morris", "Patrick", "Young"]
    car_bin = [ifelse(PEOPLE[i] in car_peo, 1, 0) for i in 1:length(PEOPLE)]
    car_limit = [1, 0, 0, 2, 2, 2, 1, 1]
    return car_bin, car_limit
end

function  startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)
    
    PE, PR, PEOPLE, PROJECT, cost = data()
    car_bin, car_limit = car_data(PE)
    model = c_assignment_problem_model(model, PEOPLE, PROJECT, cost, car_bin, car_limit)
    optimize!(model)
    ship = value.(model[:Assign])
    assign_set = [(PE[i], PR[j], cost[i,j]) for i in PEOPLE for j in PROJECT if ship[i,j] > 0]         
    pre_num = [(PE[i], cost[i,j]) for i in PEOPLE for j in PROJECT if ship[i,j] > 0 && (cost[i,j] == 2 || cost[i,j] == 3)]
    println(assign_set)
    println(pre_num)
    println(length(pre_num))
end
startmodel()

# solution 
# (b) obj = +3.50000000000000e+01
# assign_plan = [("Allen", "A", 1), ("Black", "RB", 1), ("Chung", "H1", 1), ("Clark", "EZ", 1), ("Conners", "EZ", 1), ("Cumming", "SC", 1), ("Demming", "H2", 1), ("Eng", "G", 1), ("Farmer", "G", 2), ("Forest", "H2", 1), ("Goodman", "RB", 1), ("Harris", "H2", 1), ("Holmes", "SC", 1), ("Johnson", "ED", 2), ("Knorr", "EZ", 1), ("Manheim", "H1", 1), ("Morris", "SC", 2), ("Nathan", "RB", 1), ("Neuman", "RB", 1), ("Patrick", "A", 1), ("Rollins", "G", 1), ("Schuman", "H2", 1), ("Silver", "H1", 1), ("Stein", "EZ", 2), ("Stock", "ED", 2), ("Truman", "ED", 3), ("Wolman", "SC", 1), ("Young", "A", 1)]
# 2nd_or_3rd_plan = [("Farmer", 2), ("Johnson", 2), ("Morris", 2), ("Stein", 2), ("Stock", 2), ("Truman", 3)]
# 2nd_or_3rd_num = 6
# (c) obj = +3.70000000000000e+01
# assign_plan = [("Allen", "A", 1), ("Black", "RB", 1), ("Chung", "H1", 1), ("Clark", "EZ", 1), ("Conners", "EZ", 1), ("Cumming", "SC", 1), ("Demming", "H2", 1), ("Eng", "G", 1), ("Farmer", "G", 2), ("Forest", "EZ", 2), ("Goodman", "RB", 1), ("Harris", "H2", 1), ("Holmes", "SC", 1), ("Johnson", "ED", 2), ("Knorr", "EZ", 1), ("Manheim", "H1", 1), ("Morris", "H2", 3), ("Nathan", "RB", 1), ("Neuman", "SC", 2), ("Patrick", "A", 1), ("Rollins", "G", 1), ("Schuman", "H2", 1), ("Silver", "H1", 1), ("Stein", "RB", 1), ("Stock", "ED", 2), ("Truman", "ED", 3), ("Wolman", "SC", 1), ("Young", "A", 1)]
# 2nd_or_3rd_plan = [("Farmer", 2), ("Forest", 2), ("Johnson", 2), ("Morris", 3), ("Neuman", 2), ("Stock", 2), ("Truman", 3)]
# 2nd_or_3rd_num = 7