using JuMP
using SCIP
using DataFrames

function data()
    T = 1:12
    Bank = 1:2
    deposit = 1:3
    company_params = [
       #T receipt expense
        1 3200 200
        2 3600 200
        3 3100 400
        4 1000 800
        5 1000 2100
        6 1000 4500
        7 1200 3300
        8 1200 1800
        9 1200 600
        10 1500 200
        11 1800 200
        12 1900 200
    ]
    receipt = company_params[:,2]
    expense = company_params[:,3]
    bank_params = [
       #T 1 2 3     #BANK:CIT
       [1 0.00433 0.01067 0.01988 
        2 0.00437 0.01075 0.02000 
        3 0.00442 0.01083 0.02013 
        4 0.00446 0.01092 0.02038 
        5 0.00450 0.01100 0.02050
        6 0.00458 0.01125 0.02088 
        7 0.00467 0.01142 0.02113
        8 0.00487 0.01183 0.02187
        9 0.00500 0.01217 0.02237
        10 0.00500 0.01217 0.02250
        11 0.00492 0.01217 0.02250 
        12 0.00483 0.01217 0.02275],
       #T 1 2 3     #BANK:NBD
       [1 0.00425 0.01067 0.02013
        2 0.00429 0.01075 0.02025
        3 0.00433 0.01083 0.02063
        4 0.00437 0.01092 0.02088
        5 0.00442 0.01100 0.02100
        6 0.00450 0.01125 0.02138
        7 0.00458 0.01142 0.02162
        8 0.00479 0.01183 0.02212
        9 0.00492 0.01217 0.02262
        10 0.00492 0.01217 0.02275
        11 0.00483 0.01233 0.02275
        12 0.00475 0.01250 0.02312]
    ]
    rate = zeros(length(Bank),length(T),length(deposit))
    for i in 1:2
        rate[i,:,:] = bank_params[i][:,2:end]
    end
    period = [1, 2, 3]  
    return T, Bank, deposit, receipt, expense, rate, period
end

function investment_problem(model, T, Bank, deposit, receipt, expense, rate, period)
    @variable(model, Buy[T, Bank, deposit] >= 0)                        #deposit d in bank b bought for day t
    @variable(model, Hold[T] >= 0)                                      #remaining holding cash after day t

    @objective(model, Max, sum(Buy[t,b,d]*rate[b,t,d] for b in Bank for t in T for d in deposit))

    @constraint(model, receipt[1] - sum(Buy[1,b,d] for b in Bank for d in deposit) - expense[1] == Hold[1])
    @constraint(model, [t in T; t >= 2 && t <= period[1]], Hold[t-1] + receipt[t] - sum(Buy[t,b,d] for b in Bank for d in deposit) - expense[t] == Hold[t])
    @constraint(model, [t in T; t >= period[1] + 1 && t <= period[2]], Hold[t-1] + receipt[t] - sum(Buy[t,b,d] for b in Bank for d in deposit) - expense[t] + sum(Buy[t-period[1],b,1]*(1 + rate[b,t-period[1],1]) for b in Bank) == Hold[t])
    @constraint(model, [t in T; t >= period[2] + 1 && t <= period[3]], Hold[t-1] + receipt[t] - sum(Buy[t,b,d] for b in Bank for d in deposit) - expense[t] + sum(Buy[t-period[1],b,1]*(1 + rate[b,t-period[1],1]) for b in Bank) + sum(Buy[t-period[2],b,2]*(1 + rate[b,t-period[2],2]) for b in Bank) == Hold[t])
    @constraint(model, [t in T; t >= period[3] + 1], Hold[t-1] + receipt[t] - sum(Buy[t,b,d] for b in Bank for d in deposit) - expense[t] + sum(Buy[t-period[d],b,d]*(1 + rate[b,t-period[d],d]) for b in Bank for d in deposit) == Hold[t])
    return model
end

function  startmodel()
    optimizer = SCIP.Optimizer(display_verblevel=4 , limits_gap=0.00, parallel_maxnthreads=12)
    model = JuMP.direct_model(optimizer)
    set_time_limit_sec(model,100)
    
    T, Bank, deposit, receipt, expense, rate, period = data()
    model = investment_problem(model, T, Bank, deposit, receipt, expense, rate, period)
    optimize!(model)
end
startmodel()

# solution obj = +5.75723368390739e+02
# Buy 3-dimensional DenseAxisArray{Float64,3,...} with index sets:
#     Dimension 1, 1:12
#     Dimension 2, 1:2
#     Dimension 3, 1:3
# And data, a 12×2×3 Array{Float64, 3}:
# [:, :, 1] =
#     0.0                     0.0
#  1745.8376302979264         0.0
#     0.0                     0.0
#     0.0                     0.0
#     0.0                     0.0
#     0.0                     0.0
#     0.0                     0.0
#     0.0                     0.0
#     0.0                     0.0
#     0.0                     0.0
#  1600.0                     0.0
#     2.2737367544323206e-13  0.0

# [:, :, 2] =
#  1179.5959136332206  0.0
#     0.0              0.0
#     0.0              0.0
#     0.0              0.0
#     0.0              0.0
#     0.0              0.0
#     0.0              0.0
#     0.0              0.0
#     0.0              0.0
#  1300.0              0.0
#     0.0              0.0
#     0.0              0.0

# [:, :, 3] =
#  0.0  1820.4040863667794
#  0.0  1654.1623697020736
#  0.0  5645.649142774015
#  0.0  2057.0488206253426
#  0.0   587.6591576885407
#  0.0  2262.118884589442
#  0.0     0.0
#  0.0     0.0
#  0.0  2910.482986341964
#  0.0     0.0
#  0.0     0.0
#  0.0  7600.0111114930205