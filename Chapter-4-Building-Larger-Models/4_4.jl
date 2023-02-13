using JuMP
using SCIP

function data()
    P = 1:3                     #18REG, 24REG, 24PRO
    S = 1:2                     #day shift, night shift
    T = 1:13                    #denoting  periods
    l = 8                       #production lines
    M = 3                       #denoting max change crews per period
    r = [1.194, 1.509, 1.509]   #production rate for product p, in crew-hours per 1000 boxes, index by p
    w = [44900, 123100]         #wage of shift s, index by S
    h = [156, 152, 160, 152, 156, 152, 152, 160, 152, 160, 160, 144, 144]           #number of hours that a crew works in planning period t
    d = [
        63.8  1212.0 0.0  
        76.0  306.2  0.0  
        88.4  319.0  0.0  
        913.8 208.4  0.0  
        115.0 298.0  0.0  
        133.8 328.2  0.0  
        79.6  959.6  0.0  
        111.0 257.6  0.0  
        121.6 335.6  0.0  
        470.0 118.0  1102.0  
        78.4  284.8  0.0  
        99.4  970.0  0.0  
        140.4 343.8  0.0 
    ]
    return S, P, T, l, r, h, w, d, M
end

function c_data()
    P = 1:3                     #18REG, 24REG, 24PRO
    S = 1:2                     #day shift, night shift
    T = 1:13                    #denoting  periods
    l = 8                       #production lines
    M = 3                       #denoting max change crews per period
    r = [1.194, 1.509, 1.509]   #production rate for product p, in crew-hours per 1000 boxes, index by p
    w = [44900, 123100]         #wage of shift s, index by S
    h = [156, 152, 160, 152, 156, 152, 152, 160, 152, 160, 160, 144, 144]           #number of hours that a crew works in planning period t
    d = [
        63.8  1212.0 0.0  
        76.0  306.2  0.0  
        88.4  319.0  0.0  
        913.8 208.4  0.0  
        115.0 298.0  0.0  
        133.8 328.2  0.0  
        79.6  959.6  0.0  
        111.0 257.6  0.0  
        121.6 335.6  0.0  
        470.0 118.0  1102.0  
        78.4  284.8  0.0  
        99.4  970.0  0.0  
        140.4 343.8  0.0 
    ]
    Invcost = [34.56, 43.80, 43.80]
    return S, P, T, l, r, h, w, d, M, Invcost
end

function d_data()
    P = 1:3                     #18REG, 24REG, 24PRO
    S = 1:2                     #day shift, night shift
    T = 1:13                    #denoting  periods
    l = 8                       #production lines
    M = 3                       #denoting max change crews per period
    r = [1.194, 1.509, 1.509]   #production rate for product p, in crew-hours per 1000 boxes, index by p
    w = [44900, 123100]         #wage of shift s, index by S
    h = [156, 152, 160, 152, 156, 152, 152, 160, 152, 160, 160, 144, 144]           #number of hours that a crew works in planning period t
    d = [
        63.8  1212.0 0.0  
        76.0  306.2  0.0  
        88.4  319.0  0.0  
        913.8 208.4  0.0  
        115.0 298.0  0.0  
        133.8 328.2  0.0  
        79.6  959.6  0.0  
        111.0 257.6  0.0  
        121.6 335.6  0.0  
        470.0 118.0  1102.0  
        78.4  284.8  0.0  
        99.4  970.0  0.0  
        140.4 343.8  0.0 
    ]
    Invcost = [34.56, 43.80, 43.80]
    A = 1:2
    return S, P, T, l, r, h, w, d, M, Invcost, A
end

function ab_lpmodel(model, S, P, T, l, r, h, w, d, M)
    @variable(model, X[p in P, t in T], lower_bound = d[t,p])
    @variable(model, Y[S,T], lower_bound = 0, upper_bound = l, Int)
    
    @objective(model, Min, sum(w[s]*Y[s,t] for s in S for t in T))
    @constraint(model, [t in T], sum(r[p]*X[p,t] for p in P) <= h[t]*sum(Y[s,t] for s in S))
    @constraint(model, [t in 1:length(T)-1], -M <= sum(Y[s,t+1]-Y[s,t] for s in S) <= M)
    @constraint(model, -M <= sum(Y[s,1] for s in S) - 11 <= M)                                  # constraint for 4-4(b)
    return model
end

