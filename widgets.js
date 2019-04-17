/*
 * Copyright (c) 2017 Chase Patterson
 */

if (!chapatt) {
    var chapatt = {};
}

chapatt.Signal = {
    // make recursive signal emission configurable
    preventRecursiveSignalEmission: true,
    signalEmitting: false,

    initSignal: function(name) {
        this.callbacks = [];

        this.name = name;
    },

    // check if already connected
    connect: function(callback, userData) {
        this.callbacks.push({callback: callback, userData: userData});
    },

    disconnect: function(callback) {
        var callbackObj = this.callbacks.find(function(element, index, array) {
            if (element.callback === callback) {
                array.splice(index, 1);
                return true;
            }
        });

        return callbackObj;
    },

    emit: function(target, signalData) {
        var self = this;

        if (this.preventRecursiveSignalEmission && !this.signalEmitting) {
            this.signalEmitting = true;

            this.callbacks.forEach(function(item) {
                item.callback(target, self.name, signalData, item.userData);
            });

            this.signalEmitting = false;
        }
    },

    new: function(name) {
        var signal = Object.create(this);
        signal.initSignal(name);

        return signal;
    }
}

chapatt.Emitter = {
    initEmitter: function() {
        this.signals = [];

        this.signalsBlocked = false;
    },

    addSignal: function(name) {
        // if signal exists, throw error
        var signal = chapatt.Signal.new(name);
        this.signals.push(signal);
    },

    signalConnect: function(name, callback, userData) {
        // if signal doesn't exist, throw error
        this.signals.find(function(item) {
            return item.name === name;
        }).connect(callback, userData);
    },

    signalDisconnect: function(name, callback) {
        var callbackObj = this.signals.find(function(item){
            return item.name === name;
        }).disconnect(callback);

        return callbackObj;
    },

    signalEmit: function(name, signalData) {
        var self = this;

        // if signal doesn't exist, throw error
        if (!this.signalsBlocked) {
            this.signals.find(function(item) {
                return item.name === name;
            }).emit(self, signalData);
        }
    },

    blockSignals: function(block) {
        if (block)
            this.signalsBlocked = true;
        else
            this.signalsBlocked = false;
    }
}

chapatt.Unit = {
    initUnit: function(initialName, initialSymbol, initialConvFrom, initialConvTo) {
        if (arguments.length >= 1)
            this.name = initialName;
        if (arguments.length >= 2)
            this.symbol = initialSymbol;
        if (arguments.length >= 3)
            this.convFrom = initialConvFrom;
        if (arguments.length >= 4)
            this.convTo = initialConvTo;
    },

    new: function(initialName, initialSymbol, initialConvFrom, initialConvTo) {
        var argc = arguments.length;
        var unit = Object.create(this);
        unit.initUnit.apply(unit, function() {
            var args = [];

            if (argc >= 1)
                args.push(initialName);
            if (argc >= 2)
                args.push(initialSymbol);
            if (argc >= 3)
                args.push(initialConvFrom);
            if (argc >= 4)
                args.push(initialConvTo);

            return args;
        }());
        return unit;
    }
}

chapatt.UnitTable = [];
Object.assign(chapatt.UnitTable, {
    initUnitTable: function(initialUnits) {
        if (initialUnits) {
            this.addUnits(initialUnits);
        }
    },

    addUnits: function(units) {
        units.forEach(function(item) {
            this.push(item);
        }.bind(this));
    },

    valueFromToUnit: function(value, fromUnitIndex, toUnitIndex) {
        // FIXME! implement
    },

    new: function() {
        var unitTable = Object.create(this);
        unitTable.initUnitTable();
        return unitTable;
    }
});

chapatt.ValueModel = {};
Object.assign(chapatt.ValueModel, chapatt.Emitter);
Object.assign(chapatt.ValueModel,
{
    initValueModel: function() {
        this.initEmitter();
        this.addSignal('valueChanged');
    },

    getValue: function(unitIndex) {
        return this.value;
    },

    setValue: function(value) {
        if (this.value == value)
            return;

        this.signalEmit('valueChanged', value);
        this.value = value;
    },

    new: function() {
        var valueModel = Object.create(this);
        valueModel.initValueModel();
        return valueModel;
    }
});

