class JobRolesController < ApplicationController
  before_action :get_technologies, only: %i[ index ]

  require 'open-uri'
  require 'nokogiri'
  require 'pry'
  require 'json'
  require 'active_support/core_ext/hash'

  def index
    #current_url = request.original_url
    
    # GoRails Examples:
    current_url = "https://jobs.gorails.com/jobs/senior-rails-software-engineer-63d8d0c6"

    # Ruby On Remote Examples:
    #current_url = "https://rubyonremote.com/jobs/62977-senior-ruby-on-rails-engineer-at-idelsoft"

    if current_url.include? "rubyonremote"
      ruby_on_remote_card(current_url)
    elsif current_url.include? "gorails" 
      go_rails_card(current_url)
    else
      @response = "Can't track the information"
    end
  end

  def index_api #notion_api_test
    puts @tech_hash.keys
  end



  # Scraping Ruby on Remote Page example
  def ruby_on_remote_card(uri)
       
    html_file = Nokogiri::HTML(URI.open(uri))

    data = get_job_role_data(html_file)

    company_business_array = ['health', 'marketing', 'ecommerce', 'logistics', 'telecommunication']
    
    # Fix this because most of the Job Roles description includes health as a benefit, "health covered, health insurance, etc"
    # (Optional) Use AI or make regex with a collection to check the most common business 
    @company_business = company_business_array.select { | elem | data['description'].downcase.include? elem ? elem : 'Not defined' }[0].capitalize
    @role_name = data['title']
    @company_name = data['hiringOrganization']['name']

    # TODO: Improve company_type, search in the job description about the company (Product) vs (Consultant) etc or discard this field
    @company_type = data['hiringOrganization']['@type']

    @work_type = data['jobLocationType'] == 'TELECOMMUTE' ? 'Remote' : data['jobLocationType']
    @role_url = uri
    @company_url = data['hiringOrganization']['sameAs']
    @salary = data['baseSalary']['minValue'] ? data['baseSalary']['minValue'] + '-' + data['baseSalary']['maxValue'] + ' ' + data['baseSalary']['currency'] : data['baseSalary']['value']['value'].to_s + ' ' + data['baseSalary']['value']['unitText']
    @job_description = data['description']

    # Not included in the JSON body - Getting it from the HTML
    @technologies = html_file.css('.menuitem').map { |elem| elem.text }
    
    # TODO: Improve how to get this field correctly
    # You can validate if the Anywhere tag is present or check by the number of countries added to the location Array}
    # The location Array is not properly implemented, it seems like there's a bug in the page, The Job tag 
    # says 'Remote - US' but there's a list of over 249 countries
    # Validate if there's more than 1 in the array 

    @location_array = data['applicantLocationRequirements'].map { |elem| elem['name'] }

    # Options to get the desired label for location:
    # 1. Get a regex from the aria-label="view remote jobs in Remote - Anywhere"
    # 2. Validate when the First Job-tags is 'Featured'
    # 3. Validate when there're tags like 'Remote - EU' 'Remote - Europe' 'Remote - South America'
    @location = html_file.search('a.job-tags').first.text == "\n\n\n\nRemote - Anywhere\n" ? 'Worldwide' : html_file.search('a.job-tags').first.text

    # extra_notes -  (optional) Added on the board view

    # ADD new fields: 
    
    @date_posted = data['datePosted']
    @due_date_to_apply = data['validThrough']  #Transform into another format
    @employment_type = data['employmentType'] == 'full-time' ? 'Full Time' : 'Not defined'
  end

  # Scraping GoRails Jobs
  def go_rails_card(uri)
    
    html_file = Nokogiri::HTML(URI.open(uri))
    data = get_job_role_data(html_file)
    common_company_business = ['health', 'marketing', 'ecommerce', 'logistics', 'telecommunication', 'recruitment','saas', 'shopify']

    #Add more technologies to the source of technologies
    common_technologies = @tech_hash.keys
    # Manual technologies source array
    #common_technologies = ['ruby on rails', 'ruby', 'stimulus', 'hotwire', 'viewcomponents', 'javascript', 'typescript', 'react', 'vue', 'angular', 'postgresql', 'mysql', 'docker', 'api', 'sidekiq', 'aws']
    
    # (Optional) Use AI or make regex with a collection to check the most common business 
    @company_business = common_company_business.select { | elem | data['description'].downcase.include? elem ? elem : 'Not defined' }
    # Not included in the JSON body - Getting it from the HTML
    @technologies = common_technologies.select { | tech | data['description'].include? tech ? tech : 'Not defined' }

    #For the API 
    @tech_options = []

    @technologies.each do |tech|
      if @tech_hash.keys.include?(tech)
        @tech_options << {name:tech, color: @tech_hash[tech] }  
      else 
        @tech_options << {name:tech, color: default }
      end
    end

    @role_name = data['title']
    @company_name = data['hiringOrganization']['name']

    # TODO: Improve company_type, search in the job description about the company (Product) vs (Consultant) etc or discard this field
    @company_type = data['hiringOrganization']['@type']
    @work_type = data['jobLocationType'] == 'TELECOMMUTE' ? 'Remote' : data['jobLocationType']
    @role_url = uri
    @company_url = data['hiringOrganization']['sameAs']
    
    if data['baseSalary']
      @salary = data['baseSalary']['value']['minValue'] ? data['baseSalary']['value']['minValue'].to_s + '-' + data['baseSalary']['value']['maxValue'].to_s + ' ' + data['baseSalary']['currency'] : data['baseSalary']['value']['value'].to_s + '' + data['baseSalary']['value']['unitText']
    else 
      @salary = ""
    end

    @job_description = data['description']
    
    @location = []

    if data['applicantLocationRequirements']
      @location = data['applicantLocationRequirements'].map { |elem| elem['name'] }
    else 
      @location << "Worldwide"
    end

    #Get locations options from table

    @location_options = []

    @location.each do |loc|
      if @tech_hash.keys.include?(loc)
        @location_options << {name:loc }
      end
    end

    @date_posted = data['datePosted']
    @due_date_to_apply = data['validThrough']  #Transform into another format
    @employment_type = data['employmentType'] == 'FULL_TIME' ? 'Full Time' : 'Not defined'

    # Sending data to the Notion Page

    client = Notion::Client.new(token: ENV['NOTION_API_TOKEN'])

    properties =     {
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
        "multi_select": @tech_options
      },
      "Location": {
        "multi_select": [
          {
            "name": "USA"
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

    children = [
      {
        "object": "block",
        "type": "paragraph",
        "paragraph": {
          "rich_text": [
            {
              "type": "text",
              "text": {
                "content": "<li>Unlike a rigid separation between front end and back end, you'll engage in full-stack development, working with Ruby on Rails and React.</li><li>We prioritize creating an environment where our development team can concentrate on building and delivering features. This involves providing detailed specifications and designs, in which you will play a role, and minimizing distractions.</li><li>While we strive for efficiency, it's important to note that, being a small team in a rapidly growing business, flexibility is key, and embracing challenges is part of the journey for a successful candidate.</li><li><a href=\"https://stackshare.io/Japestrale/pinpoint\">Our full stack can be found&nbsp;<strong>here</strong>.</a></li></ul><div><br><strong>About the Role:</strong></div><ul><li>Collaborate within a squad to facilitate timely feature delivery, actively participating in planning, discovery, and design phases.</li><li>Provide insights and expertise on broader technical decisions impacting the team, including the review of work by junior developers</li><li>Actively suggesting enhancements to our technology stack, coding standards, and processes based on your observations and insights.</li></ul><div><br><strong>About You:</strong></div><ul><li>3-5 years of experience working professionally with Ruby on Rails</li><li>3+ YOE with React, Typescript, Web app development, and MVC frameworks.</li><li>Ability to quickly grasp new concepts and subjects, conduct thorough research, and effectively communicate findings to team members.</li><li>Demonstrated enthusiasm and care for the work performed. A genuine interest in the tasks at hand, coupled with a willingness to learn and grow professionally.</li><li>"
              }
            }
          ]
        }
      }
    ]

    
    client.create_page(
    parent: { database_id: 'bf36075ff6a44ed9a836bdb4efb885e3'}, 
    properties: properties,
    children: children
    )
  end

  private

  def get_job_role_data(html)
    # Get the scripts with type="application/ld+json" and get the one with the JobRole info
    # TODO - validate if the ld+json exists, case https://rubyonremote.com/jobs/61412-junior-software-engineer-at-syntax
    jsons = html.search('script[type="application/ld+json"]')
    json = jsons.children.select { |e|  e.text.include?("JobPosting") } 
    json_string = json[0].text
    
    JSON[json_string]
  end

  def get_technologies
    client = Notion::Client.new(token: ENV['NOTION_API_TOKEN'])

    client.database_query(database_id: 'bf36075ff6a44ed9a836bdb4efb885e3') do |page|  
      @pages = page.results
      @technologies_array = page.results.map { |elem| elem.properties['Technologies'].multi_select }
    end

    @tech_hash = { }

    @technologies_array.map do |elem|
      elem.map do |arr|
        @tech_hash.store( arr.name, arr.color ) 
      end
    end

    # Verify what's the form of the retrieved data for company business and technologies
    # filter = { 
    #   'property': 'Position',
    #    'multi_select': {
    #       'is_not_empty': true
    #    }
    # }

    #Brings whole database and is not easy to get the data
    #@data = client.database_query(database_id: '8e5a839422664a3499c69ca34f5c912c', filter:filter)  
  end
end
