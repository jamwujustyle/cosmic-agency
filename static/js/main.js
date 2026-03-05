$(document).ready(function () {
  // Open Fancybox programmatically on gallery image click.
  // This avoids Slick Slider swallowing click events on <a> tags,
  // which caused the "4 clicks to close" bug.
  $(document).on("click", ".slider-for .gallery-image", function (e) {
    e.preventDefault();
    e.stopPropagation();

    // Build gallery from original (non-cloned) slides only
    var gallery = [];
    $(".slider-for .slick-slide:not(.slick-cloned) .gallery-image").each(
      function () {
        gallery.push({
          src: $(this).data("full-src"),
          caption: $(this).data("caption") || "",
        });
      },
    );

    // Find index of current slide
    var currentIndex = $(".slider-for").slick("slickCurrentSlide");

    Fancybox.show(gallery, {
      startIndex: currentIndex,
      infinite: true,
      closeClick: "content",
      Toolbar: {
        display: {
          left: [],
          middle: [],
          right: ["close"],
        },
      },
      keyboard: {
        Escape: "close",
        Delete: "close",
        Backspace: "close",
        ArrowRight: "next",
        ArrowLeft: "prev",
      },
    });
  });

  // Initialize Slick Slider Syncing
  $(".slider-for").slick({
    slidesToShow: 1,
    slidesToScroll: 1,
    arrows: false,
    fade: true,
    asNavFor: ".slider-nav",
  });

  $(".slider-nav").slick({
    slidesToShow: 4,
    slidesToScroll: 1,
    asNavFor: ".slider-for",
    dots: false,
    centerMode: false,
    focusOnSelect: true,
    arrows: true,
    responsive: [
      {
        breakpoint: 768,
        settings: {
          slidesToShow: 3,
        },
      },
      {
        breakpoint: 480,
        settings: {
          slidesToShow: 2,
        },
      },
    ],
  });
});
