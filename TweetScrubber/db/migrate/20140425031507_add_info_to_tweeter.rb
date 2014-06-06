class AddInfoToTweeter < ActiveRecord::Migration
  def change
  	change_table :tweeters do |t|
  		t.text :info
  	end
  end
end
