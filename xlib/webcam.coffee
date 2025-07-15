class window.WebCam
  constructor: (canplayCallback, failCallback) ->
    userMedia = navigator.getUserMedia or navigator.webkitGetUserMedia
    if not userMedia
      return failCallback?()
    
    @video = document.createElement('video')
    @video.addEventListener('canplay', =>
      @width = @video.videoWidth
      @height = @video.videoHeight
      @video.play()
      canplayCallback?()
    , false)
    setSourceURL = (src) =>
      @video.srcObject = src

    userMedia.call(navigator, video: facingMode: 'environment', setSourceURL, failCallback)
