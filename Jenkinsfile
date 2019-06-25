// vim:set ft=groovy:
node {
    def workspace = pwd()
    def metarepo = "file://${env.HOME}/develop/ci-meta"
    def julia_version = "${params.JULIA_VERSION}"
    def gap_version = "${params.GAP_VERSION}"
    def buildtype = "${params.BUILDTYPE}"
    def stdenv = [
        "GAPROOT=${workspace}/gap",
        "NEMO_SOURCE_BUILD=1",
        "JULIA_DEPOT_PATH=${workspace}/jenv/pkg",
        "JULIA_PROJECT=${workspace}/jenv/proj",
	"POLYMAKE_CONFIG=${workspace}/local/bin/polymake-config",
	"PATH=${workspace}/local/bin:${env.PATH}",
    ]
    stage('Preparation') { // for display purposes
        // Get some code from a GitHub repository
        dir("meta") {
            git url: "file:///${env.HOME}/develop/ci-meta",
                branch: "master"
        }
	// major components
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
	// Julia packages
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
            git url: "https://github.com/wbhart/Hecke.jl",
                branch: "master"
        }
        dir("Singular.jl") {
            git url: "https://github.com/oscar-system/Singular.jl",
                branch: "master"
        }
        sh "meta/patch-singular-jl.sh"
	// Polymake
	// sh "meta/install-boost.sh" // needed for Polymake
	sh "meta/install-perl.sh" // needed for Polymake
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
            sh "make -j8"
        }
	dir("polymake") {
	    withEnv(stdenv) {
	        sh "./configure --prefix=${workspace}/local"
	        // sh "./configure --prefix=${workspace}/local --with-boost=${workspace}/local"
		sh "ninja -C build/Opt -j8"
		sh "ninja -C build/Opt install"
	    }
	}
        dir("gap") {
            sh "./autogen.sh"
            sh "./configure --with-gc=julia --with-julia=../julia/usr"
            sh "make -j8"
            sh "test -d pkg || make bootstrap-pkg-minimal"
        }
        withEnv(stdenv) {
            sh "julia/julia meta/packages-${buildtype}.jl"
        }
    }
    stage('Test') {
	withEnv(stdenv) {
	    sh "meta/run-tests.sh"
	}
    }
}
