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

# bats file_tags=test_from_template
@test "The specified repository is created from the specified template" {
  if [ ! -d "${REPO_NAME}" ]; then
    git clone https://github.com/${REPO_ORG}/${REPO_NAME}.git ${REPO_NAME}
  fi
  assert_file_exist ./${REPO_NAME}/${TEST_UUID_FILE}
  content=$(cat ./${REPO_NAME}/${TEST_UUID_FILE})
  assert_equal $content ${WAITED_UUID}
}

# bats file_tags=common
@test "A new secret is created to store the ssh private key" {
  run gh secret list --repo ${REPO_ORG}/${REPO_NAME} --json name --jq '.[].name'
  assert_line --partial 'PUBLISHING_KEY'
}

#@test "Deployment key is defined" {
#  run gh repo deploy-key list --repo ${PUBLISHED_REPO_ORG}/${PUBLISHED_REPO_NAME} --json title --jq '.[].title'
#  assert_line --partial '${REPO_ORG}/${REPO_NAME}'
#}

# bats file_tags=common
@test "TestSpace Project is created" {
  refute [ -z "${TESTSPACE_SPACE_ID}" ]
  url_api="https://${REPO_ORG}.testspace.com/api/projects/${TESTSPACE_SPACE_ID}"
  http_response=$(curl -o response.txt -w "%{response_code}" --no-progress-meter  -H "Authorization: Token ${TESTSPACE_TOKEN}" "$url_api")
  assert_equal "$http_response" "200"
}

# bats file_tags=common
@test "develop branch is created on the repository" {
  if [ ! -d "${REPO_NAME}" ]; then
    git clone https://github.com/${REPO_ORG}/${REPO_NAME}.git ${REPO_NAME}
  fi
  cd ${REPO_NAME}
  existed_in_remote=$(git ls-remote --heads origin develop)
  [[ ! -z ${existed_in_remote} ]]
  cd ..
}

# bats file_tags=common
@test "main branch is correctly protected" {
  run -0 gh api "repos/${REPO_ORG}/${REPO_NAME}/branches/main/protection" --method GET
  dismiss_stale_reviews=$(jq -r .required_pull_request_reviews.dismiss_stale_reviews <<< $output)
  assert_equal "$dismiss_stale_reviews" "false"
  require_code_owner_reviews=$(jq -r .required_pull_request_reviews.require_code_owner_reviews <<< $output)
  assert_equal "$require_code_owner_reviews" "false"
  required_approving_review_count=$(jq -r .required_pull_request_reviews.required_approving_review_count <<< $output)
  assert_equal "$required_approving_review_count" "0"
  required_status_checks_strict=$(jq -r .required_status_checks.strict <<< $output)
  assert_equal "$required_status_checks_strict" "false"
  required_conversation_resolution=$(jq -r .required_conversation_resolution.enabled <<< $output)
  assert_equal "$required_conversation_resolution" "true"
  enforce_admins=$(jq -r .enforce_admins.enabled <<< $output)
  assert_equal "$enforce_admins" "true"
}

# bats file_tags=common
@test "develop branch is correctly protected" {
  run -0 gh api "repos/${REPO_ORG}/${REPO_NAME}/branches/develop/protection" --method GET
  dismiss_stale_reviews=$(jq -r .required_pull_request_reviews.dismiss_stale_reviews <<< $output)
  assert_equal "$dismiss_stale_reviews" "false"
  require_code_owner_reviews=$(jq -r .required_pull_request_reviews.require_code_owner_reviews <<< $output)
  assert_equal "$require_code_owner_reviews" "false"
  required_approving_review_count=$(jq -r .required_pull_request_reviews.required_approving_review_count <<< $output)
  assert_equal "$required_approving_review_count" "0"
  required_status_checks_strict=$(jq -r .required_status_checks.strict <<< $output)
  assert_equal "$required_status_checks_strict" "false"
  required_conversation_resolution=$(jq -r .required_conversation_resolution.enabled <<< $output)
  assert_equal "$required_conversation_resolution" "true"
  enforce_admins=$(jq -r .enforce_admins.enabled <<< $output)
  assert_equal "$enforce_admins" "true"
}

