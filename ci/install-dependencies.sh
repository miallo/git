#!/bin/sh
#
# Install dependencies required to build and test Git on Linux and macOS
#

. ${0%/*}/lib.sh

P4WHENCE=https://cdist2.perforce.com/perforce/r21.2
LFSWHENCE=https://github.com/github/git-lfs/releases/download/v$LINUX_GIT_LFS_VERSION

# Make sudo a no-op and execute the command directly when running as root.
# While using sudo would be fine on most platforms when we are root already,
# some platforms like e.g. Alpine Linux do not have sudo available by default
# and would thus break.
if test "$(id -u)" -eq 0
then
	sudo () {
		"$@"
	}
fi

case "$distro" in
ubuntu-*)
	sudo apt-get -q update
	sudo apt-get -q -y install \
		language-pack-is libsvn-perl apache2 \
		make libssl-dev libcurl4-openssl-dev libexpat-dev \
		tcl tk gettext zlib1g-dev perl-modules liberror-perl libauthen-sasl-perl \
		libemail-valid-perl libio-socket-ssl-perl libnet-smtp-ssl-perl \
		$CC_PACKAGE $PYTHON_PACKAGE

	mkdir --parents "$P4_PATH"
	wget --quiet --directory-prefix="$P4_PATH" \
		"$P4WHENCE/bin.linux26x86_64/p4d" "$P4WHENCE/bin.linux26x86_64/p4"
	chmod u+x "$P4_PATH/p4d" "$P4_PATH/p4"

	mkdir --parents "$GIT_LFS_PATH"
	wget --quiet "$LFSWHENCE/git-lfs-linux-amd64-$LINUX_GIT_LFS_VERSION.tar.gz"
	tar -xzf "git-lfs-linux-amd64-$LINUX_GIT_LFS_VERSION.tar.gz" \
		-C "$GIT_LFS_PATH" --strip-components=1 "git-lfs-$LINUX_GIT_LFS_VERSION/git-lfs"
	rm "git-lfs-linux-amd64-$LINUX_GIT_LFS_VERSION.tar.gz"
	;;
macos-*)
	export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1
	# Uncomment this if you want to run perf tests:
	# brew install gnu-time
	test -z "$BREW_INSTALL_PACKAGES" ||
	brew install $BREW_INSTALL_PACKAGES
	brew link --force gettext

	mkdir -p "$P4_PATH"
	wget -q "$P4WHENCE/bin.macosx1015x86_64/helix-core-server.tgz" &&
	tar -xf helix-core-server.tgz -C "$P4_PATH" p4 p4d &&
	sudo xattr -d com.apple.quarantine "$P4_PATH/p4" "$P4_PATH/p4d" 2>/dev/null || true
	rm helix-core-server.tgz

	if test -n "$CC_PACKAGE"
	then
		BREW_PACKAGE=${CC_PACKAGE/-/@}
		brew install "$BREW_PACKAGE"
		brew link "$BREW_PACKAGE"
	fi
	;;
esac

case "$jobname" in
StaticAnalysis)
	sudo apt-get -q update
	sudo apt-get -q -y install coccinelle libcurl4-openssl-dev libssl-dev \
		libexpat-dev gettext make
	;;
sparse)
	sudo apt-get -q update -q
	sudo apt-get -q -y install libssl-dev libcurl4-openssl-dev \
		libexpat-dev gettext zlib1g-dev
	;;
Documentation)
	sudo apt-get -q update
	sudo apt-get -q -y install asciidoc xmlto docbook-xsl-ns make

	test -n "$ALREADY_HAVE_ASCIIDOCTOR" ||
	sudo gem install --version 1.5.8 asciidoctor
	;;
esac

if type p4d >/dev/null 2>&1 && type p4 >/dev/null 2>&1
then
	echo "$(tput setaf 6)Perforce Server Version$(tput sgr0)"
	p4d -V
	echo "$(tput setaf 6)Perforce Client Version$(tput sgr0)"
	p4 -V
else
	echo >&2 "WARNING: perforce wasn't installed, see above for clues why"
fi
if type git-lfs >/dev/null 2>&1
then
	echo "$(tput setaf 6)Git-LFS Version$(tput sgr0)"
	git-lfs version
else
	echo >&2 "WARNING: git-lfs wasn't installed, see above for clues why"
fi
