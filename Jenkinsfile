// vim:set ft=groovy:
parameters {
    string("JULIA_VERSION", defaultValue: "master")
    string("GAP_VERSION", defaultValue: "master")
    choice("BUILDTYPE", choices: [ "src", "bin" ], defaultValue: "src")
    string("BUILDJOBS", defaultValue: "8")
    choice("REBUILDMODE", choices: [ "normal", "full", "none" ],
        defaultValue: "normal")
}

node {
    def workspace = pwd()
    // URLs
    def metarepo = env.OSCAR_CI_REPO ?
      "${env.OSCAR_CI_REPO}" :
      "file://${env.HOME}/develop/ci-meta"

    // parameters
    def julia_version = "${params.JULIA_VERSION}"
    def gap_version = "${params.GAP_VERSION}"
    def buildtype = "${params.BUILDTYPE}"
    def jobs = "${params.BUILDJOBS}"
    def rebuild = "${params.REBUILDMODE}"

    // environment variables
    def stdenv = [
        "GAPROOT=${workspace}/gap",
        "NEMO_SOURCE_BUILD=1",
        "JULIA_DEPOT_PATH=${workspace}/jenv/pkg",
        "JULIA_PROJECT=${workspace}/jenv/proj",
        "POLYMAKE_CONFIG=${workspace}/local/bin/polymake-config",
        "PATH=${workspace}/local/bin:${env.PATH}",
    ]
    try {
        stage('Preparation') { // for display purposes
	    // Get some code from a GitHub repository
	    dir("meta") {
		git url: metarepo,
		    branch: "master"
	    }
	    sh script: "mkdir -p ${workspace}/local/bin",
	        label: "Make local directories."
            if (rebuild != "none") {
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
                    git url: "https://github.com/Nemocas/AbstractAlgebra.jl",
                        branch: "master"
                }
                dir("Nemo.jl") {
                    git url: "https://github.com/Nemocas/Nemo.jl",
                        branch: "master"
                }
                dir("Hecke.jl") {
                    git url: "https://github.com/thofma/Hecke.jl",
                        branch: "master"
                }
                dir("Singular.jl") {
                    git url: "https://github.com/oscar-system/Singular.jl",
                        branch: "master"
                }
                sh script: "meta/patch-singular-jl.sh",
		    label: "Make Singular.jl use local Singular installation."
                // Polymake
                if (!fileExists("/.dockerenv")) {
                    // We are running outside a docker container, create
                    // a self-contained Perl installation.
                    sh script: "meta/install-perl.sh", // needed for Polymake
		        label: "Create local Perl installation."
                }
                dir("Polymake.jl") {
                    git url: "https://github.com/oscar-system/Polymake.jl",
                        branch: "master"
                }
                dir("HomalgProject.jl") {
                    git url: "https://github.com/homalg-project/HomalgProject.jl",
                        branch: "master"
                }
                dir("OSCAR.jl") {
                    git url: "https://github.com/oscar-system/OSCAR.jl",
                        branch: "master"
                }
                // GAP packages
                dir("gap/pkg/OscarForHomalg") {
                    git url: "https://github.com/homalg-project/OscarForHomalg.git",
                        branch: "master"
                }
            } else {
                // skip preparation
		echo "Skipping preparation stage."
            }
        }
        stage('Build') {
            if (rebuild != "none") {
                dir("julia") {
                    sh script: "make -j${jobs}",
		        label: "Build Julia."
		    sh script: "ln -sf ${workspace}/julia/julia ${workspace}/local/bin",
		        label: "Install Julia."
                }
                dir("polymake") {
                    withEnv(stdenv) {
                        sh script: "./configure --prefix=${workspace}/local",
			    label: "Configure Polymake."
                        sh script: "ninja -C build/Opt -j${jobs}",
                            label: "Build Polymake."
                        sh script: "ninja -C build/Opt install",
                            label: "Install Polymake."
                    }
                }
                dir("gap") {
                    withEnv(stdenv) {
                        sh script: "./autogen.sh",
                            label: "Configure GAP."
                        sh script: "./configure --with-gc=julia --with-julia=../julia/usr",
                            label: "Configure GAP (step 2)."
                        sh script: "make -j${jobs}",
                            label: "Build GAP."
                        sh script: "test -d pkg || (make bootstrap-pkg-full && cd pkg && ../bin/BuildPackages.sh)",
                            label: "Build GAP packages."
		        sh script: "ln -sf ${workspace}/gap/bin/gap.sh ${workspace}/local/bin/gap",
		            label: "Install GAP."
                    }
                }
                dir("singular") {
                    withEnv(stdenv) {
                        sh script: "./autogen.sh",
                            label: "Autogen Singular"
                        sh script: "./configure --disable-polymake",
                            label: "Configure Singular"
                        sh script: "make -j${jobs}",
                            label: "Make Singular"
                        sh script: "ln -sf ${workspace}/singular/Singular/Singular ${workspace}/local/bin/Singular",
                            label: "Install Singular."
                    }
                }
                dir("gap") {
		    withEnv(stdenv) {
		        def GAP_jl_PATH = sh(returnStdout: true, script: "julia -e 'import Pkg; print(Pkg.dir(\"GAP\"))'").trim()
		        sh script: "ln -s ${GAP_jl_PATH}/pkg/GAPJulia/ ${workspace}/gap/pkg/GAPJulia",
                            label: "Install GAPJulia packages from GAP.jl in GAP pkg folder"
	            }
                }
                withEnv(stdenv) {
                    sh script: "julia/julia meta/packages-${buildtype}.jl",
                        label: "Build OSCAR packages."
                }
            } else {
                // skip build stage
                echo "Skipping build stage."
            }
        }
        stage('Test') {
            withEnv(stdenv) {
                sh script: "meta/run-tests.sh",
                    label: "Run tests."
            }
        }
    } finally {
        archiveArtifacts artifacts: "logs/build-${env.BUILD_NUMBER}/*"
    }
}
