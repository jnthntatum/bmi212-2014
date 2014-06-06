class UsersController < ApplicationController
	before_action :require_login
	
    def show
	end

    def edit
    end

    def update
        if @user.update(user_params)
            flash[:notice] = "Update Successful"
            redirect_to user_show_path
        else
            flash[:error] = "Could not update user"
            redirect_to user_edit_path
        end
    end

    private 

    def user_params
        params.require(:user).permit(:api_key, :api_secret, :access_token, :access_token_secret)
    end
end