chapatt.Indexed = {
    initIndexed: function(initialValues) {
        this.valueTable = chapatt.ValueTable.new(initialValues);

        this.valueIndex = 0;
    },

    getValueTable: function() {
        return this.valueTable;
    },

    setValue: function(value) {
        if (this.value == value)
            return true;

        for (var i=0; i < this.valueTable.length; ++i) {
            if (this.valueTable[i] == value) {
                this.signalEmit('valueChanged', value);
                this.valueIndex = i;
                this.value = this.valueTable[i];
                return true;
            }
        };

        return false;
    },

    setValueByIndex: function(index) {
        this.signalEmit('valueChanged', (value = this.valueTable[index]));
        this.value = value;
        this.valueIndex = index;
    }
}

chapatt.Numerical = {
    initNumerical: function() {
        // FIXME! initialize unitIndex properly
        this.unitIndex = 1;
    },

    getUnitTable: function() {
        return this.unitTable;
    },

    setUnitTable: function(unitTable) {
        this.unitTable = unitTable;
    },

    getUnitIndex: function() {
        return this.unitIndex;
    },

    setUnitIndex: function(unitIndex) {
        this.unitIndex = unitIndex;
    },

    getValue: function(unitIndex) {
        if (!unitIndex) {
            return this.value;
        } else {
            return this.unitTable.valueFromToUnit(this.value, this.unitIndex, unitIndex);
        }
    }
}

chapatt.Integral = {
    setValue: function(value) {
        value = Math.round(value);
        this.signalEmit('valueChanged', value);
        this.value = value;
    }
}

chapatt.Bounded = {
    setValue: function(value) {
        if (this.value == value) {
            return;
        }

        if (value < this.minimum) {
            if (this.value == this.minimum)
                return;

            this.signalEmit('valueChanged', this.minimum);
            this.value = this.minimum;
        } else if (value > this.maximum) {
            if (this.value == this.maximum)
                return;

            this.signalEmit('valueChanged', this.maximum);
            this.value = this.maximum;
        } else {
            this.signalEmit('valueChanged', value);
            this.value = value;
        }
    },

    getMinimum: function() {
        return this.minimum;
    },

    setMinimum: function(minimum) {
        this.minimum = minimum;
    },

    getMaximum: function() {
        return this.maximum;
    },

    setMaximum: function(maximum) {
        this.maximum = maximum;
    }
};

chapatt.BoundedIntegral = {
    setValue: function(value) {
        value = Math.round(value);

        if (this.value == value) {
            return;
        }

        if (value < this.minimum) {
            if (this.value == this.minimum)
                return;

            this.signalEmit('valueChanged', this.minimum);
            this.value = this.minimum;
        } else if (value > this.maximum) {
            if (this.value == this.maximum)
                return;

            this.signalEmit('valueChanged', this.maximum);
            this.value = this.maximum;
        } else {
            this.signalEmit('valueChanged', value);
            this.value = value;
        }
    },

    getMinimum: function() {
        return this.minimum;
    },

    setMinimum: function(minimum) {
        this.minimum = minimum;
    },

    getMaximum: function() {
        return this.maximum;
    },

    setMaximum: function(maximum) {
        this.maximum = maximum;
    }
};

chapatt.Valuable = {
    initValuable: function() {
        this.valueModel = chapatt.ValueModel.new();
    },

    getValueModel: function() {
        return this.valueModel;
    },

    setValueModel: function(valueModel) {
        this.valueModel = valueModel;
    }
}

chapatt.Widget = {
    widgets: [],

    initWidget: function(element) {
        this.element = element;

        this.widgets.push(this);
    },

    // FIXME! either keep instances array in widget subclasses, or reimplement each time
    getByElement: function(element) {
        return this.instances.find(function(item) {
            return (item.element === element);
        });
    }
}

