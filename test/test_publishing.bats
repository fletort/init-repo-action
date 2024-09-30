#!/usr/bin/env bats

# Waited Env. Variable:
# - TEST_UUID_FILE: Name of the file (inside REPO_NAME directory) contening the UUID
# - WAITED_UUID: UUID value that musy be fond in the ${TEST_UUID_FILE}
# - PUBLISHED_REPO_NAME: Name of the Published Repo

setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    load 'test_helper/bats-file/load'
}

@test "Deployment can be made between the new repo and the repository_deployment" {
  assert_file_exist ./${PUBLISHED_REPO_NAME}/${TEST_UUID_FILE}
  content=$(cat ./${PUBLISHED_REPO_NAME}/${TEST_UUID_FILE})
  assert_equal $content ${WAITED_UUID}
}
