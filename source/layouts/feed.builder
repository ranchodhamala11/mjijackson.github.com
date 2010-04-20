xml.instruct! :xml, :version => '1.0', :encoding => "UTF-8"
xml.feed :xmlns => "http://www.w3.org/2005/Atom", :'xml:base' => "http://mjijackson.com/", :'xml:lang' => "en-us" do
  xml.title "mjijackson.com"
  xml.subtitle "Web development and design on the Mac, by Michael J. I. Jackson"
  xml.link :rel => "self", :type => "application/atom+xml", :href => "http://mjijackson.com/index.xml"
  xml.link :rel => "alternate", :type => "text/html", :href => "http://mjijackson.com/"
  xml.id "http://mjijackson.com/"
  xml.updated posts[0].published.xmlschema
  xml.rights "Copyright © 2008-#{Time.now.year}, Michael J. I. Jackson"

  posts.each do |post|
    xml.entry do
      xml.title post.title
      xml.id post.atom_id
      xml.link :rel => "alternate", :type => "text/html", :href => post.alt
      xml.published post.published.xmlschema
      xml.updated post.updated.xmlschema
      xml.author do
        xml.name post.author
        xml.uri "http://mjijackson.com/"
      end
      xml.content :type => "html" do
        cdata = post.to_html
        #cdata = markdown(post.body, false)
        cdata << %{<p>[<a href="#{post.permalink}" title="Permalink">Permalink</a>]</p>} unless post.is_original?
        xml.cdata!(cdata)
      end
    end
  end
end
