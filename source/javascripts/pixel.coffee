$ ->
  schedule = (fct) ->
    clearTimeout(@timeout) if @timeout?
    @timeout = setTimeout(fct,200)

  # the picture
  matrix = undefined

  render = ->
		#matrix_json = matrix.to_json()
		#matrix = ColourMatrix.from_json(matrix_json)
    image = new PixelImage(matrix,dx(),dy())
    image.render_image('image_canvas','image_img')
    $('#json').html(JSON.stringify(matrix.to_json()))

  update = ->
    console.log("update")
    update_colours() unless colours_factory
    factory = new ColourDistanceFilter(colours_factory, neighbour_distance())
    matrix = new ColourMatrix(nx(),ny())
    matrix.fill_random(factory)
    render()

  # colours
  colours_factory = undefined

  render_colours = ->
    update_colours() unless colours_factory
    colours = _.sortBy(colours_factory.colours, (c) -> c.sort_key())
    colours_matrix = new ColourMatrix(colours,20)
    image = new PixelImage(colours_matrix,20,20)
    image.render_image('colours_canvas','colours_img')
    $.each colour_type().labels, (i, label) ->
      values = $("#colour_#{i}").slider("values")
      $("#colour_label_#{i}").html(Locales.t(label) + " " + values[0] + " - " + values[1])

  update_colours = ->
    f = new RandomColourFactory(colour_type(),colour_ranges())
    colours_factory = new ColourSetFactory(f,n_colours(),colour_distance())
    render_colours()
    update()

  colour_type = -> eval $('input:radio[name=colour_type]:checked').val()

  neighbour_distance = -> $('#neighbour_distance').slider("values")

  colour_distance = -> $('#colour_distance').slider("values")

  colour_ranges = -> [ $('#colour_0').slider("values"),
                       $('#colour_1').slider("values"),
                       $('#colour_2').slider("values") ]
  n_colours = ->
    n = parseInt($('input[name=n_colours]').val() )
    n = nx()*ny() if n < 1 or isNaN(n)
    n

  nx = -> $('input[name=nx]').val()
  ny = -> $('input[name=ny]').val()

  dx = -> $('input[name=dx]').val()
  dy = -> $('input[name=dy]').val()

  #  callbacks

  $('#refresh_colours').click -> update_colours()

  $('#refresh').click -> update()

  $('input[name=n_colours]').on('change keyup', -> update_colours())

  $('input:radio[name=colour_type]').click ->
    update_colour_sliders()
    update_colours()

  $('input[name=nx],input[name=ny],input[name=dx],input[name=dy]').on 'change keyup', -> schedule(update)

  #$('#slider_neighbour_distance').slider { range: true, min: 0, max: 100, values: [0,100], slide: -> schedule(update) }
  $('#neighbour_distance').on 'change', -> schedule(update)

  #$('#slider_colour_distance').slider { range: true, min: 0, max: 100, values: [0,100], slide: -> schedule(update_colours) }

  update_colour_sliders = ->
    $.each colour_type().ranges, (i, range) ->
      r = range.slice() # dup range since slider modifies values
      #$("#slider_colour_#{i}").slider { range: true, min: r[0], max: r[1], values: r, slide: -> schedule(update_colours)}
    update_colours()

  update_colour_sliders()
