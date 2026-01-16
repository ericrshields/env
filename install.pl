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
my $repo = 'git@github.com:ericrshields/env.git';

# Home and bin for symlinks
my $home = <~>;
my $bin = <~/bin>;

# Installs the core repo at $home/$repo_dir
my $repo_dir = "env";

# Installs sub repos in dirs inside $home/$sub_repo_dir
my $sub_repo_dir = "env-sub";

push @sub_repos,
	'https://github.com/shannonmoeller/hosts.git',
	'https://github.com/shannonmoeller/up.git',
	'git@github.com:ericrshields/gitprompt.git';
#	'https://github.com/synacor/gitprompt.git'  //backup repo
#	'https://github.com/somegithubuser/env.git';  //backup repo
#	'https://github.com/mikecanz/env.git';  //Original source

# Symlink sources
push @link_source,
	"$home/$sub_repo_dir/hosts/hosts.sh",
	"$home/$sub_repo_dir/up/up.sh",
	"$home/$sub_repo_dir/gitprompt/gitprompt.pl",

	"$home/$repo_dir/git/config",
	"$home/$repo_dir/git/ignore",
	"$home/$repo_dir/git/attributes",
	"$home/$repo_dir/bash/rc",
	"$home/$repo_dir/bash/profile",
	"$home/$repo_dir/bash/dir_colors",
	"$home/$repo_dir/bash/hush",
	"$home/$repo_dir/screen/rc",
	"$home/$repo_dir/vim/rc",
	"$home/$repo_dir/nvm/rc",
	"$home/$repo_dir/vnc/xstartup",
#	"$home/$repo_dir/intellij/settings.jar",

	"$home/$repo_dir/ssh/config",
	"$home/$repo_dir/ssh/authorized_keys";

# Symlink destinations
push @link_dest,
	"$bin/hosts",
	"$bin/up.sh",
	"$bin/gitprompt.pl",

	"$home/.gitconfig",
	"$home/.gitignore",
	"$home/.gitattributes",
	"$home/.bashrc",
	"$home/.bash_profile",
	"$home/.dir_colors",
	"$home/.hushlogin",
	"$home/.screenrc",
	"$home/.vimrc",
	"$home/.nvmrc",
	"$home/.vnc/xstartup",
#	"$home/.IntelliJIdea2022.3/config/settings.jar", # Currently using Intellij acct to store settings

	"$home/.ssh/config",
	"$home/.ssh/authorized_keys";

# Setup directories
# TODO:  Add more verbosity here for non-error cases
if (!-e $home) { die "Home directory does not exist and should not be auto-created.\n" }

if (!-e "$home/$repo_dir") {
	system("cd $home && git clone $repo $repo_dir") == 0
		or die "Attempt to clone $repo into $home/$repo_dir failed: $?";
} elsif (!(&promptUser("$home/$repo_dir already exists.  Enter continue if the repo is already cloned, anything else to exit.", "continue")
		eq "continue")) {
	die "$home/$repo_dir already exists.  Please remove it or specify a new destination.\n";
}

&createDir("$home/$sub_repo_dir");
&createDir($bin);
&createDir("$home/.ssh");
&createDir("$home/.vnc");
#&createDir("$home/.IntelliJIdea2022.3/config");

# Create environment marker files for layered configuration
# Context layer: work machine marker (home is default)
if (&promptUser("Is this a work machine? (creates context marker)", "no") eq "yes") {
	open(my $fh, '>', "$home/$repo_dir/.env-marker-work") or die "Cannot create marker file: $!";
	close($fh);
	print "Created .env-marker-work marker file\n";
}

# Environment layer: cloud machine marker (WSL is auto-detected)
if (&promptUser("Is this a cloud instance? (creates environment marker)", "no") eq "yes") {
	open(my $fh, '>', "$home/$repo_dir/.env-marker-cloud") or die "Cannot create marker file: $!";
	close($fh);
	print "Created .env-marker-cloud marker file\n";
}

