---
name: julia-numerical
description: Expert guidance on Julia programming for numerical computing and scientific computing — covering DifferentialEquations.jl for ODE/SDE/PDE solving, JuliaDiff for automatic differentiation, JuMP for optimization, CUDA.jl for GPU computing, Plots.jl for visualization, and high-performance workflows. Triggers when user asks about: solving differential equations in Julia, ODE/SDE/PDE solvers, automatic differentiation, optimization with JuMP, GPU computing in Julia, Julia performance, scientific computing with Julia, or any numerical task in Julia.
---

# Julia Numerical Computing Skill

Julia combines the speed of C with the ergonomics of Python — ideal for scientific computing. This skill covers the full stack from performance fundamentals to HPC-scale numerical methods.

---

## 1. Julia Performance Fundamentals

### Key Rules
1. **Type stability:** `@code_warntype` to check; `@inline` hot functions
2. **Preallocate arrays:** Avoid `append!` in hot loops
3. **Use views not copies:** `@view`, `避 @inbounds`
4. **Loop fusion:** `c = a .+ b .* c` — no temporaries
5. **Avoid globals:** Pass as function arguments

```julia
# Type instability example
function bad(x)
    if x > 0
        return x * 2.0      # returns Float64
    else
        return 0             # returns Int
    end
end
# FIX: return 0.0 instead of 0

# Preallocate
function heat_loop!(u, dt, nsteps)
    for i in 1:nsteps
        @. u += dt * Laplacian(u)  # in-place
    end
end

# Benchmark tools
using BenchmarkTools
@btime heat_loop!(u, $dt, $nsteps)
@allocated heat_loop!(u, dt, nsteps)  # bytes allocated
```

---

## 2. DifferentialEquations.jl — The Core

### Installation
```julia
using Pkg
Pkg.add(["DifferentialEquations", "BenchmarkTools", "Plots"])
```

### ODE Example: Exponential Decay
```julia
using DifferentialEquations

f(u, p, t) = -p * u          # du/dt = -p*u
u0 = 1.0                       # initial condition
tspan = (0.0, 10.0)
p = 0.5                        # parameter

prob = ODEProblem(f, u0, tspan, p)
sol = solve(prob, Tsit5())    # 4th/5th order Runge-Kutta

# Interpolated solution
t = 0.0:0.1:10.0
u = sol.(t)                   # broadcast

# Full output
sol = solve(prob, Tsit5(), saveat=0.1)
```

### Stiff ODE: Robertson Reaction
```julia
# Chemical kinetics — stiff system
function robertson!(du, u, p, t)
    a, b, c = p
    k1, k2, k3 = (0.04, 1e4, 3e7)
    du[1] = -k1*u[1] + k3*u[2]*u[3]
    du[2] =  k1*u[1] - k2*u[2]^2 - k3*u[2]*u[3]
    du[3] =  k2*u[2]^2
end

u0 = [1.0, 0.0, 0.0]
tspan = (0.0, 1e5)
prob = ODEProblem(robertson!, u0, tspan)
sol = solve(prob, Rodas5())   # stiff solver
```

### SDE Example: Geometric Brownian Motion
```julia
# dS = μ*S*dt + σ*S*dW
function gbm!(du, u, p, t)
    du[1] = p.μ * u[1] * dt + p.σ * u[1] * dW[1]
end

# Or simpler using scalar form:
f(u, p, t) = p.μ * u
g(u, p, t) = p.σ * u

prob = SDEProblem(f, g, u0, tspan, p)
sol = solve(prob, EM(), dt=0.01)  # Euler-Maruyama
```

### DDE Example: Delay with Constant Lag
```julia
function delay!(du, u, h, p, t)
    τ = p.τ
    du[1] = -p.k * h(p, t-τ)[1]   # history at t-τ
end

# History function
h(p, t) = [1.0]
prob = DDEProblem(delay!, [0.0], h, (0.0, 100.0), p; constant_lags=[τ])
sol = solve(prob, MethodOfSteps(Rodas5()))
```

### PDEs via MethodOfLines
```julia
using DifferentialEquations, MethodOfLines, ModelingToolkit

@parameters x t
@variables u(..)
Dx = Differential(x)
Dt = Differential(t)

# 1D heat equation: u_t = D*u_xx
eq = Dt(u(x,t)) ~ D * Dx(Dx(u(x,t)))
ics = u(x,0) ~ sin(pi*x)
bcs = [u(0,t) ~ 0, u(1,t) ~ 0]

domain = [x ∈ Interval(0,1), t ∈ Interval(0,0.1)]
pdesys = PDESystem([eq], ics, bcs, domain, [x, t], [u=>D])

# Discretize
dx = 0.01
discretization = MOLFiniteDifference([x=>dx], t)
prob = discretize(pdesys, discretization)
sol = solve(prob, Tsit5())
```

