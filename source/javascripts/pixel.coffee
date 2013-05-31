$ ->
  schedule = (fct) ->
    clearTimeout(@timeout) if @timeout?
    @timeout = setTimeout(fct,200)

  matrix = undefined
  render = ->
    matrix_json = matrix.to_json()
    matrix = ColourMatrix.from_json(matrix_json)
    image = new PixelImage(matrix,dx(),dy())
    image.render_image('image_canvas','image_img')
    $('#json').html(JSON.stringify(matrix.to_json()))
  update = ->
    update_colours() unless colours_factory
    factory = new ColourDistanceFilter(colours_factory, neighbour_distance())
    matrix = new ColourMatrix(nx(),ny())
    matrix.fill_random(factory)
    #matrix.dump()
    render()

  colours_factory = undefined
  colours_matrix = undefined
  render_colours = ->
    update_colours() unless colours_factory
    colours = _.sortBy(colours_factory.colours, (c) -> c.sort_key())
    colours_matrix = new ColourMatrix(colours,20)
    image = new PixelImage(colours_matrix,20,20)
    image.render_image('colours_canvas','colours_img')
  update_colours = ->
    f = new RandomColourFactory(colour_type(),colour_ranges())
    colours_factory = new ColourSetFactory(f,n_colours(),colour_distance())
    render_colours()
    update()

  colour_type = -> eval $('input:radio[name=colour_type]:checked').val()
  neighbour_distance = -> $('#slider_neighbour_distance').slider("values")
  colour_distance = -> $('#slider_colour_distance').slider("values")
  colour_ranges = -> [ $('#slider_colour_0').slider("values"),
                       $('#slider_colour_1').slider("values"),
                       $('#slider_colour_2').slider("values") ]
  n_colours = ->
    n = parseInt($('input[name=n_colours]').val() )
    n = nx()*ny() if n < 1 or isNaN(n)
    n
  nx = -> $('input[name=nx]').val()
  ny = -> $('input[name=ny]').val()
  dx = -> $('input[name=dx]').val()
  dy = -> $('input[name=dy]').val()

  $('#refresh_colours').click -> update_colours()
  $('#refresh').click -> update()
  $('input[name=n_colours]').on('change keyup', -> update_colours())
  $('input:radio[name=colour_type]').click ->
    update_colour_sliders()
    update_colours()

  $('input[name=nx],input[name=ny],input[name=dx],input[name=dy]').on 'change keyup', -> schedule(update)
  $('#slider_neighbour_distance').slider { range: true, min: 0, max: 100, values: [0,100], slide: -> schedule(update) }
  $('#slider_colour_distance').slider { range: true, min: 0, max: 100, values: [0,100], slide: -> schedule(update) }
  update_colour_sliders = ->
    type = colour_type()
    $.each type.ranges, (i, range) ->
      $("#slider_colour_#{i}").slider { range: true, min: range[0], max: range[1], values: range, slide: -> schedule(update_colours)}
    $.each type.labels, (i, label) -> $("#colour_label_#{i}").html(Locales.t(label))

  update_colour_sliders()
  update_colours()
  #matrix.dump()
