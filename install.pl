#!/usr/bin/perl
use strict;
use warnings;

use File::Path qw(make_path);

# TODO: Make these defaults and override them if user provides command line args
# TODO: Add option for interactive (includes user prompts) vs. quick (uses all defaults, unless defined via command line)
# TODO: Add option for verbose vs. silent

# sub repos, link sources and destinations
my @sub_repos;
my @link_source;
my @link_dest;

# URL to pull main env repo from
my $repo = 'git@github.com:coldcandor/env.git';

# Destination install directory
my $base = <~>;

# Home and bin for symlinks
my $home = <~>;
my $bin = <~/bin>;

# Installs the core repo at $base/$repo_dir
my $repo_dir = "env";

# Installs sub repos in dirs inside $base/$sub_repo_dir
my $sub_repo_dir = "env-sub";

push @sub_repos,
	"https://github.com/shannonmoeller/hosts.git",
	"https://github.com/shannonmoeller/up.git",
	"https://github.com/shannonmoeller/bulk.git",
	"https://github.com/vim-scripts/Colortest.git",
	"https://github.com/coldcandor/extract.git",
	"https://github.com/ericrshields/gitprompt.git"
#	"https://github.com/synacor/gitprompt.git"  //backup repo
#	"https://github.com/somegithubuser/env.git";  //backup repo
#	"https://github.com/mikecanz/env.git";  //Original source

# Symlink sources
push @link_source,
	"$base/$sub_repo_dir/hosts/hosts.sh",
	"$base/$sub_repo_dir/up/up.sh",
	"$base/$sub_repo_dir/bulk/bulk.sh",
	"$base/$sub_repo_dir/Colortest/colortest",
	"$base/$sub_repo_dir/extract/extract.bash",
	"$base/$sub_repo_dir/gitprompt/gitprompt.pl"

	"$base/$repo_dir/git/config",
	"$base/$repo_dir/git/ignore",
	"$base/$repo_dir/git/attributes",
	"$base/$repo_dir/bash/rc",
	"$base/$repo_dir/bash/local/amazon", # TODO: Fix this to pick one based on CLI option
	"$base/$repo_dir/bash/profile",
	"$base/$repo_dir/bash/dir_colors",
	"$base/$repo_dir/bash/hush",
	"$base/$repo_dir/screen/rc",
	"$base/$repo_dir/vim/rc",
	"$base/$repo_dir/nvm/rc",
	"$base/$repo_dir/vnc/xstartup",
	"$base/$repo_dir/intellij/settings.jar",

	"$base/$repo_dir/git/completion.bash",
	"$base/$repo_dir/tree/tree.sh",
	"$base/$repo_dir/ssh/config",
	"$base/$repo_dir/ssh/authorized_keys";

# Symlink destinations
push @link_dest,
	"$bin/hosts",
	"$bin/up.sh",
	"$bin/bulk",
	"$bin/colortest",
	"$bin/extract",
	"$bin/gitprompt.pl",

	"$home/.gitconfig",
	"$home/.gitignore",
	"$home/.gitattributes",
	"$home/.bashrc",
	"$home/.bash_local",
	"$home/.bash_profile",
	"$home/.dir_colors",
	"$home/.hushlogin",
	"$home/.screenrc",
	"$home/.vimrc",
	"$home/.nvmrc",
	"$home/.vnc/xstartup",
#	"$home/.IntelliJIdea2022.3/config/settings.jar", # Currently using Intellij acct to store settings

	"$bin/git-completion.sh",
	"$bin/tree",
	"$home/.ssh/config",
	"$home/.ssh/authorized_keys";

# Setup directories
# TODO:  Add more verbosity here for non-error cases
if (!-e $home) { die "Home directory does not exist and should not be auto-created.\n" }
&createDir($base);

if (!-e "$base/$repo_dir") {
	system("cd $base && git clone $repo $repo_dir") == 0
		or die "Attempt to clone $repo into $base/$repo_dir failed: $?";
} elsif (!(&promptUser("$base/$repo_dir already exists.  Enter continue if the repo is already cloned, anything else to exit.", "continue")
		eq "continue")) {
	die "$base/$repo_dir already exists.  Please remove it or specify a new destination.\n";
}

&createDir("$base/$sub_repo_dir");
&createDir($bin);
&createDir("$home/.ssh");
&createDir("$home/.vnc");
#&createDir("$home/.IntelliJIdea2022.3/config");

# Clone subrepos
for my $i (@sub_repos) {
	$i =~ /\/(\w+)\.git$/; # Match is saved automatically into $1
	if (!$1 || !-e "$base/$sub_repo_dir/$1") {
		system("cd $base/$sub_repo_dir && git clone $i") == 0
			or print STDERR "Attempt to clone $i failed: $?\n";
	}
}

# Create symlinks
# TODO:  Add more verbosity here
my $count = 0;
for my $i (@link_source) {
	my $dest = $link_dest[$count];
	$count++;

	# Backup existing file
	if (-e $dest || -l $dest) {
		my $time = time();
		system("mv $dest $dest~$time") == 0
			or print STDERR "Attempt to rename existing file $dest failed: $?\n";
	}

	# Create new symlink
	system("ln -s $i $dest") == 0
		or print STDERR "Attempt to create symlink from $i to $dest failed: $?\n";
}

# Simple subroutine to avoid duplicating the logic to create a directory
sub createDir {
	my ($dir) = @_;
	if ($dir && !-e "$dir") {
		if (&promptUser("$dir does not exist.  Do you wish to create it?", "yes") eq "yes") {
			make_path("$dir");
		} else {
			die "$dir does not exist and was not created.  Please define a new destination.\n"; # Newline prevents location output
		}
	}
}

#----------------------------(  promptUser  )-----------------------------#
#                                                                         #
#  FUNCTION: promptUser                                                   #
#                                                                         #
#  PURPOSE: Prompt the user for some type of input, and return the        #
#           input back to the calling program.                            #
#                                                                         #
#  ARGS: $promptString - what you want to prompt the user with            #
#        $defaultValue - (optional) a default value for the prompt        #
#                                                                         #
#  AUTHOR: http://alvinalexander.com/perl/edu/articles/pl010005           #
#                                                                         #
#-------------------------------------------------------------------------#
sub promptUser {

	#-------------------------------------------------------------------#
	#  two possible input arguments - $promptString, and $defaultValue  #
	#  make the input arguments local variables.                        #
	#-------------------------------------------------------------------#
	my($promptString,$defaultValue) = @_;

	#-------------------------------------------------------------------#
	#  if there is a default value, use the first print statement; if   #
	#  no default is provided, print the second string.                 #
	#-------------------------------------------------------------------#
	if ($defaultValue) {
		print $promptString, "[", $defaultValue, "]: ";
	} else {
		print $promptString, ": ";
	}

	$| = 1;               # force a flush after our print
	$_ = <STDIN>;         # get the input from STDIN (presumably the keyboard)


	#------------------------------------------------------------------#
	# remove the newline character from the end of the input the user  #
	# gave us.                                                         #
	#------------------------------------------------------------------#
	chomp;

	#-----------------------------------------------------------------#
	#  if we had a $default value, and the user gave us input, then   #
	#  return the input; if we had a default, and they gave us no     #
	#  no input, return the $defaultValue.                            #
	#                                                                 #
	#  if we did not have a default value, then just return whatever  #
	#  the user gave us.  if they just hit the <enter> key,           #
	#  the calling routine will have to deal with that.               #
	#-----------------------------------------------------------------#
	if ("$defaultValue") {
		return $_ ? $_ : $defaultValue;    # return $_ if it has a value
	} else {
		return $_;
	}
}
