class User < ActiveRecord::Base
    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable and :omniauthable
    devise :database_authenticatable, :registerable,
        :recoverable, :rememberable, :trackable, :validatable

    has_many :tweeters 

    def setup_client 
        client = Twitter::REST::Client.new do |config|
          config.consumer_key        = self.api_key
          config.consumer_secret     = self.api_secret
          config.access_token        = self.access_token
          config.access_token_secret = self.access_token_secret
        end
        client
    end
end
