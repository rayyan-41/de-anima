# De Anima — Knowledge Vault

An [Obsidian](https://obsidian.md/) vault organised across five domains: **Art**, **History**, **Literature**, **Reason**, and **Science**.

---

## Downloading the vault

### Latest version

Click **Code → Download ZIP** on the [repository page](https://github.com/rayyan-41/de-anima) to get the current snapshot.

### Older versions

Every save is a Git commit, so any past state of the vault is recoverable.

#### Option 1 — Download a ZIP from GitHub (no Git required)

1. Open the repository on GitHub: `https://github.com/rayyan-41/de-anima`
2. Click the **Commits** counter near the top of the file list to browse commit history.
3. Find the commit you want, then click the `<>` (Browse files) button on the right.
4. Once you are viewing the repository at that point in time, click **Code → Download ZIP**.

#### Option 2 — Clone and check out a specific commit

```bash
# 1. Clone the full repository
git clone https://github.com/rayyan-41/de-anima.git
cd de-anima

# 2. List all commits to find the one you want
git log --oneline

# 3. Check out that commit (replace <hash> with the 7-character commit SHA)
git checkout <hash>
```

After step 3 the working directory contains the vault exactly as it was at that commit. Open the folder in Obsidian as a vault to browse its notes.

To return to the latest version at any time:

```bash
git checkout main
```

---

## Vault structure

| Folder | Domain | Agent |
|--------|--------|-------|
| `Art/` | Art history & theory | Michelangelo |
| `History/` | Empires, biographies, geopolitics | Machiavelli |
| `Literature/` | Books, myths, short stories | Tolstoy |
| `Reason/` | Philosophy & logic | Avicenna |
| `Science/` | Astronomy, mathematics, CS/AI | Ibn Haytham |

AI orchestration instructions live in [`GEMINI.md`](GEMINI.md).
