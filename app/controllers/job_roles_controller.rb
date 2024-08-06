class JobRolesController < ApplicationController
  require 'open-uri'
  require 'nokogiri'
  require 'pry'

  # Scraping Ruby on Remote Page example
  def index
    #uri = "https://rubyonremote.com/jobs/62960-senior-developer-grow-my-clinic-at-jane"
    uri = "https://rubyonremote.com/jobs/61412-junior-software-engineer-at-syntax"
    html_file = Nokogiri::HTML(URI.open(uri))
    #@response = html_file.status
    #body = html_file.read

    # TODO: Improve - The script order may change in the future
    json = html_file.at('script[type="application/ld+json"]').text
    data = JSON[json]    

    @role_name = data['title']
    @company_name = data['hiringOrganization']['name']
    @company_type = data['hiringOrganization']['@type']
    @company_business = data['']  # Use AI or make regex with a collection to check the most common business types ['Health', 'Marketing', 'Ecommerce', etc]
    @work_type = data['jobLocationType'] == 'TELECOMMUTE' ? 'Remote' : data['jobLocationType']
    @role_url = uri
    @company_url = data['hiringOrganization']['sameAs']
    @salary = data['baseSalary']['minValue'] + '-' + data['baseSalary']['maxValue'] + ' ' + data['baseSalary']['currency']
    @job_description = data['description']

    # Not included in the JSON body
    @technologies = html_file.css('.menuitem').map { |elem| elem.text }

    # TODO: Improve how to get this field correctly
    # You can validate if the Anywhere tag is present or check by the number of countries added to the location Array}
    # The location Array is not properly implemented, it seems like there's a bug in the page, The Job tag 
    # says 'Remote - US' but there's a list of over 249 countries
    @location = data['applicantLocationRequirements'].map { |elem| elem['name'] }

    #  location cuando son muchos se complica, mejor sacarlo del HTML  or validar si tiene el tag Anywhere

    @location_html = html_file.search('a.job-tags').first.text == "\n\n\n\nRemote - Anywhere\n" ? 'Worldwide' : html_file.search('a.job-tags').first.text

    # Option not considered:
    # @job_description_from_html = html_file.css('.trix-content').text
    # Options to get the desired label for location:

    # 1. Get a regex from the aria-label="view remote jobs in Remote - Anywhere"
    # 2. Validate when the First Job-tags is 'Featured'

    # extra_notes -  (optional) Added on the board view

    # ADD new fields: 
    #
    # seniority_level = data['experienceRequirements']['monthsOfExperience']  The JSON doesn't include it everytime so if nil == Junior, or get from HTML (job-tags = Junior)
    # date_posted - data['datePosted']
    # due_date_to_apply - data['validThough']
    # employment_type - data['employmentType']
    # company_logo - data['hiringOrganization']['logo']
  end
end
