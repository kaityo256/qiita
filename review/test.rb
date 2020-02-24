require 'redcarpet'
require 'redcarpet/render/review'
render = Redcarpet::Render::ReVIEW.new()
mk = Redcarpet::Markdown.new(render)
puts mk.render(ARGV[0])
