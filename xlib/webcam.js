(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  window.WebCam = (function() {
    function WebCam(canplayCallback, failCallback) {
      var setSourceURL, userMedia;
      userMedia = navigator.getUserMedia || navigator.webkitGetUserMedia;
      if (!userMedia) {
        return typeof failCallback === "function" ? failCallback() : void 0;
      }
      this.video = document.createElement('video');
      this.video.addEventListener('canplay', __bind(function() {
        this.width = this.video.videoWidth;
        this.height = this.video.videoHeight;
        this.video.play();
        return typeof canplayCallback === "function" ? canplayCallback() : void 0;
      }, this), false);
      setSourceURL = __bind(function(src) {
        return this.video.srcObject = src;
      }, this);
      try {
        userMedia.call(navigator, {
          video: true
        }, setSourceURL, failCallback);
      } catch (e) {
        userMedia.call(navigator, 'video', setSourceURL, failCallback);
      }
    }
    return WebCam;
  })();
}).call(this);
