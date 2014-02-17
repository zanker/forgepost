class Usercp::SettingsController < Usercp::BaseController
  def edit
  end

  def update
    user = User.where(:_id => current_user._id).first
    user.email_market = params[:email_market] != "false"

    # Now the user
    unless user.valid?
      return respond_with_model(user)
    end

    # We're good
    flash[:success] = t("usercp.settings.edit.settings_updated")

    user.save(:validate => false)
    account.save(:validate => false) if account

    render :nothing => true, :status => :no_content
  end
end