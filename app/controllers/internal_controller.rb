class InternalController < ApplicationController
  skip_before_filter :authenticate_user

  def ping
    render :text => "pong"
  end
end