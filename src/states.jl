import Base: ==, +, -, *, /, length, copy, eltype
import LinearAlgebra: norm, normalize, normalize!

"""
Abstract base class for [`Bra`](@ref) and [`Ket`](@ref) states.

The state vector class stores the coefficients of an abstract state
in respect to a certain basis. These coefficients are stored in the
`data` field and the basis is defined in the `basis`
field.
"""
abstract type StateVector{B<:Basis,T<:AbstractVector} end

"""
    Bra(b::Basis[, data])

Bra state defined by coefficients in respect to the basis.
"""
mutable struct Bra{B<:Basis,T<:AbstractVector} <: StateVector{B,T}
    basis::B
    data::T
    function Bra{B,T}(b::B, data::T) where {B<:Basis,T<:AbstractVector}
        (length(b)==length(data)) || throw(DimensionMismatch("Tried to assign data of length $(length(data)) to Hilbert space of size $(length(b))"))
        new(b, data)
    end
end

"""
    Ket(b::Basis[, data])

Ket state defined by coefficients in respect to the given basis.
"""
mutable struct Ket{B<:Basis,T<:AbstractVector} <: StateVector{B,T}
    basis::B
    data::T
    function Ket{B,T}(b::B, data::T) where {B<:Basis,T<:AbstractVector}
        (length(b)==length(data)) || throw(DimensionMismatch("Tried to assign data of length $(length(data)) to Hilbert space of size $(length(b))"))
        new(b, data)
    end
end

eltype(::Type{K}) where {K <: Ket{B,V}} where {B,V} = eltype(V)
eltype(::Type{K}) where {K <: Bra{B,V}} where {B,V} = eltype(V)

Bra{B}(b::B, data::T) where {B<:Basis,T} = Bra{B,T}(b, data)
Ket{B}(b::B, data::T) where {B<:Basis,T} = Ket{B,T}(b, data)

Bra(b::B, data::T) where {B<:Basis,T} = Bra{B,T}(b, data)
Ket(b::B, data::T) where {B<:Basis,T} = Ket{B,T}(b, data)

Bra{B}(::Type{T}, b::B) where {T,B<:Basis} = Bra{B}(b, zeros(T, length(b)))
Ket{B}(::Type{T}, b::B) where {T,B<:Basis} = Ket{B}(b, zeros(T, length(b)))
Bra(::Type{T}, b::Basis) where T = Bra(b, zeros(T, length(b)))
Ket(::Type{T}, b::Basis) where T = Ket(b, zeros(T, length(b)))

Bra{B}(b::B) where B<:Basis = Bra{B}(ComplexF64, b)
Ket{B}(b::B) where B<:Basis = Ket{B}(ComplexF64, b)
Bra(b::Basis) = Bra(ComplexF64, b)
Ket(b::Basis) = Ket(ComplexF64, b)

copy(a::T) where {T<:StateVector} = T(a.basis, copy(a.data))
length(a::StateVector) = length(a.basis)::Int
basis(a::StateVector) = a.basis

==(x::Ket{B}, y::Ket{B}) where {B<:Basis} = (samebases(x, y) && x.data==y.data)
==(x::Bra{B}, y::Bra{B}) where {B<:Basis} = (samebases(x, y) && x.data==y.data)
==(x::Ket, y::Ket) = false
==(x::Bra, y::Bra) = false

Base.isapprox(x::Ket{B}, y::Ket{B}; kwargs...) where {B<:Basis} = (samebases(x, y) && isapprox(x.data,y.data;kwargs...))
Base.isapprox(x::Bra{B}, y::Bra{B}; kwargs...) where {B<:Basis} = (samebases(x, y) && isapprox(x.data,y.data;kwargs...))
Base.isapprox(x::Ket, y::Ket; kwargs...) = false
Base.isapprox(x::Bra, y::Bra; kwargs...) = false