chapatt.TextBox = Object.create(chapatt.Widget);
Object.assign(chapatt.TextBox, chapatt.Valuable);
Object.assign(chapatt.TextBox,
{
    textBoxes: [],

    initTextBox: function(element) {
        this.initWidget(element);
        this.initValuable();

        this.textBoxes.push(this);

        this.valueModel.signalConnect('valueChanged', this.handleValueChanged.bind(this));

        var field = this.element.getElementsByClassName('field')[0].firstElementChild;
        field.addEventListener('keydown', this.fieldHandleKeydown.bind(this));
        field.addEventListener('focusout', this.fieldHandleFocusout.bind(this));

        this.mutatedSinceSaved = false;
        var fieldObserver = new MutationObserver(this.fieldHandleMutation.bind(this));
        fieldObserver.observe(field, {characterData: true, subtree: true});
    },

    handleValueChanged: function(target, signalName, signalData)  {
        var field = this.element.getElementsByClassName('field')[0].firstElementChild;
        field.textContent = signalData;
    },

    fieldHandleKeydown: function(event) {
        if (event.key === 'Enter') {
            event.preventDefault();

            // FIXME! if set to change on enter
            this.saveFieldText();
        }
    },

    fieldHandleFocusout: function(event) {
        // FIXME! if set to change on mouseout
            // only save if text has mutated (to prevent rounding of actual value to display value)
            if (this.mutatedSinceSaved)
                this.saveFieldText();
    },

    fieldHandleMutation: function(mutations) {
        this.mutatedSinceSaved = true;

        // FIXME! if set to change on mutation
        // this.saveFieldText();
    },

    saveFieldText: function() {
        var field = this.element.getElementsByClassName('field')[0].firstElementChild;
        this.valueModel.setValue(field.textContent);

        this.mutatedSinceSaved = false;
    },

    new: function(element) {
        var textBox = Object.create(this);
        textBox.initTextBox(element);
        return textBox;
    }
});

chapatt.Button = Object.create(chapatt.Widget);
Object.assign(chapatt.Button, chapatt.Emitter);
Object.assign(chapatt.Button, chapatt.Valuable);
Object.assign(chapatt.Button,
{
    buttons: [],

    initButton: function(element, initialValue) {
        this.initWidget(element);
        this.initEmitter();
        this.initValuable();

        this.valueModel.setValue(initialValue);

        this.buttons.push(this);

        this.addSignal('clicked');
        this.element.addEventListener('click', this.handleClick.bind(this));

        this.element.addEventListener('mousedown', function(event)
        {
            event.preventDefault();
        });
    },

    handleClick: function() {
            this.signalEmit('clicked', this.valueModel.getValue());
    },

    new: function(element, initialValue) {
        var button = Object.create(this);
        button.initButton(element, initialValue);
        return button;
    }
});

chapatt.ValueTable = [];
Object.assign(chapatt.ValueTable, {
    initValueTable: function(initialValues) {
        initialValues.forEach(function(item) {
            this.push(item);
        }.bind(this));
    },

    addValue: function(value) {
        this.push(item);
    },

    new: function(initialValues) {
        var valueTable = Object.create(this);
        valueTable.initValueTable(initialValues);
        return valueTable;
    }
});

chapatt.CycleButton = Object.create(chapatt.Button);
Object.assign(chapatt.CycleButton, chapatt.Valuable);
Object.assign(chapatt.CycleButton,
{
    cycleButtons: [],

    initCycleButton: function(element, initialValues) {
        this.initButton(element);
        this.initValuable();

        Object.assign(this.valueModel, chapatt.Indexed);
        this.valueModel.initIndexed(initialValues);

        this.cycleButtons.push(this);

        this.signalConnect('clicked', this.cycle.bind(this));
    },

    cycle: function() {
        if ((i = this.valueModel.valueIndex) < this.valueModel.getValueTable().length - 1) {
            this.valueModel.setValueByIndex(++this.valueModel.valueIndex);
        } else {
            this.valueModel.setValueByIndex(0);
        }
    },

    new: function(element, initialValues) {
        var cycleButton = Object.create(this);
        cycleButton.initCycleButton(element, initialValues);
        return cycleButton;
    }
});