# bats file_tags=common
@test "Template Resolution is done on a dedicated branch" {
  if [ ! -d "${REPO_NAME}" ]; then
    git clone https://github.com/${REPO_ORG}/${REPO_NAME}.git ${REPO_NAME}
  fi
  cd ${REPO_NAME}
  git fetch
  git switch template_resolution
  assert_file_exist ./README.md
  assert_file_contains ./README.md "Repo: ${REPO_ORG}/${REPO_NAME}"
  assert_file_contains ./README.md "TestSpaceId: ${TESTSPACE_SPACE_ID}"
  assert_file_contains ./README.md "CIReportRepoPath: ${PUBLISHED_REPO_ORG}/${PUBLISHED_REPO_NAME}"
  cd ..
}

# bats file_tags=test_data_file
@test "Template Resolution use data file" {
  if [ ! -d "${REPO_NAME}" ]; then
    git clone https://github.com/${REPO_ORG}/${REPO_NAME}.git ${REPO_NAME}
  fi
  cd ${REPO_NAME}
  git fetch
  git switch template_resolution
  assert_file_exist ./README.md
  assert_file_contains ./README.md "FromFile: ValueFromFile"
  cd ..
}

# bats file_tags=test_no_data_file
@test "Template Resolution without data file" {
  if [ ! -d "${REPO_NAME}" ]; then
    git clone https://github.com/${REPO_ORG}/${REPO_NAME}.git ${REPO_NAME}
  fi
  cd ${REPO_NAME}
  git fetch
  git switch template_resolution
  assert_file_exist ./README.md
  assert_file_contains ./README.md "FromFile:[[:space:]]\+$"
  cd ..
}

# bats file_tags=common
@test "Workflow File is deleted" {
  if [ ! -d "${REPO_NAME}" ]; then
    git clone https://github.com/${REPO_ORG}/${REPO_NAME}.git ${REPO_NAME}
  fi
  cd ${REPO_NAME}
  git fetch
  git switch template_resolution
  assert_file_not_exist .github/workflows/auto_init.yml
  cd ..
}

# bats file_tags=common
@test "Directories are renamed" {
  if [ ! -d "${REPO_NAME}" ]; then
    git clone https://github.com/${REPO_ORG}/${REPO_NAME}.git ${REPO_NAME}
  fi
  cd ${REPO_NAME}
  git fetch
  git switch template_resolution
  assert_file_not_exist $test_dir/.gitkeep
  assert_file_exist test_dir/.gitkeep
  assert_file_not_exist .github/$test_subdir/.gitkeep
  assert_file_exist .github/test_subdir/.gitkeep
  # Following assertion added for bug gh-014
  assert_file_not_exist .newtest/.gitkeep
  assert_file_exist .newtest/.gitkeep2
}

# bats file_tags=test_keep_template
@test "Template Resolution keeps the original template file" {
  if [ ! -d "${REPO_NAME}" ]; then
    git clone https://github.com/${REPO_ORG}/${REPO_NAME}.git ${REPO_NAME}
  fi
  cd ${REPO_NAME}
  git fetch
  git switch template_resolution
  assert_file_exist ./README.md.j2
  cd ..
}

# bats file_tags=test_not_keep_template
@test "Template Resolution does not keep the original template file" {
  if [ ! -d "${REPO_NAME}" ]; then
    git clone https://github.com/${REPO_ORG}/${REPO_NAME}.git ${REPO_NAME}
  fi
  cd ${REPO_NAME}
  git fetch
  git switch template_resolution
  assert_file_not_exist ./README.md.j2
  cd ..
}

# bats file_tags=common
@test "A PR is open for the Template Resolution" {
  run gh pr list --repo ${REPO_ORG}/${REPO_NAME} --json title,headRefName,baseRefName
  assert_line --partial '"baseRefName":"develop"'
  assert_line --partial '"headRefName":"template_resolution"'
  assert_line --partial '"title":"Dynamic Template Resolution"'
}