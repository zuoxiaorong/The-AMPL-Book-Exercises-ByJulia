using JuMP
using SCIP

function a_lpmodel(model)
    orders = [48, 35, 24, 10, 8]

    num_aval = sum(orders)

    nbr = [
        3 1 0 2 1 3
        0 2 0 0 0 1
        1 0 1 0 0 0
        0 0 1 1 0 0
        0 0 0 0 1 0
    ]

    patterns = 1:6
    widths = 1:5

    @variable(model, x[1:num_aval], Bin)
    @variable(model, y[1:num_aval, patterns], Bin)
    @constraint(model, [i in 1:num_aval], sum(y[i,j] for j in patterns) == x[i])

    @constraint(model, [w in widths], sum(y[i,j]*nbr[w,j] for i in 1:num_aval for j in patterns) >= orders[w])

    @objective(model, Min, sum(x[i] for i in 1:num_aval))

    return model
end

function b_lpmodel(model)
    orders = [48, 35, 24, 10, 8]

    num_aval = sum(orders)

    nbr = [
        3 1 0 2 1 3
        0 2 0 0 0 1
        1 0 1 0 0 0
        0 0 1 1 0 0
        0 0 0 0 1 0
    ]

    patterns = 1:6
    widths = 1:5

    @variable(model, x[1:num_aval], Bin)
    @variable(model, y[1:num_aval, patterns], Bin)

    @constraint(model, [i in 1:num_aval], sum(y[i,j] for j in patterns) == x[i])
    @constraint(model, [i in 1:num_aval, j in patterns], y[i,j] <= x[i])
    
    @constraint(model, [w in widths], 0.1*orders[w] <= sum(y[i,j]*nbr[w,j] for i in 1:num_aval for j in patterns) <= 0.4*orders[w])

    @objective(model, Min, sum(x[i] for i in 1:num_aval))

    return model
end

function findpatterns(len, lens)
    min_diff = minimum(lens)
    set = []
    function find_combinations(comb, items)
        if sum(comb) <= len && abs(len - sum(comb)) < min_diff
            push!(set, filter(x -> x > 0, comb))
        end
        
        for item in items
            new_comb = [comb..., item]
            new_items = filter(x -> x <= len - sum(new_comb) && x <= item, lens)
            find_combinations(new_comb, new_items)
        end
    end
    find_combinations([0], lens)
    patterns = [count(set[j] .== len) for len in lens, j in 1:length(set)]
    return patterns
end

function c_lpmodel(model)
    orders = [48, 35, 24, 10, 8]

    num_aval = sum(orders)
    lens = [20, 45, 50, 55, 75]
    len = 110

    nbr = findpatterns(len, lens)
    display(nbr)
    patterns = 1:size(nbr,2)
    widths = 1:length(lens)

    @variable(model, x[1:num_aval], Bin)
    @variable(model, y[1:num_aval, patterns], Bin)
    @constraint(model, [i in 1:num_aval], sum(y[i,j] for j in patterns) == x[i])
    @constraint(model, [w in widths], sum(y[i,j]*nbr[w,j] for i in 1:num_aval for j in patterns) >= orders[w])
    @objective(model, Min, sum(x[i] for i in 1:num_aval))
    return model
end

function d_lpmodel(model)
    orders = [48, 35, 24, 10, 8]

    num_aval = sum(orders)

    nbr = [
        3 1 0 2 1 3 5 0 0
        0 2 0 0 0 1 0 0 0
        1 0 1 0 0 0 0 0 2
        0 0 1 1 0 0 0 2 0
        0 0 0 0 1 0 0 0 0
    ]

    patterns = 1:9
    widths = 1:5

    @variable(model, x[patterns], lower_bound = 0)

    @constraint(model, [w in widths], sum(x[p]*nbr[w,p] for p in patterns) >= orders[w])

    @objective(model, Min, sum(x[p] for p in patterns))
    return model
end

function  startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)
    
    model  = d_lpmodel(model)
    optimize!(model)                                                                         
end
startmodel() 

#  solution
# 2-6(a)  obj = 50
# 2-6(b)  obj = 6
# 2-6(c)  obj = 47,  total_patterns = 9
# 2-6(d)  obj = 46.25

 