### Algorithm Selection Guide
| Problem Type | Recommended Solvers |
|-------------|-------------------|
| Non-stiff ODE | `Tsit5`, `Vern7`, `RK46` |
| Stiff ODE | `Rodas5`, `RadauIIA5`, `QNDF` |
| DAEs (index 1) | `IDA`, `DImplicitEuler` |
| SDEs (additive noise) | `EM`, `SRA1` |
| SDEs (multiplicative) | `RKMil`, `SRIW1` |
| DDEs (constant lag) | `MethodOfSteps(Rodas5())` |
| DDEs (state-dependent) | `MethodOfSteps(VCAB3())` |
| SDAEs | `SDAE1` |

### Callbacks
```julia
using DifferentialEquations

# Stop at condition
function condition(u, t, integrator)
    t - 5.0   # stop when t == 5.0
end
cb = DiscreteCallback(condition, terminate!)

# Affect on crossing
affect!(integrator) = nothing

sol = solve(prob, Tsit5(), callback=cb)

# Continuous callback (root finding)
function condition_cont(u, t, integrator)
    u[1] - 0.5   # cross when u[1] == 0.5
end
cb_cont = ContinuousCallback(condition_cont, affect!)
```

---

## 3. Automatic Differentiation

### ForwardDiff.jl (Forward Mode)
```julia
using ForwardDiff

f(x) = sin(x) * exp(-x^2)
derivative(f, 0.0)              # f'(0)

# Gradient
f(x) = sum(x.^2)
ForwardDiff.gradient(f, [1.0, 2.0, 3.0])  # [2, 4, 6]

# Jacobian
F(x) = [x[1]^2, x[2]*x[3]]
ForwardDiff.jacobian(F, [1.0, 2.0, 3.0])
```

### Zygote.jl (Reverse Mode)
```julia
using Zygote

f(x) = sum(x^2)
gradient(f, [1.0, 2.0, 3.0])   # [2, 4, 6]

# Neural network layer
W = rand(10, 5)
b = rand(10)
predict(x) = W*x .+ b
gradient(() -> sum(predict(rand(5))), params(W, b))
```

### Enzyme.jl (LLVM-based, fastest for scientific)
```julia
using Enzyme

# Works directly with native Julia functions
f(x::Vector{Float64}) = sum(x.^2)
Enzyme.autodiff(f, Duplicated(x, ones(5)))
```

### When to Use What
| Method | Best For | Speed |
|--------|----------|-------|
| ForwardDiff | ≤10 inputs | Very fast |
| Zygote | ≥10 outputs | Good |
| Enzyme | Large loops, HPC | Fastest |
| ReverseDiff | Medium scale | Moderate |

---

## 4. JuMP — Mathematical Optimization

### Installation
```julia
using Pkg
Pkg.add(["JuMP", "Ipopt", "GLPK"])
```

### Basic NLP
```julia
using JuMP, Ipopt

model = Model(Ipopt.Optimizer)
set_silent(model)

@variable(model, x >= 0)
@variable(model, y >= 0)

@objective(model, Min, (x - 1)^2 + (y - 2.5)^2)
@constraint(model, x + 2y <= 4)       # linear
@constraint(model, x + y >= 1)
@NLconstraint(model, x^2 + y^2 <= 25) # nonlinear

optimize!(model)
@show value(x), value(y)     # ~0.0, 2.0
@show objective_value(model)
```

### Linear / Mixed Integer
```julia
using JuMP, GLPK

model = Model(GLPK.Optimizer)
@variable(model, x, Int)
@variable(model, y, Int)
@objective(model, Max, x + y)
@constraint(model, 2x + y <= 10)
@constraint(model, x + 3y <= 12)
optimize!(model)
```

### Semidefinite Programming
```julia
using JuMP, SCS

model = Model(SCS.Optimizer)
@variable(model, X[1:3, 1:3], Symmetric)
@constraint(model, X in PSDCone())      # X ⪰ 0
@objective(model, Min, sum(X))
optimize!(model)
```

---

## 5. CUDA.jl — GPU Computing

### Setup
```julia
using Pkg
Pkg.add("CUDA")
using CUDA

# Check GPU
CUDA.device()    # 0 = first GPU
CUDA.devices()   # list all
```