chapatt.ToggleButton = Object.create(chapatt.CycleButton);
Object.assign(chapatt.ToggleButton,
{
    initToggleButton: function(element) {
        this.initCycleButton(element, ['unselected', 'selected']);

        this.valueModel.signalConnect('valueChanged', this.handleValueChanged.bind(this));

        if (this.element.classList.contains('selected')) {
            this.valueModel.setValueByIndex(1);
        } else {
            this.valueModel.setValueByIndex(0);
        }
    },

    handleValueChanged: function(target, signalName, signalData) {
        classList = this.element.classList;
        if (signalData == 'selected') {
            if (!classList.contains('selected'))
                classList.add('selected');
        } else {
            if (classList.contains('selected'))
                this.element.classList.remove('selected');
        }
    },

    new: function(element) {
        var toggleButton = Object.create(this);
        toggleButton.initToggleButton(element);
        return toggleButton;
    }
});

chapatt.SpinBox = Object.create(chapatt.Widget);
Object.assign(chapatt.SpinBox, chapatt.Valuable);
Object.assign(chapatt.SpinBox,
{
    initSpinBox: function(element, initialUnits) {
        this.initWidget(element);
        this.initValuable();

        Object.assign(this.valueModel, chapatt.Numerical);
        this.valueModel.initNumerical();
        if (initialUnits) {
            this.valueModel.setUnitTable(chapatt.UnitTable.new());
            this.valueModel.getUnitTable().addUnits(initialUnits);
        }
        Object.assign(this.valueModel, chapatt.Integral);

        // the magnitude of the wheel delta which results in 1 unit change.
        // Larger values result in finer adjustment
        this.scrollPixelsPerUnit = 55;
        // the magnitude of the mousemove delta which results in 1 unit change.
        // Larger values result in finer adjustment
        this.mousemovePixelsPerUnit = 15;

        // if a mousedown was received in the SpinBox and the corresponding mouseup
        // hasn't yet been received
        this.mouseIsDown = false;

        // minimum mousemove before it affects the value
        this.dragMinimumMovement = 10;
        this.dragMinimumMovementExceeded = false;

        this.cursorYOnMousedown = null;
        this.valueOnMousedown = null;

        this.valueModel.signalConnect('valueChanged', this.handleValueChanged.bind(this));

        this.field = chapatt.TextBox.new(this.element);
        this.field.valueModel.signalConnect('valueChanged',
            this.handleFieldValueChanged.bind(this));

        this.increaseButton = chapatt.Button.new(this.element.getElementsByClassName('increase')[0]);
        this.decreaseButton = chapatt.Button.new(this.element.getElementsByClassName('decrease')[0]);

        this.increaseButton.element.addEventListener('click', this.increase.bind(this));
        this.decreaseButton.element.addEventListener('click', this.decrease.bind(this));
        this.element.addEventListener('wheel', this.handleWheel.bind(this));
        this.element.addEventListener('mousedown', this.handleMousedown.bind(this));
        document.documentElement.addEventListener('mousemove', this.handleMousemove.bind(this));
        document.documentElement.addEventListener('mouseup', this.handleMouseup.bind(this));

        var field = this.element.getElementsByClassName('field')[0].firstElementChild;
        this.setValueParsingString(field.textContent);
    },

    handleMousedown: function(event) {
        this.cursorYOnMousedown = event.clientY;
        this.valueOnMousedown = this.valueModel.getValue();
        this.mouseIsDown = true;
    },

    handleMousemove: function(event) {
        if (this.mouseIsDown) {
            var deltaY = this.cursorYOnMousedown - event.clientY;

            if (Math.abs(deltaY) >= this.dragMinimumMovement) {
                this.dragMinimumMovementExceeded = true;
            }

            if (this.dragMinimumMovementExceeded) {
                var unit = this.valueModel.getUnitTable()[this.valueModel.getUnitIndex()];
                this.valueModel.setValue(this.valueOnMousedown + unit.convFrom(deltaY / this.mousemovePixelsPerUnit));
            }

            event.preventDefault();
        }
    },

    handleMouseup: function(event) {
        if (this.mouseIsDown) {
            this.mouseIsDown = false;
            this.dragMinimumMovementExceeded = false;
        }
    },

    handleFieldValueChanged: function(target, signalName, signalData) {
        this.setValueParsingString(signalData);
    },

    setValueParsingString: function(string) {
        if (units = this.valueModel.getUnitTable()) {
            if (isNaN(Number(string))) {
                // Not a number; attempt to parse as number with suffix
                units.forEach(function(unit, index) {
                    if (string.endsWith(unit.symbol)) {
                        // if set to switch to this unit by default
                        this.valueModel.setUnitIndex(index);

                        var newValue = unit.convFrom(Number(string.slice(0, -unit.symbol.length)));
                        this.valueModel.setValue(newValue);
                    }
                }.bind(this));
            } else {
                var newValue = units[this.valueModel.unitIndex].convFrom(Number(string));
                this.valueModel.setValue(newValue);
            }
        } else {
            if (isNaN(Number(string)))
                return false;
            else
                this.valueModel.setValue(parseFloat(string));
        }
    },

    increase: function() {
        if (units = this.valueModel.getUnitTable()) {
            var newValue = this.valueModel.getValue() + units[this.valueModel.getUnitIndex()].convFrom(1);
            this.valueModel.setValue(newValue);
        } else {
            this.valueModel.setValue(this.valueModel.getValue() + 1);
        }
    },

    decrease: function() {
        if (units = this.valueModel.getUnitTable()) {
            var newValue = this.valueModel.getValue() - units[this.valueModel.getUnitIndex()].convFrom(1);
            this.valueModel.setValue(newValue);
        } else {
            this.valueModel.setValue(this.valueModel.getValue() - 1);
        }
    },

    handleValueChanged: function(target, signalName, signalData) {
        function roundToDecimalPlaces(x, places) {
            var roundScale = Math.pow(10, places);
            return Math.round(roundScale * x) / roundScale;
        }

        var field = this.element.getElementsByClassName('field')[0].firstElementChild;
        // FIXME! parameterize rounding
        var newFieldContent = roundToDecimalPlaces(
            ((units = this.valueModel.getUnitTable()) ?
                units[this.valueModel.unitIndex].convTo(signalData) :
                signalData),
            2
        );

        // FIXME! if set to show unit suffix, and space or not based on unit 
        if (units)
            newFieldContent = newFieldContent + ' ' + units[this.valueModel.unitIndex].symbol;

        field.textContent = newFieldContent;
    },

    handleWheel: function(event) {
        // FIXME! add x and y scrolling
        var unit = this.valueModel.getUnitTable()[this.valueModel.getUnitIndex()];
        var newValue = this.valueModel.getValue() + unit.convFrom(-event.deltaY / this.scrollPixelsPerUnit);
        this.valueModel.setValue(newValue);

        event.preventDefault();
    },

    new: function(element, initialUnits) {
        var spinBox = Object.create(this);
        if (initialUnits)
            spinBox.initSpinBox(element, initialUnits);
        else
            spinBox.initSpinBox(element);
        return spinBox;
    }
});

