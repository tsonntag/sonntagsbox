$ ->
  rand  = (n) -> Math.random()*n
  nrand = (n) -> Math.floor(rand(n))
  RGBColour.rand = -> new RGBColour(nrand(r()+1),nrand(g()+1),nrand(b()+1))
  HSLColour.rand = -> new HSLColour(rand(360),rand(100),rand(100))
  HSVColour.rand = -> new HSVColour(rand(360),rand(100),rand(100))

  class ColorMatrix
    constructor: (@nx,@ny) ->
      @data = (new Array(@ny) for ix in [1..@nx])
    get: (x,y)     -> @data[x][y]
    set: (x,y,val) -> @data[x][y] = val
    randomize: (colour_type) ->
      @data = ((colour_type.rand() for iy in [1..@ny]) for ix in [1..@nx]) 
      this
    render: (canvas,dx,dy)->
      canvas.attr('width', @nx*dx)
      canvas.attr('height',@ny*dy)
      c = canvas.get(0).getContext('2d')
      for iy in [0..@ny-1] 
        for ix in [0..@nx-1] 
          c.beginPath()
          c.rect(dx*ix,dy*iy,dx,dy)
          color = this.get(ix,iy)
          c.fillStyle = color.getCSSHexadecimalRGB()
          c.fill()
      this

  slider_val = (selector,_default) -> $(selector).slider().data('slider')?.getValue()	? _default

  nx = -> slider_val('#slider_nx',10)
  ny = -> slider_val('#slider_ny',10)
  dx = -> slider_val('#slider_dx',40)
  dy = -> slider_val('#slider_dy',40)
  r = -> slider_val('#slider_color_1',255)
  g = -> slider_val('#slider_color_2',255)
  b = -> slider_val('#slider_color_3',255)

  colour_type = -> $('input:radio[name=colour_type]:checked').val()

  canvas = $('#canvas')
  matrix = undefined

  render = -> matrix.render(canvas,dx(),dy())
  update = -> 
    matrix = new ColorMatrix(nx(),ny()).randomize eval(colour_type())
    render()

  $('input:radio[name=colour_type]').click update 

  $('#refresh').click update

  slider_setup = (selector,value,fct) ->
    $(selector).slider('setValue',value).on('slide', fct)

  slider_setup '#slider_nx', 10, update
  slider_setup '#slider_ny', 10, update
  slider_setup '#slider_dx', 40, render
  slider_setup '#slider_dy', 40, render
  slider_setup '#slider_color_1', 255, update
  slider_setup '#slider_color_2', 255, update
  slider_setup '#slider_color_3', 255, update

  update() 
  render()
