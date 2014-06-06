class AddCheckListToTweeters < ActiveRecord::Migration
  def change
  	change_table :tweeters do |t|
  		t.string :spam
  		t.string :cohort
  		t.boolean :updated
  	end
  end
end
