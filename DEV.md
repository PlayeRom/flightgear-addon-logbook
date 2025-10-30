Development
===========

The `/framework` directory belongs to a separate project [Framework](https://github.com/PlayeRom/flightgear-addon-framework), which has a separate git repository. The framework is included in the project as a subtree.


## Adding Framework project to `/framework` directory (once only)

```bash
git subtree add --prefix=framework git@github.com:PlayeRom/flightgear-addon-framework.git main --squash
```

**Note**: `--prefix` must be `framework`.

## Update Framework...

### ...with auto commit

```bash
git subtree pull --prefix=framework git@github.com:PlayeRom/flightgear-addon-framework.git main --squash
```

## ...manually

```bash
git fetch git@github.com:PlayeRom/flightgear-addon-framework.git main
git subtree merge --prefix=framework FETCH_HEAD --squash
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
