xml.instruct! :xml, :version => '1.0', :encoding => 'UTF-8'
xml.urlset :xmlns => 'http://www.sitemaps.org/schemas/sitemap/0.9' do
  map.each do |url, priority|
    xml.url do
      xml.loc 'http://mjijackson.com' + url
      xml.priority sprintf('%.1f', priority)
    end
  end
end
