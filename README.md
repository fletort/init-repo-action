# init-repo-action
Internal (personal) Action to Init my Repositories following my internal rules  

[![Continuous Testing](https://github.com/fletort/init-repo-action/actions/workflows/test.yml/badge.svg)](https://github.com/fletort/init-repo-action/actions/workflows/test.yml)

This personal action was created to can have an unique code/procedure to create my
repor whatever the context.

Actually my repositories can be created from:
- _a repository tool_ as my [dynamic-template-tool action](https://github.com/fletort/dynamic-template-tool),
- or as a Dynamic Template: directly from the template creation procedure as in
my [template-common-js](https://github.com/fletort/template-common-js). This
last case is only possible when the new repositories is created inside an
organization, where needed secrets can be available globally.

## Behaviour

- Create the new repository defined by `repository` from the specified `template` (if asked)
- Checkout the new repository defined by `repository`
- Manage ssh cnx to the repository specified by `repository_deployment` with the help of the
[generate-ssh-deploy-repo-action](https://github.com/fletort/generate-ssh-deploy-repo-action) action.
- Create the linked TestSpace Project with the help of the
[fletort/testspace-create-action](https://github.com/fletort/testspace-create-action) action in the specified `testspace_domain`
- Create a develop branch on the new repository
- Define main and develop branch protection
- Manage Dynamic Template Substitution with the help of the
[fletort/template-common-js](https://github.com/fletort/template-common-js) action.
- Remove AutoInit Workflow (this feature can be disabled with the `delete-workflow` option):
  - on a Dynamic Template (repo that init itself), the current workflow file (calling the current action) is deleted
  - on a tool behaviour (repo targeted is not the repo calling the action), workflow contening a call to the current action are deleted
    (such workflow exist if the repo is created from a Template with Dynamic Feature)
- Rename all directorie from the template that beging with the `$` character.
For example the `$.github` directory will be renamed to `.github`.
If the final directory exists, it is replaced with the content of the renamed directory.
- Create the Pull Request for this Template resolution code modification
with the help of [peter-evans/create-pull-request](https://github.com/peter-evans/create-pull-request) action.

We recommend using a service account with the least permissions necessary. Also
when generating a new PAT, select the least scopes necessary.
[Learn more about creating and using encrypted secrets](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/creating-and-using-encrypted-secrets)

## Usage

### Used as a tool

```yaml
- uses: fletort/init-repo-action@v1
  with:
    repository: owner/my_repo_to_create
    template: owner/my_template_repo
    repository_deployment: owner/repo_on_which_we_can_deploy
    token: ${{ secrets.PAT }}
    testspace_token: ${{ secrets.TESTSPACE_TOKEN }}
    testspace_domain: testspace_domain
```
You can also pin to a [specific release](https://github.com/fletort/init-repo-action/releases) version in the format `@v1.x.x`

### Used from a repo that init itself

```yaml
- uses: fletort/init-repo-action@v1
  with:
    repository_deployment: owner/repo_on_which_we_can_deploy
    token: ${{ secrets.PAT }}
    testspace_token: ${{ secrets.TESTSPACE_TOKEN }}
```
You can also pin to a [specific release](https://github.com/fletort/init-repo-action/releases) version in the format `@v1.x.x`

To have a dynamic template feature like you can call this action on the `create` event:
```yaml
name: Init Repository and Resolve Dynamic Template
on:
  - create

jobs:
  init_repo:
    name: Init Repository
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - name: Checkout
        id: checkout
        uses: fletort/init-repo-action@v1
        with:
          repository_deployment: owner/repo_on_which_we_can_deploy
          token: ${{ secrets.PAT }}
          testspace_token: ${{ secrets.TESTSPACE_TOKEN }}
```

See my template-common-js [template init workflow](https://github.com/fletort/template-common-js/blob/main/.github/workflows/init_repo.yml) for an up to date Dynamic Template worflow 


### Actions inputs

Only inputs specified in the "init itself" usage upper are mandatories.
All other inputs are **optional**.

| Name | Description | Default |
| ---- | ----------- | ------- |
| `repository` | Repository to create and/or init. Indicate the repository name with owner. | `${{ github.repository }}` |
| `template` | Template Repository to use to create the repository. Indicate the repository name with owner. If the repository is already created, indicates `no_init`  | `no_init` |
| `repository_deployment` | Repository on which `repository` will be able to deploy to through ssh credentials. Indicate the repository name with owner. | **MANDATORY** |
| `token` | The token that action (and used actions) will use. See token. | **MANDATORY** |
| `testspace_token` | Personal testspace token used to interact with the testspace API to create the project | **MANDATORY** |
| `testspace_domain` | Testspace SubDomain where the testspace project will be created | `${{ github.repository_owner }}` |
| `delete_workflow` | Indicates if the workflow contening the call to this action must be deleted | `true`|

#### token

The token must have the following permissions:
- 'Repository  Administration': 
   - To can create the `repository` (if requested i.e. if a template is defined)
   - To be able to add a publish key to the `repository_deployment`
- 'Repository  Contents': To be able to Fetch the `repository` and commit to the `repository`
- 'Repository  Secrets': Store secret inside the `repository`
- 'Repository  Pull Requests': To be able to create the PR on the `repository` with the template resolution

## Code Quality

All unit/functional test executed on each branch/PR are listed/described on
[ this testspace space](https://fletort.testspace.com/projects/68169/spaces).

2 functionals (integration) testsuites are executed on github pipelines
![alt](./test/img/pipeline.png)

and tests results are send to TestSpace:

![alt](./test/img/testspace_suites.png)

For exemple the "tool" test suite contains the following tests:

![alt](./test/img/testspace_tool_scenary.png)


- The **Tool scenario** tests the role in ["a tool way"](#used-as-a-tool), i.e. targeting a remote repository that is created by the role itself.
- The **AutoInit scenario** tests the role in ["Dynamic Template way"](#used-from-a-repo-that-init-itself), i.e. a repository that is using the role on itself.
- The **publishing feature** is tested only in one of the scenario, and appears as a third _test suite_ on TestSpace side.

## License

The scripts and documentation in this project are released under the
[MIT License](LICENSE)