# Arithmetic operations
+(a::Ket{B}, b::Ket{B}) where {B<:Basis} = Ket(a.basis, a.data+b.data)
+(a::Bra{B}, b::Bra{B}) where {B<:Basis} = Bra(a.basis, a.data+b.data)
+(a::Ket, b::Ket) = throw(IncompatibleBases())
+(a::Bra, b::Bra) = throw(IncompatibleBases())

-(a::Ket{B}, b::Ket{B}) where {B<:Basis} = Ket(a.basis, a.data-b.data)
-(a::Bra{B}, b::Bra{B}) where {B<:Basis} = Bra(a.basis, a.data-b.data)
-(a::Ket, b::Ket) = throw(IncompatibleBases())
-(a::Bra, b::Bra) = throw(IncompatibleBases())

-(a::T) where {T<:StateVector} = T(a.basis, -a.data)

*(a::Bra{B}, b::Ket{B}) where {B<:Basis} = transpose(a.data)*b.data
*(a::Bra, b::Ket) = throw(IncompatibleBases())
*(a::Number, b::Ket) = Ket(b.basis, a*b.data)
*(a::Number, b::Bra) = Bra(b.basis, a*b.data)
*(a::StateVector, b::Number) = b*a

/(a::Ket, b::Number) = Ket(a.basis, a.data ./ b)
/(a::Bra, b::Number) = Bra(a.basis, a.data ./ b)


"""
    dagger(x)

Hermitian conjugate.
"""
dagger(x::Bra) = Ket(x.basis, conj(x.data))
dagger(x::Ket) = Bra(x.basis, conj(x.data))
Base.adjoint(a::StateVector) = dagger(a)

"""
    tensor(x::Ket, y::Ket, z::Ket...)

Tensor product ``|x⟩⊗|y⟩⊗|z⟩⊗…`` of the given states.
"""
tensor(a::Ket, b::Ket) = Ket(tensor(a.basis, b.basis), kron(b.data, a.data))
tensor(a::Bra, b::Bra) = Bra(tensor(a.basis, b.basis), kron(b.data, a.data))
tensor(state::StateVector) = state
tensor(states::Ket...) = reduce(tensor, states)
tensor(states::Bra...) = reduce(tensor, states)
tensor(states::Vector{T}) where T<:StateVector = reduce(tensor, states)

# Normalization functions
"""
    norm(x::StateVector)

Norm of the given bra or ket state.
"""
norm(x::StateVector) = norm(x.data)

"""
    normalize(x::StateVector)

Return the normalized state so that `norm(x)` is one.
"""
normalize(x::StateVector) = x/norm(x)

"""
    normalize!(x::StateVector)

In-place normalization of the given bra or ket so that `norm(x)` is one.
"""
normalize!(x::StateVector) = (normalize!(x.data); x)

function permutesystems(state::T, perm::Vector{Int}) where T<:Ket
    @assert length(state.basis.bases) == length(perm)
    @assert isperm(perm)
    data = reshape(state.data, state.basis.shape...)
    data = permutedims(data, perm)
    data = reshape(data, length(data))
    Ket(permutesystems(state.basis, perm), data)
end
function permutesystems(state::T, perm::Vector{Int}) where T<:Bra
    @assert length(state.basis.bases) == length(perm)
    @assert isperm(perm)
    data = reshape(state.data, state.basis.shape...)
    data = permutedims(data, perm)
    data = reshape(data, length(data))
    Bra(permutesystems(state.basis, perm), data)
end

# Creation of basis states.
"""
    basisstate(b, index)
    basisstate(::Type{T}, b, index)

Basis vector specified by `index` as ket state.

For a composite system `index` can be a vector which then creates a tensor
product state ``|i_1⟩⊗|i_2⟩⊗…⊗|i_n⟩`` of the corresponding basis states.
"""
function basisstate(::Type{T}, b::Basis, indices::Vector) where T
    @assert length(b.shape) == length(indices)
    x = zeros(T, length(b))
    x[LinearIndices(tuple(b.shape...))[indices...]] = one(T)
    Ket(b, x)
