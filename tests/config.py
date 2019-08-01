[
    Test(name="OscarForHomalg", script = "test-OscarForHomalg.sh"),
    Test(name="GAP", script="test-gap.sh"),
    Test(name="GAP.jl", script="test-gapjl.sh"),
    Test(name="Nemo.jl", script="test-nemo.sh"),
    Test(name="Hecke.jl", script="test-hecke.sh", timeout=3600),
    Test(name="AbstractAlgebra.jl", script = "test-absalg.sh"),
    Test(name="Singular.jl", script = "test-singularjl.sh"),
    Test(name="HomalgProject.jl", script = "test-HomalgProject_jl.sh"),
    Test(name="Polymake.jl", script = "test-polymakejl.sh"),
    Test(name="JuliaInterface", script="test-JuliaInterface.sh"),
    Test(name="JuliaExperimental", script="test-JuliaExperimental.sh"),
]
