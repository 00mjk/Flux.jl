children(x) = ()
mapchildren(f, x) = x

function treelike(T, fs = fieldnames(T))
  @eval begin
    children(x::$T) = ($([:(x.$f) for f in fs]...),)
    mapchildren(f, x::$T) = $T(f.(children(x))...)
  end
end

isleaf(x) = isempty(children(x))

function mapleaves(f, x; cache = ObjectIdDict())
  haskey(cache, x) && return cache[x]
  cache[x] = isleaf(x) ? f(x) : mapchildren(x -> mapleaves(f, x, cache = cache), x)
end

export mapparams
@deprecate mapparams(f, x) mapleaves(f, x)

using DataFlow: OSet

function forleaves(f, x; seen = OSet())
  x ∈ seen && return
  push!(seen, x)
  isleaf(x) ? f(x) : foreach(x -> forleaves(f, x, seen = seen), children(x))
  return
end

function params(m)
  ps = []
  forleaves(p -> p isa TrackedArray && push!(ps, p), m)
  return ps
end
