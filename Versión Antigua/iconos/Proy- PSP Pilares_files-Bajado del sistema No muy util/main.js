$(document).ready(function () {
    $('.drawer').drawer();
    $('.btn-tap-form').on('click', function () {
        $('.tap-form').toggleClass('form-hide');
        $('.glass').toggleClass('hide');

        if ($(this).css('right') === '-96px') {
            $(this).css('right', '-446px');
        } else {
            $(this).css('right', '-96px');
        }

        const $child = $(this).children('.oi');
        if ($child.hasClass('oi-caret-bottom')) {
            $child
                .removeClass('oi-caret-bottom')
                .addClass('oi-caret-top')
        } else {
            $child
                .removeClass('oi-caret-top')
                .addClass('oi-caret-bottom')
        }
    });

    $('.btn-tap-form-mobile, .oi.oi-x').on('click', function () {
        $('.form-mobile').toggleClass('form-hide');
    });

    $('.prop-menu  > .prop-list-item > li > a').on('click', function () {
        const $info = $(this).siblings('.prop-list-item__info');
        $(this)
            .parent()
            .siblings()
            .children('.active')
            .removeClass('active')
            .children('.oi.oi-caret-bottom')
            .removeClass('oi-caret-bottom')
            .addClass('oi-caret-right');
        $(this)
            .addClass('active')
            .children('.oi.oi-caret-right')
            .removeClass('oi-caret-right')
            .addClass('oi-caret-bottom');
        $('.prop-list-item__info').addClass('hide');
        if ($(this).attr('href') !== '#prop-summary') {
            $('.side-menu-button').addClass('hide');
        } else {
            $('.side-menu-button').removeClass('hide');
        }
        $('.prop-container').addClass('hide');
        $($(this).data('tap')).removeClass('hide');
        $($(this).data('menu-btn')).removeClass('hide');
        if ($info.length) {
            $info.removeClass('hide');
        }
    });
    $('[data-toggle="tooltip"]').tooltip();
    $('[data-toggle="popover"]').popover({ html: true });
    $('.select2').select2();
    $('.datepicker').datepicker({ format: 'dd/mm/yyyy' });
    $('.glass').on('click', function() {
        $('.btn-tap-form').trigger('click');
    });

    let href = window.location.href;
    let tap = href.substr(href.indexOf("#"));
    if (tap === '#prop-summary') {
        tab = $('a[data-tap="#prop-summary"]');
    }
    let tab;
    if (tap === '#prop-properties') {
        tab = $('a[data-tap="#prop-properties"]');
    }
    if (tap === '#prop-documents') {
        tab = $('a[data-tap="#prop-documents"]');
    }
    if (tab !== undefined && tab.length) {
        tab.click();
    }
    if ($(document).width() < 1127) {
        $('.prop-container').removeClass('hide');
    }
    $(window).resize(function() {
        if ($(document).width() < 1127) {
            $('.prop-container').removeClass('hide');
        }
    });
});