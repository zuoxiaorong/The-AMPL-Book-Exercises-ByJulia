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
    worst = 5
    return ORIG, DEST, supply, demand, cost, worst 
end 

function str()
    ORIG = ["Coullard", "Daskin", "Hazen", "Hopp", "Iravani", "Linetsky", "Mehrotra", "Nelson", "Smilowitz", "Tamhane", "White"]
    DEST = ["C118", "C138", "C140", "C246", "C250", "C251", "D237", "D239", "D241", "M233", "M239"]
    return ORIG, DEST
end

function lpmodel(model, ORIG, DEST,supply, demand, cost, worst)
    @variable(model, Trans[ORIG,DEST], lower_bound = 0)
    @objective(model, Min, sum(cost[i,j]*Trans[i,j] for i in ORIG for j in DEST))
    @constraint(model, [i in ORIG], sum(Trans[i,j] for j in DEST) == supply)
    @constraint(model, [j in DEST], sum(Trans[i,j] for i in ORIG) == demand)
    # @constraint(model, [i in ORIG, j in DEST; cost[i,j] > worst], Trans[i,j] == 0)              #(a)
    @constraint(model, [j in DEST; cost[8,j] > 1], Trans[8,j] == 0)                               #(d)
    return model
end


function  startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)
    
    ORIG, DEST, supply, demand, cost, worst = orig_data()
    O, D = str()
    model = lpmodel(model, ORIG, DEST, supply, demand, cost, worst)
    optimize!(model) 
end
startmodel() 

# solution
# (b) ["Tamhane" => "C118", "Iravani" => "C138", "Nelson" => "C140", "Hazen" => "C246", "Linetsky" => "C250", "Hopp" => "C251", "Daskin" => "D237", "Mehrotra" => "D239", "Coullard" => "D241", "Smilowitz" => "M233", "White" => "M239"]
# (c) [("Coullard", "C118", 6)]
# (d) obj = +3.10000000000000e+01 assign_set = [("Coullard", "C118", 6), ("Iravani", "C138", 2), ("Daskin", "C140", 7), ("Hazen", "C246", 1), ("Linetsky", "C250", 3), ("Tamhane", "C251", 3), ("Nelson", "D237", 1), ("Mehrotra", "D239", 2), ("Hopp", "D241", 4), ("Smilowitz", "M233", 1), ("White", "M239", 1)]