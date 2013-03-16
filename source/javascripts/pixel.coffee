$ ->
  rand = (n) -> Math.random()*n
  nrand = (n) -> Math.floor(rand(n))
  RGBColour.rand = -> new RGBColour(nrand(256),nrand(256),nrand(256))
  HSVColour.rand = -> new HSVColour(rand(360),rand(100),rand(100))
  HSLColour.rand = -> new HSLColour(rand(360),rand(100),rand(100))
  colourType = -> $('input:radio[name=colourType]:checked').val()
  render = ->
    canvas = document.getElementById('canvas')
    c = canvas.getContext('2d')
    dy = 40
    dx = 40
    ny = 20
    nx = 20
    for y in [0..ny*dy] by dy
      for x in [0..nx*dx] by dx
        c.beginPath()
        c.rect(x,y,dx,dy)
        c.fillStyle = eval(colourType()).rand().getCSSHexadecimalRGB()
        c.fill()
  $('input:radio[name=colourType]').click -> render()
  $('#refresh').click -> render()

  render()
