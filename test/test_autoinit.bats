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
#  run gh repo deploy-key list --repo ${PUBLISHED_REPO_ORG}/${PUBLISHED_REPO_NAME} --json title --jq '.[].title'
#  assert_line --partial '${REPO_ORG}/${REPO_NAME}'
#}

@test "TestSpace Project is created" {
  refute [ -z "${TESTSPACE_SPACE_ID}" ]
  url_api="https://${REPO_ORG}.testspace.com/api/projects/${TESTSPACE_SPACE_ID}"
  http_response=$(curl -o response.txt -w "%{response_code}" --no-progress-meter -H "Authorization: Token ${TESTSPACE_TOKEN}" "$url_api")
  assert_equal "$http_response" "200"
}

@test "default branch protection is used" {
  run -0 gh api "repos/${REPO_ORG}/${REPO_NAME}/branches/main/protection" --method GET
  dismiss_stale_reviews=$(jq -r .required_pull_request_reviews.dismiss_stale_reviews <<<"$output")
  assert_equal "$dismiss_stale_reviews" "false"
  require_code_owner_reviews=$(jq -r .required_pull_request_reviews.require_code_owner_reviews <<<"$output")
  assert_equal "$require_code_owner_reviews" "false"
  required_approving_review_count=$(jq -r .required_pull_request_reviews.required_approving_review_count <<<"$output")
  assert_equal "$required_approving_review_count" "0"
  required_status_checks_strict=$(jq -r .required_status_checks.strict <<<"$output")
  assert_equal "$required_status_checks_strict" "false"
  required_conversation_resolution=$(jq -r .required_conversation_resolution.enabled <<<"$output")
  assert_equal "$required_conversation_resolution" "true"
  enforce_admins=$(jq -r .enforce_admins.enabled <<<"$output")
  assert_equal "$enforce_admins" "true"

  run -0 gh api "repos/${REPO_ORG}/${REPO_NAME}/branches/develop/protection" --method GET
  dismiss_stale_reviews=$(jq -r .required_pull_request_reviews.dismiss_stale_reviews <<<"$output")
  assert_equal "$dismiss_stale_reviews" "false"
  require_code_owner_reviews=$(jq -r .required_pull_request_reviews.require_code_owner_reviews <<<"$output")
  assert_equal "$require_code_owner_reviews" "false"
  required_approving_review_count=$(jq -r .required_pull_request_reviews.required_approving_review_count <<<"$output")
  assert_equal "$required_approving_review_count" "0"
  required_status_checks_strict=$(jq -r .required_status_checks.strict <<<"$output")
  assert_equal "$required_status_checks_strict" "false"
  required_conversation_resolution=$(jq -r .required_conversation_resolution.enabled <<<"$output")
  assert_equal "$required_conversation_resolution" "true"
  enforce_admins=$(jq -r .enforce_admins.enabled <<<"$output")
  assert_equal "$enforce_admins" "true"
}

# bats file_tags=common
@test "Template Resolution is done on default branch" {
  if [ ! -d "${REPO_NAME}" ]; then
    git clone "https://github.com/${REPO_ORG}/${REPO_NAME}.git" "${REPO_NAME}"
  fi
  cd "${REPO_NAME}" || exit
  assert_file_exist ./README.md
  assert_file_contains ./README.md "Repo: ${REPO_ORG}/${REPO_NAME}"
  assert_file_contains ./README.md "TestSpaceId: ${TESTSPACE_SPACE_ID}"
  assert_file_contains ./README.md "CIReportRepoPath: ${PUBLISHED_REPO_ORG}/${PUBLISHED_REPO_NAME}"
  cd ..
}

@test "Template Resolution without data file and with specific Undefined Behavior" {
  if [ ! -d "${REPO_NAME}" ]; then
    git clone "https://github.com/${REPO_ORG}/${REPO_NAME}.git" "${REPO_NAME}"
  fi
  cd "${REPO_NAME}" || exit
  assert_file_exist ./README.md
  assert_file_contains ./README.md "FromFile: {{ MY_VAR_FROM_FILE }}\+$"
  cd ..
}

@test "Template Resolution without url file and with specific Undefined Behavior" {
  if [ ! -d "${REPO_NAME}" ]; then
    git clone "https://github.com/${REPO_ORG}/${REPO_NAME}.git" "${REPO_NAME}"
  fi
  cd "${REPO_NAME}" || exit
  assert_file_exist ./README.md
  assert_file_contains ./README.md "FromUrl: {{ URL_KEY_2 }} {{ URL_KEY_1 }}$"
  cd ..
}

@test "Workflow File is deleted" {
  if [ ! -d "${REPO_NAME}" ]; then
    git clone "https://github.com/${REPO_ORG}/${REPO_NAME}.git" "${REPO_NAME}"
  fi
  cd "${REPO_NAME}" || exit
  assert_file_not_exist .github/workflows/auto_init.yml
  cd ..
}

@test "Directories are renamed" {
  if [ ! -d "${REPO_NAME}" ]; then
    git clone "https://github.com/${REPO_ORG}/${REPO_NAME}.git" "${REPO_NAME}"
  fi
  cd "${REPO_NAME}" || exit
  assert_file_not_exist "\$test_dir/.gitkeep"
  assert_file_exist test_dir/.gitkeep
  assert_file_not_exist ".github/\$test_subdir/.gitkeep"
  assert_file_exist .github/test_subdir/.gitkeep
  # Following assertion added for bug gh-014
  assert_file_not_exist .newtest/.gitkeep
  assert_file_exist .newtest/.gitkeep2
}

@test "Template Resolution keeps the original template file" {
  if [ ! -d "${REPO_NAME}" ]; then
    git clone "https://github.com/${REPO_ORG}/${REPO_NAME}.git" "${REPO_NAME}"
  fi
  cd "${REPO_NAME}" || exit
  assert_file_exist ./README.md.j2
  cd ..
}

@test "A PR is not open for the Template Resolution" {
  run gh pr list --repo "${REPO_ORG}/${REPO_NAME}" --json title,headRefName,baseRefName
  assert_line "[]"
}
