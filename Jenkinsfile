// :vim:set ft=groovy:
node {
    def workspace = pwd()
    def julia_version = "release-1.1"
    def gap_version = "master"
    def stdenv = [
        "GAPROOT=${workspace}/gap",
        "NEMO_SOURCE_BUILD=1",
        "JULIA_DEPOT_PATH=${workspace}/jenv/pkg",
        "JULIA_PROJECT=${workspace}/jenv/proj"
    ]
    stage('Preparation') { // for display purposes
        // Get some code from a GitHub repository
        dir("meta") {
            git url: "file:///Users/behrends/develop/ci-meta",
                branch: "master"
        }
        dir("julia") {
            git url: "https://github.com/julialang/julia",
                branch: julia_version
        }
        dir("gap") {
            git url: "https://github.com/gap-system/gap",
                branch: gap_version
        }
        dir("singular") {
            git url: "https://github.com/singular/sources",
                branch: "spielwiese"
        }
        dir("GAP.jl") {
            git url: "https://github.com/oscar-system/GAP.jl",
                branch: "master"
        }
        dir("AbstractAlgebra.jl") {
            git url: "https://github.com/wbhart/AbstractAlgebra.jl",
                branch: "master"
        }
        dir("Nemo.jl") {
            git url: "https://github.com/wbhart/Nemo.jl",
                branch: "master"
        }
        dir("Hecke.jl") {
            git url: "https://github.com/wbhart/Nemo.jl",
                branch: "master"
        }
        dir("Singular.jl") {
            git url: "https://github.com/oscar-system/Singular.jl",
                branch: "master"
        }
        sh "meta/patch-singular-jl.sh"
        dir("Polymake.jl") {
            git url: "https://github.com/oscar-system/Polymake.jl",
                branch: "master"
        }
        dir("OSCAR.jl") {
            git url: "https://github.com/oscar-system/OSCAR.jl",
                branch: "master"
        }
    }
    stage('Build') {
        dir("julia") {
            sh "make -j6"
        }
        dir("gap") {
            sh "./autogen.sh"
            sh "./configure --with-gc=julia --with-julia=../julia/usr"
            sh "make -j6"
            sh "test -d pkg || make bootstrap-pkg-minimal"
        }
        withEnv(stdenv) {
            sh "julia/julia meta/packages.jl"
        }
    }
    stage('Test') {
        dir("gap") {
            sh "./gap tst/testinstall.g"
        }
    }
}
