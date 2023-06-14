class FeedbackMailer < ApplicationMailer

  def feedback_send(name, email, subject, message)
     @message = message
     @email = email
     @name = name
     @subject = subject
     @url  = 'http://www.make-retail.ru'
     mail(to: 'mail@make-retail.ru', subject: 'Получен обращение от посетителя (из сайта)')
  end
end