function c_lpmodel(model, S, P, T, l, r, h, w, d, M, Invcost)
    @variable(model, X[p in P, t in T], lower_bound = 0)
    @variable(model, Y[S,T], lower_bound = 0, upper_bound = l, Int)
    @variable(model, Inv[P, T], lower_bound = 0)
    
    @objective(model, Min, sum(w[s]*Y[s,t] for s in S for t in T) + sum(Invcost[p]*Inv[p,t] for p in P for t in T))
    @constraint(model, [t in T], sum(r[p]*X[p,t] for p in P) <= h[t]*sum(Y[s,t] for s in S))
    @constraint(model, [t in 1:length(T)-1], -M <= sum(Y[s,t+1]-Y[s,t] for s in S) <= M)
    @constraint(model, -M <= sum(Y[s,1] for s in S) - 11 <= M)                                  # constraint for 4-4(b)
    @constraint(model, [p in P], Inv[p,1] == X[p,1] - d[1,p])
    @constraint(model, [p in P, t in 2:length(T)], Inv[p,t] == Inv[p,t-1] + X[p,t] - d[t,p])
    return model
end

function e_lpmodel(model, S, P, T, l, r, h, w, d, M, Invcost, A)
    @variable(model, X[p in P, t in T], lower_bound = 0)
    @variable(model, Y[S,T], lower_bound = 0, upper_bound = l, Int)
    @variable(model, Inv[P, T, A], lower_bound = 0)
    
    @objective(model, Min, sum(w[s]*Y[s,t] for s in S for t in T) + sum(Invcost[p]*Inv[p,t,a] for p in P for t in T for a in A))
    @constraint(model, [t in T], sum(r[p]*X[p,t] for p in P) <= h[t]*sum(Y[s,t] for s in S))
    @constraint(model, [t in 1:length(T)-1], -M <= sum(Y[s,t+1]-Y[s,t] for s in S) <= M)
    @constraint(model, -M <= sum(Y[s,1] for s in S) - 11 <= M)                                  # constraint for 4-4(b)
    @constraint(model, [p in P, t in T], Inv[p,t,1] <= X[p,t])
    @constraint(model, [p in P, t in 2:length(T), a in 2:length(A)], Inv[p,t,a] <= Inv[p, t-1, a-1])
    @constraint(model, [p in P], Inv[p,1,1] == X[p,1] - d[1,p])
    @constraint(model, [p in P, a in 2:length(A)], Inv[p,1,a] == 0)
    @constraint(model, [p in P, t in 2:length(T)], sum(Inv[p,t,a] for a in A) == sum(Inv[p,t-1,a] for a in A) + X[p,t] - d[t,p])
    return model
end

function d2_lpmodel(model, S, P, T, l, r, h, w, d, M, Invcost, A)
    @variable(model, X[p in P, t in T], lower_bound = 0)
    @variable(model, Y[S,T], lower_bound = 0, upper_bound = l, Int)
    @variable(model, Inv[P, T], lower_bound = 0)
    
    @objective(model, Min, sum(w[s]*Y[s,t] for s in S for t in T) + sum(Invcost[p]*Inv[p,t] for p in P for t in T))
    @constraint(model, [t in T], sum(r[p]*X[p,t] for p in P) <= h[t]*sum(Y[s,t] for s in S))
    @constraint(model, [t in 1:length(T)-1], -M <= sum(Y[s,t+1]-Y[s,t] for s in S) <= M)
    @constraint(model, -M <= sum(Y[s,1] for s in S) - 11 <= M)                                  # constraint for 4-4(b)
    @constraint(model, [p in P], Inv[p,1] == X[p,1] - d[1,p])
    @constraint(model, [p in P, t in 2:length(T)], Inv[p,t] == Inv[p,t-1] + X[p,t] - d[t,p])
    @constraint(model, [p in P, t in length(A):length(T)], Inv[p,t] <= sum(X[p,t1] for t1 in (t-length(A)+1):t))
    return model
end


function  startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)
    
    S, P, T, l, r, h, w, d, M, Invcost, A = d_data()
    model  = d2_lpmodel(model, S, P, T, l, r, h, w, d, M, Invcost, A)
    optimize!(model)
end
startmodel() 


