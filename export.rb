# frozen_string_literal: true

require 'yaml'
require 'open-uri'
require 'fileutils'

def export_posts(dir, article)
  export_dir = '/Users/watanabe/github/mysite'
  posts_dir  = File.join(export_dir, '_posts')
  created = Time.iso8601(article['created_at']).strftime('%Y-%m-%d')
  filename = "#{created}-#{dir}.md"
  puts filename
  readme_path = File.join(dir, 'README.md')
  content = File.read(readme_path, encoding: 'UTF-8')
  content.gsub!(/!\[([^\]]*)\]\(([^)]+)\)/) do
    alt = Regexp.last_match(1)
    url = Regexp.last_match(2).strip

    # Keep title part if present: (path "title") or (path 'title')
    # Very simple split: first token is path, remainder is title (if any)
    path, title = url.split(/\s+/, 2)
    title = title ? " #{title}" : ''

    # Do not rewrite absolute/remote links
    if path.start_with?('/', 'http://', 'https://', '#')
      "![#{alt}](#{path}#{title})"
    else
      # normalize "./foo.png" -> "foo.png"
      path = path.sub(%r{\A\./}, '')
      "![#{alt}](/assets/images/#{dir}/#{path}#{title})"
    end
  end
  # Front matterの作成
  categories = Array(article['tags']).filter_map { |t| t['name'] }.uniq

  title = (article['title'] || '').to_s
  yaml_title = title.gsub('"', '\"') # escape double-quotes for YAML

  front_matter = +"---\n"
  front_matter << "layout: post\n"
  front_matter << "title: \"#{yaml_title}\"\n"
  front_matter << "categories:\n"
  categories.each do |c|
    front_matter << "  - \"#{c.to_s.gsub('"', '\"')}\"\n"
  end
  front_matter << "---\n\n"
  content = front_matter + content
  out_post_path = File.join(posts_dir, filename)
  File.write(out_post_path, content, mode: 'w', encoding: 'UTF-8')
  pngs = Dir.glob(File.join(dir, '*.png'))
  images_dir = File.join(export_dir, 'assets', 'images', dir)
  pngs.each do |src|
    dest = File.join(export_dir, 'assets', 'images', src)
    FileUtils.mkdir_p(images_dir)
    FileUtils.cp(src, dest)
  end
end

def main
  data = YAML.safe_load(File.open('qiita.yaml'))
  dirlist = YAML.safe_load(File.open('dirlist.yaml'))

  data.sort! { |a, b| b['created_at'] <=> a['created_at'] }
  data.each do |article|
    title = article['title']
    next unless dirlist[title]

    dir = dirlist[title]
    export_posts(dir, article)
  end
end

main
