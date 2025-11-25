Development
===========

## FG Add-on Framework

The `/framework` directory belongs to a separate [FG Add-on Framework](https://github.com/PlayeRom/flightgear-addon-framework) project, which has a separate git repository. The Framework is included in the project as a git subtree.

### Adding Framework project to `/framework` directory (once only)

Assuming you are installing version `v1.0.0` (change to another version if you wish).

```bash
git remote add framework git@github.com:PlayeRom/flightgear-addon-framework.git
git subtree add --prefix=framework framework v1.0.0 --squash
```

**Note**: `--prefix` must be `framework`.

### Update Framework...

Assuming you are updating to `v1.0.1`, change this version to yours.

#### ...with auto commit

```bash
git subtree pull --prefix=framework framework v1.0.1 --squash -m "Update framework to v1.0.1"
```

If you get the error: `fatal: working tree has modifications. Cannot add.` even though you have no changes, run `git fetch framework` first.

#### ...manually

```bash
git fetch framework v1.0.1
git merge -s subtree --squash FETCH_HEAD --allow-unrelated-histories
git diff
```

next commit changes:

```bash
git commit -m "Update framework"
```

or cancel changes:

```bash
git checkout -- framework
```

Alternatively with a local tag:

```bash
git fetch framework v1.0.1
git tag framework-v1.0.1 FETCH_HEAD
git merge -s subtree --squash framework-v1.0.1 --allow-unrelated-histories
git diff
git commit -m "Update framework"
git tag -d framework-v1.0.1
```

## The `.env` file

For more convenient development, this add-on recognizes an `.env` file, where you can set certain variables. The `.env` file is best created by making a copy of the `.env.example` file and renaming it to `.env`. The `.env` file is on the `.gitignore` list, making it more convenient to use than modifying the code in the repository.

The add-on recognizes the following variables in the `.env` file:

1. `DEV_MODE` which takes the values `​​true` or `false` (or `1`/`0`). Setting this variable to `true` will enable possibility to use `RELOAD_MENU` and `RELOAD_MULTIKEY_CMD` variable and will set the global variable `g_isDevMode` to `true`.
2. `RELOAD_MENU` which takes the values `​​true` or `false` (or `1`/`0`). Setting this variable to `true` will add a "Dev Reload" item to the add-on's menu. This menu is used to reload all of the add-on's Nasal code.
3. `RELOAD_MULTIKEY_CMD` is using to set multi-key command to reload the add-on's Nasal code. As default `:Yarlo`.
4. `MY_LOG_LEVEL` – here you can specify the logging level for logs added using the `Log.print()` method. Possible values: `LOG_ALERT`, `LOG_WARN`, `LOG_INFO`, `LOG_DEBUG` or `LOG_BULK`. If you set, for example, `LOG_INFO`, then logs using `Log.print()` will be logged with this flag, which means that to see them you need to run the simulator with the log level at the same level or higher: `--log-level=info`.

After changing these values, you need to reload the Nasal code using the "Dev Reload" menu item or the `:Yarlo` multi-key command, or, as a last resort, restart the entire simulator.

## Class Diagram

![alt Class Diagram](docs/class-diagram.png "Class Diagram")
