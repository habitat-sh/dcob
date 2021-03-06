pkg_name=dcob
pkg_origin=chef_community_engineering
pkg_description="This is a github bot to ensure every commit on a PR has the
  Signed-off-by attribution required by the Developer Certificate of Origin."
pkg_upstream_url=https://github.com/habitat-sh/dcob
pkg_maintainer="Chef Community Engineering Team <community@chef.io>"
pkg_license=('MIT')
pkg_deps=(
  core/cacerts
  core/coreutils
  core/ruby
)
pkg_build_deps=(
  core/git
  core/gcc
  core/openssl
  core/make
)
pkg_bin_dirs=(bin)
pkg_expose=(4567)

pkg_version() {
  # Ask the DCOB gem what version it is. Use that as the hab package version.
  # Only have to set/bump version in one place like we would for any gem.
  ruby -I$PLAN_CONTEXT/../src/lib/dcob -rversion -e 'puts Dcob::VERSION'
}

do_before() {
  do_default_before
  update_pkg_version
}

do_download() {
  # Instead of downloading, build a gem based on the source in src/
  cd $PLAN_CONTEXT/../src
  gem build $pkg_name.gemspec
}

do_verify() {
  # No download to verify.
  return 0
}

do_unpack() {
  # Unpack the gem we built to the source cache path. Building then unpacking
  # the gem reuses the file inclusion/exclusion rules defined in the gemspec.
  gem unpack $PLAN_CONTEXT/../src/$pkg_name-$pkg_version.gem --target=$HAB_CACHE_SRC_PATH
}

do_build() {
  cd $CACHE_PATH
  export GIT_DIR=$PLAN_CONTEXT/../.git # appease the git command in the gemspec
  export BUNDLE_SILENCE_ROOT_WARNING=1 GEM_PATH

  gem install bundler --no-ri --no-rdoc

  bundle install --jobs "$(nproc)" --retry 5 --standalone \
    --without development \
    --path "bundle" \
    --binstubs
}

do_install () {
  cd $CACHE_PATH
  fix_interpreter "bin/*" core/coreutils bin/env
  cp -a "." "$pkg_prefix"
}
