/*
  initPhotoSwipeFromDOM function, see
  http://photoswipe.com/documentation/getting-started.html
  This version is derived from the example on the http://photoswipe.com main page.
  Takes all images in the page and makes a PhotoSwape gallery.

  Images should be arranged like this:

  <div class=pswp_image [othe attributes, see below]>
    <a href=""> -- optional link which works w/o javascript
      <img>     -- a thumbnail image
    </a>
    <div>Some HTML</div> -- caption
  </div>

  Attibutes of the 'pswp_image' div:
   data          -- url  of the image
   data-size     -- size of the image
   data-med      -- url  of the medium-size image (if any)
   data-med-size -- size of the medium-size image (if any)
   ==data-author

*/

var PhotoSwipeInitFromDOM = function() {

  var Gallery;

/***********************************************************/
  var closest = function closest(el, fn) {
      return el && ( fn(el) ? el : closest(el.parentNode, fn) ); };

  var onImageClick = function(e) {
      // prevent default
      e = e || window.event;
      e.preventDefault ? e.preventDefault() : e.returnValue = false;
      var eTarget = e.target || e.srcElement;


      var clickedListItem = closest(eTarget,
        function(el) { return el.tagName === 'DIV';});
      if(!clickedListItem) { return; }

      var index = clickedListItem.getAttribute('index');

      if (index) {openPhotoSwipe(index);}
      return false;
  };


/***********************************************************/
/// create a gallery element from <div> block
  var parseElement = function(i, el) {

    el.onclick = onImageClick;
    el.setAttribute('index', i);

    // thumbnail image
    var th = el.getElementsByTagName('img')[0];

    size = el.getAttribute('data-size').split('x');
    // create slide object
    item = {
      el:  el,   // save link to element for getThumbBoundsFn
      th:  th,   // save link to image element
      src: el.getAttribute('data'),
      msrc: th.getAttribute('src'), // thumbnail url
      w: parseInt(size[0], 10),
      h: parseInt(size[1], 10),
      author:  el.getAttribute('data-author'),
      lat:     el.getAttribute('lat'),
      lon:     el.getAttribute('lon'),
      alt:     el.getAttribute('alt'),
      dat:     el.getAttribute('dat'),
      mrk:     el.getAttribute('mrk-src'),
    };


    // caption
    var ccd = el.getElementsByTagName('div');
    for (i=0; i<ccd.length; i++){
      if (ccd[i].innerHTML) {
        item.title = ccd[i].innerHTML;
      }
    }

    var mediumSrc = el.getAttribute('data-med');
    if(mediumSrc) {
      size = el.getAttribute('data-med-size').split('x');
      // "medium-sized" image
      item.m = {
          src: mediumSrc,
          w: parseInt(size[0], 10),
          h: parseInt(size[1], 10)
      };
    }
    // original image
    item.o = {
      src: item.src,
      w: item.w,
      h: item.h
    };
    return item;
  };


/***********************************************************/
  // parse hash string
  var photoswipeParseHash = function() {
    var hash = window.location.hash.substring(1);
    var params = {};

      if(hash.length < 3) {return params;} // a=b

      var vars = hash.split('&');
      for (var i = 0; i < vars.length; i++) {
          if(!vars[i]) { continue; }
          var pair = vars[i].split('=');
          if(pair.length < 2) {
              continue;
          }
          params[pair[0]] = pair[1];
      }
      return params;
  };


/***********************************************************/
  var openPhotoSwipe = function(index, disableAnimation, fromURL) {

    // Define PhotoSwipe options
    // See: http://photoswipe.com/documentation/options.html
    var options = {
        index: parseInt(index, 10),

        getThumbBoundsFn: function(index) {
            // See Options->getThumbBoundsFn section of docs for more info
            var rect = Gallery[index].th.getBoundingClientRect();
            var pageYScroll = window.pageYOffset || document.documentElement.scrollTop;
            return {x:rect.left, y:rect.top + pageYScroll, w:rect.width};
        },

        addCaptionHTMLFn: function(item, captionEl, isFake) {
//          var text = '<table border=0 bgcolor=white width=100%><tr><td>';
//          if(item.title) { text += item.title; }
//          text += '</td><td>';
//          if(item.dat) { text += '<br>Date and time: ' + item.dat; }
//          if(item.alt) { text += '<br>Altitude: ' + item.alt; }
//          if(item.lat && item.lat) { text += '<br>Coordinates: ' + item.lat; }
//          text += '</td></tr></table>';
//          captionEl.children[0].innerHTML = text;

          var text = '';
          if(item.title) { text += item.title + '<br>'; }
          if(item.dat) { text += 'date and time: ' + item.dat; }
          if(item.lat && item.lon) { text += '<br>coordinates: ' + item.lat + ',' + item.lon; }
          if(item.alt) { text += ' altitude: ' + item.alt; }
          captionEl.children[0].innerHTML = text;

          return true;
        },
    };


    // exit if index not found
    if( isNaN(options.index) ) { return; }


//      options.mainClass = 'pswp--minimal--dark';
//      options.barsSize = {top:0,bottom:0};
//      options.captionEl = false;
//      options.fullscreenEl = false;
//      options.shareEl = false;
//      options.bgOpacity = 0.5;
//      options.tapToClose = true;
//      options.tapToToggleControls = false;

    if(disableAnimation) { options.showAnimationDuration = 0; }

    // Pass data to PhotoSwipe and initialize it
    var pswpElement = document.querySelectorAll('.pswp')[0];
    var pswp = new PhotoSwipe( pswpElement, PhotoSwipeUI_Default, Gallery, options);

    // see: http://photoswipe.com/documentation/responsive-images.html
    var realViewportW, realViewportH,
        useLargeImages = false,
        firstResize = true,
        imageSrcWillChange;

    pswp.listen('beforeResize', function() {
      var dpiRatio = window.devicePixelRatio ? window.devicePixelRatio : 1;
      dpiRatio = Math.min(dpiRatio, 2.5);
      realViewportW = pswp.viewportSize.x * dpiRatio;
      realViewportH = pswp.viewportSize.y * dpiRatio;
      if (!realViewportW) {realViewportW = screen.width;}
      if (!realViewportH) {realViewportH = screen.heigh;}
    });

    pswp.listen('gettingData', function(index, item) {
        if (item.m && (realViewportW < item.m.w
                    || realViewportH < item.m.h)) {
          item.src = item.m.src;
          item.w = item.m.w;
          item.h = item.m.h;
        } else {
          item.src = item.o.src;
          item.w = item.o.w;
          item.h = item.o.h;
        }
    });

      pswp.init();
  };

/***********************************************************/


  //Add hidden html element for PhotoSwipe pages
  var html=[
  '  <div class="pswp__bg"></div>',
  '  <div class="pswp__scroll-wrap">',
  '    <div class="pswp__container">',
  '      <div class="pswp__item"></div>',
  '      <div class="pswp__item"></div>',
  '      <div class="pswp__item"></div>',
  '    </div>',
  '    <div class="pswp__ui pswp__ui--hidden">',
  '      <div class="pswp__top-bar">',
  '        <div class="pswp__counter"></div>',
  '        <button class="pswp__button pswp__button--close" title="Close (Esc)"></button>',
  '        <button class="pswp__button pswp__button--share" title="Share"></button>',
  '        <button class="pswp__button pswp__button--fs" title="Toggle fullscreen"></button>',
  '        <button class="pswp__button pswp__button--zoom" title="Zoom in/out"></button>',
  '        <div class="pswp__preloader">',
  '          <div class="pswp__preloader__icn">',
  '            <div class="pswp__preloader__cut">',
  '              <div class="pswp__preloader__donut"></div>',
  '            </div>',
  '          </div>',
  '        </div>',
  '      </div>',
  '      <!--div class="pswp__loading-indicator"><div class="pswp__loading-indicator__line"></div></div-->',
  '      <div class="pswp__share-modal pswp__share-modal--hidden pswp__single-tap">',
  '        <div class="pswp__share-tooltip">',
  '          <!-- <a href="#" class="pswp__share--facebook"></a>',
  '               <a href="#" class="pswp__share--twitter"></a>',
  '               <a href="#" class="pswp__share--pinterest"></a>',
  '               <a href="#" download class="pswp__share--download"></a> -->',
  '        </div>',
  '      </div>',
  '      <button class="pswp__button pswp__button--arrow--left" title="Previous (arrow left)"></button>',
  '      <button class="pswp__button pswp__button--arrow--right" title="Next (arrow right)"></button>',
  '      <div class="pswp__caption" align=left>',
  '        <div class="pswp__caption__center" width=100% align=left></div>',
  '      </div>',
  '    </div>',
  '  </div>'].join('\n');

  var div = document.createElement('div');
  div.setAttribute('id', 'gallery');
  div.setAttribute('class', 'pswp');
  div.setAttribute('tabindex', '-1');
  div.setAttribute('role', 'dialog');
  div.setAttribute('aria-hidden', 'true');
  div.innerHTML = html;
  document.getElementsByTagName('body')[0].appendChild(div);

  // Find pswp images.
  var images = document.getElementsByClassName('pswp_image');
  Gallery = new Array(images.length);
  for(var i = 0; i < images.length; i++) {
    Gallery[i] = parseElement(i, images[i]);
  }

  // Parse URL hash and open pswp if it contains #pid
  var hashData = photoswipeParseHash();
  if(hashData.pid) {openPhotoSwipe( hashData.pid-1, true, true); }

};