### Basic Operations
```julia
a = cu(rand(1000, 1000))   # GPU array
b = cu(rand(1000, 1000))
c = a * b                   # GPU matmul (cuBLAS)

# Back to CPU
cpu_c = Array(c)

# In-place
mul!(c, a, b)              # c .= a * b

# Element-wise
d = @. c + sin(a) * exp(-b)
```

### Custom Kernels
```julia
function add_vectors!(c, a, b)
    i = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    n = length(c)
    if i ≤ n
        c[i] = a[i] + b[i]
    end
    return nothing
end

n = 1024
a = cu(rand(n)); b = cu(rand(n)); c = cu(zeros(n))
@cuda threads=256 blocks=cld(n,256) add_vectors!(c, a, b)
synchronize()
```

### cuBLAS / cuFFT
```julia
using LinearAlgebra

# cuBLAS (automatic)
c = a * b          # uses cuBLAS internally
factorize(c)       # LU/Cholesky on GPU

# cuFFT
using CUDA
p = plan_fft(a)    # create FFT plan
fa = p * a         # apply FFT
```

---

## 6. Data Handling & Visualization

### DataFrames.jl
```julia
using DataFrames, CSV

df = DataFrame(
    time  = 1:100,
    value = randn(100),
    group = rand(["A", "B", "C"], 100)
)

# Filter
filter!(row -> abs(row.value) < 2, df)

# Group by
gdf = groupby(df, :group)
combine(gdf, :value .=> [mean, std])

# Join
df2 = DataFrame(group=["A","B"], label=["alpha","beta"])
innerjoin(df, df2, on=:group)
```

### Plots.jl
```julia
using Plots

# Default GR backend (fast)
plot(sol.t, sol[1,:], label="u(t)", xlabel="Time")
scatter!(sol.t, sol[1,:], label="data")

# 2D heatmap
heatmap(reshape(sol[1,:], 50, 50), colorbar=true)

# Phase portrait
plot(sol[1,:], sol[2,:], sol[3,:], label="trajectory")
```

### Makie.jl (Interactive)
```julia
using GLMakie

x = range(-3, 3, length=100)
surface(x, x, (x,y) -> sin(x)*cos(y))
```

---

## 7. Parallel Computing

### Threading
```julia
using Base.Threads

# Check threads
nthreads()   # BLAS.set_num_threads(1) before @threads

# Parallel loop
@threads for i in 1:1000
    result[i] = heavy_computation(i)
end
```

### Distributed
```julia
using Distributed
addprocs(4)

@everywhere using MyModule

@sync @distributed for i in 1:1000
    result[i] = compute_something(i)
end
```

### MPI.jl
```julia
using MPI
MPI.Init()

comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
size = MPI.Comm_size(comm)

data = zeros(Float64, 100)
MPI.Reduce(data, MPI.SUM, 0, comm)  # sum to root

MPI.Finalize()
```

---

## 8. Parameter Estimation & Inverse Problems

```julia
using Optimization, OptimizationOptimisers

# Given: noisy data from known parameters
# Goal: recover parameters

function loss(p)
    prob = ODEProblem(f, u0, tspan, exp.(p))
    sol = solve(prob, Tsit5(), saveat=0.1)
    sum(abs2, sol[1,:] .- observed_data)
end

p0 = [0.0, 0.0]   # log-scale initial guess
prob = OptimizationProblem(loss, p0)
sol = solve(prob, ADAM(0.1), maxiters=1000)
```

---

## 9. Package Quick Reference

| Domain | Packages |
|--------|----------|
| ODEs / SDEs / PDEs | DifferentialEquations.jl |
| Auto-diff (forward) | ForwardDiff.jl |
| Auto-diff (reverse) | Zygote.jl, Enzyme.jl |
| Optimization | JuMP.jl, Optimization.jl |
| GPUs | CUDA.jl, AMDGPU.jl, oneAPI.jl |
| Linear Algebra | LinearAlgebra (stdlib), MKLSparse |
| Statistics | StatsBase.jl, Distributions.jl |
| Machine Learning | Flux.jl, Lux.jl, MLJ.jl |
| FFT | FFTW.jl |
| Sparse Matrices | SparseArrays (stdlib) |
| Interpolation | Dierckx.jl, Interpolations.jl |
| ODE Optimization | DiffEqFlux.jl |
| Uncertainty Quant. | Measurements.jl, MonteCarloMeasurements.jl |
