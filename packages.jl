using Pkg
GAP = PackageSpec(path="GAP.jl")
AbstractAlgebra = PackageSpec(path="AbstractAlgebra.jl")
Nemo = PackageSpec(path="Nemo.jl")
Hecke = PackageSpec(path="Hecke.jl")
Singular = PackageSpec(path="Singular.jl")
Polymake = PackageSpec(path="Polymake.jl")

Pkg.add(GAP)
Pkg.add(AbstractAlgebra)
Pkg.add(Nemo)
Pkg.add(Hecke)
Pkg.add(Singular)
Pkg.add(Polymake)

Pkg.update()
