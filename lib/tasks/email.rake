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
    wp.date = v.to_datetime if k == 'date'
    if k == 'latlng'
      lat, lng = v.split(",").map(&:strip)
      wp.latitude = lat
      wp.longitude = lng
    end
  end

  logbook = lines.join("\n").chomp.strip
  wp.logbook = logbook unless logbook.empty?
  wp
end

def parse_waypoint_safe(body)
  begin
    parse_waypoint(body)
  rescue Exception
    puts "Exception raised while processing body '#{body.chomp}'"
  end
end


def create_waypoints(msg_body)
  waypoints = msg_body.split('===').map {|b| parse_waypoint_safe(b)}.compact
  waypoints.each do |w|
    if w&.save
      puts "waypoint saved #{mod_to_s(w)}"
    else
      puts "waypoint NOT saved #{mod_to_s(w)}"
    end

  end

end

task :pull_messages => [:environment] do
  username = Rails.application.credentials.dig(:geopos_email, :user_name, Rails.env.to_sym)
  password = Rails.application.credentials.dig(:geopos_email, :password, Rails.env.to_sym)
  puts "Receving emails for #{username}..."

  Mail.defaults do


    retriever_method :imap,
                     :address    => "imap.coderouge.ovh",
                     :port       => 993,
                     :user_name  => username,
                     :password   => password,
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
    create_waypoints email.body
  end
  FromIndexService.new.perform
end


