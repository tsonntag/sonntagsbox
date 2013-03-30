$ ->
  rand  = (n) -> Math.random()*n
  nrand = (n) -> Math.floor(rand(n))
  rand  = (n) -> Math.random()*n
  nrand = (n) -> Math.floor(rand(n))
  distance = (a,b) ->
    d0 = a[0]-b[0]; d1 = a[1]-b[1]; d2 = a[2]-b[2]
    d0*d0+d1*d1+d2*d2

  RGBColour.labels   = ['red', 'green', 'blue']
  RGBColour.ranges   = [[0,255], [0,255], [0,255]]
  RGBColour.rand_fct = nrand
  HSLColour.labels   = ['hue', 'saturation', 'lightness']
  HSLColour.ranges   = [[0,360], [0,100], [0,100]]
  HSLColour.rand_fct = rand
  HSVColour.labels   = ['hue', 'saturation', 'value']
  HSVColour.ranges   = [[0,360], [0,100], [0,100]]
  HSVColour.rand_fct = rand
  RGBColour::data = -> _.values(@getRGB())
  HSLColour::data = -> _.values(@getHSL())
  HSVColour::data = -> _.values(@getHSL())
  RGBColour::norm = 3*255*255
  HSLColour::norm = 360*360+2*100*100
  HSVColour::norm = 360*360+2*100*100

  Colour::distance = (that) -> distance(@data(), that.data()) / @norm
  Colour::to_s = (that) -> "(#{@data()})"

  class RandomColourFactory
    constructor: (@colour_type, @colour_ranges) ->
    colour: ->
      [arg0,arg1,arg2] = _.map @colour_ranges, (colour_range) =>
        [min,max] = colour_range
        _.random min, max
      new @colour_type(arg0,arg1,arg2)

  # returns colour with distance to distance_colours
  class ColourDistanceFilter
    constructor: (@factory, @distance) ->
    colour: (distance_colours) ->
      max_try = 500
      while max_try -= 1
        colour = @factory.colour()
        break if _.every(distance_colours, (nb) =>
          [min,max] = @distance
          (min/100) <= colour.distance(nb) <= (max/100)
        )
      console.log "max tries exceeded" if max_try <= 0
      colour

  # returns random colour from set of n colours with given distance
  class ColourSetFactory
    constructor: (@factory, @n, @distance) ->
      factory = new ColourDistanceFilter(@factory, @distance)
      @colours = []
      for i in [0..@n-1]
        @colours.push factory.colour(@colours.slice(0,i))
    colour: -> @colours[_.random(0,@n-1)]
    dump: ->
      head = _.reduce @colours, ((res,c) ->"#{res}  #{c.to_s()}"), '      '
      console.log "--------#{@n}----distance=#{@distance}"
      console.log head
      for colour in @colours
        line = _.reduce @colours, ((res,c) -> "#{res}: #{colour.distance(c)}"), ''
        console.log "#{colour.to_s()}: #{line}"

  class ColourMatrix
    constructor: (@nx,@ny,@factory) ->
      @n = @nx*@ny
      @data = new Array(@n)
      @points = (i for i in [0..@n-1])
      @xs = (i%@nx for i in @points)
      @ys = (Math.floor(i/@nx) for i in @points)
      @update(@factory)
    x: (point) -> @xs[point]
    y: (point) -> @ys[point]
    update: ->
      _.each _.shuffle(@points), (point) =>
        @set point, @factory.colour(@neighbour_colours(point))
      this
    colour: (point)     -> @data[point]
    set: (point,colour) -> @data[point] = colour
    neighbours: (point) ->
      nb = []
      nb.push(point-1)   if @x(point) > 0
      nb.push(point+1)   if @x(point) < @nx-1
      nb.push(point-@nx) if @y(point) > 0
      nb.push(point+@ny) if @y(point) < @ny-1
      nb
    neighbour_colours: (point) -> c for nb in @neighbours(point) when (c = @colour(nb))?
    point_to_s: (p)-> "#{@x(p)},#{@y(p)} #{@colour(p).to_s()}"
    dump: ->
      _.each @points, (p) =>
        console.log @point_to_s(p)
        c = @colour(p)
        for nb in @neighbours(p)
          console.log "   #{@point_to_s(nb)} dist=#{c.distance(@colour(nb))}"

  class PixelImage
    constructor: (@matrix,@dx,@dy) ->
      @width  = @matrix.nx*@dx
      @height = @matrix.ny*@dy
    render_canvas: (canvas)->
      canvas.setAttribute('width', @width)
      canvas.setAttribute('height',@height)
      ctx = canvas.getContext('2d')
      _.each @matrix.points, (p) =>
        ctx.beginPath()
        ctx.rect(@dx*@matrix.x(p),@dy*@matrix.y(p),@dx,@dy)
        ctx.fillStyle = @matrix.colour(p).getCSSHexadecimalRGB()
        ctx.fill()
      this
    render_image: (canvas,image)->
      @render_canvas(canvas)
      image.src = canvas.toDataURL()
      this

  schedule = (fct) ->
    clearTimeout(@timeout) if @timeout?
    @timeout = setTimeout(fct,200)

  matrix = undefined
  colour_set_factory = undefined
  canvas = document.getElementById('canvas')
  canvas_img = document.getElementById('canvas_img')
  render = ->
    image = new PixelImage(matrix,dx(),dy())
    image.render_image(canvas,canvas_img)
  update = ->
    factory = colour_set_factory() ? new RandomColourFactory(colour_type(),colour_ranges())
    factory = new ColourDistanceFilter(factory, neighbour_distance())
    matrix = new ColourMatrix(nx(),ny(),factory)
    #matrix.dump()
    render()

  colour_set_factory = ->
    if n_colours() > 0
      f = new RandomColourFactory(colour_type(),colour_ranges())
      f = new ColourSetFactory(f,n_colours(),colour_distance())
      f.dump()
      f
    else
      undefined

  colour_type = -> eval $('input:radio[name=colour_type]:checked').val()
  neighbour_distance = -> $('#slider_neighbour_distance').slider("values")
  colour_distance = -> $('#slider_colour_distance').slider("values")
  colour_ranges = -> [ $('#slider_colour_0').slider("values"),
                       $('#slider_colour_1').slider("values"),
                       $('#slider_colour_2').slider("values") ]
  n_colours = -> $('input[name=n_colours]').val()
  nx = -> $('#slider_nx').slider("value")
  ny = -> $('#slider_ny').slider("value")
  dx = -> $('#slider_dx').slider("value")
  dy = -> $('#slider_dy').slider("value")

  $('#refresh').click -> update()
  $('input[name=n_colours]').change ->
    $('#slider_colour_distance').slider(disabled: (n_colours() < 2))
    update()
  $('input:radio[name=colour_type]').click ->
    update_colour_sliders()
    update()

  slider_setup = (selector,range,min,max,value,orientation,fct) ->
    slide = -> schedule(fct)
    $(selector).slider { range, min, max, value, 'values': value, orientation,slide }

  slider_setup '#slider_nx', false, 1, 100, 15, 'horizontal', update
  slider_setup '#slider_ny', false, 1, 100, 15, 'horizontal', update
  slider_setup '#slider_dx', false, 1,  80, 20, 'horizontal', render
  slider_setup '#slider_dy', false, 1,  80, 20, 'horizontal', render
  slider_setup '#slider_neighbour_distance', true, 0, 100, [0,100], 'horizontal', update
  slider_setup '#slider_colour_distance',    true, 0, 100, [0,100], 'horizontal', update
  update_colour_sliders = ->
    type = colour_type()
    $.each type.ranges, (i, range) ->
      slider_setup "#slider_colour_#{i}", true, range[0], range[1], range, 'horizontal', update
    $.each type.labels, (i, label) ->
      label = Locales.t label
      $("#colour_label_#{i}").html(label)

  update_colour_sliders()
  update()
  render()
  #matrix.dump()
