---
name: physics-ai
description: Expert guidance on AI/machine learning methods for physics — Physics-Informed Neural Networks (PINNs), Fourier Neural Operators (FNO), Neural ODEs, DeepONets, operator learning, scientific machine learning (SciML), and AI-accelerated physics simulations. Triggers when user asks about: physics-informed machine learning, PINNs, neural operators for PDEs, AI solving differential equations, SciML with Julia/Python, neural ODEs, DeepONets, Fourier Neural Operators, operator learning for physics, AI-accelerated simulations, data-driven physics models, or combining AI with physical modeling.
---

# Physics-AI Skill

Your expert companion for scientific machine learning (SciML) and AI-accelerated physics simulations. Whether you're embedding PDEs into neural network loss functions, learning operators between function spaces, or replacing traditional solvers with neural approaches — this skill covers it all.

---

## 1. Physics-Informed Neural Networks (PINNs)

### Core Idea
PINNs embed governing PDEs directly into the neural network's loss function. Rather than approximating a solution directly, the network learns to satisfy the differential equation at collocation points throughout the domain.

**Loss components:**
```
L_total = λ_data · L_data + λ_pde · L_pde + λ_ic · L_IC + λ_bc · L_BC

L_pde   = (1/N) Σ ||NN(x,t;θ)_t + NN·∇NN - ν∇²NN||²   # PDE residual
L_IC    = ||NN(x,0;θ) - u₀(x)||²                       # initial conditions
L_bc    = ||NN(∂Ω;θ) - g(x,t)||²                      # boundary conditions
```

### Network Architectures

**Standard fully-connected:**
```
Input(2) → [Dense(64) → tanh] × 8 → Dense(1)
```

**Fourier feature embeddings** (multi-scale/high-frequency):
```python
class FourierFeatures(nn.Module):
    def __init__(self, B):
        super().__init__()
        self.B = nn.Parameter(B, requires_grad=False)  # random freq matrix

    def forward(self, x):
        x_proj = 2π · x @ B.T
        return concat([sin(x_proj), cos(x_proj)], dim=-1)

# Use in place of raw (x,t) input
model = nn.Sequential(FourierFeatures(B=randn(256,2)), MLP)
```

**Residual blocks** (easier optimization for deep networks):
```python
class ResidualBlock(nn.Module):
    def __init__(self, dim, act=nn.tanh):
        super().__init__()
        self.fc = nn.Linear(dim, dim)
        self.act = act

    def forward(self, x):
        return x + self.act(self.fc(x))
```

### Hard vs Soft Domain Constraints

| Approach | Method | Pros | Cons |
|----------|--------|------|------|
| **Soft** | Add IC/BC to loss | Flexible, easy | Needs careful weighting |
| **Hard** | Design network output to satisfy IC/BC analytically | Guarantees constraints, better for simple BCs | Limited expressiveness, complex BCs hard |

**Hard constraint example (IC):**
```python
# u(x,0) = -sin(πx)  →  network outputs only the deviation from IC
def u_net(x, t):
    ic = -torch.sin(np.pi * x)
    return ic + network(x, t)  # deviation decays to 0 at t=0
```

### Activation Functions

- **`tanh`**: Default choice, smooth gradients
- **`sin`/`cos`**: Spectral bias matches Fourier series of PDE solutions — often superior for oscillatory physics
- **`swish`/`silu`**: Better gradient flow in deep networks, but less physics-informed
- **`gelu`**: Good general-purpose; less commonly used in PINN literature

### Adaptive Sampling Strategies

**Residual-based adaptive weighting (RAR):**
```python
# Compute pointwise PDE residuals
residuals = compute_pde_residual(model, collocation_points)
# Weight sampling probability by residual magnitude
weights = residuals / residuals.sum()
# Resample batch proportionally
batch = sample_from_distribution(collocation_points, weights, n=1024)
```

**Hard example mining:** Focus training on regions where PDE is hardest to satisfy (shock fronts, boundary layers).

### Multi-Scale Phenomena

Multi-scale PDEs (e.g., Navier-Stokes at high Re) are challenging because different physics operate at different scales.

**Strategies:**
- **Curriculum learning:** Start withviscous Burgers (high ν), gradually reduce ν
- **Fourier features at multiple scales:** Use multiple B matrices with different frequency ranges
- **Adaptive weight balancing:** Dynamically adjust λ_pde vs λ_bc vs λ_ic using uncertainty quantification
- **Domain decomposition:** Partition into subdomains, train separate networks