chapatt.Bar = Object.create(chapatt.Widget);
Object.assign(chapatt.Bar, chapatt.Valuable);
Object.assign(chapatt.Bar,
{
    initBar: function(element) {
        this.initWidget(element);
        this.initValuable();

        Object.assign(this.valueModel, chapatt.Bounded);
        this.valueModel.setMinimum(0);
        this.valueModel.setMaximum(1);

        this.valueModel.signalConnect('valueChanged', this.handleValueChanged.bind(this));
    },

    handleValueChanged: function(target, signalName, signalData) {
        var bar = this.element.getElementsByClassName('bar')[0];
        bar.style.width = signalData * 100 + '%';
    },

    new: function(element) {
        var bar = Object.create(this);
        bar.initBar(element);
        return bar;
    }
});

chapatt.Slider = Object.create(chapatt.SpinBox);
Object.assign(chapatt.Slider,
{
    initSlider: function(element, initialUnits, minimum, maximum) {
        this.initSpinBox(element, initialUnits);

        Object.assign(this.valueModel, chapatt.BoundedIntegral);
        this.valueModel.setMinimum(minimum);
        this.valueModel.setMaximum(maximum);

        this.bar = chapatt.Bar.new(this.element);

        this.valueModel.signalConnect('valueChanged', this.setBar.bind(this));
    },

    setBar: function(target, signalName, signalData) {
        var fraction = signalData / (this.valueModel.getMaximum() - this.valueModel.getMinimum());
        this.bar.getValueModel().setValue(fraction);
    },

    new: function(element, initialUnits, minimum, maximum) {
        var slider = Object.create(this);
        slider.initSlider(element, initialUnits, minimum, maximum);
        return slider;
    }
});

