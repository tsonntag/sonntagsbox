# coding: utf-8

class Arr
  def initialize els, indent = ""
    @els = els
    @indent = indent
  end

  def to_elm
    if @els.is_a? String
      @els
    else
      ar = @els.map do |el|
        Arr.new(el,"  ").to_elm()
      end.join( "\n" + @indent + ", " )
      "[" +
        "\n" +
        @indent + "  " + ar + "\n" +
        @indent + "]"
    end
  end

end

class ColorList
  def initialize(nitem)
    @nitem = nitem
  end

  @@colors = %w( red green black magenta darkorange gold )
  @@farben = %w( rot grün gelb blau schwarz weiß lila )

  @@ncolors = @@colors.size
  @@nfarben = @@farben.size

  def list
    (1..@nitem).map do |i|
      rcolor = @@colors[Random.rand(@@ncolors)]
      rfarbe = @@farben[Random.rand(@@nfarben)]
        "( #{i}, \"#{rfarbe}\", \"#{rcolor}\" )"
    end
  end

  def self.list nitem
    ColorList.new(nitem).list
  end
end

nlist = ARGV[0].to_i
nitem = ARGV[1].to_i

lists = (1..nlist).map do |l|
  ColorList.list(nitem)
end
list =  Arr.new(lists).to_elm
lines = list.split("\n").map{|l| "  " + l}.join("\n")

puts <<EOS
module ItemLists exposing (..)

data =
#{lines}
EOS
