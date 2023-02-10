using JuMP
using SCIP

function data()
    ORIG = 1:11                 #Coullard Daskin Hazen Hopp Iravani Linetsky Mehrotra Nelson Smilowitz Tamhane White
    DEST = 1:11                 #C138 C118 C140 C246 C250 C251 D237 D239 D241 M233 M239
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

function b_data()
    ORIG = 1:11                 #Coullard Daskin Hazen Hopp Iravani Linetsky Mehrotra Nelson Smilowitz Tamhane White
    DEST = 1:11                 #C138 C118 C140 C246 C250 C251 D237 D239 D241 M233 M239
    cost = [
        99  99  99  99  99  99   4   5   3   2   1
        99  99  99  99  99  99   1   5   4   2   3
        99  99  99   1   5  99   2  99  99   3   4
        99  99  99  99  99   5   1  99   4   2   3
        3   2  99  99  99  99   1   5   4  99  99
        99  99  99   5   3   4  99  99  99   1   2
        99  99  99  99  99  99   1   2   5   4   3
        99   5   4  99  99  99   1  99  99   2   3
        99  99  99  99  99   5  99   3   4   1   2
        5  99  99  99   4   3  99  99  99   2   1
        99  99  99   4  99   5   3  99  99   2   1
    ]
    supply = 1
    demand = 1
    return ORIG, DEST,supply, demand, cost
end   

function c_data()
    ORIG = 1:11                 #Coullard Daskin Hazen Hopp Iravani Linetsky Mehrotra Nelson Smilowitz Tamhane White
    DEST = 1:11                 #C118 C138 C140 C246 C250 C251 D237 D239 D241 M233 M239
    cost = [
        20   9   8   7  20  20  4   5   3  2  1
        20   8   7   6  20  20  1   5   4  2  3
        20  10  11   1  20  20  2   7   8  3  4
        20   9   8  10  20  20  1   7   4  2  3
        20   2   8   9  20  20  1   5   4  6  7
        20   9  10   5  20  20  6   7   8  1  2
        20  11  10   9  20  20  1   2   5  4  3
        20   5   4   6  20  20  1   9  10  2  3
        20   9  10   8  20  20  7   3   4  1  2
        20   6   9   8  20  20  7  10  11  2  1
        20   9   8   4  20  20  3  10   7  2  1
    ]
    supply = 1
    demand = [0, 2, 2, 2, 0, 0, 1, 1, 1, 1, 1]
    return ORIG, DEST,supply, demand, cost
end   

function lpmodel(model, ORIG, DEST,supply, demand, cost)
    @variable(model, Trans[ORIG,DEST], Bin)
    @objective(model, Min, sum(cost[i,j]*Trans[i,j] for i in ORIG for j in DEST))
    @constraint(model, [i in ORIG], sum(Trans[i,j] for j in DEST) == supply)
    @constraint(model, [j in DEST], sum(Trans[i,j] for i in ORIG) == demand[j])
    return model
end

function  startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)
    
    ORIG, DEST,supply, demand, cost = c_data()
    model  = lpmodel(model, ORIG, DEST,supply, demand, cost)
    optimize!(model)
println(value.(model[:Trans]))                                                                    
end
startmodel() 

#  solution
# 3-4(b)  obj = 280
# Trans = [
#     0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  1.0  0.0  0.0
#     0.0  0.0  0.0  0.0  0.0  0.0  1.0  0.0  0.0  0.0  0.0
#     0.0  0.0  0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0
#     0.0  0.0  0.0  0.0  0.0  1.0  0.0  0.0  0.0  0.0  0.0
#     0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0
#     0.0  0.0  0.0  0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0
#     0.0  0.0  0.0  0.0  0.0  0.0  0.0  1.0  0.0  0.0  0.0
#     0.0  0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0
#     0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  1.0  0.0
#     1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0
#     0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  1.0
# ]
# 3-4(c)  obj = 330
# Trans = [
#     0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  1.0
#     0.0  0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0
#     0.0  0.0  0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0
#     0.0  0.0  0.0  0.0  0.0  0.0  1.0  0.0  0.0  0.0  0.0
#     0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0
#     0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  1.0  0.0
#     0.0  0.0  0.0  0.0  0.0  0.0  0.0  1.0  0.0  0.0  0.0
#     0.0  0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0
#     0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  1.0  0.0  0.0
#     0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0
#     0.0  0.0  0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0
# ]