# Project layer: Create markers for specified projects
my $projects = &promptUser("Enter project names (space or comma separated, or 'none')", "none");
if ($projects ne "none") {
	# Split on spaces or commas and process each project
	my @project_list = split(/[\s,]+/, $projects);
	foreach my $project (@project_list) {
		# Trim whitespace
		$project =~ s/^\s+|\s+$//g;
		next if $project eq "";

		open(my $fh, '>', "$home/$repo_dir/.env-marker-project-$project") or die "Cannot create marker file: $!";
		close($fh);
		print "Created .env-marker-project-$project marker file\n";
	}
}

# Install recommended packages
print "\n--- Checking for recommended packages ---\n";

# Detect package manager
my $pkg_manager = "";
my $install_cmd = "";
my @pkg_check_cmd = ();

if (-e "/usr/bin/apt" || -e "/usr/bin/apt-get") {
	$pkg_manager = "apt";
	$install_cmd = "sudo apt install -y";
	@pkg_check_cmd = ("dpkg", "-l");
} elsif (-e "/usr/bin/yum") {
	$pkg_manager = "yum";
	$install_cmd = "sudo yum install -y";
	@pkg_check_cmd = ("rpm", "-q");
} else {
	print "Could not detect package manager (apt or yum). Skipping package installation.\n";
	goto SKIP_PACKAGES;
}

print "Detected package manager: $pkg_manager\n";

# Define recommended packages (with descriptions)
my %packages = (
	"tree" => "Directory tree viewer (replaces legacy shell script)",
	"dtrx" => "Intelligent archive extractor (replaces legacy extract script)",
);

# Check which packages are missing
my @missing_packages = ();
foreach my $pkg (keys %packages) {
	my $installed = 0;
	if ($pkg_manager eq "apt") {
		$installed = (system("dpkg -l $pkg 2>/dev/null | grep -q '^ii'") == 0);
	} elsif ($pkg_manager eq "yum") {
		$installed = (system("rpm -q $pkg >/dev/null 2>&1") == 0);
	}

	if ($installed) {
		print "  ✓ $pkg is already installed\n";
	} else {
		print "  ✗ $pkg is NOT installed - $packages{$pkg}\n";
		push @missing_packages, $pkg;
	}
}

# Install missing packages if any
if (@missing_packages) {
	print "\nMissing packages: " . join(", ", @missing_packages) . "\n";
	if (&promptUser("Would you like to install these packages now?", "yes") eq "yes") {
		my $packages_str = join(" ", @missing_packages);
		print "Running: $install_cmd $packages_str\n";
		my $result = system("$install_cmd $packages_str");
		if ($result == 0) {
			print "Successfully installed packages!\n";
		} else {
			print STDERR "Warning: Package installation failed with exit code $result\n";
			print STDERR "You can install manually later with: $install_cmd $packages_str\n";
		}
	} else {
		print "Skipping package installation. You can install manually later with:\n";
		print "  $install_cmd " . join(" ", @missing_packages) . "\n";
	}
} else {
	print "All recommended packages are already installed!\n";
}

SKIP_PACKAGES:
print "\n";

# Clone subrepos
for my $i (@sub_repos) {
	$i =~ /\/(\w+)\.git$/; # Match is saved automatically into $1
	if (!$1 || !-e "$home/$sub_repo_dir/$1") {
		system("cd $home/$sub_repo_dir && git clone $i") == 0
			or print STDERR "Attempt to clone $i failed: $?\n";
	}
}

# Add this before the symlink creation loop
if (scalar(@link_source) != scalar(@link_dest)) {
    die "Error: Number of source links (" . scalar(@link_source) .
        ") does not match number of destination links (" . scalar(@link_dest) . ")\n";
}

# Create symlinks
# TODO:  Add more verbosity here
my $count = 0;
for my $i (@link_source) {
	my $dest = $link_dest[$count];
	$count++;

	# Backup existing file (but not symlinks)
	if (-e $dest && !-l $dest) {
		my $time = time();
		system("mv $dest $dest~$time") == 0
			or print STDERR "Attempt to rename existing file $dest failed: $?\n";
	} elsif (-l $dest) {
		# Remove existing symlink without backing up
		unlink($dest) or print STDERR "Attempt to remove existing symlink $dest failed: $!\n";
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
