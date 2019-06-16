Number.prototype.coterminalInTurn = function(turn, base=360) {
    if ((positiveInFirstTurn = this % base) < 0) {
        positiveInFirstTurn += base
    }

    var fullTurns = (Math.abs(turn) - 1) * base;
    if (turn > 0)
        return positiveInFirstTurn + fullTurns;
    else
        return (positiveInFirstTurn - (positiveInFirstTurn == 0 ? 0 : base)) - fullTurns;
};

function sendBearing(bearing) {
    var xhr = new XMLHttpRequest();
    xhr.open('PUT', 'http://' + window.location.hostname + ':' + window.location.port + '/api/rel-bearing', true);
    xhr.setRequestHeader('Content-type', 'text/plain; charset=utf-8');
    xhr.send(bearing);
}

function rotorTargetToBearing(bearing) {
    document.getElementById('arrow-target').setAttribute("transform", "rotate(" + bearing + " 270 270)");
    document.querySelector('#arrow-target text').textContent = bearing + "°";
}

function rotorToBearing(bearing) {
    document.getElementById('arrow').setAttribute("transform", "rotate(" + bearing + " 270 270)");
    document.querySelector('#arrow text').textContent = bearing + "°";
}

function calculateNegativeLimitBox() {
    var bbox = document.querySelector('#negative-limit text').getBBox();
    document.querySelector('#negative-limit .box').setAttribute("width", bbox.width + 10);
    document.querySelector('#negative-limit .box').setAttribute("x", -bbox.width - 15);
}

function negativeLimitToBearing(bearing) {
    document.getElementById('negative-limit').setAttribute("transform", "rotate(" + bearing + " 270 270)");
    document.querySelector('#negative-limit text').textContent = bearing + "°";

    var normalizedBearing = bearing.coterminalInTurn(1);
    if (normalizedBearing > 90 && normalizedBearing < 270) {
        var bbox = document.querySelector('#negative-limit text').getBBox();
        document.querySelector('#negative-limit text').setAttribute("transform", "rotate(180 " + (bbox.x + (bbox.width / 2)) + " " + (bbox.y + (bbox.height / 2)) + ")");
    } else {
        document.querySelector('#negative-limit text').setAttribute("transform", "");
    }

    calculateNegativeLimitBox();
}

function setNegativeLimitActive(active) {
    negativeLimit = document.getElementById('negative-limit');
    classes = negativeLimit.classList;
    if (active)
        classes.add("active");
    else
        classes.remove("active");
}

function calculatePositiveLimitBox() {
    var bbox = document.querySelector('#positive-limit text').getBBox();
    document.querySelector('#positive-limit .box').setAttribute("width", bbox.width + 10);
}

function positiveLimitToBearing(bearing) {
    document.getElementById('positive-limit').setAttribute("transform", "rotate(" + bearing + " 270 270)");
    document.querySelector('#positive-limit text').textContent = bearing + "°";

    var normalizedBearing = bearing.coterminalInTurn(1);
    if (normalizedBearing > 90 && normalizedBearing < 270) {
        var bbox = document.querySelector('#positive-limit text').getBBox();
        document.querySelector('#positive-limit text').setAttribute("transform", "rotate(180 " + (bbox.x + (bbox.width / 2)) + " " + (bbox.y + (bbox.height / 2)) + ")");
    } else {
        document.querySelector('#positive-limit text').setAttribute("transform", "");
    }

    calculatePositiveLimitBox();
}

function setPositiveLimitActive(active) {
    positiveLimit = document.getElementById('positive-limit');
    classes = positiveLimit.classList;
    if (active)
        classes.add("active");
    else
        classes.remove("active");
}

function setHeading(heading) {
    document.getElementById('n').setAttribute("transform", "rotate(" + -heading + " 270 270)");
}
