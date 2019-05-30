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

def mod_to_s(mod)
  mod.attributes.map { |key, value| "#{key}=#{value}" }.join('|')
end

##
# latitude: 43.38533
# longitude: 4.821031
# date: Thu May 30 16:46:08 CEST 2019
# ---
# on a attrapé un thon ! barbeuc !!
#


# convert the body into waypoint
def parse_waypoint(body)

  wp = Waypoint.new

  lines = body.lines.map(&:chomp).map(&:strip).reject(&:empty?)

  while lines.any?
    l = lines.shift
    break if l.start_with?("---")

    kv = l.split(":").map(&:strip)
    raise "wrong format exception" if kv.size < 2
    k = kv.shift
    v = kv.join(":")

    wp.latitude = v.to_f if k == 'latitude'
    wp.longitude = v.to_f if k == 'longitude'
    wp.date = Date.parse(v) if k == 'date'
  end

  logbook = lines.join("\n").chomp.strip
  wp.logbook = logbook unless logbook.empty?

  puts "waypoint:  #{mod_to_s(wp)} " 
  wp
end

task :pull_messages => [:environment] do
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


# indexer date : 1 waypoint par date !
# latitude, longitude, date obligatoires
task :process_emails => [:environment] do
  Email.all.each do |email|
    begin
      waypoint = parse_waypoint(email.body)
    rescue Exception
      puts "Exception raised while processing email #{email.id}"
    end

    if waypoint&.save
      puts "waypoint saved #{mod_to_s(waypoint)}"
    end
  end
end

