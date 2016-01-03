# Multimedia SlackBuilds for ffmpeg

This project is an intent for make more easier the installation ffmpeg and its dependencies in Slackware.

For now are tested in slackaware-current, while we are awaiting for the new version, after Slacware 14.1.

# HOWTO use

## Requirements

* Full installation of slackware-current
* sbopkg, command-line tool to synchronize with SlackBuilds.org https://www.sbopkg.org/
  * sbopkg must be configured with current git repository (UNSUPPORTED SBo git repository for -current, AKA ponce's repository)
  * Finally you can run **sbopkg -r** to synchronize the repository.

## Installation

The installation is very simple, but can be customized by the user.

You will need have a true login shell to have correctly populated environment. It is imperative that you use **su -l** when switching to root, or source the /etc/profile script after doing **su**.

### FFmpeg with all its dependencies

Simply run:

```
git clone https://github.com/mmslackbuilds/slack-ffmpeg.git
cd slack-ffmpeg
./download.sh
SIMULATION=no ./build.sh
```

### Customized installation of dependencies for ffmpeg

You can customize ffmpeg dependencies, simply edit *optional-deps* file and comment what you do not want to install.

If you can test and verify your changes, you can run:

```
vim optional-deps
# make changes and type :wq"

# download only if you do not download packages previously
./downlod.sh

# testing package list and view flags added to ffmpeg
./build.sh
```

If you agree with the list of packages to be installed run:

```
SIMULATION=no ./build.sh
```

# Hacking

You can edit the file **opgiona-config** for add more group of packages and add or remove dependencies for a particular group. This file contain help for edit properly.

Many SlackBuilds for other packages are in develop for now, you can see the **packagelist** file with a list of external library support for ffmpeg.
