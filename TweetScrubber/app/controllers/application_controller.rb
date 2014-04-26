class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  def require_login
	    unless user_signed_in?
	      flash[:error] = "You must be logged in to access this section"
	      redirect_to root_path # halts request cycle
	    else
            @user = current_user
        end
  	end
end
