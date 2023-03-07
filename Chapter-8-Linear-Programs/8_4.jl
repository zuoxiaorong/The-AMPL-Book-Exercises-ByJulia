using JuMP
using SCIP

function orig_data()
    ORIG = 1:11                 #Coullard Daskin Hazen Hopp Iravani Linetsky Mehrotra Nelson Smilowitz Tamhane White
    DEST = 1:11                 #C118 C138 C140 C246 C250 C251 D237 D239 D241 M233 M239
    cost = [
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
    supply = 1
    demand = 1
    return ORIG, DEST,supply, demand, cost
end 

function b_data()               #modify cost[3,4] from 1 to 2 and cost[3,7] from 2 to 1
    ORIG = 1:11                 #Coullard Daskin Hazen Hopp Iravani Linetsky Mehrotra Nelson Smilowitz Tamhane White
    DEST = 1:11                 #C118 C138 C140 C246 C250 C251 D237 D239 D241 M233 M239
    cost = [
        6 9 8 7 11 10 4 5 3 2 1
        11 8 7 6 9 10 1 5 4 2 3
        9 10 11 2 5 6 1 7 8 3 4
        11 9 8 10 6 5 1 7 4 2 3
        3 2 8 9 10 11 1 5 4 6 7
        11 9 10 5 3 4 6 7 8 1 2
        6 11 10 9 8 7 1 2 5 4 3
        11 5 4 6 7 8 1 9 10 2 3
        11 9 10 8 6 5 7 3 4 1 2
        5 6 9 8 4 3 7 10 11 2 1
        11 9 8 4 6 5 3 10 7 2 1
    ]
    supply = 1
    demand = 1
    return ORIG, DEST,supply, demand, cost
end 

function str()
    ORIG = ["Coullard", "Daskin", "Hazen", "Hopp", "Iravani", "Linetsky", "Mehrotra", "Nelson", "Smilowitz", "Tamhane", "White"]
    DEST = ["C118", "C138", "C140", "C246", "C250", "C251", "D237", "D239", "D241", "M233", "M239"]
    return ORIG, DEST
end

function lpmodel(model, ORIG, DEST,supply, demand, cost)
    @variable(model, Trans[ORIG,DEST], Bin)
    @objective(model, Min, sum(cost[i,j]*Trans[i,j] for i in ORIG for j in DEST))
    @constraint(model, [i in ORIG], sum(Trans[i,j] for j in DEST) == supply)
    @constraint(model, [j in DEST], sum(Trans[i,j] for i in ORIG) == demand)
    return model
end

function  startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)
    
    ORIG, DEST,supply, demand, cost = b_data()
    O, D = str()
    model  = lpmodel(model, ORIG, DEST,supply, demand, cost)
    optimize!(model)
end                                                                    
startmodel() 

# (a) obj = +2.80000000000000e+01
# Solution 1: ["Coullard" => "C118", "Daskin" => "D241", "Hazen" => "C246", "Hopp" => "D237", "Iravani" => "C138", "Linetsky" => "C250", "Mehrotra" => "D239", "Nelson" => "C140", "Smilowitz" => "M233", "Tamhane" => "C251", "White" => "M239"]
# Solution 2: ["Coullard" => "M239", "Daskin" => "D237", "Hazen" => "C246", "Hopp" => "M233", "Iravani" => "C138", "Linetsky" => "C250", "Mehrotra" => "D239", "Nelson" => "C140", "Smilowitz" => "D241", "Tamhane" => "C251", "White" => "C118"]
# individuals with different assignments: ["Coullard", "Daskin", "Hopp", "Smilowitz", "White"]
# (b) obj = +2.90000000000000e+01
