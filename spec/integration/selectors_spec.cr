require "../spec_helper"

describe SeleniumWebdriver do
  describe "Basic selectors" do
    it "selects by attribute" do
      with_browser("selectors.html") do |browser|
        link = browser.a(class: "link-destination")
        link.text.should eq "Link"

        div = browser.div(id: "div1")
        div.text.should eq "Div text"
      end
    end

    it "locates all elements" do
      with_browser("html_patterns.html") do |browser|
        browser.body.should_not be(nil)
        browser.header.h1(class: /mega-ns/).text.should eq("HTML")
        browser.header(index: 1).a(title: /site title/i).text.should eq("Site title")
      end
    end
  end
end
