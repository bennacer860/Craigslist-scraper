
require 'rubygems'
require 'mechanize'

class Bot
	
  def initialize(state,search,query)
    @state,@search,@query=state,search,query
    @results = Hash.new
    @agent = WWW::Mechanize.new { |agent|
        agent.user_agent_alias = 'Mac Safari'
    }
  end

  def output
       
       File.open("result.html",'w') do |f|
	  @results.each_pair {|key, value| 
	  f.write("#{key}  #{value}\n\n\n") 
	  }       
	end      
  end


  # finds all matches
  def find_all()
    
      find_cities(@state).each do |city|
         #find_jobs_in_city(state,city["href"],@query)	  
	if @state == "dc"
	 search_city(@state,city,@search,@query)
	else
	 search_city(@state,city["href"],@search,@query)
 	end
      end
  end
  
  # Sorts the found elements by the posted date
  def sort!()
    @results.each_value do |jobs|
      jobs.sort! do |x , y|
        d_x = Date.parse(posting_date(x))
        d_y = Date.parse(posting_date(y))
        d_y <=> d_x
      end
    end
  end
  
  private
  
  def find_cities(state)
  #one exception is washington DC
    if @state != "dc"		
      return @agent.get("http://geo.craigslist.org/iso/us/#{state}").search("#list/a")
    else
      dcArea=Array.new
      dcArea << "http://washingtondc.craigslist.org/"		
      return dcArea	
    end	
  end
  

  def find_jobs_in_city(state,city_url,section)
    @options["query"].each do |query|
      search_city(state,city_url,section,query)
    end
  end
  
  def search_city(state,city_url,section,query)

    if @state == "dc"
	current = "Washington DC"
	url	= city_url+"search/#{section}?query=#{query}"
        #puts url+"\n"
    else	
	current = "#{city_name(city_url)} #{state}" 
        url	="#{city_url}search/#{section}?query=#{query}"
        #puts current+" #{city_url}search/#{section}?query=#{query}"
    end

    @results[current] = [] if @results[current].nil?

    begin	
       page=@agent.get(url) 
       #puts "debug\n"  	
       page.search("p").each do |job|
	  #puts job.to_html 
          job.search("a") do |link|
   	    
	    #if the link is relative 
	    if link['href'] !~ /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/ix  		 
            	link['href'] = city_url + link['href']
	    end	
	    #puts link['href']+"<br>"
            link['target'] = "_blank"
	    #puts job.inner_text	 
          end
          @results[current] << job.to_html unless @results[current].include? job.to_html
       end
      	

   
    rescue Exception => e  
	   puts e.message  
	   puts e.backtrace.inspect
	   puts "<p>Failed to get data from #{current}</p>"
    end
  end
  
  def city_name(city_url)
     "#{city_url[/\/{1,1}[A-Za-z]*\./].chop.sub("/","")}" 
  end
  
  def posting_date(job)
    date = job[/[A-Za-z]{3}\s*[0-9]{1,2}/]
    (!date.nil? ?  "#{date}" : "#{Time.now.month} #{Time.now.day}") + " #{Time.now.year}"
  end

end

b=Bot.new("dc","jjj","java")
b.find_all
b.sort!
b.output



