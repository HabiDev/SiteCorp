class ContactQuoteMailer < ApplicationMailer
  default from: 'habfanis@gmail.com'
   
  def contact_quote_send(name, email, message)
     @message = message
     @email = email
     @name = name
     @url  = 'http://www.make-retail.ru'
     mail(to: 'habfanis@mail.ru', subject: 'Запрос на получение подробной информации (из сайта)')
  end
end
