using HJBSolver, FactCheck

type MertonProblem{T<:Real}
    μ::T
    r::T
    γ::T
    p::T
    model::HJBOneDim{T}
    truevaluefun::Function
    truecontrolfun::Function
end

let

    function createmodel()
        T = 2.
        μ = 0.25
        r = μ-0.02
        γ = 0.3
        p = 0.7
        amid = (μ-r)/(γ^2*(1-p))
        xmin = 0.; xmax = 3.
        amin = 0.; amax = 1.1*amid*xmax

        b(t,x,a) = r*x + a*(μ-r)
        σ(t,x,a) = a*γ
        f(t,x,a) = zero(a)
        g(x) = x.^p

        ρ = p*((μ-r)^2/(2*γ^2*(1-p)) + r)
        truesol(t,x) = exp(ρ*(T-t)).*g(x)
        truepol(t,x) = (μ-r)/(γ^2*(1-p))*x
        Dfun1(t) = truesol(t,xmin)
        Dfun2(t) = truesol(t,xmax)

        @assert 0 < p < 1 # So that we can use boundary condition v(t,0) = 0 ∀ t
        model = HJBOneDim(b, σ, f, g, T, amin, amax, xmin, xmax,
                          (true,true), (Dfun1, Dfun2))
        return MertonProblem(μ, r, γ, p, model, truesol, truepol)
    end

    function calculateerror_const(merton::MertonProblem,K::Int, N::Int, M::Int)
        @time v, pol = solve(merton.model, K, N, M)
        model = merton.model

        x = linspace(model.xmin, model.xmax, K)
        Δτ = model.T/N

        w = merton.truevaluefun(0., x)
        α = merton.truecontrolfun(0., x[2:end-1])

        return norm(w-v[:,1])/norm(w), norm(α-pol[2:end-1,1])/norm(α)
    end

    function calculateerror_iter(merton::MertonProblem, K::Int, N::Int)
        @time v, pol = solve(merton.model, K, N)
        model = merton.model

        x = linspace(model.xmin, model.xmax, K)
        Δτ = model.T/N

        w = merton.truevaluefun(0., x)
        α = merton.truecontrolfun(0., x[2:end-1])

        return norm(w-v[:,1])/norm(w), norm(α-pol[2:end-1,1])/norm(α)
    end


    facts("Constant policy approximation, Merton") do
        K = 2^8+1; N = 2^7; M = 2^7
        merton = createmodel()
        # TODO: calculate error at two-three different space-time points instead
        errv, erra = calculateerror_const(merton, K, N, M)

        @fact errv --> roughly(0., 1e-3)
        @fact erra --> roughly(0., 1e-2)
    end

    facts("Policy iteration, Merton") do
        K = 2^8+1; N = 2^7
        merton = createmodel()
        # TODO: calculate error at two-three different space-time points instead
        errv, erra = calculateerror_iter(merton, K, N)

        @fact errv --> roughly(0., 1e-3)
        @fact erra --> roughly(0., 1e-2)
    end
end
