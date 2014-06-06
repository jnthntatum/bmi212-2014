class Tweeter < ActiveRecord::Base
	belongs_to :user

	def twitter_uid
		self.twitter_user_id.to_i
	end

	# Static Helpers and API crawling methods.
	# TODO: decompose to another module

	def self.add_many ( user, user_ids )
		successes = 0
		user_ids.each do |uid|
			t = Tweeter.new(user_id: user.id, twitter_user_id: uid);
			begin 
				t.save!
				successes = successes + 1
			rescue ActiveRecord::StatementInvalid
				#ignore
			end
		end
		return {status: "success", count: successes}
	end 

	def get_timeline ( user )
		client = user.setup_client
		begin  
			tweets = get_all_tweets client, self.twitter_uid 
			return {
				status: 'success', 
				user_id: self.twitter_user_id, 
				statuses: tweets
			}
		rescue Twitter::Error::NotFound
			return {
				status: 'api error', 
				user_id: self.twitter_user_id, 
				message: 'Entity not found' 
			}
		rescue Twitter::Error::Unauthorized
			return {
				status: 'api auth error', 
				user_id: self.twitter_user_id, 
				message: 'Entity not found' 
			}
		end
	end

	def get_description ( user )
		client = user.setup_client
		begin  
			result = client.user self.twitter_uid
			return {
				status: 'success', 
				user_id: self.twitter_user_id, 
				description: result.to_h
			}
		rescue Twitter::Error::NotFound
			return {
				status: 'api error', 
				user_id: self.twitter_user_id, 
				message: 'Entity not found' 
			}
		rescue Twitter::Error::Unauthorized
			return {
				status: 'api auth error', 
				user_id: self.twitter_user_id, 
				message: 'Bad Authorization' 
			}
		end
	end


	def self.add_all ( user, ids )
		ids.each do |id|
			t = Tweeter.new twitter_user_id: id, user_id: user.id 
			t.save!
		end
	end

	def self.update_all ( updates )
		updates.each do |tuid, update|
			update = Tweeter.safe_params update
			tweeter = Tweeter.find_by_twitter_id tuid
			tweeter.update(update)
			tweeter.save 
		end
	end

	def self.find_by_twitter_id ( twitter_user_id )
		Tweeter.find_by(:twitter_user_id => twitter_user_id)
	end

	def self.tablify(tweeters)
		table = [["twitter_id", "spam", "cohort", "curator", "comments"]]
		tweeters.each do |t|
			table << [t.twitter_uid, t.spam, t.cohort, t.user.first_name, t.info]
		end
		return table
	end

	require 'csv'
	
	def self.to_csv(tweeters)
		table = Tweeter.tablify(tweeters)
		CSV.generate do |csv|
			table.each do |row|
				csv << row
			end
		end
	end
	


	private 

	def self.safe_params( update )
		{ 	spam: update[:spam],
			cohort: update[:cohort],
			info: update[:info],
			updated: true
		}

	end
	
	def collect_with_max_id( max_len=Float::INFINITY, collection=[], max_id=nil, &block)
	  response = yield(max_id)
	  collection += response
	  ( response.empty? or collection.length > max_len ) ? collection.flatten : collect_with_max_id(max_len, collection, response.last.id - 1, &block)
	end

	def get_all_tweets(client, user_id, max_len=500)
	  	collect_with_max_id max_len do |max_id|
		    options = {:count => 200, :include_rts => false}
		    options[:max_id] = max_id unless max_id.nil?
		    client.user_timeline(user_id, options)
	    end
  	end

end
