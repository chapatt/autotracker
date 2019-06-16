document.addEventListener("DOMContentLoaded", function() {
    pckry = new Packery('#modules', {
        itemSelector: '.module',
        columnWidth: '.module',
        gutter: '.gutter-sizer'
    });

    function remToPixels(rem) {    
        return rem * parseFloat(getComputedStyle(document.documentElement).fontSize);
    }

    moduleMinWidth = parseInt(getComputedStyle(document.documentElement).getPropertyValue('--module-min-width'))

    function setModuleWidthFraction() {
        var widthPercentage = Math.floor(100 * (1 / Math.floor(window.innerWidth / remToPixels(moduleMinWidth))));
        document.documentElement.style.setProperty('--module-width-percentage', widthPercentage + '%');
    }
    window.addEventListener('resize', setModuleWidthFraction);

    moduleTitleDragDelta = 0;
    boundHandleModuleTitleDrag = null;

    function handleModuleTitleDrag(beginX, beginY, event) {
      deltaX = event.clientX - beginX;
      deltaY = event.clientY - beginY;
      moduleTitleDragDelta = Math.sqrt(Math.pow(Math.abs(deltaX), 2) + Math.pow(Math.abs(deltaY), 2));
    };

    var modules = Array.from(document.getElementsByClassName('module'));
    modules.forEach(function(module) {
        var draggie = new Draggabilly(module, {
            handle: '.title'
        });
        pckry.bindDraggabillyEvents(draggie);

        var titleElements = module.getElementsByClassName('title');
        if (titleElements.length > 0) {
            var title = titleElements[0];
            draggie.on('pointerDown', function(event) {
                mousedownInTitle = true;
                boundHandleModuleTitleDrag = handleModuleTitleDrag.bind(this, event.clientX, event.clientY);
                draggie.on('dragMove', boundHandleModuleTitleDrag);
            });
            draggie.on('pointerUp', function() {
                if (mousedownInTitle) {
                    mousedownInTitle = false;
                    document.removeEventListener('mousemove', boundHandleModuleTitleDrag);
                    if (moduleTitleDragDelta < 5) {
                        module.classList.toggle('collapsed');
                        pckry.fit(module);
                    }
                    moduleTitleDragDelta = 0;
                }
            });
        }

        var controlsElements = module.getElementsByClassName('move-controls');
        if (controlsElements.length > 0) {
            var down = controlsElements[0].getElementsByClassName('down')[0];
            down.addEventListener('click', function() {
                var position = draggie.position;
                if (module.nextElementSibling)
                    module.parentNode.insertBefore(module, module.nextElementSibling.nextElementSibling);
                    pckry.shiftLayout();
            });

            var up = controlsElements[0].getElementsByClassName('up')[0];
            up.addEventListener('click', function() {
                if (module.previousElementSibling)
                    module.parentNode.insertBefore(module, module.previousElementSibling);
                pckry.shiftLayout();
            });
        }
    });
});
