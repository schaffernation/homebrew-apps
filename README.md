# schaffernation/apps

A Homebrew tap for apps from [schaffernation](https://github.com/schaffernation).

## Install an app

```
brew install --cask schaffernation/apps/tend
```

Homebrew adds this tap the first time you install from it.

| App | Install |
|---|---|
| [Tend](https://github.com/schaffernation/tend) | `brew install --cask schaffernation/apps/tend` |

## How this tap works

Each app owns its cask, in its own repository, at
`packaging/homebrew/NAME.rb`. This tap keeps a copy in `Casks/`, because
Homebrew only reads casks inside a tap.

[`casks.yaml`](casks.yaml) lists the apps. The **Sync casks** workflow reads
it every hour, copies each app's cask into `Casks/`, checks it with
`brew style`, and commits any change. To sync right away, run the workflow
from the **Actions** tab.

A cask whose checksum is still a placeholder (all zeros) isn't released yet,
so the workflow skips it.

## Add an app

1. In the app's repository, add its cask at `packaging/homebrew/NAME.rb`.
2. Add an entry to `casks.yaml`:

   ```yaml
   - cask: NAME
     repo: schaffernation/REPOSITORY
   ```

3. Push. The workflow runs when `casks.yaml` changes.

To run the sync on your Mac, run `ruby scripts/sync.rb`.
