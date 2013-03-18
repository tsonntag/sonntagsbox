$ ->
  rand  = (n) -> Math.random()*n
  nrand = (n) -> Math.floor(rand(n))
  colour_types = 
    rgb:
      type:      RGBColour
      labels:    ['Red', 'Green', 'Blue']
      ranges:    [[0,255], [0,255], [0,255]]
      rand_fct:  nrand
    hsl:
      type:      HSLColour
      labels:    ['Hue', 'Saturation', 'Lightness']
      ranges:    [[0,360], [0,100], [0,100]]
      rand_fct:  rand
    hsv:
      type:      HSVColour
      labels:    ['Hue', 'Saturation', 'Value']
      ranges:    [[0,360], [0,100], [0,100]]
      rand_fct:  rand

  rand_from_range = (rand_fct, range) -> 
    offset = range[0]
    max = range[1]
    Math.min(offset + rand_fct(max+1), max)

  construct = (constructor, args) ->
    F = -> constructor.apply(this,args)
    F.prototype = constructor.prototype
    new F()

  random_colour = ->
    ct = colour_type()
    type = ct['type']
    rand_fct = ct['rand_fct']
    
    args = $.map(colour_ranges, (colour_range,i) -> 
      range = colour_range()
      rand_from_range(rand_fct, range)
    ) 
    color = construct(type, args)
    color

  class ColorMatrix
    constructor: (@nx,@ny) ->
      @data = (new Array(@ny) for ix in [1..@nx])
    get: (x,y)     -> @data[x][y]
    set: (x,y,val) -> @data[x][y] = val
    init: (colour_fct) ->
      @data = ((colour_fct() for iy in [1..@ny]) for ix in [1..@nx]) 
      this
    render: (canvas,dx,dy)->
      canvas.attr('width', @nx*dx)
      canvas.attr('height',@ny*dy)
      c = canvas.get(0).getContext('2d')
      for iy in [0..@ny-1] 
        for ix in [0..@nx-1] 
          c.beginPath()
          c.rect(dx*ix,dy*iy,dx,dy)
          colour = this.get(ix,iy)
          c.fillStyle = colour.getCSSHexadecimalRGB()
          c.fill()
      this

  slider_val = (selector) -> 
    el = $(selector).slider().data('slider')
    el.getValue()

  nx = -> slider_val('#slider_nx',10)
  ny = -> slider_val('#slider_ny',10)
  dx = -> slider_val('#slider_dx',40)
  dy = -> slider_val('#slider_dy',40)
  colour_ranges = [ (-> slider_val('#slider_colour_0')),
                    (-> slider_val('#slider_colour_1')),
                    (-> slider_val('#slider_colour_2')) ]

  colour_type = -> 
    name = $('input:radio[name=colour_type]:checked').val()
    colour_types[name] 

  $('input:radio[name=colour_type]').select -> setup_colour_sliders()

  canvas = $('#canvas')
  matrix = undefined

  render = -> matrix.render(canvas,dx(),dy())
  update = -> 
    matrix = new ColorMatrix(nx(),ny()).init random_colour
    render()

  $('input:radio[name=colour_type]').click update 

  $('#refresh').click update

  slider_setup = (selector,min,max,value,orientation,fct) ->
    $(selector).slider { 
      'min': min,
      'max':   max,
      'step':  1,
      'value': value,
      'orientation': orientation
    } 
    $(selector).slider('setValue',value).on('slide', fct)

  slider_setup '#slider_nx',      1, 100, 20,      'horizontal', update
  slider_setup '#slider_ny',      1, 100, 20,      'vertical',   update
  slider_setup '#slider_dx',      1,  80, 40,      'horizontal', render
  slider_setup '#slider_dy',      1,  80, 40,      'horizontal', render
  setup_colour_sliders = ->
    $.each colour_type()['ranges'], (i, range) ->
      id = '#slider_colour_' + i
      s = slider_setup id, range[0], range[1], range, 'horizontal', update

  setup_colour_sliders()
  update() 
  render()
