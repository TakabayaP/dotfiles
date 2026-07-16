# Agent instructions

## GitHub operations

- Keep local inspection, edits, and validation inside the sandbox when possible.
- For GitHub operations that need network access or credentials (`gh`, GitHub API
  tools, `git push`), a failure caused by the sandbox must not be treated as an
  invalid user login. Retry the same operation outside the sandbox with elevated
  permissions before asking the user to re-authenticate.
- In particular, distinguish sandbox errors such as blocked network access,
  `bwrap`, `no new privileges`, or inaccessible credential files from an actual
  GitHub authentication error.
- Never print or persist tokens, passwords, or other credentials.