**Learning rate balancing per scale:**
```python
# Different LR for layers processing different scales
optimizer = Adam([
    {'params': early_layers, 'lr': 1e-4},   # coarse scale
    {'params': late_layers, 'lr': 1e-3},    # fine scale
])
```

### Example PDEs Handled by PINNs

| PDE | Domain | Challenge |
|-----|--------|-----------|
| Burgers | 1D | Shock formation, non-linearity |
| Navier-Stokes | 2D/3D | Turbulence, incompressibility |
| Schrödinger | 1D/2D | Complex-valued solution, wave packet dispersion |
| Reaction-diffusion | 1D/2D | Pattern formation (Turing patterns) |
| Diffusion equation | Any | Smooth solutions, straightforward |
| Klein-Gordon | 1D/2D | Non-linear dispersion |
| Allen-Cahn | 1D/2D | Phase separation, interface motion |

---

## 2. Fourier Neural Operators (FNO)

### Architecture

FNO learns an operator between infinite-dimensional function spaces using spectral methods. The key insight: replace pointwise linear layers with linear operations in Fourier space.

```
Input a(x) → Lifting (MLP) → FNO Blocks (×4) → Projection (MLP) → Output u(x)
                          ↓
            Forward FFT → Linear (C×C in freq) → Inverse FFT
```

**Single FNO block:**
```python
class FNOBlock(nn.Module):
    def __init__(self, modes, width):
        self.modes = modes      # number of Fourier modes to keep
        self.width = width

    def forward(self, x):
        # x: (B, H, W, C) — 2D field
        x_ft = torch.fft.rfft2(x)                    # to Fourier domain
        x_ft[:, :self.modes, :self.modes] = self.linear(x_ft[:, :self.modes, :self.modes])
        # Apply linear transform in frequency domain (global convolution)
        x = torch.fft.irfft2(x_ft)                   # back to spatial
        return x
```

**Linear transform in Fourier domain:**
```python
# 2D linear: complex-valued weight matrix per mode
self.weight = nn.Parameter(torch.complex64(randn(modes, modes, width, width)))
# Apply as: out_ft[m,n] = Σ_kl weight[m,n,k,l] · in_ft[k,l]
```

### Key Properties

- **Resolution invariant:** Train at 64×64, infer at 256×256 without retraining
- **Global receptive field:** Every Fourier mode connects to every other — captures long-range correlations
- **Physics-interpreted:** Linear transform in Fourier domain = convolution in physical domain

### Configuration Guide

| Parameter | Typical Value | Effect |
|-----------|--------------|--------|
| Number of FNO blocks | 4–8 | More blocks = deeper spectral features |
| Fourier modes | 12–32 | Higher = more high-frequency detail, more params |
| Lifting layer | (input_dim → width) MLP | Embeds scalar/polycrystalline input to latent width |
| Projection layer | (width → output_dim) MLP | Decodes latent to output field |
| Channels (width) | 32–128 | Width vs depth tradeoff |

```python
model = FNO(
    modes=16,
    width=64,
    n_blocks=4,
    lifting_channels=128,
    projection_channels=128
)
```

### Libraries

**Python:**
```bash
pip install neural-operator    # FNO, DeepONet, etc. from LANL/NVIDIA
```

**Julia:**
```julia
using NeuralOperators
model = FourierNeuralOperator(4, 16, 64)
```

---

## 3. DeepONets

### Architecture

DeepONets learn an operator G: U → V, mapping an input function u(s) to an output function (Gu)(t). They consist of two networks:

- **Trunk network** t(t): Encodes output coordinate t ∈ R^d
- **Branch network** b(u): Encodes the entire input function u(s)

```python
class DeepONet(nn.Module):
    def __init__(self, trunk_dim, branch_dim, width, output_dim):
        self.trunk_net = MLP(trunk_dim, width**2, output_dim)   # (1, width²)
        self.branch_net = MLP(branch_dim, width**2, output_dim) # (sampl_pts, width²)

    def forward(self, u, t):
        # u: (batch, sensor_points, u_dim) — input function sampled at sensor locations
        # t: (batch, query_points, t_dim)  — query coordinates
        b = self.branch_net(u)                                    # (B, width²)
        b = b.unsqueeze(1).expand(-1, t.shape[1], -1)            # (B, Q, width²)
        t_enc = self.trunk_net(t)                                 # (B, Q, width²)
        return sum(b * t_enc, dim=-1)                              # (B, Q, output_dim)
        # Inner product of trunk and branch encodings
```

