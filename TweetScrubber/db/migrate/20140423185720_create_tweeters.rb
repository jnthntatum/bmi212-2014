class CreateTweeters < ActiveRecord::Migration
  def change
    create_table :tweeters do |t|
      	t.timestamps
  		t.string :twitter_user_id, null: false

    end
    add_index :tweeters, :twitter_user_id, unique: true, name: 'tweeters_twitter_user_id_index'
   	change_table :users do |t|
   		t.string :first_name
   		t.string :last_name
   		t.string :api_key
   		t.string :api_secret
   		t.string :access_token
   		t.string :access_token_secret
   	end
  end
end
