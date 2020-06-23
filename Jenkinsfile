// vim:set ft=groovy:

parameters {
    string("JULIA_VERSION", defaultValue: "master")
    string("GAP_VERSION", defaultValue: "master")
    choice("BUILDTYPE", choices: [ "master", "stable", "release" ],
      defaultValue: "master")
    string("BUILDJOBS", defaultValue: "8")
    choice("REBUILDMODE", choices: [ "normal", "full", "none" ],
        defaultValue: "normal")
    choice("NODE_LABEL", choices: [ "main", "macos" ])
}

def get(Map args) {
    url = args.url
    dir = args.dir ?: args.url.split("/")[-1]
    if (args.scm == "hg") {
	rev = args.branch ?: "default"
        checkout([$class: "MercurialSCM",
	    source: url,
	    revision: rev,
	    subdir: dir])
    } else if (args.scm == "git" || args.scm == null) {
	rev = args.branch ?: "master"
	if (rev.startsWith("tag:"))
	   rev = "refs/tags/" + rev[4..-1]
	checkout([$class: "GitSCM",
	    userRemoteConfigs: [[url: url]],
	    branches: [[name: rev]],
	    extensions: [[$class: "RelativeTargetDirectory",
		relativeTargetDir: dir]] ])
    }
}

date = new Date().format("yyyy-MM-dd")
timestampFile = ".timestamp"

def rebuildMode() {
    rebuild = "${params.REBUILDMODE}"
    // Do a full rebuild every day after midnight
    try {
	olddate = readFile(file: timestampFile)
	if (olddate != date)
	    rebuild = "full"
    } catch (all) {
	rebuild = "full"
    }
    return rebuild
}

def updateTimestamp() {
    writeFile(file: timestampFile, text: date)
}

nodeLabel = params.NODE_LABEL ?: "main"

node(label: nodeLabel) {
    def workspace = pwd()
    def jenkins_home = env.JENKINS_HOME
    // Docker image to use as build/test environment
    def buildenv = env.OSCAR_CI_IMAGE ?: env.OSCAR_CI_NAME ?: "oscar-ci"
    def run_in_docker = { block ->
      if (nodeLabel == "main") {
	img = docker.image(buildenv)
	img.inside("--init -v ${jenkins_home}:${jenkins_home}") {
	  block()
	}
      } else {
        block()
      }
    }
    // URLs
    def metarepo =
      env.OSCAR_CI_REPO ?: "https://github.com/oscar-system/oscar-ci"

    // parameters
    def julia_version = "${params.JULIA_VERSION}"
    def gap_version = "${params.GAP_VERSION}"
    def buildtype = "${params.BUILDTYPE}"
    def rebuild = rebuildMode()
    try {
        stage('Preparation') {
	    // Setup workspace.
            if (rebuild == "full") {
                cleanWs disableDeferredWipeout: true, deleteDirs: true
            }
	    updateTimestamp()
	    get url: metarepo, dir: "meta"
	    sh "meta/prepare.rb"
            // Update repositories
            if (rebuild != "none") {
		get url: "https://github.com/julialang/julia",
		    branch: julia_version
		get url: "https://github.com/gap-system/gap",
		    branch: gap_version
		get url: "https://github.com/singular/sources",
		    dir: "singular", branch: "spielwiese"
		get url: "https://github.com/oscar-system/GAP.jl"
                get url: "https://github.com/Nemocas/AbstractAlgebra.jl"
		get url: "https://github.com/Nemocas/Nemo.jl"
                get url: "https://github.com/thofma/Hecke.jl"
		get url: "https://github.com/oscar-system/LoadFlint.jl"
                get url: "https://github.com/oscar-system/Singular.jl"
		get url: "https://github.com/oscar-system/Polymake.jl"
		get url: "https://github.com/homalg-project/HomalgProject.jl"
		get url: "https://github.com/oscar-system/GroupAtlas.jl"
		get url: "https://github.com/ederc/GroebnerBasis.jl"
		get url: "https://github.com/oscar-system/Oscar.jl"
                get url: "https://github.com/sebastianpos/NemoLinearAlgebraForCAP"
		get url: "https://github.com/oscar-system/OSCARBinder",
		        dir: "notebooks"
		get url: "https://github.com/micjoswig/oscar-notebooks",
		        dir: "notebooks-polymake"
		get url: "https://github.com/homalg-project/CapHomalgNotebooks",
		        dir: "notebooks-homalg"
		get url: "https://github.com/oscar-system/GITFans",
		        dir: "notebooks-gitfans"
		get url: "https://github.com/ederc/GroebnerBasisNotebooks",
		        dir: "notebooks-groebner"
            } else {
                // skip preparation
		echo "Skipping preparation stage."
            }
        }
        stage('Build') {
            if (rebuild != "none") {
	        run_in_docker {
		    sh "meta/install/install-julia.rb"
		    sh "meta/install/install-oscar.rb"
		    sh "meta/install/install-jupyter.rb"
		    sh "meta/install/install-gap.rb"
		    sh "meta/install/install-gap-packages.rb"
		    sh "meta/install/install-finalize.rb"
		}
            } else {
                // skip build stage
                echo "Skipping build stage."
            }
        }
        stage('Test') {
	    run_in_docker {
		sh "meta/run-tests.rb"
	    }
        }
    } finally {
        archiveArtifacts artifacts: "logs/build-${env.BUILD_NUMBER}/*"
        archiveArtifacts artifacts: "julia-env/*.toml"
    }
}
