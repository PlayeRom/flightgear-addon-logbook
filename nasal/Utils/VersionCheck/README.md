Canvas Skeleton Add-on
======================

## Version checker

The files in this directory are responsible for checking whether a newer version of the add-on has been released. This allows you to inform the user about it. There are 2 ways to check your version, of course you should only choose one.

### Method 1. MetaDataVersionChecker

The simplest method involves downloading the `/addon-metadata.xml` file from your repository, which contains the add-on's version. Therefore, if you push a new commit to the server and increment the add-on's version, users can receive notification of the new version. The disadvantage of this solution is that releases are not used, so the version will always be loaded from a main branch (HEAD). Therefore, if you increment the version of an add-on that isn't quite ready, users will receive notifications.

The advantage is that this solution is more repository-agnostic. Currently, GitHub, GitLab, and FGAddons on SourceForge are supported, but supporting any other repository is very easy by modifying the `MetaDataVersionChecker._getUrl` method.

Requirements:

1. In the `/addon-metadata.xml` file, in the `<code-repository>` field, place the full URL to your repository, e.g., `https://github.com/PlayeRom/flightgear-addon-canvas-skeleton`.
2. In `/Config.nas` file set `useVersionCheck.byMetaData` on `true` and others flags in `useVersionCheck` set on `false`.

### Method 2. GitTagVersionChecker

You can use this version checking method if you host your add-on on GitHab or GitLab and you are using git tags to create releases, where name of tag it's a version number, e.g. `1.2.5` or `v.1.2.5`.

1. In the `/addon-metadata.xml` file, in the `<code-repository>` field, place the full URL to your repository, e.g., `https://gitlab.com/PlayeRom/flightgear-addon-canvas-skeleton`.
2. In `/Config.nas` file set `useVersionCheck.byGitTag` on `true` and others flags in `useVersionCheck` set on `false`.
3. Git tags must be in version notation as accepted by the `<version>` field in the `/addon-metadata.xml` file (see below). Optionally, you can prefix the version in the tag with `v.` or `v`, e.g. `v.1.2.5`. or `v1.2.5`.

## Version notation for add-on

Add-on version in the `/addon-metadata.xml` file must be written in one of the following format:

```
MAJOR.MINOR.PATCH
MAJOR.MINOR.PATCH{a|b|rc}N
MAJOR.MINOR.PATCH{a|b|rc}N.devM
MAJOR.MINOR.PATCH.devM
```

where `MAJOR`, `MINOR`, `PATCH`, `N`, `M` are integers. `MAJOR`, `MINOR`, `PATCH` can be zeros, and `N`, `M` must be greater than 0.

The character `a` denotes alpha versions, `b` - beta, `rc` - release candidate, and each version can have the suffix `.devM`.

Examples from the smallest version to the largest:

```
1.2.5.dev1      # first development release of 1.2.5
1.2.5.dev4      # fourth development release of 1.2.5
1.2.5
1.2.9
1.2.10a1.dev2   # second dev release of the first alpha release of 1.2.10
1.2.10a1        # first alpha release of 1.2.10
1.2.10b5        # fifth beta release of 1.2.10
1.2.10rc12      # twelfth release candidate for 1.2.10
1.2.10
1.3.0
2017.4.12a2
2017.4.12b1
2017.4.12rc1
2017.4.12
```

## Version notation for git tags

The git tag assigned to releases should be the same as the add-on version. However, tag versions may be additionally marked with the prefix `v.` or `v`, for example: `v.1.2.5` or `v1.2.5`.

## Class diagram

```
                 ┌────────────────┐
                 │ VersionChecker │
                 └────────────────┘
                         ▲
                         │
            ┌────────────┴───────────┐
  ┌─────────┴──────────┐   ┌─────────┴─────────┐
  │ JsonVersionChecker │   │ XmlVersionChecker │
  └────────────────────┘   └───────────────────┘
            ▲                        ▲
            │                        │
 ┌──────────┴───────────┐ ┌──────────┴─────────────┐
 │ GitTagVersionChecker │ │ MetaDataVersionChecker │
 └──────────────────────┘ └────────────────────────┘
```

The `VersionChecker` class implements key elements, such as registering callbacks to inform other classes about the new version. It is inherited by `JsonVersionChecker` and `XmlVersionChecker`, which implement various methods for downloading resources from the web.

The `JsonVersionChecker` class can download any file from the internet and pass its contents (as text) to its child's callback function. This class also includes a JSON parser, as the most frequently downloaded resource will be a JSON file. This class uses the `http.load()` method to download the resource.

The `XmlVersionChecker` class implements XML file downloading as a `<PropertyList>`, a solution that only works with FlightGear. For this purpose, the `xmlhttprequest` fgcommand is used, and then it passes the `props.Node` object to its child's callback function, allowing navigation through the parsed XML.

The `MetaDataVersionChecker` class inherits from `XmlVersionChecker` because it downloads the `/addon-metadata.xml` file from the add-on repository. This class's task is to determine the URL pointing to the file to download and to handle a callback function called by `XmlVersionChecker`, which will receive a `props.Node` object with the parsed XML. The callback function retrieves the new version of the add-on as a string and passes it to the `me.checkVersion()` method.

The `GitTagVersionChecker` class inherit from `JsonVersionChecker` because it communicate with the appropriate service via API. The purpose of this class is to establish a URL pointing to the file to download and to handle a callback function called by `JsonVersionChecker`, which receives a string as content in JSON format. The callback function retrieves the new version of the add-on as a string and passes it to the `me.checkVersion()` method.

If you need your own implementation for downloading a file, simply add a new class such as `MetaDataVersionChecker` or `GitTagVersionChecker`, where you specify the URL to the resource and implement a callback function that receives the downloaded resource and finally calls `me.checkVersion()`.

## How do I notify the user about a new version?

1. Make sure you have set the repository URL in the `<code-repository>` tag in the `/addon-metadata.xml` file.

2. Make sure that in the `/Config.nas` file you have set at least one of the options in `useVersionCheck` to `true`.

3. Make sure that in the `/nasal/Bootstrap.nas` file, after creating all class instances, the `g_VersionChecker.checkLastVersion();` method is called.

4. In the class created globally in `Bootstrap`, where you want to inform the user about a new version, e.g. in the `AboutPersistentDialog`, register a callback that will be called if a newer version is available. For example in the `AboutPersistentDialog.new` method, add:

    ```nasal
    new: func() {
        var obj = {...};

        g_VersionChecker.registerCallback(Callback.new(obj.newVersionAvailable, obj));

        return obj;
    },
    ```

    and write the `newVersionAvailable` method and in its body what you want to do with the information about the new version:

    ```nasal
    #
    # Callback called when a new version of add-on is detected.
    #
    # @param  string  newVersion
    # @return void
    #
    newVersionAvailable: func(newVersion) {
        # TODO: your implementation here...
    },
    ```

    You can register multiple such callbacks in your different classes, each of them will be called if a new version is available.

When creating objects at runtime, you can simply use the `g_VersionChecker.isNewVersion()` and `g_VersionChecker.getNewVersion()` methods to drive the logic of informing the user about the new version. You can see it in `AboutTransientDialog.nas` file.
