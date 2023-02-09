using JuMP
using SCIP

function lpmodel(model)
    intermediates = 1:5            #SRG N RF CG B DI index by i
    attributes = 1:2               #vap, oct index by k

    a = [21170, 500, 16140, 4610, 370]
    r = [18.4 78.5
        6.54 65.0
        2.57 104.0
        6.90 93.7
        199.2 91.8
    ]
    u = [
        11.7 12.7
        89 91
    ]
    cost = [9.57, 8.87, 11.69, 10.88, 6.75]
    num = 42000

    @variable(model, x[i in intermediates], lower_bound = 0, upper_bound = a[i], Int)
    @objective(model, Min, sum(x[i]*cost[i] for i in intermediates))

    @constraint(model, [k in attributes], u[k,1]*num <= sum(r[i,k]*x[i] for i in intermediates) <= u[k,2]*num)  
    return model
end

function  startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)
    
    model  = lpmodel(model)
    optimize!(model)                                                                    
end
startmodel() 

#  solution
# 2-6  obj = 435599.28 (minimize total cost)
# x = [20302.0, 0.0, 16140.0, 4608.0, 370.0]