### Extensions

- **PodDeepONet:** Use POD (Proper Orthogonal Decomposition) basis for dimension reduction on branch
- **Geometry-Informed DeepONets:** Incorporate spatial geometry into trunk network
- **Transformer-DeepONets:** Attention mechanisms for long-range sensor dependencies

### Applications

- Parametric PDEs: map forcing function f(x) to solution u(x; f)
- Stress-strain mapping: given material property field, predict displacement
- Control: map system state to control action

---

## 4. Neural ODEs & Neural SDEs

### Neural ODEs

Replace discrete residual layers with a continuous differential equation. The forward pass is integration of an ODE.

```python
# Standard residual: y_{n+1} = y_n + f(y_n, θ)
# Neural ODE:       dy/dt = f(y, t, θ)

class NeuralODE(nn.Module):
    def __init__(self, func):
        self.func = func  # MLP representing RHS of ODE

    def forward(self, y0, t_span):
        return odeint(self.func, y0, t_span)  # adaptive ODE solver
```

**Adjoint method (memory-efficient backprop):**
```python
# Standard backprop stores all intermediate states (memory O(depth))
# Adjoint method: augment ODE with adjoint states, only store y0
# Memory O(1) in depth, O(time steps) in time

from torchdiffeq import odeint_adjoint
loss = criterion(odeint_adjoint(func, y0, t_span), target)
```

### Libraries

**Python:**
```bash
pip install torchdiffeq
```

```python
from torchdiffeq import odeint, odeint_adjoint

class ODEFunc(nn.Module):
    def __init__(self):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(2, 64), nn.Tanh(),
            nn.Linear(64, 2)
        )

    def forward(self, t, y):
        return self.net(y)

func = ODEFunc()
y0 = tensor([1.0, 0.0])
t_span = linspace(0, 10, 100)
trajectory = odeint(func, y0, t_span)  # (100, 2)
```

**Julia:**
```julia
using DifferentialEquations, Lux

function!(du, u, p, t)
    du[1] = u[2]
    du[2] = -p[1]*u[1]
end

u0 = [1.0, 0.0]
p = [1.0]
prob = ODEProblem(function!, u0, (0.0, 10.0), p)
sol = solve(prob, Tsit5())
```

### Neural SDEs

For stochastic dynamics (Brownian motion, noise-driven systems):

```python
class NeuralSDE(nn.Module):
    def __init__(self, drift_net, diffusion_net):
        self.drift = drift_net      # f(y,t) — deterministic part
        self.diffusion = diffusion_net  # g(y,t) — noise coeff

    def forward(self, y0, t_span):
        return sdeint(self.drift, self.diffusion, y0, t_span)

# Gradient through SDE via stochastic adjoint
```

### Applications

- Dynamical systems: Lorenz attractor, double pendulum
- Chemical kinetics: reaction networks with noise
- Turbulence modeling: stochastic closure models
- Finance: option pricing, stochastic control
- Population dynamics: Lotka-Volterra with environmental noise

---

## 5. Operator Learning Frameworks Comparison

| Method | Library | Language | Best For | Trained On | Inference Speed |
|--------|---------|----------|----------|------------|-----------------|
| **FNO** | NeuralOperators | PyTorch | Global operators, PDEs on grids | Multiple pairs (a, u(a)) | ~1ms/point |
| **DeepONet** | TensorFlow/PyTorch | Python | Parametric PDEs, sensor data | Multiple pairs (u, G(u)) | Fast evaluation |
| **U-NO** | custom | PyTorch | Local + global features | Multiple pairs | Medium |
| **MIONet** | custom | PyTorch | Multi-input operators | Multiple pairs | Medium |
| **Kernel methods** | FINITE | Python | Elliptic PDEs, rigorous error bounds | Single high-fidelity solve | Slow |
| **Random Feature** | Specht | Python | Low-dim operators | Single solve | Medium |

**Choosing:**
- Grid-based PDE → FNO
- Sensor/point-cloud input → DeepONet
- Multiple inputs (e.g., forcing + boundary) → MIONet
- Need interpretability/rigorous bounds → Kernel methods
- Hybrid local/global → U-NO

