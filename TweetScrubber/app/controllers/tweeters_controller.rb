class TweetersController < ApplicationController
	before_filter :require_login
	before_filter :gon_set_paths

	def show
		@tweeters = @user.tweeters
		gon.tweeters =  @tweeters
	end

	def add_many
		user_ids = add_many_params
		result = Tweeter.add_many(@user, user_ids)
		respond_to do |format|
			format.json {render json: result }
		end
	end

	def add
		gon.tweeter_add = true;
	end

	def table
		tweeters = @user.tweeters
		respond_to do |format|
			format.csv {send_data Tweeter.to_csv(tweeters) }
			format.html {@table = Tweeter.tablify(tweeters) } #default
		end

	end

	def load_description
		tuid = load_description_params
		tweeter = Tweeter.find_by_twitter_id tuid
		respond_to do |format|
			format.json {render json: tweeter.get_description(@user)}
		end
	end 

	def load_timeline
		params = load_timeline_params
		tweeter = Tweeter.find_by_twitter_id params[:user_id]
		respond_to do |format|
			format.json {render json: tweeter.get_timeline(@user)}
		end
	end

	def update_many
		if Tweeter.update_all(update_many_params)
			respond_to do |format|
				format.json {render json: {status: "success"}}
			end
		else
			respond_to do |format|
				format.json {render json: {status: "error"}}
			end
		end
	end

	private

		def gon_set_paths
			gon.tweeter_add_many_url = tweeters_add_many_url
			gon.tweeter_load_timeline_url = tweeters_load_timeline_url
			gon.tweeter_update_many_url = tweeters_update_many_url
			gon.tweeter_load_description_url = tweeters_load_description_url
		end

		def add_many_params
			params.require(:user_ids)
		end

		def update_many_params
			params.require(:updates)
		end

		def load_timeline_params
			params.permit([:user_id, :max_len])
		end

		def load_description_params
			params.require(:user_id)
		end 

end
