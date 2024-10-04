class JobRolesController < ApplicationController
  before_action :get_common_technologies, only: %i[ index ]

  require 'open-uri'
  require 'nokogiri'
  require 'pry'
  require 'json'
  require 'active_support/core_ext/hash'

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
    common_company_business = ['health', 'marketing', 'ecommerce', 'logistics', 'telecommunication', 'recruitment','saas', 'shopify', 'fintech', 'payment']
      
    common_technologies = @tech_hash.keys
  
    @role_name = data['title']
    @company_name = data['hiringOrganization']['name']
    @work_type = data['jobLocationType'] == 'TELECOMMUTE' ? 'Remote' : data['jobLocationType']
    @role_url = uri
    @company_url = data['hiringOrganization']['sameAs']
    @date_posted = data['datePosted']
    @due_date_to_apply = data['validThrough']
    @company_type = 'Product'   
    @employment_type = data['employmentType'] == 'full-time' || 'FULL_TIME' ? 'Full Time' : 'Not defined'
    business_type = common_company_business.select { | elem | data['description'].downcase.include? elem ? elem : 'Not defined' }
    @company_business = business_type.size > 0 ? business_type[0].capitalize : 'Not defined'
  
    if uri.include? "rubyonremote"
      puts "------RUBYONREMOTE------"
      #Technologies: 
      @tech_array = html_file.css('.menuitem').map { |elem| elem.text }
      @technologies = set_technologies(@tech_array)

      @salary = data['baseSalary']['minValue'] ? data['baseSalary']['minValue'] + '-' + data['baseSalary']['maxValue'] + ' ' + data['baseSalary']['currency'] : data['baseSalary']['value']['value'].to_s + ' ' + data['baseSalary']['currency'] + ' ' + data['baseSalary']['value']['unitText']

      @location = html_file.search('a.job-tags').first.text == "\n\n\n\nRemote - Anywhere\n" ? 'Worldwide' : html_file.search('a.job-tags').first.text

      @job_description = data['description']
    elsif uri.include? "gorails"
      puts '------GORAILS------'
      #Technologies:
      @tech_array = common_technologies.select { | tech | data['description'].include? tech ? tech : 'Not defined' }
      @technologies = set_technologies(@tech_array)

  
      if data['baseSalary']
        @salary = data['baseSalary']['value']['minValue'] ? data['baseSalary']['value']['minValue'].to_s + '-' + data['baseSalary']['value']['maxValue'].to_s + ' ' + data['baseSalary']['currency'] : data['baseSalary']['value']['value'].to_s + '' + data['baseSalary']['value']['unitText']
      else 
        @salary = ""
      end
  
      @location = html_file.css('div.flex.flex-shrink-0.items-center.text-sm').text.delete("\n").strip!.tr(',', '-')

      @job_description = html_file.css('div.mt-12.rich-text').text
    else 
      return "Can't track the information"
    end
  
    
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
    
        children = [
          {
            "object": "block",
            "type": "paragraph",
            "paragraph": {
              "rich_text": [
                {
                  "type": "text",
                  "text": {
                    "content": @job_description
                  }
                }
              ]
            }
          }
        ]
        
        #client.create_page(
        #parent: { database_id: 'bf36075ff6a44ed9a836bdb4efb885e3'}, 
        #properties: properties,
        #children: children
        #)
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

  def get_common_technologies
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
