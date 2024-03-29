#!/bin/bash

# This script is used to release a new version of the Skyline CLI.

set -e

function check_tools() {
  if [ -z "$(which python3)" ]; then
    echo_red "ERROR: Python 3.6+ (python3) must be installed."
    exit 1
  fi

  if [ -z "$(which pip3)" ]; then
    echo_red "ERROR: Pip for Python 3 (pip3) must be installed."
    exit 1
  fi

  set +e
  $(python3 -c "import pep517" 2> /dev/null > /dev/null)
  pep517_exists=$?
  set -e

  if [ $pep517_exists -ne 0 ]; then
    echo_red "ERROR: The pep517 module (used for building wheels) was not found."
    exit 1
  fi

  if [ -z "$(which twine)" ]; then
    echo_red "ERROR: Twine (used for uploading wheels to PyPI) must be installed."
    exit 1
  fi

  echo_green "✓ Release tooling OK"
}

function build_release() {
  pushd ../cli

  echo_yellow "> Building wheels..."
  rm -rf build dist
  python3 -m pep517.build .
  echo_green "✓ Wheels successfully built"

  popd
}

function upload_release() {
  pushd ../cli

  echo ""
  echo_yellow "> Uploading release to PyPI..."
  twine upload -r pypi "dist/skyline_cli-${NEXT_CLI_VERSION}*"
  echo_green "✓ New release uploaded to PyPI"

  echo ""
  echo_yellow "> Creating a release tag..."
  git tag -a "$VERSION_TAG" -m ""
  git push --follow-tags
  echo_green "✓ Git release tag created and pushed to GitHub"

  popd
}

function main() {
  echo ""
  echo_blue "Skyline CLI Release Tool"
  echo_blue "========================"

  echo ""
  echo_yellow "> Checking the Skyline monorepo (this repository)..."
  check_monorepo

  echo ""
  echo_yellow "> Checking tools..."
  check_tools

  echo ""
  echo_yellow "> Tooling versions:"
  echo "$(python3 --version)"
  echo "$(pip3 --version)"
  echo "$(twine --version)"

  NEXT_CLI_VERSION=$(cd ../cli && python3 -c "import skyline; print(skyline.__version__)")
  VERSION_TAG="v$NEXT_CLI_VERSION"
  REPO_HASH=$(get_monorepo_hash)

  echo ""
  echo_yellow "> The next CLI version will be '$VERSION_TAG'."
  prompt_yn "> Is this correct? (y/N) "

  build_release
  if [ "$1" != "--deploy" ]; then
    echo ""
    echo_yellow "Skipping the upload to PyPI and GitHub since the --deploy flag was not used."
    echo_green "✓ Done!"
    exit 0
  fi

  echo ""
  echo_yellow "> This tool will release the CLI code at commit hash '$REPO_HASH'."
  prompt_yn "> Do you want to continue? This is the final confirmation step. (y/N) "

  echo ""
  echo_yellow "> Releasing $VERSION_TAG of the CLI..."
  upload_release

  echo_green "✓ Done!"
}

RELEASE_SCRIPT_PATH=$(cd $(dirname $0) && pwd -P)
cd $RELEASE_SCRIPT_PATH
source shared.sh

main $@
