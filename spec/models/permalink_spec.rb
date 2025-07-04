require 'rails_helper'

describe "permalink" do
  [ :organization, :project ].each do |model| # model with permalink
    xit "should check weird permalinks for #{model}" do
      %w[with.dots with%percent with$dolars with&ampersands with^carets].each do |permalink|
        FactoryBot.create(model, permalink: permalink).permalink.should == permalink.gsub(/[\.\%\$\&\^]/, '')
      end
    end

    xit "should add class name to numerical permalink for #{model}" do
      %w[1020 1233.2].each do |permalink|
        obj = FactoryBot.create(model, permalink: permalink)
        obj.permalink.should == "#{obj.class.to_s.downcase}-#{permalink.gsub('.', '')}"
      end
    end

    xit "should add integer to #{model} permalink if its already taken" do
      first_obj = FactoryBot.create(model, permalink: "permalink")
      duplicate = FactoryBot.create(model, permalink: "permalink")
      duplicate.permalink.should_not == first_obj.permalink
    end

    it "should replace non-ascii chars with their ascii counterparts" do
      obj = FactoryBot.create(model, permalink: "òéàüñ ìí")
      obj.permalink.should == "oeaun-ii"
    end

    it "should generate a unique permalink to #{model} if none is given" do
      first_obj = FactoryBot.create(model, name: 'Teambox')
      first_obj.permalink.should_not be_nil
      duplicate = FactoryBot.create(model, name: 'Teambox!!!')
      duplicate.permalink.should_not == first_obj.permalink
    end
  end
end
