# Security and signing material

## What was exposed

The repository used to track Android signing keys and a password file:

- `android.keystore`
- `debug.keystore`
- `potato.keystore`
- `debug.keystore.pass.txt`

These files are now removed from the Git index (they remain on the local disk so existing local
builds keep working) and are covered by `.gitignore`.

> Removing a file from the index does **not** remove it from Git history. Anyone with access to the
> repository or an old clone can still recover the keys. Treat the exposed keys as compromised.

## Recommended actions

1. **Rotate the release key.** Generate a new upload key and register it with Google Play
   (Play App Signing → App integrity → Upload key certificate → Request upload key reset). Keep the
   new keystore outside the repository.
2. **Replace the debug key** on developer machines if the exposed debug key was used for anything
   beyond local debug builds.
3. **Change the keystore password** if the old one was reused elsewhere.
4. **Do not commit** `google-services.json`, `serviceAccountKey.json`, keystores (`.jks`,
   `.keystore`) or password files. `.gitignore` already covers them.
5. Store signing secrets in a password manager or CI secret store. Configure the keystore path in
   Defold *Preferences → Android* per machine (or inject it in CI).

## Purging history (optional, destructive)

If the repository is public or has been shared, purge the files from history with
[`git filter-repo`](https://github.com/newren/git-filter-repo) or
[BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/), then force-push and ask every
collaborator to re-clone.

Example with `git filter-repo`:

```bash
git filter-repo --invert-paths \
  --path android.keystore \
  --path debug.keystore \
  --path potato.keystore \
  --path debug.keystore.pass.txt
```

This rewrites commit hashes. Coordinate with the team and update CI/tags before force-pushing.
Rotating the keys is mandatory even after a history purge.

## Local build setup

Keep a local copy of the keystore outside the worktree, for example:

```text
D:\keys\great-potato-war-upload.jks
```

In Defold: *Preferences → Android → Keystore*, select the local file and enter the password. The
password is stored in the editor preferences, not in the project.

For CI, pass the keystore and passwords through environment variables/secrets and decode the
keystore into a temporary directory during the build.
