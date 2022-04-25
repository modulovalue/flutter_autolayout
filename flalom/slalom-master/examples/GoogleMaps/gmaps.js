"use strict";


function makeGoogleMapsExample() {
    // Get the first element by class name.
    function ec(className) { return document.querySelector('.' + className); }

    var height = 480;
    var parentElement = ec('container');
    var context = new Slalom.MotionContext();
    var solver = context.solver();

    // Replicate the DOM structure with "boxes". The Box is just a JS object which
    // can have geometry that gets reflected back into DOM from Cassowary. Probably
    // should use a more generic approach in the future where we selectively reflect
    // individual variables into DOM/style.
    var form = new Slalom.Box(ec('form'));
    var shadow = new Slalom.Box(ec('shadow'));
    form.addChild(shadow);
    var photo = new Slalom.Box(ec('photo'));
    form.addChild(photo);
    var photoDimmingLayer = new Slalom.Box(ec('photo-dimming-layer'));
    photo.addChild(photoDimmingLayer);
    var infoBar = new Slalom.Box(ec('infobar'));
    form.addChild(infoBar);
    var topNavbar = new Slalom.Box(ec('top-navbar'));
    infoBar.addChild(topNavbar);
    var navigationControls = new Slalom.Box(ec('navigation-controls'));
    form.addChild(navigationControls);
    var content = new Slalom.Box(ec('gmaps-content'));
    // Extract the natural height of the content.
    var contentHeight = 0;
    {
        var el = content.element();
        el.style.position = 'static';
        el.style.width = '320px';
        el.style.height = null;
        contentHeight = el.offsetHeight;
        el.style.position = null;
        el.style.width = null;
    }

    form.addChild(content);

    // Add the root box to the content.
    context.addBox(form);

    // Now we can set up some constraints.
    var scrollPosition = new c.Variable({name: 'scroll-position'});

    infoBar.x = 0;
    infoBar.right = 320;
    infoBar.bottom = new c.Variable({name: 'infobar-bottom'});
    infoBar.y = new c.Variable({name: 'infobar-y'});

    topNavbar.x = 0;
    topNavbar.right = 320;
    topNavbar.y = 0;
    topNavbar.bottom = 55;

    photo.x = 0;
    photo.right = 320;
    photo.y = new c.Variable({name: 'photo-y'});
    photo.bottom = new c.Variable({name: 'photo-bottom'});

    shadow.x = 0;
    shadow.right = 320;
    shadow.y = new c.Variable({name: 'shadow-y'});
    shadow.bottom = new c.Variable({name: 'shadow-bottom'});

    photoDimmingLayer.x = 0;
    photoDimmingLayer.y = 0;
    photoDimmingLayer.right = 320;
    photoDimmingLayer.bottom = 50;

    content.x = 0;
    content.right = 320;
    content.y = new c.Variable({name: 'content-y'});
    content.bottom = new c.Variable({name: 'content-bottom'});

    var photoHeight = 160;

    // Infobar is weakly at the bottom, infobar is 80 high.
    solver.add(eq(infoBar.bottom, height, weak));
    solver.add(eq(infoBar.y, c.minus(infoBar.bottom, 80), medium));

    // Infobar weakly tracks scroll position.
    solver.add(eq(infoBar.bottom, c.plus(height, scrollPosition), medium));

    // Infobar shrinks to 55px visible at the top.
    solver.add(geq(infoBar.bottom, 55, medium));


    // Photo's top is the infobar's top plus 2x scrollpos.
    solver.add(geq(photo.y, c.plus(infoBar.y, c.times(scrollPosition, (height - photoHeight) / 480)), weak));
    // Photo's height
    solver.add(eq(photo.bottom, c.plus(photo.y, photoHeight), medium));
    // Photo doesn't go off the top.
    //solver.add(geq(photo.y, 0, medium));
    //   Actually, make it more interesting, have the photo track at 1/3 position when going off the top.
    solver.add(geq(photo.y, c.times(c.plus(infoBar.y, c.times(scrollPosition, (height - photoHeight) / 480)), 0.2), weak));

    // Shadow goes above the photo; could make it get more opaque as we scroll up or something...
    solver.add(eq(shadow.bottom, photo.y, medium));
    solver.add(eq(shadow.y, c.plus(shadow.bottom, -5), medium)); // Shadow is 5px tall.

    // The content is similar to the infobar -- it's weakly positioned at the bottom of
    // the screen and is scrolled up. But it's not constrained by the top of the screen.
    // 
    // We add some extra height to the content so that overdragging doesn't expose the map
    // underneath. This is pretty hacky.
    var extraContentHeight = 1000;
    solver.add(eq(content.bottom, c.plus(content.y, contentHeight + extraContentHeight), medium));
    solver.add(eq(content.y, c.plus(height, scrollPosition), medium));

    context.addManipulator(createManipulator(scrollPosition, parentElement, 'y'));

    // This is the physics model we use for our constraints: a critically damped spring, so no extra bounces.
    function physicsModel() { return new Gravitas.Spring(1, 440, 37); }
    // Don't drag the infobar off of the bottom.
    context.addMotionConstraint(new Slalom.MotionConstraint(infoBar.bottom, '<=', height, { overdragCoefficient: 0.75, physicsModel: physicsModel }));
    // Don't expose the bottom of the content.
    context.addMotionConstraint(new Slalom.MotionConstraint(content.bottom, '>=', height + extraContentHeight, { overdragCoefficient: 0.75, physicsModel: physicsModel }));

    // This is a motion constraint with a complicated predicate which snaps the position when
    // the photo hasn't reached the top of the screen yet. We don't want to leave the UI with
    // the photo half-way up the screen...
    var motionConstraint = new Slalom.MotionConstraint(photo.y,
        function(a, b, naturalEnd, startPosition) {
            // We want to say that the photo's y has to either be the same as the infobar's
            // y or it has to be less than zero. If it's zero or less then we don't care to
            // enforce anything.
            if (a <= 0) return 0;
            if (Math.round(a) >= Math.round(infoBar.y.valueOf())) return 0;

            // Where do we want it to end with y = 0, or with y = (height - 80) which is the
            // home position.
            var target = 0;
            if (naturalEnd >= height/2) target = height - 80;
            // If we started from the photo being above the origin then we will only go there.
            if (startPosition <= -5) target = 0;

            return target - a;
        }, 0, { overdragCoefficient: 0, physicsModel: physicsModel, captive: false });
    context.addMotionConstraint(motionConstraint);
    // Add a second motion constraint that prevents the infobar from partially covering
    // the photo when the photo is at the top of the screen.
    // This prevents us from getting stuck between 
    // Note: this constraint isn't captive, we want it to overflow into scrolling.
    motionConstraint = new Slalom.MotionConstraint(infoBar.y,
        function(a, b, naturalEnd) {
            // If the photo isn't touching the top then we're not enforcing.
            if (photo.y.valueOf() >= 0) return 0;

            var topTarget = 0 - 80 + 55;
            var bottomTarget = photoHeight;

            if (naturalEnd > 0) return bottomTarget - a;
            return topTarget - a;
        }, 0, { overdragCoefficient: 0, physicsModel: physicsModel });
    context.addMotionConstraint(motionConstraint);
    context.update();
}

window.addEventListener('load', makeGoogleMapsExample, false);
