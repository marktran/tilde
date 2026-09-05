---
name: commit
description: "Read this skill before making git commits"
---

Create a git commit for the current changes using a concise Conventional Commits-style subject.

## Format

`<type>(<scope>): <summary>`

- `type` REQUIRED. Use `feat` for new features, `fix` for bug fixes. Other common types: `docs`, `refactor`, `chore`, `test`, `perf`.
- `scope` OPTIONAL. Short noun in parentheses for the affected area (e.g., `api`, `parser`, `ui`).
- `summary` REQUIRED. Short, imperative, <= 72 chars, no trailing period.

## Notes

- Body is OPTIONAL. If needed, add a blank line after the subject and write short paragraphs.
- Do NOT include breaking-change markers or footers.
- Do NOT add sign-offs (no `Signed-off-by`).
- Publishing follows the user's Git workflow policy; do not assume every commit must be pushed.
- Do not push directly to `main`, `master`, or the repository's default branch unless the user explicitly asks. An instruction to commit or open a PR is not direct-push permission.
- On a topic branch, a coherent, reviewable milestone with relevant checks passing may be pushed and proposed as a PR without a separate approval. Use a draft PR if more work remains; summarize validation and limitations.
- Honor explicit commit-only, local-only, and do-not-push instructions. Never merge a PR or force-push without explicit permission.
- Sign commits. If signing fails, stop rather than disabling signing.
- If it is unclear whether a file should be included, ask the user which files to commit.
- Split unrelated changes into separate logical commits instead of bundling them together.
- Treat any caller-provided arguments as additional commit guidance. Common patterns:
  - Freeform instructions should influence scope, summary, and body.
  - File paths or globs should limit which files to commit. If files are specified, only stage/commit those unless the user explicitly asks otherwise.
  - If arguments combine files and instructions, honor both.

## Steps

1. Infer from the prompt if the user provided specific file paths/globs and/or additional instructions.
2. Review `git status` and `git diff` to understand the current changes (limit to argument-specified files if provided).
3. (Optional) Run `git log -n 50 --pretty=format:%s` to see commonly used scopes.
4. If there are ambiguous extra files, ask the user for clarification before committing.
5. Stage only the intended files for the next logical commit (all related changes if no files specified).
6. Run `git commit -m "<subject>"` (and `-m "<body>"` if needed).
7. Repeat staging and committing for each unrelated logical change.
8. If publishing is appropriate under the user's Git workflow policy, push the topic branch and open or update its PR. If on a default branch without explicit direct-push permission, create a topic branch first. Otherwise, report the local commit without pushing.
