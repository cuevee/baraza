require 'rails_helper'

describe Article do
  context "tag_list" do
    it "should list the tags as comma separated string" do
      tag1 = create(:tag, name: "history")
      tag2 = create(:tag, name: "science")
      article = create(:article)
      article.tags << [tag1, tag2]

      expect(article.tag_list).to eq("history,science")
    end
  end

  context "tag_list=" do
    it "should add tags of the given names" do
      article = create(:article, tag_list: "history,science")
      expect(article.tag_list).to eq("history,science")
    end

    it "should not create same tag again" do
      tag1 = create(:tag, name: "history")
      article = create(:article)
      article.tags << tag1
      article.update_attributes(tag_list: "history,science")
      expect(article.tags.count).to eq(2)
    end

    it "should delete tags" do
      tag1 = create(:tag, name: "history")
      tag2 = create(:tag, name: "science")
      article = create(:article)
      article.tags << [tag1, tag2]
      article.update_attributes(tag_list: "history")
      expect(article.reload.tags.count).to eq(1)
      expect(Tag.count).to eq(2)
    end
  end

  context "search_by_tag", search: true do
    it "should return articles of the given tag_name" do
      tag1 = create(:tag, name: "history")
      tag2 = create(:tag, name: "science")
      article1 = create(:article, content: "article1", tag_list: "#{tag1.name},#{tag2.name}")
      article2 = create(:article, content: "article2", tag_list: tag1.name)

      Article.__elasticsearch__.import force: true
      Article.__elasticsearch__.refresh_index!

      expect(Article.search_by_tag(tag2.name).collect(&:id)).to eq([article1.id.to_s])
    end

    it "should return articles of the given  new tag_name" do
      tag1 = create(:tag, name: "history")
      article1 = create(:article, content: "article1", tag_list: "#{tag1.name},science")
      article2 = create(:article, content: "article2", tag_list: tag1.name)

      Article.__elasticsearch__.import force: true
      Article.__elasticsearch__.refresh_index!

      expect(Article.search_by_tag("science").collect(&:id)).to eq([article1.id.to_s])
    end
  end

  context "as_indexed_json" do
    it "should index including tag names, category names" do
      tag1 = create(:tag, name: "history")
      tag2 = create(:tag, name: "science")
      category = create(:category)
      article = create(:article)
      article.tags << [tag1, tag2]
      article.categories << category

      expect(article.as_indexed_json).to eq({"id"=>article.id,
                                             "title"=>article.title,
                                             "content"=>article.content,
                                             "tags"=>[{"name"=>tag1.name}, {"name"=>tag2.name}],
                                             "categories"=>[{"name"=>category.name}]})
    end
  end

  context "index_name" do
    it "should set the environment along with index" do
      expect(Article.index_name).to eq("articles_#{Rails.env}")
    end
  end

  context "mapping" do
    it "should set snowball analyzer for title and content" do
      mapping = Article.mapping.to_hash[:article][:properties]
      expect(mapping[:title][:analyzer]).to eq("snowball")
      expect(mapping[:content][:analyzer]).to eq("snowball")
      expect(mapping[:tags][:properties]).to eq({:name=>{:index=>"not_analyzed", :type=>"string"}})
      expect(mapping[:categories][:properties]).to eq({:name=>{:index=>"not_analyzed", :type=>"string"}})
    end
  end

  context "index_document" do
    context "tags" do
      it "should update document on adding tags through tag_list", search: true do
        tag1 = create(:tag, name: "history")
        tag2 = create(:tag, name: "science")
        article = create(:article, tag_list: tag1.name)

        article.update_attributes(tag_list: "#{tag1.name},#{tag2.name},abcd")
        Article.__elasticsearch__.refresh_index!
        expect(Article.search_by_tag(tag1.name).collect(&:id)).to eq([article.id.to_s])
        expect(Article.search_by_tag(tag2.name).collect(&:id)).to eq([article.id.to_s])
        expect(Article.search_by_tag("abcd").collect(&:id)).to eq([article.id.to_s])
      end

      it "should update document on removing tags through tag_list", search: true do
        tag1 = create(:tag, name: "history")
        tag2 = create(:tag, name: "science")
        article = create(:article)
        article.tags << [tag1, tag2]

        article.update_attributes(tag_list: "#{tag1.name}")
        Article.__elasticsearch__.refresh_index!
        expect(Article.search_by_tag(tag1.name).collect(&:id)).to eq([article.id.to_s])
        expect(Article.search_by_tag(tag2.name).collect(&:id)).to eq([])
      end
    end
    
    context "categories" do
      it "should update document on adding categories through category_ids", search: true do
        category1 = create(:category, name: "history")
        category2 = create(:category, name: "science")
        article = create(:article, category_ids: [category1.id])
        Article.__elasticsearch__.import force: true

        article.update_attributes(category_ids: [category1.id, category2.id])
        Article.__elasticsearch__.refresh_index!
        expect(Article.search_by_category(category1.name).collect(&:id)).to eq([article.id.to_s])
        expect(Article.search_by_category(category2.name).collect(&:id)).to eq([article.id.to_s])
      end

      it "should update document on removing categories through category_ids", search: true do
        category1 = create(:category, name: "history")
        category2 = create(:category, name: "science")
        article = create(:article)
        article.categories << [category1, category2]
        Article.__elasticsearch__.import force: true

        article.update_attributes(category_ids: [category1.id])
        Article.__elasticsearch__.refresh_index!
        expect(Article.search_by_category(category1.name).collect(&:id)).to eq([article.id.to_s])
        expect(Article.search_by_category(category2.name).collect(&:id)).to eq([])
      end
    end
  end

  context "search_by_category", search: true do
    it "should return articles of the given category name" do
      category1 = create(:category, name: "history")
      category2 = create(:category, name: "science")
      article1 = create(:article, content: "article1")
      article2 = create(:article, content: "article2")
      article1.categories << [category1, category2]
      article2.categories << [category1]
      Article.__elasticsearch__.import force: true
      Article.__elasticsearch__.refresh_index!

      expect(Article.search_by_category(category2.name).collect(&:id)).to eq([article1.id.to_s])
    end
  end

  context "search_by_all", search: true do
    it "should return articles of the given name" do
      category1 = create(:category, name: "history")
      category2 = create(:category, name: "science")
      tag = create(:category, name: "tag1")
      article1 = create(:article, content: "article1", category_ids: [category1.id, category2.id], tag_list: tag.name)
      article2 = create(:article, content: "article2", category_ids: [category1.id])

      Article.__elasticsearch__.import force: true
      Article.__elasticsearch__.refresh_index!

      expect(Article.search_by_all("article1").collect(&:id)).to eq([article1.id.to_s])
      expect(Article.search_by_all(tag.name).collect(&:id)).to eq([article1.id.to_s])
      expect(Article.search_by_all(category2.name).collect(&:id)).to eq([article1.id.to_s])

      expect(Article.search_by_all("article2").collect(&:id)).to eq([article2.id.to_s])

      expect(Article.search_by_all(category1.name).collect(&:id)).to match_array([article1.id.to_s, article2.id.to_s])
    end
  end
end
