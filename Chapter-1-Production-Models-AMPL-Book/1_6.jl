using JuMP
using SCIP

function lpmodel(model)
    intermediates = 1:8            #SRG N RF CG B DI GO RS index by i
    f_products = 1:4               #PG, RG, D, HF index by j
    attributes = 1:4               #vap, oct, den, sul index by k

    a = [21170, 500, 16140, 4610, 370, 250, 11600, 25210]
    r = [
        18.4 -78.5 0 0
        6.54 -65.0 272 0.283
        2.57 -104.0 0 0
        6.90 -93.7 0 0
        199.2 -91.8 0 0
        0 0 292 0.526
        0 0 295 0.353
        0 0 343 4.70
    ]
    g = [
        1 1 0 0
        1 1 1 0
        1 1 0 0
        1 1 0 0
        1 1 0 0
        0 0 1 0
        0 0 1 1
        0 0 0 1
    ]
    u = [
        12.2 -90 9999 9999
        12.7 -86 9999 9999
        9999 9999 306 0.5
        9999 9999 352 3.5
    ]
    c = [10.5, 9.1, 7.7, 6.65]

    @variable(model, x[i in intermediates, j in f_products], lower_bound = 0, upper_bound = a[i]*g[i,j], Int)
    @variable(model, y[f_products], lower_bound = 0, Int)
    
    @objective(model, Max, sum(y[j]*c[j] for j in f_products))

    @constraint(model, [i in intermediates], sum(x[i,j] for j in f_products) == a[i])
    @constraint(model, [j in f_products], sum(x[i,j] for i in intermediates) == y[j])
    @constraint(model, [j in f_products, k in attributes], sum(r[i,k]*x[i,j] for i in intermediates) <= u[j,k]*y[j])  
    return model
end

function  startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)
    
    model  = lpmodel(model)
    optimize!(model)                                                                         
end
startmodel() 

#  solution
# 1-6  when x and y is not required to be int
# obj = 648385
# x = [
    # 3981.968448387339     17188.03155161266      -0.0                -0.0
    # 0.0                  500.0                 0.0                -0.0
    # 3266.2508494714457    12873.749150528554     -0.0                -0.0
    # 0.0                 4610.0                -0.0                -0.0
    # 36.180702141222184    333.8192978587778    -0.0                -0.0
    # -0.0                   -0.0               250.0                -0.0
    # -0.0                   -0.0              1987.035271687324   9612.964728312676
    # -0.0                   -0.0                -0.0             25210.0
# ]
# y = [7284.400000000007, 35505.59999999999, 2237.035271687324,34822.964728312676]                                                             
# 1-6  when x and y is required to be int
# obj = 648384
# x = [
#     9.0  21161.0    -0.0     -0.0
#     0.0    500.0     0.0     -0.0
#  6874.0   9266.0    -0.0     -0.0
#    46.0   4564.0    -0.0     -0.0
#   355.0     15.0    -0.0     -0.0
#    -0.0     -0.0   250.0     -0.0
#    -0.0     -0.0  1987.0   9613.0
#    -0.0     -0.0    -0.0  25210.0
# ]
# y = [7284.0, 35506.0, 2237.0, 34823.0]   