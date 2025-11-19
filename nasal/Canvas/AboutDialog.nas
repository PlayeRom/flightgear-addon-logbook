#
# Logbook - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2022 Roman Ludwicki
#
# Logbook is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# AboutDialog class to display about info.
#
var AboutDialog = {
    CLASS: "AboutDialog",

    #
    # Constants:
    #
    PADDING: 10,

    #
    # Constructor.
    #
    # @return hash
    #
    new: func {
        var obj = {
            parents: [
                AboutDialog,
                PersistentDialog.new(
                    width: 280,
                    height: 500,
                    title: "About Logbook",
                ),
            ],
        };

        call(PersistentDialog.setChild, [obj, AboutDialog], obj.parents[1]); # Let the parent know who their child is.
        call(PersistentDialog.setPositionOnCenter, [], obj.parents[1]);

        obj._widget = WidgetHelper.new(obj._group);

        obj._createLayout();

        g_VersionChecker.registerCallback(Callback.new(obj._newVersionAvailable, obj));

        return obj;
    },

    #
    # Destructor.
    #
    # @return void
    #
    del: func {
        call(PersistentDialog.del, [], me);
    },

    #
    # Create layout.
    #
    # @return void
    #
    _createLayout: func {
        me._vbox.setContentsMargins(me.PADDING, me.PADDING, me.PADDING, me.PADDING);

        me._vbox.addItem(me._getLabel(g_Addon.name));
        me._vbox.addItem(me._getLabel(sprintf("version %s", g_Addon.version.str())));
        me._vbox.addItem(me._getLabel("2025-10-29"));

        me._vbox.addStretch(1);
        me._vbox.addItem(me._getLabel("Written by:"));

        foreach (var author; g_Addon.authors) {
            me._vbox.addItem(me._getLabel(author.name));
        }

        me._vbox.addStretch(1);
        # TODO: Unfortunately, it seems that FG incorrectly handles wordWrap for widgets.Label, artificially narrowing
        # the Label's width so it doesn't adhere to the available window width. Therefore, I don't use wordWrap and
        # manually break the text using the \n character.
        me._vbox.addItem(me._getLabel("This add-on uses © OpenStreetMap and OpenTopoMap to draw the map.", true));

        me._vbox.addStretch(1);

        me._vbox.addItem(me._getButton("FlightGear Wiki", func {
            Utils.openBrowser({ url: g_Addon.homePage });
        }));

        me._vbox.addItem(me._getButton("GitHub Website", func {
            Utils.openBrowser({ url: g_Addon.codeRepositoryUrl });
        }));

        me._vbox.addItem(me._getButton("Open Storage Folder", func {
            Utils.openBrowser({ path: g_Addon.storagePath });
        }));

        me._vbox.addStretch(1);

        me._createLayoutNewVersionInfo();

        me._vbox.addStretch(1);

        me._vbox.addSpacing(me.PADDING);
        me._vbox.addItem(me._drawBottomBar());
    },

    #
    # Create hidden layout for new version info.
    #
    # @return void
    #
    _createLayoutNewVersionInfo: func {
        var label = me._newVersionAvailLabel = me._getLabel("New version is available");
        label.setVisible(false);

        if (Utils.isFG2024Version()) {
            me._newVersionAvailLabel.setColor([0.9, 0.0, 0.0]);
        }

        var button = me._newVersionAvailBtn = me._getButton("Download new version", func {
            Utils.openBrowser({ url: g_Addon.downloadUrl });
        });
        button.setVisible(false);

        me._vbox.addItem(me._newVersionAvailLabel);
        me._vbox.addItem(me._newVersionAvailBtn);
    },

    #
    # @param  string  text  Label text.
    # @param  bool  wordWrap  If true then text will be wrapped.
    # @return ghost  Label widget.
    #
    _getLabel: func(text, wordWrap = 0) {
        var align = nil;

        if (Utils.isFG2024Version()) {
            align = "center";
        }

        return me._widget.getLabel(text, wordWrap, align);
    },

    #
    # @param  string  text  Label of button.
    # @param  func  callback  Function which will be executed after click the button.
    # @return ghost  Button widget.
    #
    _getButton: func(text, callback) {
        return me._widget.getButton(text, callback, 200);
    },

    #
    # @return ghost  HBoxLayout object with button.
    #
    _drawBottomBar: func {
        var btnClose = me._widget.getButton("Close", func me.hide(), 75);

        var hBox = canvas.HBoxLayout.new();
        hBox.addStretch(1);
        hBox.addItem(btnClose);
        hBox.addStretch(1);

        return hBox;
    },

    #
    # Callback called when a new version of add-on is detected.
    #
    # @param  string  newVersion
    # @return void
    #
    _newVersionAvailable: func(newVersion) {
        me._newVersionAvailLabel
            .setText(sprintf("New version %s is available", newVersion))
            .setVisible(true);

        me._newVersionAvailBtn
            .setVisible(true);
    },
};
