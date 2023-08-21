#!/usr/bin/env ruby
require 'ox'
require 'open-uri'
require 'sanitize'

feed = Ox.load URI('https://www.perfil.com/feed').open.read.strip, mode: :hash
# see ./perfil.feed.example.xml for a formatted sample feed
items = feed[:rss][1][:channel][:item]


feed = Ox.load URI('https://www.perfil.com/feed').open.read.strip
channel_node = feed.root.channel
items = channel_node.nodes.select { |node| node.value == "item" }

def cdata(node)
  node.nodes.first.value
end

notas = items.map do |item|
  {
    title: cdata(item.title),
    url: item.link.text,
    description: Sanitize.fragment(cdata(item.description)).strip,
    date: DateTime.parse(item.pubDate.text)
  }
end

today = Time.now.getlocal('-03:00')
page_header = <<~HTML
  <!DOCTYPE html>
  <html>
    <head>
      <title>Dejá de hueve.ar - Perfil.com</title>
      <meta content="width=device-width, initial-scale=1" name="viewport">
      <meta charset="utf-8">
      <style>
        body {
          background-color: #222;
          font: 14px sans-serif;
          color: #f6f4ea;
        }
        .articles {
          line-height: 2;
          margin: 2em;
        }
        .articles, .articles a {
          color: #aaa;
        }
        .articles a.link-to-story {
          color: #f6f4ea;
        }
      </style>
    </head>
    <body>
      <h1>Perfil.com</h1>
      <h2>Snapshot del #{today.strftime('%d/%m')}</h2>
      <div class="articles">
HTML

page_footer = <<~HTML
      </div>
      <em>Snapshot generado el #{today}. Todos los horarios son locales de Argentina (GMT-3)</em>
    </body>
  </html>
HTML

today = Date.today
File.open('perfil.html', 'w') { |page|
  page.write(page_header)
  notas.each { |nota|
    fecha = nota[:date]
    relative_date = fecha.strftime(fecha.to_date == today ? '%H:%M' : '%d/%m %H:%M')
    article = <<~ARTICLE
      <div class="article">
        <a class="link-to-story" href="#{nota[:url]}">#{nota[:title]}</a> | #{relative_date}
        <p>#{nota[:description]}</p>
      </div>
    ARTICLE
    page.write(article)
  }
  page.write(page_footer)
}
