## Scripting language

- Prefer Ruby over Python for new standalone scripts, automation, and supporting
  tests. Keep simple shell glue in shell.
- Follow the existing language and conventions when extending a project.
- Use Python when the task explicitly requires it or an existing Python codebase
  makes it the natural choice; otherwise, default to Ruby.

## Git workflow

- Do not push directly to `main`, `master`, or the repository's default branch
  unless I explicitly ask you to do so. Permission to implement, commit, or open
  a PR is not permission to push directly to those branches.
- Prefer topic branches for implementation. If publishing work from a default
  branch without direct-push permission, create a topic branch and open a PR.
- On a topic branch, you may make signed commits, push that branch, and open or
  update a PR without a separate approval when the work reaches a coherent,
  reviewable milestone and relevant checks pass. Include only intended changes,
  summarize validation, and disclose remaining work or known limitations.
- Use a draft PR if the milestone is useful to review but the overall work is
  not ready to merge. Do not publish unfinished or unvalidated work as merge-ready.
- Respect explicit commit-only, local-only, or do-not-push requests. Never merge
  a PR or force-push without explicit permission.
- Never disable commit signing. If signing fails, stop and ask me to fix it.
