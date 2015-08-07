require 'rails_helper'

describe ArticlesHelper do
  context 'cover_image_url_for' do
    it 'should set the cover_image default image url if no image is provided' do
      article = create(:article)
      expect(helper.cover_image_url_for(article)).to eq("http://test.host/assets/z_original.png")
    end

    it 'should set the actual cover_image url, if present' do
      cover_image = double(:cover_image, url: "http://s3_url/x.png")
      article = double(:article, cover_image: cover_image)
      expect(helper.cover_image_url_for(article)).to eq("http://s3_url/x.png")
    end
  end

  context "truncate_summary" do
    it "should reduce the text to 150 characters" do
      article = double(:article, summary: ("*"*75)+" "+("$"*80))
      expect(helper.truncate_summary(article.summary)).to eq(("*"*75)+" "+("$"*74)+"...")
    end
  end
end