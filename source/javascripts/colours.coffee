$ ->
  root = exports ? window
  rand  = (n) -> Math.random()*n
  nrand = (n) -> Math.floor(rand(n))
  rand  = (n) -> Math.random()*n
  nrand = (n) -> Math.floor(rand(n))
  distance = (a,b) ->
    d0 = a[0]-b[0]; d1 = a[1]-b[1]; d2 = a[2]-b[2]
    d0*d0+d1*d1+d2*d2

  Colour.from_json = (json) -> new RGBColour(json.r,json.g,json.b,json.a)
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
  HSVColour::data = -> _.values(@getHSV())
  RGBColour::norm = 3*255*255
  HSLColour::norm = 360*360+2*100*100
  HSVColour::norm = 360*360+2*100*100

  Colour::distance = (that) -> distance(@data(), that.data()) / @norm
  Colour::sort_key = -> 
    d = @getHSL()
    d.h*1000000 + d.s*1000 + d.l
  Colour::to_s = -> "(#{@data()})"
  Colour::to_json = -> @getRGB()

  root.RandomColourFactory = class RandomColourFactory
    constructor: (@colour_type, @colour_ranges) ->
    colour: ->
      [arg0,arg1,arg2] = _.map @colour_ranges, (colour_range) =>
        [min,max] = colour_range; _.random min, max
      new @colour_type(arg0,arg1,arg2)

  # returns colour with distance to distance_colours
  root.ColourDistanceFilter = class ColourDistanceFilter
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
  root.ColourSetFactory = class ColourSetFactory
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

  root.ColourMatrix = class ColourMatrix
    constructor: (nx_or_colours, ny_or_nx) ->
      if typeof nx_or_colours == 'object'
        @nx = ny_or_nx
        @ny = Math.ceil(nx_or_colours.length / @nx)
        @colours = nx_or_colours
      else
        @nx = nx_or_colours
        @ny = ny_or_nx
        @colours = new Array(@nx*@ny)
      @n = @nx*@ny
      @points = [0..@n-1]
      @xs = (i%@nx for i in @points)
      @ys = (Math.floor(i/@nx) for i in @points)
    x: (point) -> @xs[point]
    y: (point) -> @ys[point]
    fill_random: (factory) ->
      _.each _.shuffle(@points), (point) =>
        @set point, factory.colour(@neighbour_colours(point))
      this
    colour: (point)     -> @colours[point]
    set: (point,colour) -> @colours[point] = colour
    neighbours: (point) ->
      nb = []
      nb.push(point-1)   if @x(point) > 0
      nb.push(point+1)   if @x(point) < @nx-1
      nb.push(point-@nx) if @y(point) > 0
      nb.push(point+@ny) if @y(point) < @ny-1
      nb
    neighbour_colours: (point) -> c for nb in @neighbours(point) when (c = @colour(nb))?
    point_to_s: (p)-> "#{@x(p)},#{@y(p)} #{@colour(p).to_s()}"
    to_json: -> { nx: @nx, colours: _.map(@colours, (c)->c.to_json()) }
    dump: ->
      _.each @points, (p) =>
        console.log @point_to_s(p)
        c = @colour(p)
        for nb in @neighbours(p)
          console.log "   #{@point_to_s(nb)} dist=#{c.distance(@colour(nb))}"
  ColourMatrix.from_json = (json) -> new ColourMatrix(_.map(json.colours, (js)->Colour.from_json(js)), json.nx)

  root.PixelImage = class PixelImage
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
        if (colour = @matrix.colour(p))?
          ctx.fillStyle = colour.getCSSHexadecimalRGB()
          ctx.fill()
      this
    render_image: (canvas_id,image_id)->
      canvas = document.getElementById(canvas_id)
      image  = document.getElementById(image_id)
      @render_canvas(canvas)
      image.src = canvas.toDataURL()
      this
