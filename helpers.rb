%w(gmail mail uri httpclient).each { |dependency| require dependency }

def String.random_alphanumeric(size=16)
  s = ""
  size.times { s << (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }
  s
end

def mkdir!(directory) 
  if !FileTest::directory?(directory)
    Dir::mkdir(directory)
  end
end

def process!(email)
  begin
    links = {}

    email.body.parts.each do |part|
      find_links!(part.decoded, links)
    end

    links.each do |key, val|
      true_link = follow_redirects(key)

      save_page(key, val, true_link)
    end

    send_email(email, links)
  ensure
    #email.mark(:unread)
  end
  links
end

def follow_redirects(link)
  httpc = HTTPClient.new
  resp = httpc.get(link)
  resp.header['Location']
end

def send_email(email, links) 
  begin
    data = prepare_email(links)
    mail(email.from, 'wgetmetest@gmail.com', email.subject + ' -> TEXTED!!1!', data)
  ensure
    cleanup(links)
  end
end

def mail(email_to, email_from, email_subject, email_text)

  yml = YAML::load(File.open('config/config.rb'))

  gmail = Gmail.new(yml['gmail']['username'], yml['gmail']['password']) do |gmail|
    gmail.deliver do
      to email_to
      from email_from
      subject email_subject
      text_part do
        body email_text
      end
    end
  end
end

def prepare_email(links)
  retval = ''
  links.each do |key,val|
    File.open(val, "r") do |f|
      data = f.read
      retval = retval + '>> ' + key + '

' + data + '
      
      
      
'
    end
  end
  retval
end

def find_links!(part, links)
  arr = part.scan(/http[s]?:\/\/[a-zA-Z0-9\/\.\_-]*/)
  arr.each do |entry|
    if /www\.w3\.org/.match(entry).nil? \
      and /schemas\.microsoft/.match(entry).nil?
      links[entry] = 'tmp/' + String.random_alphanumeric()
    end
  end
end

def save_page(link, file, true_link) 
  mkdir!("tmp")
  system("/usr/bin/links -dump " + link + " > " + file)
end

def cleanup(links)
 links.each do |key, val|
    File.delete(val)
  end
end
