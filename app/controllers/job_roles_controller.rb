class JobRolesController < ApplicationController
  before_action :get_common_technologies, only: %i[ index ]

  require 'open-uri'
  require 'nokogiri'
  require 'pry'
  require 'json'
  require 'active_support/core_ext/hash'
  require 'gemini-ai'

  def home
  end


  def index
    @url =  params[:url]

    if @url.include?("https://rubyonremote.com/jobs/") || @url.include?("https://jobs.gorails.com/jobs/") && @url != nil
      scrap_job_role(@url)
    else
      redirect_to :home, alert: "URL not valid"
    end
  end

  def scrap_job_role(uri)

    html_file = Nokogiri::HTML(URI.open(uri))
    data = get_job_role_data(html_file)
    

    common_technologies = @tech_hash.keys

    @role_name = data['title']
    @company_name = data['hiringOrganization']['name']
    @role_url = uri
    @company_url = data['hiringOrganization']['sameAs']
    @date_posted = data['datePosted']
    @due_date_to_apply = data['validThrough']
    @company_type = 'Product'
    
    if data['employmentType'] == 'full-time' || data['employmentType'] == 'FULL_TIME' 
      @employment_type = 'Full Time'
    elsif data['employmentType'] = 'PART_TIME'
      @employment_type = 'Part Time'
    else 
      'Not defined'
    end
  
    if uri.include? "rubyonremote"
      puts "------RUBYONREMOTE------"

      @work_type = data['jobLocationType'] == 'TELECOMMUTE' ? 'Remote' : data['jobLocationType']
      #Technologies: 
      @tech_array = html_file.css('.menuitem').map { |elem| elem.text }
      @technologies = set_technologies(@tech_array)

      @salary = data['baseSalary']['minValue'] ? data['baseSalary']['minValue'] + '-' + data['baseSalary']['maxValue'] + ' ' + data['baseSalary']['currency'] : data['baseSalary']['value']['value'].to_s + ' ' + data['baseSalary']['currency'] + ' ' + data['baseSalary']['value']['unitText']

      @location = html_file.search('a.job-tags').first.text == "\n\n\n\nRemote - Anywhere\n" ? 'Worldwide' : html_file.search('a.job-tags').first.text

      @job_description = data['description']
    elsif uri.include? "gorails"
      puts '------GORAILS------'
      @work_details = html_file.css('div.flex.flex-col.mt-1.pt-2').children.map { |e| e.text.strip! }.reject(&:blank?)

      @work_type = data['jobLocationType'] == 'TELECOMMUTE' ? 'Remote' : @work_details[1]
      #Technologies:
      @tech_array = common_technologies.select { | tech | data['description'].include? tech ? tech : 'Not defined' }
      @technologies = set_technologies(@tech_array)

      if @work_details.count == 4
        @salary = @work_details[3]
      elsif data['baseSalary']
        @salary = data['baseSalary']['value']['minValue'] ? data['baseSalary']['value']['minValue'].to_s + '-' + data['baseSalary']['value']['maxValue'].to_s + ' ' + data['baseSalary']['currency'] : data['baseSalary']['value']['value'].to_s + '' + data['baseSalary']['value']['unitText']
      else
        @salary = ""
      end
      
      @location = html_file.css('div.flex.flex-shrink-0.items-center.text-sm').text.delete("\n").strip!.tr(',', '-')

      @job_description = html_file.css('div.mt-12.rich-text').text
    else 
      return "Can't track the information"
    end

    # Instantiating a new Gemini AI API client
    begin
      client = Gemini.new(
      credentials: {
        service: 'generative-language-api',
        api_key: ENV['GOOGLE_API_KEY']
      },
      options: { model: 'gemini-1.5-flash', server_sent_events: true }
      )
    
    # Using Gemini AI to get a summary of the Job description, as the Notion API has a limit of 2000 characters for Text fields
      loop do 
        to_summarize = client.generate_content( { contents: { role: 'user', parts: { text: "Please summarize the following text up to 1800 characters maximum (this condition is CRITICAL: you can't surpass the 1800 characters) getting the most important information like Requirements, Benefits and Responsabilities. NOTICE: DO NOT include a note clarifying that you respected the 1800 characters limit nor indicating the total number of characters, because it sums and affects the final count of characters: #{@job_description} " }  }, generationConfig: { maxOutputTokens: 400 } } )
        @job_role_summary = to_summarize["candidates"][0]["content"]["parts"][0]["text"].strip!
        break if @job_role_summary.size < 2000
        puts "The job Role Summary is #{@job_role_summary.size}"
      end

    # Getting a business type with the help of Gemini AI and the context 
      business_type = client.generate_content( { contents: { role: 'user', parts: { text: "In up to 2 words can you tell me what is the company business of the company description given: #{@job_description} " }  } } )
      @company_business = business_type["candidates"][0]["content"]["parts"][0]["text"].strip!
    rescue GeminiError => error
      puts error.class
    end

    @@properties = {
      "Company Name": {
        "title": [
          {
            "text": {
              "content": @company_name
            }
          }
        ]
      },
      "Role Name": {
        "rich_text": [
          {
            "text": {
              "content": @role_name
            }
          }
        ]
      },
      "Company Type": {
        "select": {
          "name": @company_type
        }
      },
      "Company Business": {
        "select": {
          "name": @company_business
        }
      },
      "Employment Type": {
        "rich_text": [
          {
            "text": {
              "content": @employment_type
            }
          }
        ]
      },
      "Work Type": {
        "rich_text": [
          {
            "text": {
              "content": @work_type
            }
          }
        ]
      },
      "Role Url": {
        "rich_text": [
          {
            "text": {
              "content": @role_url,
              "link": { "url": @role_url }
            }
          }
        ]
      },
      "Company Url": {
        "rich_text": [
          {
            "text": {
              "content": @company_url,
              "link": { "url": @company_url }
            }
          }
        ]
      },
      "Salary": {
        "rich_text": [
          {
            "text": {
              "content": @salary
            }
          }
        ]
      },
      "Status": {
        "select": {
          "name": "Test"
        }
      },
      "Technologies": {
        "multi_select": @technologies
      },
      "Location": {
        "multi_select": [
          {
            "name": @location
          }
        ]
      },
      "Date Posted": {
        "rich_text": [
          {
            "text": {
              "content": @date_posted
            }
          }
        ]
      },
      "Due Date": {
        "rich_text": [
          {
            "text": {
              "content": @due_date_to_apply
            }
          }
        ]
      }
    }

    @@children = [
      {
        "object": "block",
        "type": "paragraph",
        "paragraph": {
          "rich_text": [
            {
              "type": "text",
              "text": {
                "content": @job_role_summary
              }
            }
          ]
        }
      }
    ]

    flash[:notice] = "Job role information collected"
  end

  def create_notion_card
    
    client = Notion::Client.new(token: ENV['NOTION_API_TOKEN'])
    
    client.create_page(
      parent: { database_id: ENV['NOTION_TARGET_DB'] }, 
      properties: @@properties,
      children: @@children
    )

    flash[:notice] = "Card added to your Notion DB"
    redirect_to :home    
  end


  private

  def get_job_role_data(html)
    jsons = html.search('script[type="application/ld+json"]')
    json = jsons.children.select { |e|  e.text.include?("JobPosting") } 
    json_string = json[0].text
    
    JSON[json_string]
  end

  def get_common_technologies
    client = Notion::Client.new(token: ENV['NOTION_API_TOKEN'])
    notion_db = client.database(database_id: ENV['NOTION_TARGET_DB'])
  
    @technologies_array = notion_db.properties['Technologies'].multi_select.options


    @tech_hash = { }

    @technologies_array.map do |elem|
      @tech_hash.store( elem.name, elem.color ) 
    end
  end

  def set_technologies(arr)
    @tech_options = []
    
    arr.each do |tech|
      if @tech_hash.keys.include?(tech)
        @tech_options << {name:tech, color: @tech_hash[tech] }  
      else 
        @tech_options << {name:tech, color: 'default' }
      end
    end
    return @tech_options
  end
end