---

## 6. Libraries & Tools

### Python

**DeepXDE** (most complete PINN framework):
```bash
pip install deepxde
```

```python
import deepxde as dde

# 1D Burgers equation
def pde(x, y):
    dy_x = dde.grad.jacobian(y, x, i=0, j=0)
    dy_t = dde.grad.jacobian(y, x, i=0, j=1)
    d2y_xx = dde.grad.hessian(y, x, i=0, j=0)
    return dy_t + y * dy_x - 0.01/np.pi * d2y_xx

geom = dde.geometry.Interval(-1, 1)
timedomain = dde.geometry.TimeDomain(0, 1)
geomtime = dde.geometry.GeometryXTime(geom, timedomain)

bc = dde.icbc.DirichletBC(geomtime, lambda x: 0, lambda _, on_boundary, _ : on_boundary)
ic = dde.icbc.IC(geomtime, lambda x: -np.sin(np.pi * x[:, 0:1]), lambda _, on_initial, _ : on_initial)

data = dde.data.TimePDE(geomtime, pde, [bc, ic], num_domain=1000, num_boundary=100)
net = dde.maps.FNN([2, 64, 64, 64, 1], "tanh", "Glorot uniform")
model = dde.Model(data, net)
model.compile("adam", lr=1e-3)
model.train(epochs=50000)
```

**Neural Operators (FNO, DeepONet):**
```bash
pip install neuraloperator
```

```python
from neuraloperator import FourierNeuralOperator

model = FourierNeuralOperator(
    modes=16,
    width=64,
    n_blocks=4
)
# Supervised training on (a, u) pairs
```

**PyTorch (manual PINN):**
```python
# See Section 9 for full 1D Burgers example
```

### Julia (SciML Ecosystem)

**DifferentialEquations.jl** — the core solver:
```julia
using DifferentialEquations

# ODE
f(u, p, t) = -p * u
prob = ODEProblem(f, 1.0, (0.0, 10.0), [0.5])
sol = solve(prob, Tsit5())

# PDE (via Method of Lines + DifferentialEquations)
# Use SummationPIDESolver oreparately handle spatial operators
```

**NeuralPDE.jl** — PINNs in Julia:
```julia
using NeuralPDE, Lux, OptimizationOptimisers

# Define PDE system
@named pde_system = PDESystem(equation, boundary_conditions, domain, u, t, num_domain)

# Discretize with PhysicsInformedNN
discretization = PhysicsInformedNN("xavier", "tanh")
prob = discretize(pde_system, discretization)
solve(prob, OptimizationOptimisers.Adam(); maxiters=50000)
```

**Lux.jl** — modern neural network library:
```julia
using Lux

model = Chain(
    Dense(2 => 64, tanh),
    Dense(64 => 64, tanh),
    Dense(64 => 64, tanh),
    Dense(64 => 1)
)
```

**Key Julia packages:**
| Package | Purpose |
|---------|---------|
| `DifferentialEquations.jl` | ODE/SDE/PDE solving |
| `NeuralPDE.jl` | PINN discretization |
| `Lux.jl` | Neural networks (modern) |
| `Flux.jl` | Neural networks (legacy) |
| `Zygote.jl` | Automatic differentiation |
| `CUDA.jl` | GPU acceleration |
| `Optim.jl` | Optimization (BFGS, etc.) |
| `ModelingToolkit.jl` | PDE symbolic manipulation |

---

## 7. Training Strategies

### Domain Decomposition

Partition the spatio-temporal domain into subdomains, train separate networks per subdomain, then couple at interfaces.

```python
# 1D spatial decomposition
domains = [(-1, -0.2), (-0.2, 0.2), (0.2, 1)]
models = [train_PINN_on_subdomain(d) for d in domains]

# Coupling: match solutions + fluxes at interfaces
L_coupling = sum(
    (model_i(domain[-1]) - model_j(domain[0]))**2
    for i, j in zip(models[:-1], models[1:])
)
```

### Curriculum Learning

Gradually increase problem difficulty:

```python
# Phase 1: High viscosity (easy, smooth)
train_Burgers(nu=0.1, epochs=20000)

# Phase 2: Medium viscosity
train_Burgers(nu=0.01, epochs=20000, load_phase1_weights=True)

# Phase 3: Target viscosity
train_Burgers(nu=0.001, epochs=20000, load_phase2_weights=True)
```

