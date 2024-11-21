#!/usr/bin/env bats

# Waited Env. Variable:
# - REPO_NAME: Name of the Repo (without the owner) and of the local directory contening its clone
# - REPO_ORG: Name of the Repo Owner
# - TEST_UUID_FILE: Name of the file (inside REPO_NAME directory) contening the UUID
# - WAITED_UUID: UUID value that musy be fond in the ${TEST_UUID_FILE}
# - TESTSPACE_SPACE_ID: TestSpae Id that should be created
# - TESTSPACE_TOKEN: TestSpace token to used for WabApi authentification
# - PUBLISHED_REPO_ORG: Owner of the Published Repo
# - PUBLISHED_REPO_NAME: Name of the Published Repo
# - GH_TOKEN: Token used by gh cli

setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  load 'test_helper/bats-file/load'
}

@test "A new secret is created to store the ssh private key" {
  run gh secret list --repo "${REPO_ORG}/${REPO_NAME}" --json name --jq '.[].name'
  assert_line --partial 'PUBLISHING_KEY'
}

#@test "Deployment key is defined" {
#  run gh repo deploy-key list --repo "${PUBLISHED_REPO_ORG}/${PUBLISHED_REPO_NAME}" --json title --jq '.[].title'
#  assert_line --partial '${REPO_ORG}/${REPO_NAME}'
#}

@test "TestSpace Project is not created" {
  url_api="https://${REPO_ORG}.testspace.com/api/projects"
  run curl --no-progress-meter -H "Authorization: Token ${TESTSPACE_TOKEN}" "$url_api"
  refute_output --partial "${REPO_ORG}/${REPO_NAME}"
}

@test "Template Resolution is done on a new branch without testspace information" {
  git clone "https://github.com/${REPO_ORG}/${REPO_NAME}.git" "${REPO_NAME}"
  cd "${REPO_NAME}" || exit
  git fetch
  git switch test_not_existing_branch
  assert_file_exist ./README.md
  assert_file_contains ./README.md "TestSpaceId:[[:space:]]\+$"
  cd ..
}

@test "A PR is not open for the Template Resolution" {
  run gh pr list --repo "${REPO_ORG}/${REPO_NAME}" --json title,headRefName,baseRefName
  assert_line "[]"
}
