class SubscribeMailer < ApplicationMailer

  def subscribe_send(email)
     @email = email
     @url  = 'http://www.make-retail.ru'
     mail(to: 'mail@make-retail.ru', subject: 'Получен запрос на подписку (из сайта)')
  end
end