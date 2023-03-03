using JuMP
using SCIP

T = 4

# (a)
function a()
    model = Model(SCIP.Optimizer)
    @variable(model, x[1:T],lower_bound = 0)

    # @constraint(model, [i in 1:T], ifelse(i == 1, x[i], 2x[i]) <= 10)
    @constraint(model, [i in 1:T], ifelse(i == findfirst(x -> x == 1, 1:T), x[i], 2x[i]) <= 10)
    println(model)
end
test_v = [ifelse(t == 1, 1, 2) for t in 1:T]
test_v1 = [ifelse(t == findfirst(x -> x == 1, 1:T), 1, 2) for t in 1:T]
