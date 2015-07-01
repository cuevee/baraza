require 'rails_helper'

describe NewslettersController do
  context "update" do
    it "should update and approve the newsletter if params[:commit] is APPROVE" do
      sign_in(create(:administrator))
      newsletter = create(:newsletter)
      category = create(:category)
      cn = CategoryNewsletter.create(newsletter: newsletter, category: category)
      patch :update, "newsletter"=>{
                       "category_newsletters_attributes"=>[{"position_in_newsletter"=>"100", "category_id"=>category.id, "newsletter_id"=>newsletter.id, "id" => cn.id}], "articles_attributes"=>[],},
                       "commit"=>"Approve", "id"=>newsletter.id

      expect(CategoryNewsletter.where(newsletter: newsletter, category: category).first.position_in_newsletter).to eq(100)
      expect(newsletter.reload.status).to eq(Newsletter::Status::APPROVED)
    end

    it "should remove article params which dont have ids in article_ids" do
      sign_in(create(:administrator))
      newsletter = create(:newsletter)
      category = create(:category)
      cn = CategoryNewsletter.create(newsletter: newsletter, category: category)
      article1 = create(:article)
      article2 = create(:article)
      article3 = create(:article)
      newsletter.articles << [article1, article2, article3]
      patch :update, "newsletter"=>{"article_ids"=>[article1.id],
                                    "articles_attributes"=>[{"position_in_newsletter"=>"1", "id"=>article1.id}, {"position_in_newsletter"=>"2", "id"=>article2.id}, {"position_in_newsletter"=>"3", "id"=>article3.id}]},
                                    "commit"=>"Approve", "id"=>newsletter.id

      expect(newsletter.reload.articles).to eq([article1])
    end
  end
end
