using JuMP
using SCIP
using DataFrames

function caterer_problem(model, T, Initial_s, cost_new, cost2, cost4, day2, day4, demand)
    @variable(model, Buy[T] >= 0)                       #clean napkins bought for day t
    @variable(model, Carry[T] >= 0)                     #clean napkins still on hand at the end of day t
    @variable(model, Wash2[T] >= 0)                     #used napkins sent to the fast laundry after day t
    @variable(model, Wash4[T] >= 0)                     #used napkins sent to the slow laundry after day t
    @variable(model, Trash[T] >= 0)                     #used napkins discarded after day t

    @objective(model, Min, sum(Buy[t]*cost_new + Wash2[t]*cost2 + Wash4[t]*cost4 for t in T))

    @constraints(model, begin
        Initial_s + Buy[1] >= demand[1]
        [t in T; t >= 2 && t <= day2], Carry[t-1] + Buy[t] >= demand[t]
        [t in T; t >= day2 + 1 && t <= day4], Carry[t-1] + Buy[t] + Wash2[t-day2] >= demand[t]
        [t in T; t >= day4 + 1], Carry[t-1] + Buy[t] + Wash2[t-day2] + Wash4[t-day4] >= demand[t]
    end)
    @constraint(model, [t in T], Wash2[t] + Wash4[t] + Trash[t] == demand[t])
    @constraint(model, Initial_s + Buy[1] - Wash2[1] - Wash4[1] - Trash[1] == Carry[1])
    @constraint(model, [t in T; t >= 2 && t <= day2], Carry[t-1] + Buy[t] - Wash2[t] - Wash4[t] - Trash[t] == Carry[t])
    @constraint(model, [t in T; t >= day2 + 1 && t <= day4], Carry[t-1] + Buy[t] - Wash2[t] - Wash4[t] - Trash[t] + Wash2[t-day2] == Carry[t])
    @constraint(model, [t in T; t >= day4 + 1], Carry[t-1] + Buy[t] - Wash2[t] - Wash4[t] - Trash[t] + Wash2[t-day2] + Wash4[t-day4] == Carry[t])
    return model
end

function data()
    T = 1:15
    Initial_s = 10
    cost_new = 10
    cost2 = 2
    cost4 = 0.5
    day2 = 2
    day4 = 4
    demand = [50,31,24,62,25,52,34,53,25,26,74,16,52,10,10]
    return T, Initial_s, cost_new, cost2, cost4, day2, day4, demand
end

function  startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)
    
    T, Initial_s, cost_new, cost2, cost4, day2, day4, demand = data()
    model = caterer_problem(model, T, Initial_s, cost_new, cost2, cost4, day2, day4, demand)
    optimize!(model)

    df = DataFrame()
    df.buy = value.(model[:Buy])
    df.wash2 = value.(model[:Wash2])
    df.wash4 = value.(model[:Wash4])
    df.trash = value.(model[:Trash])
    df.carry = value.(model[:Carry])
    df.used = value.(model[:Wash2]) .+ value.(model[:Wash4]) .+ value.(model[:Trash])
    df.demand = demand
    println(df)
end 
startmodel()    

# solution obj = +1.66350000000000e+03
# 15×7 DataFrame
#  Row │ buy      wash2    wash4    trash    carry    used     demand 
#      │ Float64  Float64  Float64  Float64  Float64  Float64  Int64  
# ─────┼──────────────────────────────────────────────────────────────
#    1 │    71.0     36.0     14.0      0.0     31.0     50.0      50
#    2 │     0.0     31.0      0.0      0.0      0.0     31.0      31
#    3 │    19.0     11.0     13.0      0.0     31.0     24.0      24
#    4 │     0.0     52.0     10.0      0.0      0.0     62.0      62
#    5 │     0.0     21.0      4.0      0.0      0.0     25.0      25
#    6 │     0.0     52.0      0.0      0.0      0.0     52.0      52
#    7 │     0.0     12.0     22.0      0.0      0.0     34.0      34
#    8 │     0.0     53.0      0.0      0.0      9.0     53.0      53
#    9 │     0.0     25.0      0.0      0.0      0.0     25.0      25
#   10 │     0.0     16.0     10.0      0.0     27.0     26.0      26
#   11 │     0.0     52.0     10.0     12.0      0.0     74.0      74
#   12 │     0.0      0.0      0.0     16.0      0.0     16.0      16
#   13 │     0.0      0.0      0.0     52.0      0.0     52.0      52
#   14 │     0.0      0.0      0.0     10.0      0.0     10.0      10
#   15 │     0.0      0.0      0.0     10.0      0.0     10.0      10