end
function basisstate(::Type{T}, b::Basis, index::Integer) where T
    data = zeros(T, length(b))
    data[index] = one(T)
    Ket(b, data)
end

# Deprecate kwargs
function basisstate(b::Basis, index; sparse=nothing, dType=nothing)
    if sparse===nothing && dType===nothing
        return basisstate(ComplexF64, b, index)
    end
    if sparse !== nothing
        Base.depwarn("basisstate(b, index, sparse=true) is deprecated, use sparsebasisstate(b, index) instead",
                    :basisstate; force=true)
    end
    if dType !== nothing
        Base.depwarn("basisstate(b, index, dType=$dType) is deprecated, use basisstate($dType, b, index) instead",
                    :basisstate)
    end
    if sparse !== nothing
        if dType === nothing
            return sparsebasisstate(b, index)
        else
            return sparsebasisstate(dType, b, index)
        end
    else
        return basisstate(dType, b, index)
    end
end

"""
    sparsebasisstate(b, index)
    sparsebasisstate(::Type{T}, b, index)

Sparse version of [`basisstate`](@ref).
"""
function sparsebasisstate(::Type{T}, b::Basis, indices) where T
    @assert length(b.shape) == length(indices)
    x = spzeros(T, length(b))
    x[LinearIndices(tuple(b.shape...))[indices...]] = one(T)
    Ket(b, x)
end
function sparsebasisstate(::Type{T}, b::Basis, index::Integer) where T
    data = spzeros(T, length(b))
    data[index] = one(T)
    Ket(b, data)
end
sparsebasisstate(b::Basis, indices) = sparsebasisstate(ComplexF64, b, indices)

# Helper functions to check validity of arguments
function check_multiplicable(a::Bra, b::Ket)
    if a.basis != b.basis
        throw(IncompatibleBases())
    end
end

samebases(a::Ket{B}, b::Ket{B}) where {B} = samebases(a.basis, b.basis)::Bool
samebases(a::Bra{B}, b::Bra{B}) where {B} = samebases(a.basis, b.basis)::Bool

# Array-like functions
Base.size(x::StateVector) = size(x.data)
@inline Base.axes(x::StateVector) = axes(x.data)
Base.ndims(x::StateVector) = 1
Base.ndims(::Type{<:StateVector}) = 1
Base.eltype(x::StateVector) = eltype(x.data)

# Broadcasting
Base.broadcastable(x::StateVector) = x

# Custom broadcasting style
abstract type StateVectorStyle{B<:Basis} <: Broadcast.BroadcastStyle end
struct KetStyle{B<:Basis} <: StateVectorStyle{B} end
struct BraStyle{B<:Basis} <: StateVectorStyle{B} end

# Style precedence rules
Broadcast.BroadcastStyle(::Type{<:Ket{B}}) where {B<:Basis} = KetStyle{B}()
Broadcast.BroadcastStyle(::Type{<:Bra{B}}) where {B<:Basis} = BraStyle{B}()
Broadcast.BroadcastStyle(::KetStyle{B1}, ::KetStyle{B2}) where {B1<:Basis,B2<:Basis} = throw(IncompatibleBases())
Broadcast.BroadcastStyle(::BraStyle{B1}, ::BraStyle{B2}) where {B1<:Basis,B2<:Basis} = throw(IncompatibleBases())

# Out-of-place broadcasting
@inline function Base.copy(bc::Broadcast.Broadcasted{Style,Axes,F,Args}) where {B<:Basis,Style<:KetStyle{B},Axes,F,Args<:Tuple}
    bcf = Broadcast.flatten(bc)
    bc_ = Broadcasted_restrict_f(bcf.f, bcf.args, axes(bcf))
    b = find_basis(bcf)
    return Ket{B}(b, copy(bc_))
