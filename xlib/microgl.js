(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty;
  window.MicroGL = (function() {
    function MicroGL(opt) {
      var c;
      c = document.createElement('canvas');
      this.enabled = true;
      this.gl = c.getContext('webgl', opt) || c.getContext('experimental-webgl', opt);
      if (!this.gl) {
        this.enabled = false;
        return;
      }
      this.uniforms = {};
      this.attributes = {};
      this.textures = {};
      this.TYPESUFFIX = {};
      this.TYPESUFFIX[this.gl.FLOAT] = '1fv';
      this.TYPESUFFIX[this.gl.FLOAT_VEC2] = '2fv';
      this.TYPESUFFIX[this.gl.FLOAT_VEC3] = '3fv';
      this.TYPESUFFIX[this.gl.FLOAT_VEC4] = '4fv';
      this.TYPESUFFIX[this.gl.INT] = '1iv';
      this.TYPESUFFIX[this.gl.INT_VEC2] = '2iv';
      this.TYPESUFFIX[this.gl.INT_VEC3] = '3iv';
      this.TYPESUFFIX[this.gl.INT_VEC4] = '4iv';
      this.TYPESUFFIX[this.gl.FLOAT_MAT2] = 'Matrix2fv';
      this.TYPESUFFIX[this.gl.FLOAT_MAT3] = 'Matrix3fv';
      this.TYPESUFFIX[this.gl.FLOAT_MAT4] = 'Matrix4fv';
      this.TYPESUFFIX[this.gl.SAMPLER_2D] = 'Sampler2D';
      this.TYPESUFFIX[this.gl.SAMPLER_CUBE] = 'SamplerCube';
      this.TYPESIZE = {};
      this.TYPESIZE[this.gl.FLOAT] = 1;
      this.TYPESIZE[this.gl.FLOAT_VEC2] = 2;
      this.TYPESIZE[this.gl.FLOAT_VEC3] = 3;
      this.TYPESIZE[this.gl.FLOAT_VEC4] = 4;
      this.TYPESIZE[this.gl.FLOAT_MAT2] = 4;
      this.TYPESIZE[this.gl.FLOAT_MAT3] = 9;
      this.TYPESIZE[this.gl.FLOAT_MAT4] = 16;
    }
    MicroGL.prototype.init = function(elem, width, height) {
      if (width == null) {
        width = 256;
      }
      if (height == null) {
        height = 256;
      }
      this.gl.canvas.width = width;
      this.gl.canvas.height = height;
      elem.appendChild(this.gl.canvas);
      this.gl.viewport(0, 0, width, height);
      this.gl.clearColor(0, 0, 0, 1);
      this.gl.clearDepth(1);
      this.gl.enable(this.gl.DEPTH_TEST);
      return this.gl.depthFunc(this.gl.LEQUAL);
    };
    MicroGL.prototype.program = function(vsSource, fsSource) {
      var attribute, i, initShader, location, program, uniform, _ref, _ref2;
      initShader = __bind(function(type, source) {
        var shader;
        shader = this.gl.createShader(type);
        this.gl.shaderSource(shader, source);
        this.gl.compileShader(shader);
        if (!this.gl.getShaderParameter(shader, this.gl.COMPILE_STATUS)) {
          console.log(this.gl.getShaderInfoLog(shader));
        }
        return this.gl.attachShader(program, shader);
      }, this);
      program = this.gl.createProgram();
      initShader(this.gl.VERTEX_SHADER, vsSource);
      initShader(this.gl.FRAGMENT_SHADER, fsSource);
      this.gl.linkProgram(program);
      if (!this.gl.getProgramParameter(program, this.gl.LINK_STATUS)) {
        console.log(this.gl.getProgramInfoLog(program));
      }
      this.gl.useProgram(program);
      for (i = 0, _ref = this.gl.getProgramParameter(program, this.gl.ACTIVE_UNIFORMS); 0 <= _ref ? i < _ref : i > _ref; 0 <= _ref ? i++ : i--) {
        uniform = this.gl.getActiveUniform(program, i);
        this.uniforms[uniform.name] = {
          location: this.gl.getUniformLocation(program, uniform.name),
          type: uniform.type,
          size: uniform.size
        };
      }
      for (i = 0, _ref2 = this.gl.getProgramParameter(program, this.gl.ACTIVE_ATTRIBUTES); 0 <= _ref2 ? i < _ref2 : i > _ref2; 0 <= _ref2 ? i++ : i--) {
        attribute = this.gl.getActiveAttrib(program, i);
        location = this.gl.getAttribLocation(program, attribute.name);
        this.gl.enableVertexAttribArray(location);
        this.attributes[attribute.name] = {
          location: location,
          type: attribute.type,
          size: attribute.size
        };
      }
    };
    MicroGL.prototype.texture = function(source, tex) {
      var cst, img, setTexture;
      setTexture = __bind(function(img) {
        this.gl.bindTexture(this.gl.TEXTURE_2D, tex);
        this.gl.pixelStorei(this.gl.UNPACK_FLIP_Y_WEBGL, true);
        this.gl.texImage2D(this.gl.TEXTURE_2D, 0, this.gl.RGBA, this.gl.RGBA, this.gl.UNSIGNED_BYTE, img);
        this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_MAG_FILTER, this.gl.LINEAR);
        this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_MIN_FILTER, this.gl.LINEAR);
        this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_WRAP_S, this.gl.CLAMP_TO_EDGE);
        return this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_WRAP_T, this.gl.CLAMP_TO_EDGE);
      }, this);
      if (tex == null) {
        tex = this.gl.createTexture();
      }
      cst = source.constructor;
      if (cst === String) {
        img = document.createElement('img');
        img.onload = function() {
          return setTexture(img);
        };
        img.src = source;
      } else if ((cst === HTMLImageElement) || (cst === HTMLCanvasElement) || (cst === HTMLVideoElement) || (cst === Image) || (cst === window.ImageData)) {
        setTexture(source);
      }
      return tex;
    };
    MicroGL.prototype.variable = function(param) {
      var attribute, buffer, name, obj, value;
      obj = {};
      for (name in param) {
        if (!__hasProp.call(param, name)) continue;
        value = param[name];
        if (name in this.uniforms) {
          obj[name] = value;
        } else {
          buffer = this.gl.createBuffer();
          if (attribute = this.attributes[name]) {
            this.gl.bindBuffer(this.gl.ARRAY_BUFFER, buffer);
            this.gl.bufferData(this.gl.ARRAY_BUFFER, new Float32Array(value), this.gl.STATIC_DRAW);
          } else {
            this.gl.bindBuffer(this.gl.ELEMENT_ARRAY_BUFFER, buffer);
            this.gl.bufferData(this.gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(value), this.gl.STATIC_DRAW);
          }
          buffer.length = value.length;
          obj[name] = buffer;
        }
      }
      return obj;
    };
    MicroGL.prototype.bind = function(obj) {
      var attribute, name, size, suffix, texnum, type, uniform, value;
      this._useElementArray = false;
      this.gl.bindBuffer(this.gl.ELEMENT_ARRAY_BUFFER, null);
      texnum = 0;
      for (name in obj) {
        if (!__hasProp.call(obj, name)) continue;
        value = obj[name];
        if (uniform = this.uniforms[name]) {
          suffix = this.TYPESUFFIX[uniform.type];
          if (~suffix.indexOf('Sampler')) {
            type = suffix === 'Sampler2D' ? this.gl.TEXTURE_2D : this.gl.TEXTURE_CUBE_MAP;
            this.gl.activeTexture(this.gl['TEXTURE' + texnum]);
            this.gl.bindTexture(type, value);
            this.gl.uniform1i(uniform.location, texnum);
            texnum++;
          } else if (~suffix.indexOf('Matrix')) {
            this.gl["uniform" + suffix](uniform.location, false, new Float32Array(value));
          } else {
            this.gl["uniform" + suffix](uniform.location, value);
          }
        } else {
          if (attribute = this.attributes[name]) {
            size = this.TYPESIZE[attribute.type];
            this.gl.bindBuffer(this.gl.ARRAY_BUFFER, value);
            this.gl.vertexAttribPointer(attribute.location, size, this.gl.FLOAT, false, 0, 0);
            if (!this._useElementArray) {
              this._numElements = value.length / size;
            }
          } else {
            this.gl.bindBuffer(this.gl.ELEMENT_ARRAY_BUFFER, value);
            this._numElements = value.length;
            this._useElementArray = true;
          }
        }
      }
    };
    MicroGL.prototype.bindVars = function(param) {
      return this.bind(this.variable(param));
    };
    MicroGL.prototype.draw = function(type, num) {
      if (num == null) {
        num = this._numElements;
      }
      if (this._useElementArray) {
        return this.gl.drawElements(this.gl[type || 'TRIANGLES'], num, this.gl.UNSIGNED_SHORT, 0);
      } else {
        return this.gl.drawArrays(this.gl[type || 'TRIANGLE_STRIP'], 0, num);
      }
    };
    MicroGL.prototype.clear = function() {
      return this.gl.clear(this.gl.COLOR_BUFFER_BIT | this.gl.DEPTH_BUFFER_BIT);
    };
    MicroGL.prototype.read = function() {
      var array, canv, height, width;
      canv = this.gl.canvas;
      width = canv.width;
      height = canv.height;
      array = new Uint8Array(width * height * 4);
      this.gl.readPixels(0, 0, width, height, this.gl.RGBA, this.gl.UNSIGNED_BYTE, array);
      return array;
    };
    return MicroGL;
  })();
  this.requestAnimationFrame = this.requestAnimationFrame || this.webkitRequestAnimationFrame || this.mozRequestAnimationFrame || function(f) {
    return setTimeout(f, 1000 / 60);
  };
}).call(this);
