desc 'Receive and store unread emails'

#https://github.com/mikel/mail/issues/403
def message_body(mail)
  if mail.multipart?
    charset = mail.text_part.content_type_parameters[:charset]
    message_body = mail.text_part.body.to_s.force_encoding(charset).encode("UTF-8")
  else
    charset = mail.content_type_parameters[:charset]
    message_body = mail.body.decoded.force_encoding(charset).encode("UTF-8")
  end
  message_body
end


task :pull_emails => [:environment] do
  puts "Receving emails..."
  Mail.defaults do
    retriever_method :imap,
                     :address    => "imap.coderouge.ovh",
                     :port       => 993,
                     :user_name  => Rails.application.credentials.dig(:geopos_email, :user_name),
                     :password   => Rails.application.credentials.dig(:geopos_email, :password),
                     :enable_ssl => true
  end

  not_seen = Mail.find(keys: ['NOT', 'SEEN'])
  # not_seen = [Mail.last]
  puts "Not seen: #{not_seen}"

  not_seen.map do |mail|
    email = Email.new
    email.subject = mail.subject
    email.from = mail.from.to_s
    email.date = mail.date
    email.message_id = mail.message_id
    email.body = message_body(mail)
    email.save
  end

end

