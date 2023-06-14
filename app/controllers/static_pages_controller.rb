class StaticPagesController < ApplicationController

  def home; end
  def about; end
  def contact; end
  def service; end
  def service_adaptation; end
  def service_consalting; end
  
  def contact_quote_send
    name = params[:name]
    email = params[:email]
    message = params[:message]
    ContactQuoteMailer.contact_quote_send(name, email, message).deliver_later
    redirect_to root_path
  end
  
  def feedback_send
    name = params[:name]
    email = params[:email]
    subject = params[:subject]
    message = params[:message]
    FeedbackMailer.feedback_send(name, email, subject, message).deliver_later
    redirect_to contact_path
  end

  def subscribe_send
    email = params[:email]
    SubscribeMailer.subscribe_send(email).deliver_later
    redirect_to root_path
  end
end
