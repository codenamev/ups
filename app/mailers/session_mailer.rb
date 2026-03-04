# Mailer for sending magic link authentication emails
class SessionMailer < ApplicationMailer
  default from: "ups.dev <auth@send.codenamev.com>"

  def magic_link
    @user = params[:user]
    @token = params[:token]
    @magic_link_url = verify_magic_link_url(token: @token)

    mail(
      to: @user.email,
      subject: "Sign in to your ups.dev account"
    )
  end
end
