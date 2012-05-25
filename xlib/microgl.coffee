class window.MicroGL
  constructor: (opt) ->
    c = document.createElement('canvas')
    @enabled = true
    @gl = c.getContext('webgl', opt) or c.getContext('experimental-webgl', opt)
    if not @gl
      @enabled = false
      return
    
    @uniforms = {}
    @attributes = {}
    @textures = {}

    @TYPESUFFIX = {}
    @TYPESUFFIX[@gl.FLOAT]        = '1fv'
    @TYPESUFFIX[@gl.FLOAT_VEC2]   = '2fv'
    @TYPESUFFIX[@gl.FLOAT_VEC3]   = '3fv'
    @TYPESUFFIX[@gl.FLOAT_VEC4]   = '4fv'
    @TYPESUFFIX[@gl.INT]          = '1iv'
    @TYPESUFFIX[@gl.INT_VEC2]     = '2iv'
    @TYPESUFFIX[@gl.INT_VEC3]     = '3iv'
    @TYPESUFFIX[@gl.INT_VEC4]     = '4iv'
    @TYPESUFFIX[@gl.FLOAT_MAT2]   = 'Matrix2fv'
    @TYPESUFFIX[@gl.FLOAT_MAT3]   = 'Matrix3fv'
    @TYPESUFFIX[@gl.FLOAT_MAT4]   = 'Matrix4fv'
    @TYPESUFFIX[@gl.SAMPLER_2D]   = 'Sampler2D'
    @TYPESUFFIX[@gl.SAMPLER_CUBE] = 'SamplerCube'

    @TYPESIZE = {}
    @TYPESIZE[@gl.FLOAT]      = 1
    @TYPESIZE[@gl.FLOAT_VEC2] = 2
    @TYPESIZE[@gl.FLOAT_VEC3] = 3
    @TYPESIZE[@gl.FLOAT_VEC4] = 4
    @TYPESIZE[@gl.FLOAT_MAT2] = 4
    @TYPESIZE[@gl.FLOAT_MAT3] = 9
    @TYPESIZE[@gl.FLOAT_MAT4] = 16


  init: (elem, width=256, height=256) ->
    @gl.canvas.width = width
    @gl.canvas.height = height
    elem.appendChild(@gl.canvas)
    @gl.viewport(0, 0, width, height)
    @gl.clearColor(0, 0, 0, 1);
    @gl.clearDepth(1);
    @gl.enable(@gl.DEPTH_TEST);
    @gl.depthFunc(@gl.LEQUAL);


  program: (vsSource, fsSource) ->
    initShader = (type, source) =>
      shader = @gl.createShader(type)
      @gl.shaderSource(shader, source)
      @gl.compileShader(shader)
      if not @gl.getShaderParameter(shader, @gl.COMPILE_STATUS)
        console.log(@gl.getShaderInfoLog(shader))
      @gl.attachShader(program, shader)

    program = @gl.createProgram()
    initShader(@gl.VERTEX_SHADER, vsSource)
    initShader(@gl.FRAGMENT_SHADER, fsSource)

    @gl.linkProgram(program)
    if not @gl.getProgramParameter(program, @gl.LINK_STATUS)
      console.log(@gl.getProgramInfoLog(program))

    @gl.useProgram(program)
    for i in [0...@gl.getProgramParameter(program, @gl.ACTIVE_UNIFORMS)]
      uniform = @gl.getActiveUniform(program, i)
      @uniforms[uniform.name] = {
        location: @gl.getUniformLocation(program, uniform.name)
        type: uniform.type
        size: uniform.size # array length
      }
    for i in [0...@gl.getProgramParameter(program, @gl.ACTIVE_ATTRIBUTES)]
      attribute = @gl.getActiveAttrib(program, i)
      location = @gl.getAttribLocation(program, attribute.name)
      @gl.enableVertexAttribArray(location)
      @attributes[attribute.name] = {
        location
        type: attribute.type
        size: attribute.size
      }
    return


  texture: (source, tex) ->
    setTexture = (img) =>
      @gl.bindTexture(@gl.TEXTURE_2D, tex)
      @gl.pixelStorei(@gl.UNPACK_FLIP_Y_WEBGL, true)
      @gl.texImage2D(@gl.TEXTURE_2D, 0, @gl.RGBA, @gl.RGBA, @gl.UNSIGNED_BYTE, img)
      @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_MAG_FILTER, @gl.LINEAR)
      @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_MIN_FILTER, @gl.LINEAR)
      @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_WRAP_S, @gl.CLAMP_TO_EDGE)
      @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_WRAP_T, @gl.CLAMP_TO_EDGE)

    tex ?= @gl.createTexture()
    cst = source.constructor
    if cst is String
      img = document.createElement('img')
      img.onload = ->
        setTexture(img)
      img.src = source
    else if (cst is HTMLImageElement) or (cst is HTMLCanvasElement) or
            (cst is HTMLVideoElement) or (cst is Image) or
            (cst is window.ImageData)
      setTexture(source)
    tex


  variable: (param) ->
    obj = {}
    for own name, value of param
      if name of @uniforms
        obj[name] = value
      else
        buffer = @gl.createBuffer()
        if attribute = @attributes[name]
          @gl.bindBuffer(@gl.ARRAY_BUFFER, buffer)
          @gl.bufferData(@gl.ARRAY_BUFFER, new Float32Array(value), @gl.STATIC_DRAW)
        else
          @gl.bindBuffer(@gl.ELEMENT_ARRAY_BUFFER, buffer)
          @gl.bufferData(@gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(value), @gl.STATIC_DRAW)
        buffer.length = value.length
        obj[name] = buffer
    obj


  bind: (obj) ->
    @_useElementArray = false
    @gl.bindBuffer(@gl.ELEMENT_ARRAY_BUFFER, null)
    texnum = 0
    for own name, value of obj
      if uniform = @uniforms[name]
        suffix = @TYPESUFFIX[uniform.type]
        if ~suffix.indexOf('Sampler')
          type = if suffix is 'Sampler2D' then @gl.TEXTURE_2D else @gl.TEXTURE_CUBE_MAP
          @gl.activeTexture(@gl['TEXTURE' + texnum])
          @gl.bindTexture(type, value)
          @gl.uniform1i(uniform.location, texnum)
          texnum++
        else if ~suffix.indexOf('Matrix')
          @gl["uniform" + suffix](uniform.location, false, new Float32Array(value))
        else
          @gl["uniform" + suffix](uniform.location, value)
      else
        if attribute = @attributes[name]
          size = @TYPESIZE[attribute.type]
          @gl.bindBuffer(@gl.ARRAY_BUFFER, value)
          @gl.vertexAttribPointer(attribute.location, size, @gl.FLOAT, false, 0, 0)
          if not @_useElementArray
            @_numElements = value.length / size
        else
          @gl.bindBuffer(@gl.ELEMENT_ARRAY_BUFFER, value)
          @_numElements = value.length
          @_useElementArray = true
    return
    
    
  bindVars: (param) ->
    @bind(@variable(param))


  draw: (type, num) ->
    num ?= @_numElements
    if @_useElementArray
      @gl.drawElements(@gl[type or 'TRIANGLES'], num, @gl.UNSIGNED_SHORT, 0)
    else
      @gl.drawArrays(@gl[type or 'TRIANGLE_STRIP'], 0, num)
      
      
  clear: ->
    @gl.clear(@gl.COLOR_BUFFER_BIT | @gl.DEPTH_BUFFER_BIT)
    
  
  read: ->
    canv = @gl.canvas
    width = canv.width
    height = canv.height
    array = new Uint8Array(width * height * 4)
    @gl.readPixels(0, 0, width, height, @gl.RGBA, @gl.UNSIGNED_BYTE, array)
    array
    

@requestAnimationFrame = @requestAnimationFrame or @webkitRequestAnimationFrame or @mozRequestAnimationFrame or (f) -> setTimeout(f, 1000/60)