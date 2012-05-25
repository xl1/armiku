IDMAT4 = -> [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]

### variables ###
perspective = IDMAT4()
glWidth = glHeight = 0

videoModel = {}
#cubeModel = {}
models = []

gl = webcam = detector = null


### 3次元ベクトル ###
class Vec3
  constructor: (@x, @y, @z) ->
  copy: -> new Vec3(@x, @y, @z)
  add: (v) -> new Vec3(@x + v.x, @y + v.y, @z + v.z)
  mul: (a) -> new Vec3(@x * a, @y * a, @z * a)
  sub: (v) -> @add(v.mul(-1))
  dot: (v) -> @x * v.x + @y * v.y + @z * v.z
  cross: (v) -> new Vec3(
    @y * v.z - @z * v.y,
    @z * v.x - @x * v.z,
    @x * v.y - @y * v.x
  )
  len: -> Math.sqrt(@.dot(@))
  normalize: -> if l = @len() then @.mul(1/l) else @.copy()
  toArray: -> [@x, @y, @z]
  toString: -> 'Vec3(' + @toArray().join(', ') + ')'


makeTransformMatrix = (origin, ex, ey, ez) ->
  [
    a, b, c, d
    e, f, g, h
    i, j, k, l
  ] = [
    ex.x, ey.x, ez.x, origin.x
    ex.y, ey.y, ez.y, origin.y
    ex.z, ey.z, ez.z, origin.z
  ]
  [
    a-d, e-h, i-l, 0
    b-d, f-h, j-l, 0
    c-d, g-h, k-l, 0
      d,   h,   l, 1
  ]


makeModelViewMatrix = (fovx, width, height, corners) ->
  depth = 0.5 * width / Math.tan(fovx / 360 * Math.PI)

  projected = (jx, jy) -> new Vec3(
    jx - width / 2,
    jy - height / 2,
    -depth
  )

  proj = (projected(j.x, j.y) for j in corners)
  normalTop    = proj[0].cross(proj[1])
  normalRight  = proj[1].cross(proj[2])
  normalBottom = proj[2].cross(proj[3])
  normalLeft   = proj[3].cross(proj[0])

  markerAX = normalTop.cross(normalBottom).normalize()
  markerAY = normalLeft.cross(normalRight).normalize()
  markerAZ = markerAX.cross(markerAY).normalize()

  det   = normalTop.z
  rate1 = proj[0].x * markerAX.y - proj[0].y * markerAX.x
  rate0 = proj[1].x * markerAX.y - proj[1].y * markerAX.x  
  p0 = proj[0].mul(-rate0 / det)
  p1 = proj[1].mul(-rate1 / det)
  p2 = p0.add(markerAY)
  q0 = p0.add(markerAZ.mul(-1))
  
  makeTransformMatrix(p0, p1, p2, q0)


makePerspective = (fovx, aspect, near, far) ->
  width  = 2 * near * Math.tan(fovx * Math.PI / 360)
  height = width / aspect;
  x = 2 * near / width
  y = 2 * near / height
  z = (near + far) / (near - far)
  p = 2 * near * far / (near - far)
  [
    x, 0, 0, 0,
    0, y, 0, 0,
    0, 0, z, -1,
    0, 0, p, 0
  ]


# utilities

$ = (i) -> document.getElementById(i)

get = (url, callback) ->
  xhr = new XMLHttpRequest()
  xhr.open('GET', url, true)
  xhr.onload = -> callback(xhr.responseText)
  xhr.send()
  
  
### マーカーを表示する ###
showMarker = ->
  img = document.createElement('img')
  img.src = 'marker.gif'
  img.onload = -> document.body.appendChild(img)
  
  
### モデルつくる ###
loadModels = (data) ->
  (gl.variable {
    uSampler:  gl.texture('miku.png')
    aPosition: d.position
    aTexCoord: d.texCoord
    Index:     d.index
  } for d in data)


### 毎フレーム呼ばれる ###
update = ->
  gl.clear()
  gl.bindVars {
    uSampler: gl.texture(webcam.video)
  }
  gl.bind(videoModel)
  gl.draw()
  
  markers = detector.detect {
    data: gl.read()
    width: glWidth
    height: glHeight
  }
  for marker in markers
    gl.bindVars {
      uPerspective: perspective
      uModelView: makeModelViewMatrix(60, glWidth, glHeight, marker.corners)
    }
#    gl.bind(cubeModel)
#    gl.draw()
    for m in models
      gl.bind(m)
      gl.draw()
  requestAnimationFrame(update)


### gl を初期化して update を呼ぶ ###
init = ->
  glWidth  = 300
  glHeight = 300 * webcam.height / webcam.width |0
  perspective = makePerspective(60, glWidth / glHeight, 0.1, 100)
  
  gl.init(document.body, glWidth, glHeight)
  requestAnimationFrame(update)


main = ->
  gl = new MicroGL()
  if not gl.enabled
    return showMarker()
  gl.program($('vshader').textContent, $('fshader').textContent)

  webcam = new WebCam(init, showMarker)

  detector = new AR.Detector()

  videoModel = gl.variable {
    uPerspective: IDMAT4()
    uModelView:   IDMAT4()
    aPosition:    [-1, -1, 1, -1, 1, 1, 1, -1, 1, 1, 1, 1]
    aTexCoord:    [0, 0, 0, 1, 1, 0, 1, 1]
  }
  # cubeModel = gl.variable {
    # uSampler: gl.texture('image.png')
    # aPosition: [
      # 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0
      # 0, 0, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1
    # ]
    # aTexCoord: [
      # 0, 0, 0, 1, 1, 0, 1, 1
      # 1, 0, 1, 1, 0, 0, 0, 1
    # ]
    # Index: [0,1,2, 1,2,3, 2,3,7, 2,7,6, 7,6,5, 6,5,4, 5,4,0, 5,0,1]
  # }
  get('miku.obj.json', (text) ->
    models = loadModels(JSON.parse(text))
  )
  

main()