class AddUserIdToTweeter < ActiveRecord::Migration
  def change
  	change_table :tweeters do |t|
  		t.integer :user_id
  	end
  	add_index :tweeters, [:user_id], name: :tweeters_user_id_index
  end
end