### Residual Adaptive Refinement (RAR)

```python
def rar_training_loop(model, domain, n_initial=1000, n_rar=100, n_epochs=500):
    colloc = sample_uniform(domain, n_initial)
    for epoch in range(n_epochs):
        # Compute residuals
        residuals = torch.abs(pde_residual(model, colloc))
        # Add top n_rar worst points
        _, indices = torch.topk(residuals.squeeze(), n_rar)
        new_points = colloc[indices]
        colloc = torch.cat([colloc, new_points])
        # Train
        loss = compute_PINN_loss(model, colloc)
        optimizer.step()
```

### Transfer Learning

Pre-train on:
1. Simplified physics (e.g., Stokes flow → Navier-Stokes)
2. Lower resolution (64² → 256²)
3. Synthetic data → experimental data
4. Related PDE (heat → diffusion → reaction-diffusion)

### Ensemble Methods

Train multiple PINNs with different:
- Random seeds
- Network architectures
- Loss weight initializations

```python
ensemble = [train_PINN(seed=s, width=w) for s, w in zip(range(5), [32, 64, 128, 64, 32])]
prediction = mean([m(x) for m in ensemble], dim=0)
uncertainty = std([m(x) for m in ensemble], dim=0)
```

---

## 8. Validation & Testing

### Metrics

| Metric | Formula | Use Case |
|--------|---------|----------|
| Relative L2 | ‖u_pred - u_exact‖₂ / ‖u_exact‖₂ | Standard accuracy |
| Max Abs Error | max\|u_pred - u_exact\| | Worst-case point |
| Energy norm | ⟨u - u_h, L(u - u_h)⟩ | Elliptic PDEs |
| Conservation error | d/dt ∫ᵢ quantity | Hamiltonian systems |

### Convergence Studies

```python
# Mesh refinement study
resolutions = [32, 64, 128, 256]
errors = []
for N in resolutions:
    model = train_PINN(N_points=N)
    error = relative_L2(model, test_set)
    errors.append(error)
# Expect: error ∝ N^(-k) for spectral accuracy
```

### Generalization Tests

```python
# Parametric generalization
train_params = nu ∈ [0.01, 0.05, 0.1]
test_params = nu ∈ [0.02, 0.03, 0.07]  # unseen

for nu_test in test_params:
    u_pred = model(x, t, nu=nu_test)
    error = relative_L2(u_pred, exact_solution(x, t, nu_test))
```

### Conservation Law Verification

```python
# For Hamiltonian system: H = T + V should be constant
def verify_conservation(model, t_span):
    H_t = [compute_hamiltonian(model, t) for t in t_span]
    drift = max(H_t) - min(H_t)
    return drift  # should be near zero
```

---

## 9. Example: PINN for 1D Burgers Equation

### PDE
```
u_t + u·u_x - (0.01/π)·u_xx = 0
BCs: u(-1,t) = u(1,t) = 0
ICs: u(x,0) = -sin(πx)
Domain: x ∈ [-1, 1], t ∈ [0, 1]
```

### Complete PyTorch Implementation

