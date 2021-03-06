require "selenium-webdriver"
require "byebug"
require "csv"

class Scraper
  attr_accessor :driver, :auth_code
  @@branches = ["ActiveLakelandTampa", "ActiveStaffingElizabeth", "ActiveAtlanta", "ActiveStaffingJerseyCIty", "ActiveStaffingMiami" ] #, "activestaffingARL"

  def initialize(auth_code)
    Selenium::WebDriver::Chrome.driver_path = '/Users/andres/Desktop/scraper/chromedriver'
    caps       = Selenium::WebDriver::Remote::Capabilities.chrome("goog:chromeOptions" => {"args" => ["--disable-notifications"]})
    @driver    = Selenium::WebDriver.for :chrome, desired_capabilities: caps
    @auth_code = auth_code

    login
    insert_auth_code
    collect_applicants_info
  end

  def login
    @driver.navigate.to "https://facebook.com"
    @driver.find_element(:id, 'email').send_keys ENV['FB_EMAIL']
    @driver.find_element(:id, 'pass').send_keys ENV['FB_PW']
    @driver.find_element(:name, 'login').click
    sleep 3
  end

  def insert_auth_code
    @driver.find_element(:name, 'approvals_code').send_keys @auth_code
    @driver.find_element(:id, 'checkpointSubmitButton').click
    sleep 3

    @driver.find_element(:id, 'checkpointSubmitButton').click
    sleep 3
  end

  def collect_applicants_info
    @@branches.each do |branch|
      date_time = DateTime.now.strftime("%d_%m_%y_%I_%M_%S_%p")
      CSV.open("#{date_time}___#{branch}.csv",'wb') do |csv|
  
        csv << [branch]
        csv << ["Full Name", "Phone Number", "Position"]
        
        @driver.navigate.to "https://www.facebook.com/#{branch}/manage_jobs/?source=manage_jobs_tab&tab=applications"
        puts "--------------------------------------------------------"
        puts "Getting applications for branch #{branch}"
        sleep 2

        applicants = get_applicants
        end_loop   = false

        while applicants.length > 0 && !end_loop

          puts "Applicants in queue: #{applicants.count}"
          if applicant_processed(applicants.shift)
            end_loop = true
            next
          end

          begin
            main_section                  = @driver.find_element(:css, "div[role='main']")
            citizenship_container         = main_section.find_elements(:css, "span[class='d2edcug0 hpfvmrgz qv66sw1b c1et5uql oi732d6d ik7dh3pa fgxwclzu a8c37x1j keod5gw0 nxhoafnm aigsh9s9 d9wwppkn fe6kdd0r mau55g9w c8b282yb iv3no6db a5q79mjw g1cxx5fr ekzkrbhg oo9gr5id hzawbc8m']").first
            parent_citizenship_container  = citizenship_container.find_element(:xpath, "./../..")
            citizenship_answer            = parent_citizenship_container.find_elements(:css, "div[class='qzhwtbm6 knvmm38d']").last.text
          rescue
            puts "Error on finding the citizenship answer"
            next
          end

          if citizenship_answer.downcase.include? "yes"
            csv << applicant_info
          elsif citizenship_answer.downcase.include? "no"
            csv << ["applicant_full_name", "-------", "No citizenship"]
          end
  
        end
      end# end of csv
    end
  end

  # returns true if applicant has been processed
  def applicant_processed(applicant)
    processed = nil
    applicant.find_element(:xpath, "*").click
    sleep 3

    main_section          = @driver.find_element(:css, "div[role='main']")
    full_name_container   = main_section.find_element(:css,"div[class='bp9cbjyn j83agx80 bkfpd7mw aodizinl hv4rvrfc ofv0k9yr dati1w0a']")

    if full_name_container.text.include?("Set Status")
      puts "Applicant has NOT been processed"
      processed = false
    else
      puts "Applicant has been processed"
      processed = true
    end

    return processed 
  end


  def get_applicants
    load_more_applicants = true
    applicants           = nil

    while load_more_applicants
      # get applications container and push elements inside applications_container to applications
      applicants_container  = @driver.find_element(:css, "div[class='aahdfvyu'] > div[class='b20td4e0 muag1w35']")
      applicants            = applicants_container.find_elements(:xpath, "*")

      puts "Number of applicants #{applicants.count}"
      if applicant_processed(applicants.last)
        load_more_applicants = false
        puts "Dont load more applicants"
      else
        script = "var arr = document.getElementsByClassName('q5bimw55 rpm2j7zs k7i0oixp gvuykj2m j83agx80 cbu4d94t ni8dbmo4 eg9m0zos l9j0dhe7 du4w35lb ofs802cu pohlnb88 dkue75c7 mb9wzai9 d8ncny3e buofh1pr g5gj957u tgvbjcpo l56l04vs r57mb794 kh7kg01d c3g1iek1 k4xni2cv');arr[arr.length-1].scrollBy({left: 0,top: 500,behavior: 'smooth'});"
        @driver.execute_script(script)
        puts "Loading more applicants...."
        sleep 3
      end
    end

    puts "returning #{applicants.count} applicants"
    return applicants
  end


  def applicant_info
    begin
      main_section = @driver.find_element(:css, "div[role='main']")
      main_section.find_element(:css, "div[aria-label='Maybe']").click
      sleep 3

    # get full name
      full_name_container = main_section.find_element(:css,"div[class='bp9cbjyn j83agx80 bkfpd7mw aodizinl hv4rvrfc ofv0k9yr dati1w0a']")
      applicant_full_name = full_name_container.find_element(:css, "span[class='d2edcug0 hpfvmrgz qv66sw1b c1et5uql oi732d6d ik7dh3pa fgxwclzu a8c37x1j keod5gw0 nxhoafnm aigsh9s9 ns63r2gh fe6kdd0r mau55g9w c8b282yb hrzyx87i o0t2es00 f530mmz5 hnhda86s oo9gr5id hzawbc8m']").text

      show_pn_container = main_section.find_elements(:css , "div[class='wovflp6s cxmmr5t8 gjjqq4r6 hcukyx3x']").last

      return ['no','phone','number'] if !show_pn_container.text.downcase.include?("number")

    # get phone number
      show_pn_container.click
      sleep 2
      applicant_phone_number = show_pn_container.find_element(:css, "span[class='d2edcug0 hpfvmrgz qv66sw1b c1et5uql oi732d6d ik7dh3pa fgxwclzu a8c37x1j keod5gw0 nxhoafnm aigsh9s9 d9wwppkn fe6kdd0r mau55g9w c8b282yb mdeji52x e9vueds3 j5wam9gi knj5qynh m9osqain hzawbc8m']").text
      applicant_phone_number.gsub!(" copied to clipboard.", "")

    # get applicant possition
      applicant_position = main_section.find_elements(:css, "span[class='d2edcug0 hpfvmrgz qv66sw1b c1et5uql oi732d6d ik7dh3pa fgxwclzu a8c37x1j keod5gw0 nxhoafnm aigsh9s9 d9wwppkn fe6kdd0r mau55g9w c8b282yb iv3no6db a5q79mjw g1cxx5fr lrazzd5p oo9gr5id hzawbc8m']").first.text
      return [applicant_full_name, applicant_phone_number, applicant_position]
    rescue
      return ["error getting","applicant","info"]
    end

  end

end

Scraper.new(ARGV.first)


