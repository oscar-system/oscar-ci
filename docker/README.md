# Creating a docker image

You can create a docker image either manually or using the provided
Makefile to automate creation.

## One step docker image creation

Simply run:

    make

This will download the specified version of Jenkins and the meta repository
that controls Jenkins operations and build an image called `oscar-ci` from
it. You can pass various options to make, e.g.:

    make IMAGENAME=oscar-local JENKINS_VER=2.176.1

The most important options are `IMAGENAME`, which specifies the image to
be created, and `JENKINS_VER`, which specifies which version of Jenkins
to download.

By default, the most recent Jenkins version will be downloaded to ensure
that the latest security fixes are in. This can in theory break
compatibility, so you can specify a fixed version if you run into such
problems.

## Multi step docker image creation

If you wish to not just run Jenkins, but to use the docker image for
interactive tasks (such as debugging Jenkins operations or test scripts),
you best use a multi step process:

    make prepare
    cp <additional files> user/
    make

The docker image will run with a user called `jenkins` and the contents
of the `user` directory will be copied to that user's home directory.
This allows installation of files like `.bashrc` or whatever else you
need for debugging and development.

During this step you can also modify the `ci-meta` repository that was
created.

## Manual configuration

Finally, you can also build the docker image manually by following the
basic steps in the Makefile.

1. Create an empty directory and cd to it.
2. Copy `Dockerfile` to this directory.
3. Run: `git clone git@github.com:oscar-system/oscar-ci ci-meta`
4. Run: `wget http://mirrors.jenkins.io/war-stable/latest/jenkins.war`
5. Run: `mkdir user`
6. Any additional modifications to the above files and directories.
6. Run: `docker build -t <image-name> .`

# Running Jenkins

This is intended to be run with:

    docker run -it -v jenkins_home:/var/jenkins_home -p 8080:8080 <image-name>

where `jenkins_home` is a docker volume, which can be created with:

   docker volume create jenkins_home

This volume will store Jenkins state (logs, workspaces) between runs and
reboots.

You can alternatively use a bind mount instead of a docker volume to
store Jenkins state in the file system. In this case, please follow
the Jenkins documentation for ensuring that the user and group ids on
host system and container are properly matched up, or you may run into
permission problems.

The image is currently designed to drop you into a shell to debug the
Jenkins setup. In order to start Jenkins by default, replace the current
CMD directive at the end of the Dockerfile with:

    CMD jenkins

You can also configure tmux by putting in a .tmux.conf file of your
choice. This allows you to run Jenkins in one tmux tab and perform
other tasks in other ones. The above instructions will leave .tmux.conf
empty. If you need other files in the jenkins setup (such as a .bashrc),
add them to the COPY directive.

To start Jenkins from the container shell, run:

    jenkins

You can also run Jenkins directly from the host using:

    docker run -it \
        -v jenkins_home:/var/jenkins_home -p 8080:8080 \
        <image-name> jenkins

# Configuring Jenkins

The first time you run Jenkins with a new `jenkins_home` volume, you will
need to set up Jenkins using the GUI. You will be prompted to connect to
the GUI using your web browser and to enter a pregenerated password (shown
on the console). Then follow the following steps in the GUI:

1. Download and install the recommended plugins.
2. Create an admin user.
3. Create a job by either running `create-stdjob <jobname>` or configuring
   it from the GUI (you may need to interrupt/pause Jenkins and resume it
   for that).
4. Go to "Manage Jenkins => Reload Configuration from Disk" if you used
   the `create-stdjob` command to let Jenkins know that a job was created
   on disk.

Note:

The ci-meta directory is currently pulled from local storage, rather
than from GitHub directly. This is to allow you to introduce
local commits for debugging purposes. In the long term, we will pull
directly from GitHub so that Jenkins will immediately adjust to any
changes made there.

# Debugging/developing inside the container

The container is set up to have the usual tools installed, including
common scripting languages (Perl, Python, Ruby), C/C++ compilers and
debuggers, as well as tools such as tmux and screen.

To run Jenkins tests from a specific workspace, use the `with-workspace`
command. It will set the environment variables for that workspace,
change the current directory to the workspace, and execute any command
following it, e.g.:

    with-workspace oscar ls gap

or:

    with-workspace oscar julia

The general syntax is:

    with-workspace <workspace name> <command>

where `<workspace name>` is the name of the workspace and `<command>` is
an arbitrary shell command.
