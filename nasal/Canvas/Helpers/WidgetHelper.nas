#
# Logbook - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2025 Roman Ludwicki
#
# Logbook is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# General helper class for create Canvas Widgets.
#
var WidgetHelper = {
    #
    # Constructor.
    #
    # @param  hash|nil  context  Canvas parent.
    # @return void
    #
    new: func(context = nil) {
        return {
            parents: [
                WidgetHelper,
            ],
            _context: context,
        };
    },

    #
    # @param  hash  context  Canvas parent.
    # @return void
    #
    setContext: func(context) {
        me._context = context;
    },

    #
    # Create Label widget.
    #
    # @param  string|nil  text
    # @param  bool  wordWrap
    # @param  string|nil  align
    # @return ghost  Label widget.
    #
    getLabel: func(text = nil, wordWrap = 0, align = nil) {
        var label = canvas.gui.widgets.Label.new(me._context, canvas.style, { wordWrap: wordWrap });

        if (text != nil) {
            label.setText(text);
        }

        if (align != nil) {
            label.setTextAlign(align);
        }

        return label;
    },

    #
    # Create Button widget.
    #
    # @param  string  text  Label of button.
    # @param  params  Optional parameters in any order:
    #       func  Function which will be executed after click the button.
    #       int  Width of the button.
    # @return ghost  Button widget.
    #
    getButton: func(text, params...) {
        var btn = canvas.gui.widgets.Button.new(me._context, canvas.style, {})
            .setText(text);

        foreach (var param; params) {
            var type = typeof(param);

               if (type == 'func')   btn.listen("clicked", param);
            elsif (type == 'scalar') btn.setFixedSize(param, 26);
        }

        return btn;
    },

    #
    # Create CheckBox widget.
    #
    # @param  string  text
    # @param  bool  isChecked
    # @param  func|nil  callback
    # @return ghost  CheckBox widget.
    #
    getCheckBox: func(text, isChecked, callback = nil) {
        var checkBox = canvas.gui.widgets.CheckBox.new(me._context, canvas.style, {})
            .setText(text)
            .setChecked(isChecked);

        if (callback != nil) {
            checkBox.listen("toggled", callback);
        }

        return checkBox;
    },

    #
    # Create RadioButton widget.
    #
    # @param  string  text  Label text.
    # @param  ghost|nil  parent
    # @return ghost  RadioButton widget.
    #
    getRadioButton: func(text, parent = nil) {
        var cfg = {};
        if (parent != nil) {
            cfg["parent-radio"] = parent;
        }

        return canvas.gui.widgets.RadioButton.new(me._context, canvas.style, cfg)
            .setText(text);
    },

    #
    # Create LineEdit widget.
    #
    # @param  string  text
    # @param  params  Optional parameters in any order:
    #       func  Function which will be executed on `editingFinished`.
    #       int  Width of the field.
    # @return ghost  LineEdit widget.
    #
    getLineEdit: func(text = "", params...) {
        var input = canvas.gui.widgets.LineEdit.new(me._context, canvas.style, {})
            .setText(text);

        foreach (var param; params) {
            var type = typeof(param);

               if (type == 'func')   input.listen("editingFinished", param);
            elsif (type == 'scalar') input.setFixedSize(param, 26);
        }

        return input;
    },

    #
    # Create horizontal rule.
    #
    # @return ghost  HorizontalRule widget.
    #
    getHorizontalRule: func {
        return canvas.gui.widgets.HorizontalRule.new(me._context, canvas.style, {});
    },
};
