using JuMP
using SCIP

function a_lpmodel(model, Nutr, Food, Links, f_min, f_max, n_min, n_max, amt)
    @variable(model, Buy[j in Food], lower_bound = f_min[j], upper_bound = f_max[j], Int)
    
    @constraint(model, diet[i in Nutr], sum(amt[k]*Buy[j] for j in Food for k in 1:length(Links) if (i,j) == Links[k]) >= n_min[i])
    @constraint(model, diet[i in Nutr], sum(amt[k]*Buy[j] for j in Food for k in 1:length(Links) if (i,j) == Links[k]) <= n_max[i])

    @objective(model, Min, sum(cost[j]*Buy[j] for j in Food))
    return model
end

function b_lpmodel(model, Nutr, Food, FN, f_min, f_max, n_min, n_max, amt)
    # FN = []             #food with nutr
    @variable(model, Buy[j in Food], lower_bound = f_min[j], upper_bound = f_max[j], Int)
    
    @constraint(model, diet[i in Nutr], sum(amt[k]*Buy[j] for j in Food for k in 1:length(FN) if (j,i) == Links[k]) >= n_min[i])
    @constraint(model, diet[i in Nutr], sum(amt[k]*Buy[j] for j in Food for k in 1:length(FN) if (j,i) == Links[k]) <= n_max[i])

    @objective(model, Min, sum(cost[j]*Buy[j] for j in Food))
    return model
end

function c_lpmodel(model, Nutr, Food, NF, f_min, f_max, n_min, n_max, amt)
    # NF = []             #nutr in food
    @variable(model, Buy[j in Food], lower_bound = f_min[j], upper_bound = f_max[j], Int)
    
    @constraint(model, diet[i in Nutr], sum(amt[k]*Buy[j] for j in Food for k in 1:length(NF) if (i,j) == Links[k]) >= n_min[i])
    @constraint(model, diet[i in Nutr], sum(amt[k]*Buy[j] for j in Food for k in 1:length(NF) if (i,j) == Links[k]) <= n_max[i])

    @objective(model, Min, sum(cost[j]*Buy[j] for j in Food))
    return model
end

function get_Links()
    Nutr = 1:4      #calories   protein   calcium  vitamin A
    Food = 1:6      #bread meat potatoes cabbage milk gelatin required

    amt = [
        1254 1457 318 46 309 1725 
        39 73 8 4 16 43
        418 41 42 141 536 0
        0 0 70 860 720 0
    ]
    Links = []
    map(x -> push!(Links, x[1][1] => x[1][2]), eachrow(findall(x -> x > 0, amt)))
    # map(x -> push!(Links, (x[1][1], x[1][2])), eachrow(findall(x -> x > 0, amt)))
    return Links
end