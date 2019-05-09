// :vim:set ft=groovy:
node {
    def workspace = pwd()
    def julia_version = "${params.JULIA_VERSION}"
    def gap_version = "${params.GAP_VERSION}"
    def stdenv = [
        "GAPROOT=${workspace}/gap",
        "NEMO_SOURCE_BUILD=1",
        "JULIA_DEPOT_PATH=${workspace}/jenv/pkg",
        "JULIA_PROJECT=${workspace}/jenv/proj",
	"POLYMAKE_CONFIG=${workspace}/local/bin/polymake-config",
	"PATH=${workspace}/local:${env.PATH}",
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
        dir("polymake") {
            git url: "https://github.com/polymake/polymake",
                branch: "Releases"
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
	sh "meta/install-perl.sh"
    }
    stage('Build') {
        dir("julia") {
            sh "make -j6"
        }
	dir("polymake") {
	    withEnv(stdenv) {
	        sh "./configure --prefix=${workspace}/local"
		sh "ninja -C build/Opt -j6"
		sh "ninja -C build/Opt install"
	    }
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
	withEnv(stdenv) {
	    sh "meta/run-tests.sh"
	}
    }
}