end
@inline function Base.copy(bc::Broadcast.Broadcasted{Style,Axes,F,Args}) where {B<:Basis,Style<:BraStyle{B},Axes,F,Args<:Tuple}
    bcf = Broadcast.flatten(bc)
    bc_ = Broadcasted_restrict_f(bcf.f, bcf.args, axes(bcf))
    b = find_basis(bcf)
    return Bra{B}(b, copy(bc_))
end
find_basis(bc::Broadcast.Broadcasted) = find_basis(bc.args)
find_basis(args::Tuple) = find_basis(find_basis(args[1]), Base.tail(args))
find_basis(x) = x
find_basis(a::StateVector, rest) = a.basis
find_basis(::Any, rest) = find_basis(rest)

const BasicMathFunc = Union{typeof(+),typeof(-),typeof(*)}
function Broadcasted_restrict_f(f::BasicMathFunc, args::Tuple{Vararg{<:T}}, axes) where T<:StateVector
    args_ = Tuple(a.data for a=args)
    return Broadcast.Broadcasted(f, args_, axes)
end
function Broadcasted_restrict_f(f, args::Tuple{Vararg{<:T}}, axes) where T<:StateVector
    throw(error("Cannot broadcast function `$f` on type `$T`"))
end


# In-place broadcasting for Kets
@inline function Base.copyto!(dest::Ket{B}, bc::Broadcast.Broadcasted{Style,Axes,F,Args}) where {B<:Basis,Style<:KetStyle{B},Axes,F,Args}
    axes(dest) == axes(bc) || Base.Broadcast.throwdm(axes(dest), axes(bc))
    # Performance optimization: broadcast!(identity, dest, A) is equivalent to copyto!(dest, A) if indices match
    if bc.f === identity && isa(bc.args, Tuple{<:Ket{B}}) # only a single input argument to broadcast!
        A = bc.args[1]
        if axes(dest) == axes(A)
            return copyto!(dest, A)
        end
    end
    # Get the underlying data fields of kets and broadcast them as arrays
    bcf = Broadcast.flatten(bc)
    args_ = Tuple(a.data for a=bcf.args)
    bc_ = Broadcast.Broadcasted(bcf.f, args_, axes(bcf))
    copyto!(dest.data, bc_)
    return dest
end
@inline Base.copyto!(dest::Ket{B1}, bc::Broadcast.Broadcasted{Style,Axes,F,Args}) where {B1<:Basis,B2<:Basis,Style<:KetStyle{B2},Axes,F,Args} =
    throw(IncompatibleBases())

# In-place broadcasting for Bras
@inline function Base.copyto!(dest::Bra{B}, bc::Broadcast.Broadcasted{Style,Axes,F,Args}) where {B<:Basis,Style<:BraStyle{B},Axes,F,Args}
    axes(dest) == axes(bc) || Base.Broadcast.throwdm(axes(dest), axes(bc))
    # Performance optimization: broadcast!(identity, dest, A) is equivalent to copyto!(dest, A) if indices match
    if bc.f === identity && isa(bc.args, Tuple{<:Bra{B}}) # only a single input argument to broadcast!
        A = bc.args[1]
        if axes(dest) == axes(A)
            return copyto!(dest, A)
        end
    end
    # Get the underlying data fields of bras and broadcast them as arrays
    bcf = Broadcast.flatten(bc)
    bc_ = Broadcasted_restrict_f(bcf.f, bcf.args, axes(bcf))
    copyto!(dest.data, bc_)
    return dest
end
@inline Base.copyto!(dest::Bra{B1}, bc::Broadcast.Broadcasted{Style,Axes,F,Args}) where {B1<:Basis,B2<:Basis,Style<:BraStyle{B2},Axes,F,Args} =
    throw(IncompatibleBases())

@inline Base.copyto!(A::T,B::T) where T<:StateVector = (copyto!(A.data,B.data); A)
