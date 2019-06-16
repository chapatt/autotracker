document.addEventListener("DOMContentLoaded", function() {
    var dropDownList1 = chapatt.DropDownList.new(document.getElementById('drop-down-list-1'), [0, 0, 0]);

    var textBox1 = chapatt.TextBox.new(document.getElementById('text-box-1'));
    textBox1.getValueModel().signalConnect('valueChanged', function() {
        console.log('text-box-1: valueChanged');
    });

    var toggleButtonGroup1 = chapatt.ToggleButtonGroup.new(document.getElementById('toggle-button-group-1'), [0, 1]);
    toggleButtonGroup1.valueModel.signalConnect('valueChanged', function(targetWidget, signalName, signalData, userData) {
        console.log('toggle-button-group-1: valueChanged from ' + toggleButtonGroup1.valueModel.getValue() + ' to ' + signalData);
    });

    var angleUnits = [
        chapatt.Unit.new('degrees', 'deg',
            function(valueAsThis) {
                return valueAsThis;
            },
            function(valueAsDefault) {
                return valueAsDefault;
            }
        )
    ];

    /* Bearing */
    var bearingSlider = chapatt.Slider.new(document.getElementById('bearing-slider'), angleUnits, 0, 360);
    bearingSlider.scrollPixelsPerUnit = 50;
    bearingSlider.mousemovePixelsPerUnit = 10;
    var integralConstraint = chapatt.IntegralConstraint.new();
    bearingSlider.getValueModel().insertConstraintBefore(integralConstraint, bearingSlider.getValueModel().boundedConstraint);

    function bearingButtonCallback(targetWidget, signalName, signalData, userData) {
        bearingSlider.field.saveFieldText();
        rotorTargetToBearing(bearingSlider.getValueModel().getValue());
        sendBearing(bearingSlider.getValueModel().getValue());
    }
    var bearingButton = chapatt.Button.new(document.getElementById('bearing-button'), 1);
    bearingButton.signalConnect('clicked', bearingButtonCallback, null);

    /* Heading */
    var headingSlider = chapatt.Slider.new(document.getElementById('heading-slider'), angleUnits, 0, 360);
    headingSlider.scrollPixelsPerUnit = 50;
    headingSlider.mousemovePixelsPerUnit = 10;
    var integralConstraint = chapatt.IntegralConstraint.new();
    headingSlider.getValueModel().insertConstraintBefore(integralConstraint, headingSlider.getValueModel().boundedConstraint);

    function headingButtonCallback(targetWidget, signalName, signalData, userData) {
        headingSlider.field.saveFieldText();
        setHeading(headingSlider.getValueModel().getValue());
    }
    var headingButton = chapatt.Button.new(document.getElementById('heading-button'), 1);
    headingButton.signalConnect('clicked', headingButtonCallback, null);

    /* CCW Limit */
    var negativeLimitSpinBox = chapatt.SpinBox.new(document.getElementById('negative-limit-spin-box'), angleUnits);
    negativeLimitSpinBox.scrollPixelsPerUnit = 50;
    negativeLimitSpinBox.mousemovePixelsPerUnit = 10;
    var integralConstraint = chapatt.IntegralConstraint.new();
    negativeLimitSpinBox.getValueModel().insertConstraintBefore(integralConstraint, negativeLimitSpinBox.getValueModel().boundedConstraint);

    function negativeLimitButtonCallback(targetWidget, signalName, signalData, userData) {
        negativeLimitSpinBox.field.saveFieldText();
        negativeLimitToBearing(negativeLimitSpinBox.getValueModel().getValue());
    }
    var negativeLimitButton = chapatt.Button.new(document.getElementById('negative-limit-button'), 1);
    negativeLimitButton.signalConnect('clicked', negativeLimitButtonCallback, null);

    var positiveLimitSpinBox = chapatt.SpinBox.new(document.getElementById('positive-limit-spin-box'), angleUnits);
    positiveLimitSpinBox.scrollPixelsPerUnit = 50;
    positiveLimitSpinBox.mousemovePixelsPerUnit = 10;
    var integralConstraint = chapatt.IntegralConstraint.new();
    positiveLimitSpinBox.getValueModel().insertConstraintBefore(integralConstraint, positiveLimitSpinBox.getValueModel().boundedConstraint);

    function positiveLimitButtonCallback(targetWidget, signalName, signalData, userData) {
        positiveLimitSpinBox.field.saveFieldText();
        positiveLimitToBearing(positiveLimitSpinBox.getValueModel().getValue());
    }
    var positiveLimitButton = chapatt.Button.new(document.getElementById('positive-limit-button'), 1);
    positiveLimitButton.signalConnect('clicked', positiveLimitButtonCallback, null);

    var bearingCheckbox = chapatt.ToggleButton.new(document.getElementById('bearing-checkbox'));
    bearingCheckbox.valueModel.signalConnect('valueChanged', function(targetWidget, signalName, signalData, userData) {
        console.log('bearing-checkbox: valueChanged from ' + bearingCheckbox.valueModel.getValue() + ' to ' + signalData);
    });
});
