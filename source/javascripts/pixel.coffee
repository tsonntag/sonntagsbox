$ ->
  rand  = (n) -> Math.random()*n
  nrand = (n) -> Math.floor(rand(n))
  rand  = (n) -> Math.random()*n
  nrand = (n) -> Math.floor(rand(n))
  distance = (a,b) ->
    d0 = a[0]-b[0]; d1 = a[1]-b[1]; d2 = a[2]-b[2]
    d0*d0+d1*d1+d2*d2

  RGBColour.labels   = ['Red', 'Green', 'Blue']
  RGBColour.ranges   = [[0,255], [0,255], [0,255]]
  RGBColour.rand_fct = nrand
  HSLColour.labels   = ['Hue', 'Saturation', 'Lightness']
  HSLColour.ranges   = [[0,360], [0,100], [0,100]]
  HSLColour.rand_fct = rand
  HSVColour.labels   = ['Hue', 'Saturation', 'Value']
  HSVColour.ranges   = [[0,360], [0,100], [0,100]]
  HSVColour.rand_fct = rand
  RGBColour.prototype.data = -> _.values(@getRGB())
  HSLColour.prototype.data = -> _.values(@getHSL())
  HSVColour.prototype.data = -> _.values(@getHSL())
  RGBColour.prototype.norm = 3*255*255
  HSLColour.prototype.norm = 360*360+2*100*100
  HSVColour.prototype.norm = 360*360+2*100*100

  Colour.prototype.distance = (that) -> distance(@data(), that.data()) / @norm
  Colour.prototype.to_s = (that) -> "(#{@data()})"

  colour_type = -> eval $('input:radio[name=colour_type]:checked').val()
  colour_distance = -> $('#slider_colour_distance').slider("values")

  colour_ranges = [ (-> $('#slider_colour_0').slider("values")),
                    (-> $('#slider_colour_1').slider("values")),
                    (-> $('#slider_colour_2').slider("values")) ]

  class RandomColourFactory
    constructor: (@colour_type, @colour_distance) ->
    get_colour: (neighbours) ->
      max_try = 100
      while max_try -= 1
        c = @colour()
        break if _.every(neighbours, (nb) =>
          d = c.distance(nb)
          r = (@colour_distance[0]/100) <= d <= (@colour_distance[1]/100)
          #console.log "#{@colour_distance[0]} #{d} #{@colour_distance[1]}" if not r
          r
        )
      console.log "#{max_try}" if max_try <= 0
      c
    colour: ->
      random_args = $.map colour_ranges, (colour_range,i) =>
        range = colour_range()
        _.random range[0], range[1]
      new @colour_type(random_args[0],random_args[1],random_args[2])

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
      _.each [[1,0],[-1,0],[0,1],[0,-1]], (pair) =>
        x1 = x+pair[0]; y1 = y+pair[1]
        if 0 <= x1 < @nx and 0 <= y1 < @ny
          nb.push c if (c = @get(x1,y1))?
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
        console.log "#{x},#{y} #{c.to_s()}"
        for nb in @neighbours(x,y)
          console.log "   #{nb.to_s()} dist=#{c.distance(nb)}"

  nx = -> $('#slider_nx').slider("value")
  ny = -> $('#slider_ny').slider("value")
  dx = -> $('#slider_dx').slider("value")
  dy = -> $('#slider_dy').slider("value")

  $('input:radio[name=colour_type]').select -> update_colour_sliders()

  canvas = $('#canvas')
  matrix = undefined

  render = -> matrix.render(canvas,dx(),dy())
  update_matrix = ->
    factory = new RandomColourFactory(colour_type(),colour_distance())
    matrix = new ColourMatrix(nx(),ny(),factory)
    #matrix.dump()
    render()

  $('input:radio[name=colour_type]').click ->
    update_colour_sliders()
    update_matrix()

  $('#refresh').click update_matrix

  slider_setup = (selector,range,min,max,value,orientation,fct) ->
    $(selector).slider {
      'range': range, 'min': min, 'max': max,
      'value': value, 'values': value,
      'orientation': orientation
      'slide': fct
    }

  slider_setup '#slider_nx', false, 1, 100, 20, 'horizontal', update_matrix
  slider_setup '#slider_ny', false, 1, 100, 20, 'horizontal', update_matrix
  slider_setup '#slider_dx', false, 1,  80, 40, 'horizontal', render
  slider_setup '#slider_dy', false, 1,  80, 40, 'horizontal', render
  slider_setup '#slider_colour_distance', true, 0, 100, [0,100], 'horizontal', update_matrix
  update_colour_sliders = ->
    type = colour_type()
    $.each type.ranges, (i, range) ->
      slider_setup "#slider_colour_#{i}", true, range[0], range[1], range, 'horizontal', update_matrix
    $.each type.labels, (i, label) ->
      $("#colour_label_#{i}").html(label)

  update_colour_sliders()
  update_matrix() 
  render()
