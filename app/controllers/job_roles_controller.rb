class JobRolesController < ApplicationController
  require 'open-uri'
  require 'nokogiri'
  require 'pry'
  require 'json'
  require 'active_support/core_ext/hash'

  def index
    #current_url = request.original_url

    current_url = "https://rubyonremote.com/jobs/62960-senior-developer-grow-my-clinic-at-jane"
    #current_url = "https://jobs.rubyonrails.org/jobs/886"

    if current_url.include? "rubyonremote" 
      ruby_on_remote_card
    elsif current_url.include? "rubyonrails" 
      rails_job_board_card
    end
  end

  # Scraping Ruby on Remote Page example
  def ruby_on_remote_card
    
    #  Problem with the first ld+json found -Still there, this one doesn't include a Job Posting XML::Node
    #uri = "https://rubyonremote.com/jobs/61412-junior-software-engineer-at-syntax"  
    uri = "https://rubyonremote.com/jobs/62960-senior-developer-grow-my-clinic-at-jane"
      
    html_file = Nokogiri::HTML(URI.open(uri))

    # Get the scripts with type="application/ld+json" and get the one with the JobRole info
    # TODO - validate if the ld+json exists, case https://rubyonremote.com/jobs/61412-junior-software-engineer-at-syntax
    jsons = html_file.search('script[type="application/ld+json"]')
    json = jsons.children.select { |e|  e.text.include?("JobPosting") } 
    json_string = json[0].text
    
    data = JSON[json_string]

    company_business_array = ['health', 'marketing', 'ecommerce', 'logistics', 'telecommunication']
    
    # (Optional) Use AI or make regex with a collection to check the most common business 
    @company_business = company_business_array.select { | elem | data['description'].downcase.include? elem ? elem : 'Not defined' }[0].capitalize
    @role_name = data['title']
    @company_name = data['hiringOrganization']['name']
    @company_type = data['hiringOrganization']['@type']
    @work_type = data['jobLocationType'] == 'TELECOMMUTE' ? 'Remote' : data['jobLocationType']
    @role_url = uri
    @company_url = data['hiringOrganization']['sameAs']
    @salary = data['baseSalary']['minValue'] ? data['baseSalary']['minValue'] + '-' + data['baseSalary']['maxValue'] + ' ' + data['baseSalary']['currency'] : data['baseSalary']['value']['value'].to_s + '' + data['baseSalary']['value']['unitText']
    @job_description = data['description']

    # Not included in the JSON body - Getting it from the HTML
    @technologies = html_file.css('.menuitem').map { |elem| elem.text }
    
    # TODO: Improve how to get this field correctly
    # You can validate if the Anywhere tag is present or check by the number of countries added to the location Array}
    # The location Array is not properly implemented, it seems like there's a bug in the page, The Job tag 
    # says 'Remote - US' but there's a list of over 249 countries
    # Validate if there's more than 1 in the array 
    @location = data['applicantLocationRequirements'].map { |elem| elem['name'] }

    # Options to get the desired label for location:
    # 1. Get a regex from the aria-label="view remote jobs in Remote - Anywhere"
    # 2. Validate when the First Job-tags is 'Featured'
    @location_html = html_file.search('a.job-tags').first.text == "\n\n\n\nRemote - Anywhere\n" ? 'Worldwide' : html_file.search('a.job-tags').first.text


    # extra_notes -  (optional) Added on the board view

    # ADD new fields: 
    #
    # seniority_level = data['experienceRequirements']['monthsOfExperience']  The JSON doesn't include it everytime so if nil == Junior, or get from HTML (job-tags = Junior)
    # date_posted - data['datePosted']
    # due_date_to_apply - data['validThough']
    # employment_type - data['employmentType']
    # company_logo - data['hiringOrganization']['logo']
  end

  # Scraping Rails Job Board Page example
  def rails_job_board_card
    
    uri = "https://jobs.rubyonrails.org/jobs/886"
    
    # If I scrap a similar page it works: 
    # uri = "https://rubyonremote.com/jobs/62960-senior-developer-grow-my-clinic-at-jane" 

    doc = Nokogiri::HTML(URI.open(uri))

    # Nokogiri::XML::Element that includes the CDATA node with the JSON
    json = doc.at('script[type="application/ld+json"]')
    
    #This already has the JSON parse result
    json_string = json.child.text

    data = JSON.load(json_string)
    # I TRIED:
    #data = JSON[json_string]
    #data = JSON.parse(json_string)
    #data = JSON.load(json_string)
    #data = JSON.generate(json_string)
    #data = ActiveSupport::JSON.decode(json_string)

    @role_name = data['title']   
    @company_name = data['hiringOrganization']['name']
    @company_type = data['hiringOrganization']['@type']
    @company_business = data['']  # Use AI or make regex with a collection to check the most common business types ['Health', 'Marketing', 'Ecommerce', etc]
    @work_type = data['jobLocationType'] == 'TELECOMMUTE' ? 'Remote' : data['jobLocationType']
    @role_url = uri
    @company_url = data['hiringOrganization']['sameAs']
    @salary = data['baseSalary'] ? data['baseSalary']['value']['value'] + ' ' + data['baseSalary']['currency'] : empty
    @job_description = data['description']
    @location = data['applicantLocationRequirements']['name']

    # Not included in the JSON body
    
    # date_posted - data['datePosted']
    # due_date_to_apply - data['validThough']
    # employment_type - data['employmentType']
    # company_logo - data['hiringOrganization']['logo']

    #  Not included
    # seniority_level = data['experienceRequirements']['monthsOfExperience']  The JSON doesn't include it everytime so if nil == Junior, or get from HTML (job-tags = Junior)
    # @technologies = html_file.css('.po').map { |elem| elem.text }
  end
end
