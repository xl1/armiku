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
      url = window.URL or window.webkitURL
      @video.src = if url then url.createObjectURL(src) else src
    
    try
      userMedia.call(navigator, video: true, setSourceURL, failCallback)
    catch e
      userMedia.call(navigator, 'video', setSourceURL, failCallback)