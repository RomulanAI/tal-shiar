---
name: julia-mcp
description: Operate and maintain the Julia MCP bridge server for OpenClaw, and execute Julia code from within OpenClaw sessions. Use when: starting/stopping the Julia MCP bridge server, checking bridge health and status, sending Julia code for remote execution, or working with any Julia numerical computing task (DifferentialEquations.jl, JuMP, CUDA.jl) via MCP bridge. Triggers on: Julia MCP, Julia bridge, run Julia code, Julia server, Julia execution.
---

# Julia MCP Bridge Skill

The Julia MCP bridge allows OpenClaw to execute Julia code on a remote Julia REPL server, enabling access to the full Julia package ecosystem for scientific computing.

---

## Managing the Bridge

### Start the Bridge Server
```bash
# In a terminal on the host machine
julia --project=/path/to/project -e 'using MCP; MCP.start_server()'
# Or using the MCP Julia package
julia -e 'using JuliaMCP; serve()'
```

### Check Bridge Health
```bash
# Ping the bridge
julia -e 'using MCP; ping()'
# Should return "pong" if running
```

### Stop / Restart
```bash
# SIGTERM to stop gracefully
kill $(pgrep -f "MCP.start_server")
# Or from Julia REPL
MCP.stop_server()
```

### Troubleshooting
| Problem | Fix |
|---------|-----|
| Connection refused | Verify server is running on correct port (default 3000) |
| Timeout on first call | Julia JIT compiles packages — subsequent calls are fast |
| Package not found | Ensure project has Manifest.toml with package |

---

## Executing Julia Code via MCP

### Basic Code Execution
```bash
# Send single expression
julia -e 'println(sin(π/4))'

# Multi-line script
julia - << 'EOF'
using LinearAlgebra
A = rand(3,3)
println(eigen(A).values)
EOF
```

### DifferentialEquations.jl Example
```julia
using DifferentialEquations

# Define ODE
f(u, p, t) = -p * u
u0 = 1.0
tspan = (0.0, 10.0)
p = 0.5

# Solve and extract
prob = ODEProblem(f, u0, tspan, p)
sol = solve(prob, Tsit5())

# Return key values
println("Final: ", sol[end])
println("Times: ", sol.t[1:5])
```

### JuMP Optimization Example
```julia
using JuMP, Ipopt

model = Model(Ipopt.Optimizer)
@variable(model, x >= 0)
@variable(model, y >= 0)
@objective(model, Min, (x-1)^2 + (y-2)^2)
@constraint(model, x + 2y <= 4)
optimize!(model)
println("Solution: x=$(value(x)), y=$(value(y))")
```

### CUDA.jl GPU Example
```julia
using CUDA

# GPU array creation
a = cu(rand(Float32, 1000, 1000))
b = cu(rand(Float32, 1000, 1000))

# GPU computation
c = a * b  # cuBLAS matmul
d = @. sin(a) * exp(-b)

# Back to CPU
cpu_d = Array(d)
println("GPU memory: ", CUDA.memory_status())
```

---

## Key Julia Packages (MCP-accessible)

| Package | Purpose | First Call Latency |
|---------|---------|-------------------|
| DifferentialEquations.jl | ODE/SDE/PDE solvers | ~30s (JIT) |
| JuMP.jl | Mathematical optimization | ~15s |
| CUDA.jl | GPU computing | ~10s |
| Zygote.jl | Automatic differentiation | ~20s |
| Plots.jl | Visualization | ~10s |
| DataFrames.jl | Tabular data | ~10s |

**Tip:** Keep the bridge warm — the first call to any package triggers JIT compilation. Subsequent calls are fast (~ms).