#  solution
# 4-4(a)  Initial obj = 7.90391860546559e+06
# Y = [
#     8.0                8.0                 6.247057894736841  8.0                6.247057894736841  7.1518342105263155  8.0                 8.0                 8.0                 8.0                 8.0                 8.0                 7.988983333333332
#     4.212084615384615  1.2120846153846152  0.0                1.247057894736841  0.0                0.0                 2.1518342105263155  1.0135000000000005  4.0135000000000005  7.0135000000000005  4.0135000000000005  2.9889833333333318  0.0
# ]
# modify Y to Int obj = 8.88830000000000e+06
# Y = [
#     8.0  8.0  7.0  8.0  7.0  8.0  8.0  8.0  8.0  8.0  8.0  8.0   8.0
#     5.0  2.0  0.0  2.0  0.0  0.0  3.0  2.0  5.0  8.0  5.0  3.0  -0.0
# ]
# 4-4(c) obj = 4.72222451954972e+06 (wage + invcost, wage = 4.4986e6, invcost = 223624.5195497172)
# Y = [
#     8.0  8.0   7.0   4.0   2.0   4.0   7.0   8.0   7.0   8.0   8.0   5.999999999999987   4.000000000000002
#     5.0  2.0  -0.0  -0.0  -0.0  -0.0  -0.0  -0.0  -0.0  -0.0  -0.0  -0.0                -0.0
# ]
# Inv = [
#     101.83953098827556  911.8899497487446  1261.6651591289792  347.86515912897926  232.86515912897926   99.06515912897932  19.46515912897928  652.0842546063664     530.4842546063663   60.48425460636635  191.88894472361787  92.48894472361786  0.0
#     0.0                 0.0                76.5061630218687  271.022001325381    179.7814446653412   254.4972829688536    0.0                 2.2534128561960642  118.0                0.0               397.43538767395745   0.0               5.684341886080802e-14
#     0.0                 0.0                 0.0                0.0                 0.0                 0.0                0.0                 0.0                 253.75612988734258   0.0                 0.0                0.0               0.0
# ]
# 4-4(d) age = 2 obj = 4.72222451954972e+06 (wage + invcost, wage = 4.4986e6, invcost = 223664.4137456269)
# Y = [
#     8.0  8.0   7.0   4.0   2.0   4.0   7.0   8.0   7.0   8.0   8.0   6.0   3.999999999999995
#     5.0  2.0  -0.0  -0.0  -0.0  -0.0  -0.0  -0.0  -0.0  -0.0  -0.0  -0.0  -0.0
# ]
# Inv = [
#     [:, :, 1] =
#     101.83953098827507       886.050418760469         205.3100502512558   133.79999999999995  79.6   19.465159128978613  0.0  591.6                 60.48425460636565  -3.552713678800501e-15  191.88894472361866  0.0  0.0
#       5.684341886080802e-14    5.684341886080802e-14  260.76129887342637  297.04625579854206   0.0  254.49728296885354   0.0   50.111729622266715    0.0                0.0                    397.4353876739562   0.0  0.0
#       0.0                      0.0                      0.0                 0.0                0.0    0.0                0.0    0.0                371.7561298873426    0.0                      0.0               0.0  0.0
   
#    [:, :, 2] =
#     0.0  25.83953098827508  823.4899497487442  115.0                133.8               79.6  19.465159128978613  0.0  470.0  60.484254606365695  0.0  92.48894472361866  0.0
#     0.0   0.0                 0.0               52.361298873426364  195.18330019880733   0.0   0.0                0.0    0.0   0.0                0.0   0.0               0.0
#     0.0   0.0                 0.0                0.0                  0.0                0.0   0.0                0.0    0.0   0.0                0.0   0.0               0.0               253.75612988734258   0.0                 0.0                0.0               0.0
# ]
# 4-4(e) age = 2 obj = 4.72226441374563e+06
# Y = [
#     8.0  8.0   7.0   4.0   2.0   4.0   7.0   8.0   7.0   8.0   8.0   6.0   3.999999999999999
#     5.0  2.0  -0.0  -0.0  -0.0  -0.0  -0.0  -0.0  -0.0  -0.0  -0.0  -0.0  -0.0
# ]
# Inv = [
#     101.83953098827442  911.8899497487434  1028.8              248.8              213.4                99.06515912897791  19.465159128977916  591.6               530.4842546063651   60.484254606365056  191.88894472361812  92.48894472361813  0.0
#     0.0                 0.0               260.7612988734258  349.4075546719679  195.18330019880688  254.4972829688536    0.0                  0.0                 0.0                0.0                397.43538767395626   0.0               0.0
#     0.0                 0.0                 0.0                0.0                0.0                 0.0                0.0                 50.11172962226618  371.75612988734247   0.0                  0.0                0.0               0.0
# ]