chapatt.ButtonGroup = Object.create(chapatt.Widget);
Object.assign(chapatt.ButtonGroup, chapatt.Emitter);
Object.assign(chapatt.ButtonGroup,
{
    buttonGroups: [],

    initButtonGroup: function(element) {
        this.initWidget(element);
        this.initEmitter();

        this.buttonGroups.push(this);

        this.addSignal('clicked');
        this.buttons = [];
        this.initButtons();

        this.element.addEventListener('mousedown', function(event)
        {
            event.preventDefault();
        });
    },

    initButtons: function() {
        var buttons = this.element.getElementsByClassName('button');
        for (var i = 0; i < buttons.length; i++) {
            this.buttons.push(chapatt.Button.new(buttons[i], i));
            this.buttons[i].signalConnect('clicked', this.buttonHandleClicked.bind(this), i);
        }
    },

    buttonHandleClicked: function(target, signalName, signalData, userData) {
            this.signalEmit('clicked', signalData);
    },

    new: function(element) {
        var buttonGroup = Object.create(this);
        buttonGroup.initButtonGroup(element);
        return buttonGroup;
    }
});

chapatt.ToggleButtonGroup = Object.create(chapatt.ButtonGroup);
Object.assign(chapatt.ToggleButtonGroup, chapatt.Valuable);
Object.assign(chapatt.ToggleButtonGroup,
{
    toggleButtonGroups: [],

    initToggleButtonGroup: function(element) {
        this.initButtonGroup(element);
        this.initValuable();

        this.toggleButtonGroups.push(this);

        this.toggleButtons = [];
        this.initToggleButtons();

        var valueModelInterface = Object.create(chapatt.Emitter);
        Object.assign(valueModelInterface, {
            initValueModelInterface: function(parent) {
                this.initEmitter();

                this.parent = parent;

                this.addSignal('valueChanged');
            },

            valueChanged: function(buttonIndex, buttonNewValue) {
                var value = [];
                this.parent.toggleButtons.forEach(function(item, index) {
                    if (index === buttonIndex) // this is the value that changed
                        value.push(buttonNewValue);
                    else
                        value.push(item.getValueModel().getValue());
                });
                
                this.signalEmit('valueChanged', value);
            },

            getValue: function() {
                var value = [];
                this.parent.toggleButtons.forEach(function(item) {
                    value.push(item.getValueModel().getValue());
                });

                return value;
            }
        });
        this.valueModel = Object.create(valueModelInterface);
        this.valueModel.initValueModelInterface(this);
    },

    initButtons: function() {
    },

    initToggleButtons: function() {
        var toggleButtons = this.element.getElementsByClassName('button');
        for (var i = 0; i < toggleButtons.length; i++) {
            this.toggleButtons.push(chapatt.ToggleButton.new(toggleButtons[i]));
            this.toggleButtons[i].getValueModel().signalConnect('valueChanged', this.toggleButtonHandleValueChanged.bind(this), i);
            this.toggleButtons[i].signalConnect('clicked', this.buttonHandleClicked.bind(this), i);
        }
    },

    toggleButtonHandleValueChanged: function(target, signalName, signalData, userData) {
        // react to toggle
        this.valueModel.valueChanged(userData, signalData);
    },

    new: function(element) {
        var toggleButtonGroup = Object.create(this);
        toggleButtonGroup.initToggleButtonGroup(element);
        return toggleButtonGroup;
    }
});
