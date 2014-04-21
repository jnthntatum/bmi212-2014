class IndexController < ApplicationController
	# index
	def index
		flash['error'] = "hi"
		flash['info'] = "hi alert"
	end
end
