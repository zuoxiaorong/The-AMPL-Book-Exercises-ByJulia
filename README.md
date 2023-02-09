### About This Repository
This is a repository of solutions to the end-of-chapter exercises in the AMPL book. The book is available for download at the link below, along with all the models, data and scripts that comprise the in-chapter examples (but not exercises).
http://ampl.com/resources/the-ampl-book/

### About modeling language
The mathematic programming language involved in this repository is [JuMP](https://jump.dev/JuMP.jl/stable/) embedded in [Julia](https://docs.julialang.org/en/v1/) that can describe optimization variables, objectives and constraints. The solver SCIP was called by the Julia language to directly solve all ofthe test instances.
