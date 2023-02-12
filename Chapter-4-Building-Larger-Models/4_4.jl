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

function lpmodel(model, S, P, T, l, r, h, w, d, M)
    @variable(model, X[p in P, t in T], lower_bound = d[p,t])
    @variable(model, Y[S,T], lower_bound = 0, upper_bound = l)

    @objective(model, Min, sum(w[s]*Y[s,t] for s in S for t in T))
    @constraint(model, [t in T], sum(r[p]*X[p,t] for p in P) <= h[t]*sum(Y[s,t] for s in S))
    @constraint(model, [t in 1:length(T)-1], -M <= sum(Y[s,t+1]-Y[s,t] for s in S) <= M)
    return model
end