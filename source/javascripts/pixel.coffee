$ ->
  rand  = (n) -> Math.random()*n
  nrand = (n) -> Math.floor(rand(n))
  rand  = (n) -> Math.random()*n
  nrand = (n) -> Math.floor(rand(n))
  distance = (a,b) ->
    d0 = a[0]-b[0]; d1 = a[1]-b[1]; d2 = a[2]-b[2]
    Math.sqrt(d0*d0+d1*d1+d2*d2)

  RGBColour.labels   = ['Red', 'Green', 'Blue']
  RGBColour.ranges   = [[0,255], [0,255], [0,255]]
  RGBColour.rand_fct = nrand
  HSLColour.labels   = ['Hue', 'Saturation', 'Lightness']
  HSLColour.ranges   = [[0,360], [0,100], [0,100]]
  HSLColour.rand_fct = rand
  HSVColour.labels   = ['Hue', 'Saturation', 'Value']
  HSVColour.ranges   = [[0,360], [0,100], [0,100]]
  HSVColour.rand_fct = rand
  RGBColour.prototype.data = -> _.keys(@getRGB())
  HSLColour.prototype.data = -> _.keys(@getHSL())
  HSVColour.prototype.data = -> _.keys(@getHSL())

  Colour.prototype.distance = (that) -> distance @data(), that.data()
  Colour.prototype.to_s = (that) -> "(#{@data()})"

  colour_type = -> eval $('input:radio[name=colour_type]:checked').val()

  colour_ranges = [ (-> $('#slider_colour_0').slider("values")),
                    (-> $('#slider_colour_1').slider("values")),
                    (-> $('#slider_colour_2').slider("values")) ]

  class RandomColourFactory
    constructor: (@colour_type) ->
    get_colour: (neighbours) -> 
      @colour()
    colour: ->
      args = $.map colour_ranges, (colour_range,i) => 
        range = colour_range()
        offset = range[0]
        max = range[1]
        Math.min(offset + @colour_type.rand_fct(max+1), max)
      new @colour_type(args[0],args[1],args[2])

  class ColourMatrix
    constructor: (@nx,@ny,@factory) -> 
      @data = (new Array(@ny) for ix in [1..@nx])
      @update(@factory)
    update: (@factory) ->
      @each (x,y) => 
        c = @factory.get_colour(@neighbours(x,y))
        @set x, y, c
      this
    each: (f) -> 
      for y in [0..@ny-1]
        for x in [0..@nx-1]
          f(x,y,@get(x,y))
    get: (x,y)     -> @data[x][y]
    set: (x,y,val) -> @data[x][y] = val
    neighbours: (x,y) ->
      nb = []
      nb.push @get(x-1,y) if x > 0
      nb.push @get(x+1,y) if x < @nx-1
      nb.push @get(x,y-1) if y > 0
      nb.push @get(x,y+1) if y < @ny-1
      nb
    render: (canvas,dx,dy)->
      canvas.attr('width', @nx*dx)
      canvas.attr('height',@ny*dy)
      c = canvas.get(0).getContext('2d')
      @each (ix,iy,colour) => 
        c.beginPath()
        c.rect(dx*ix,dy*iy,dx,dy)
        c.fillStyle = colour.getCSSHexadecimalRGB()
        c.fill()
      this
    dump: -> 
      @each (x,y,c) =>
        console.log "#{x},#{y} c=#{c.to_s()} nb=#{nb.to_s() for nb in @neighbours(x,y)}"

  nx = -> $('#slider_nx').slider("value")
  ny = -> $('#slider_ny').slider("value")
  dx = -> $('#slider_dx').slider("value")
  dy = -> $('#slider_dy').slider("value")

  $('input:radio[name=colour_type]').select -> setup_colour_sliders()

  canvas = $('#canvas')
  matrix = undefined

  render = -> matrix.render(canvas,dx(),dy())
  update = -> 
    factory = new RandomColourFactory(colour_type())
    matrix = new ColourMatrix(nx(),ny(),factory)
    render()

  $('input:radio[name=colour_type]').click ->
    setup_colour_sliders()
    update() 

  $('#refresh').click update

  slider_setup = (selector,range,min,max,value,orientation,fct) ->
    $(selector).slider { 
      'range': range,
      'min': min,
      'max':   max,
      #'step':  1,
      'value': value,
      'values': value,
      'orientation': orientation
      'slide': fct
    } 

  slider_setup '#slider_nx',      false, 1, 100, 20,      'horizontal', update
  slider_setup '#slider_ny',      false, 1, 100, 20,      'horizontal', update
  slider_setup '#slider_dx',      false, 1,  80, 40,      'horizontal', render
  slider_setup '#slider_dy',      false, 1,  80, 40,      'horizontal', render
  setup_colour_sliders = ->
    type = colour_type()
    $.each type.ranges, (i, range) ->
      slider_setup "#slider_colour_#{i}", true, range[0], range[1], range, 'horizontal', update
    $.each type.labels, (i, label) ->
      $("#colour_label_#{i}").html(label)

  setup_colour_sliders()
  update() 
  render()
