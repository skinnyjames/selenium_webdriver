require "../spec_helper"

describe SeleniumWebdriver do
  describe "element behavior" do
    it "should navigate on link click" do
      with_browser("link_start.html") do |browser|
        browser.a.click
        h1 = browser.element(id: "destination")
        h1.text.should eq "Link Destination" 
      end
    end
  end
end