```python
import torch
import torch.nn as nn
import numpy as np

# PDE parameters
nu = 0.01 / np.pi

# Network: 8 layers, 20 neurons each, sin activation
class BurgersPINN(nn.Module):
    def __init__(self):
        super().__init__()
        layers = [nn.Linear(2, 20), nn.sin]  # input: (x,t)
        for _ in range(7):                   # 8 total layers
            layers += [nn.Linear(20, 20), nn.sin]
        layers.append(nn.Linear(20, 1))      # output: u(x,t)
        self.net = nn.Sequential(*layers)

    def forward(self, x, t):
        return self.net(torch.cat([x, t], dim=-1))

    # Hard BC: u(±1,t) = 0 via network modification
    def apply_bc(self, x, t, u):
        # (1 - x²) factor ensures BC=0 at x=±1 for any t
        return (1 - x**2) * u

    def pde_residual(self, x, t):
        x.requires_grad_(True)
        t.requires_grad_(True)
        u = self.apply_bc(x, t, self.net(torch.cat([x, t], dim=-1)))

        # Compute derivatives via automatic differentiation
        u_x = torch.autograd.grad(u, x, grad_outputs=torch.ones_like(u), create_graph=True)[0]
        u_t = torch.autograd.grad(u, t, grad_outputs=torch.ones_like(u), create_graph=True)[0]
        u_xx = torch.autograd.grad(u_x, x, grad_outputs=torch.ones_like(u_x), create_graph=True)[0]

        return u_t + u * u_x - nu * u_xx

model = BurgersPINN()
optimizer = torch.optim.Adam(model.parameters(), lr=1e-3)

# Training loop
n_epochs = 50000
n_coll = 10000
n_bc = 100
n_ic = 100

for epoch in range(n_epochs):
    optimizer.zero_grad()

    # Collocation points (PDE residual)
    x_coll = torch.rand(n_coll, 1) * 2 - 1   # x ∈ [-1, 1]
    t_coll = torch.rand(n_coll, 1)           # t ∈ [0, 1]
    loss_pde = torch.mean(model.pde_residual(x_coll, t_coll)**2)

    # Initial condition: u(x,0) = -sin(πx)
    x_ic = torch.rand(n_ic, 1) * 2 - 1
    t_ic = torch.zeros(n_ic, 1)
    u_ic_pred = model.apply_bc(x_ic, t_ic, model.net(torch.cat([x_ic, t_ic], dim=-1)))
    loss_ic = torch.mean((u_ic_pred + torch.sin(np.pi * x_ic))**2)

    # Boundary conditions
    t_bc = torch.rand(n_bc, 1)
    x_bc_left = -torch.ones(n_bc, 1)
    x_bc_right = torch.ones(n_bc, 1)
    u_bc_left = model.apply_bc(x_bc_left, t_bc, model.net(torch.cat([x_bc_left, t_bc], dim=-1)))
    u_bc_right = model.apply_bc(x_bc_right, t_bc, model.net(torch.cat([x_bc_right, t_bc], dim=-1)))
    loss_bc = torch.mean(u_bc_left**2 + u_bc_right**2)

    loss = loss_pde + loss_ic + loss_bc
    loss.backward()
    optimizer.step()

    if epoch % 5000 == 0:
        print(f"Epoch {epoch}: Loss={loss.item():.4e} (PDE={loss_pde.item():.2e}, IC={loss_ic.item():.2e}, BC={loss_bc.item():.2e})")
```

---

## 10. Example: FNO for 2D Darcy Flow

### Problem
Predict pressure field u(x) given permeability field a(x) in steady Darcy flow:
```
-∇·(a(x)∇u(x)) = f(x)    in Ω=[0,1]²
                   u = 0  on ∂Ω
```

### PyTorch Implementation

```python
import torch
import torch.nn as nn
from neural_operator.models import FNO

# Configuration
config = {
    'modes': 12,           # Fourier modes in each dimension
    'width': 64,           # latent channel dimension
    'n_blocks': 4,         # number of FNO blocks
    'lifting_dim': 128,    # lifting MLP hidden dim
    'grid_size': 256,      # input/output resolution
}

model = FNO(
    in_channels=1,          # a(x) — permeability field
    out_channels=1,        # u(x) — pressure field
    modes=config['modes'],
    width=config['width'],
    n_blocks=config['n_blocks'],
    lifting_channels=config['lifting_dim'],
)

# Training
optimizer = torch.optim.Adam(model.parameters(), lr=1e-3)
scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=1000)

dataset = DarcyDataset(n_samples=1000, resolution=config['grid_size'])
loader = torch.utils.data.DataLoader(dataset, batch_size=8, shuffle=True)

for epoch in range(1000):
    for a, u in loader:
        # a: (B, 1, H, W), u: (B, 1, H, W)
        u_pred = model(a)
        loss = nn.functional.mse_loss(u_pred, u)
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
    scheduler.step()

# Inference (resolution invariance — train on 64², infer on 256²)
model.eval()
with torch.no_grad():
    u_test = model(a_256)  # works on any resolution
```

### Performance Expectations

| Resolution | Traditional Solver | FNO | Speedup |
|------------|-------------------|-----|---------|
| 64² | ~1s (NumPy) | ~10ms | ~100× |
| 256² | ~30s | ~20ms | ~1500× |
| 1024² | ~30min | ~50ms | ~36000× |

---

## 11. Combining with Traditional HPC

### PINNs as Initial Guesses for Newton Solvers

Use PINN solution as `x0` in Newton iteration — drastically reduces Newton iterations for stiff PDEs:

