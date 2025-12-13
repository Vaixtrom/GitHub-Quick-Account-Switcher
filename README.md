# GitHub Quick Account Switcher

**Switch between multiple GitHub accounts instantly.** One `.bat` file. No dependencies except Git.

## Download

### Mac: [⬇️ Download git-switch.sh](https://github.com/Vaixtrom/GitHub-Quick-Account-Switcher/releases/latest/download/git-switch.sh)
### Windows: [⬇️ Download git-switch.bat](https://github.com/Vaixtrom/GitHub-Quick-Account-Switcher/releases/latest/download/git-switch.bat)

## TL;DR

1. Download `git-switch.bat` (link above)
2. Double-click to run
3. Add your GitHub accounts (username + email)
4. Copy the generated SSH key to GitHub ([settings/keys](https://github.com/settings/keys)) → "Authentication Key"
5. Press `1`, `2`, `3`... to switch accounts

## What It Does

- Switches `git config --global user.name` and `user.email`
- Switches SSH keys so you can push/pull from the correct account
- Auto-generates SSH keys for each account
- Guides you through adding keys to GitHub

## Menu

```
======================================================
           GIT ACCOUNT SWITCHER v1.0
======================================================

   Current: YourName <your@email.com>

------------------------------------------------------
   ACCOUNTS:
------------------------------------------------------
   1) PersonalAccount  (personal@email.com)
   2) WorkAccount      (work@company.com)

------------------------------------------------------
   OPTIONS:
------------------------------------------------------
   a) Add new account
   r) Remove account
   t) Test GitHub SSH connection
   k) Show current SSH public key
   h) Help / Setup guide
   q) Quit
======================================================
```

## Requirements

- Windows 10/11
- [Git for Windows](https://git-scm.com/download/win)

## Troubleshooting

**"Permission denied (publickey)"** → Add the SSH key to GitHub. Press `k` to see your current key, then add it at [github.com/settings/keys](https://github.com/settings/keys). Select **"Authentication Key"** (not Signing Key).

## License

MIT
