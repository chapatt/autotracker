var ws;

document.addEventListener("DOMContentLoaded", function() {
    try {
        ws = new WebSocket('ws://' + window.location.hostname + ':' + window.location.port);
    } catch (error) {
        console.error(error);
    }
    if (ws) {
        ws.onmessage = function(event) {
            console.log(event.data);
            rotorToBearing(event.data);
        };
    }
});