```python
# 1. Get PINN initial guess
u0_PINN = pinn_model(x_grid)

# 2. Refine with Newton's method
u_newton = newton_solver(
    residual_fn=lambda u: assemble_pde_residual(u, x_grid),
    jacobian_fn=lambda u: assemble_jacobian(u, x_grid),
    x0=u0_PINN.detach().numpy(),
    tol=1e-10
)
# PINN reduces iterations from ~50 to ~5
```

### FNO as Coarse-Grid Solver in Multigrid

```python
# V-cycle with FNO coarse grid
def v_cycle(u_fine, f):
    # Relax on fine grid (Jacobi/Gauss-Seidel)
    u_fine = relax(u_fine, f, n_sweeps=3)

    # Restrict to coarse grid
    f_coarse = restrict(f - A_fine @ u_fine)

    # FNO predicts correction (instead of solving exactly)
    if grid_is_small:
        u_coarse_correction = solve_exactly(A_coarse, f_coarse)
    else:
        u_coarse_correction = fno_coarse_solver(f_coarse)

    # Prolongate and correct
    u_fine += prolongate(u_coarse_correction)
    return u_fine
```

### Neural Closure Models for RANS Turbulence

Replace unresolved Reynolds stresses with a neural network:

```python
# RANS: ∂u/∂t + (u·∇)u = -∇p/ρ + ∇·(ν_t ∇u) + ∇·τ_NN
# τ_NN = neural_network(gradients_of_filtered_velocity)

class NeuralTurbulenceClosure(nn.Module):
    def __init__(self):
        self.closure_net = nn.Sequential(
            nn.Linear(5, 64), nn.Tanh(),   # invariants of velocity gradient tensor
            nn.Linear(64, 64), nn.Tanh(),
            nn.Linear(64, 1)               # anisotropy tensor components
        )

    def forward(self, S, Ω):  # strain rate, rotation tensors
        invariants = compute_tensor_invariants(S, Ω)
        return self.closure_net(invariants)
```

### Climate Modeling: AI Parameterizations

```python
# Subgrid physics in climate models (e.g., convection, clouds)
# Traditional: parametrize at every grid point per timestep
# AI: Learn operator from high-res to coarse-res

class ClimateParameterization(nn.Module):
    # Input: coarse-grid state (T, q, u, v) at time t
    # Output: parameterized tendencies (dT/dt, dq/dt)
    def __init__(self):
        self.fno = FourierNeuralOperator(modes=16, width=32, n_blocks=3)

    def forward(self, state_coarse):
        # Map (T, q, u, v) → subgrid tendencies
        tendencies = self.fno(state_coarse)
        return tendencies
```

### Workflow: Hybrid Physics-AI Solver

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Identify expensive part (shock resolution, turbulence)   │
├─────────────────────────────────────────────────────────────┤
│ 2. Train neural surrogate on high-fidelity data             │
├─────────────────────────────────────────────────────────────┤
│ 3. Validate surrogate against held-out test cases           │
├─────────────────────────────────────────────────────────────┤
│ 4. Couple into traditional solver (operator splitting)       │
├─────────────────────────────────────────────────────────────┤
│ 5. Verify conservation/accuracy with AI component            │
└─────────────────────────────────────────────────────────────┘
```

---

## Quick Reference: When to Use What

| Problem | Method | Why |
|---------|--------|-----|
| Known PDE, want solution | PINN | Embed physics directly |
| Unknown PDE, have data | FNO/DeepONet | Learn operator from data |
| Time series, dynamical system | Neural ODE | Continuous dynamics |
| Parametric studies | DeepONet | One forward pass per parameter |
| Inverse problems | PINN | Easy to incorporate observations |
| Real-time simulation | FNO | Fast inference after training |
| Stochastic systems | Neural SDE | Native stochastic integration |
| Very high resolution | FNO + multigrid | Leverage spectral efficiency |

---

## Further Reading & Resources

- **PINNs:** Raissi et al., "Physics-Informed Neural Networks" (2019)
- **FNO:** Li et al., "Fourier Neural Operator for Parametric PDEs" (2020)
- **DeepONets:** Lu et al., "DeepONet: Learning Operators" (2021)
- **SciML (Julia):** `diffeqflux.jl`, `neuralpde.jl` docs
- **DeepXDE:** `deepxde.readthedocs.io`
- **Neural Operators:** `neuraloperator.readthedocs.io`
