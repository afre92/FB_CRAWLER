require "selenium-webdriver"
require "byebug"
require "csv"

# window_size= 1366x768
Selenium::WebDriver::Chrome.driver_path = '/Users/andres/Desktop/scraper/chromedriver'

auth_code = ARGV.first
caps      = Selenium::WebDriver::Remote::Capabilities.chrome("goog:chromeOptions" => {"args" => ["--disable-notifications"]})
driver    = Selenium::WebDriver.for :chrome, desired_capabilities: caps
wait      = Selenium::WebDriver::Wait.new(:timeout => 20)
branches  = ["ActiveStaffingElizabeth"]

driver.navigate.to "https://facebook.com"
driver.find_element(:id, 'email').send_keys ENV['FB_EMAIL']
driver.find_element(:id, 'pass').send_keys ENV['FB_PW']
driver.find_element(:name, 'login').click
sleep 3

driver.find_element(:name, 'approvals_code').send_keys auth_code
driver.find_element(:id, 'checkpointSubmitButton').click
sleep 2

driver.find_element(:id, 'checkpointSubmitButton').click
sleep 3


# TODO: remove sleep and use wait method

  branches.each do |branch|

    CSV.open('file.csv','wb') do |csv|

      csv << [branch]
      csv << ["Full Name", "Phone Number", "Position"]
      full_name = phone_number = applicant_position = ""

      driver.navigate.to "https://www.facebook.com/#{branch}/manage_jobs/?source=manage_jobs_tab&tab=applications"
      sleep 2

      byebug
      load_more_applications = true
      applications           = nil

      while load_more_applications
        # get applications container and push elements inside applications_container to applications
        applications_container      = driver.find_element(:css, "div[class='aahdfvyu'] > div[class='b20td4e0 muag1w35']")
        applications                = applications_container.find_elements(:xpath, "*")
        last_applicant_status_blank = nil
        
        begin
          last_applicant_status_blank = applications[-1].find_element(:css, "i[class='hu5pjgll lzf7d6o1 sp_lnSB2oS2umA_2x sx_cc289f']")
        rescue Selenium::WebDriver::Error::NoSuchElementError
        end
       
        if last_applicant_status_blank # which means it has not been 'marked'
          script = "var arr = document.getElementsByClassName('q5bimw55 rpm2j7zs k7i0oixp gvuykj2m j83agx80 cbu4d94t ni8dbmo4 eg9m0zos l9j0dhe7 du4w35lb ofs802cu pohlnb88 dkue75c7 mb9wzai9 d8ncny3e buofh1pr g5gj957u tgvbjcpo l56l04vs r57mb794 kh7kg01d c3g1iek1 k4xni2cv');arr[arr.length-1].scrollBy({left: 0,top: 1000,behavior: 'smooth'});"
          driver.execute_script(script)
          sleep 4
        else
          load_more_applications = false
        end
        
      end
      
      application_opened = false
      while applications.length > 0 && !application_opened

          application = applications.shift
          application.find_element(:css, "div div").click
          sleep 3
          
          # byebug
          begin
            # if it can be found then exit ?
            application.find_element(:css, "div[class^='rq0escxv l9j0dhe7'] > i[class^='hu5pjgll lzf7d6o1']")
          rescue Selenium::WebDriver::Error::NoSuchElementError
            application_opened = true
            next
          end

          #  non selected
          # rq0escxv l9j0dhe7 du4w35lb d2edcug0 hpfvmrgz j83agx80 pfnyh3mw j5wkysh0 hytbnt81
          #i hu5pjgll lzf7d6o1 sp_I2ue0_XD3tN_2x sx_521871

          # maybe selected
          # rq1escxv l9j0dhe7
          # hu5pjgll op6gxeva sp_JGdB-QXXM5I_2x sx_1ccdf1

          # point of start:
          # change all the element query by css class to xpath
          byebug
          main_section                  = driver.find_element(:css, "div[role='main']")
          citizenship_container         = main_section.find_elements(:css, "span[class='d2edcug0 hpfvmrgz qv66sw1b c1et5uql oi732d6d ik7dh3pa fgxwclzu a8c37x1j keod5gw0 nxhoafnm aigsh9s9 d9wwppkn fe6kdd0r mau55g9w c8b282yb iv3no6db a5q79mjw g1cxx5fr ekzkrbhg oo9gr5id hzawbc8m']").first
          parent_citizenship_container  = citizenship_container.find_element(:xpath, "./../..")
          citizenship_answer            = parent_citizenship_container.find_elements(:css, "div[class='qzhwtbm6 knvmm38d']").last.text

          if citizenship_answer.downcase == "yes"

            # select Interview process
            # if main_section.find_element(:css, "div[aria-label='Maybe']").displayed?
            main_section.find_element(:css, "div[aria-label='Maybe']").click
            sleep 3
            # end

            # get full name
            byebug
            full_name_container  = main_section.find_element(:css,"div[class='bp9cbjyn j83agx80 bkfpd7mw aodizinl hv4rvrfc ofv0k9yr dati1w0a']")
            full_name            = full_name_container.find_element(:css, "span[class='d2edcug0 hpfvmrgz qv66sw1b c1et5uql oi732d6d ik7dh3pa fgxwclzu a8c37x1j keod5gw0 nxhoafnm aigsh9s9 ns63r2gh fe6kdd0r mau55g9w c8b282yb hrzyx87i o0t2es00 f530mmz5 hnhda86s oo9gr5id hzawbc8m']").text

            # show phone number and copy phone number
            show_pn_container = main_section.find_elements(:css , "div[class='wovflp6s cxmmr5t8 gjjqq4r6 hcukyx3x']").last
            show_pn_container.click
            sleep 2
            phone_number = show_pn_container.find_element(:css, "span[class='d2edcug0 hpfvmrgz qv66sw1b c1et5uql oi732d6d ik7dh3pa fgxwclzu a8c37x1j keod5gw0 nxhoafnm aigsh9s9 d9wwppkn fe6kdd0r mau55g9w c8b282yb mdeji52x e9vueds3 j5wam9gi knj5qynh m9osqain hzawbc8m']").text
            phone_number.gsub!(" copied to clipboard.", "")

            # copy applicant possition
            applicant_position = main_section.find_elements(:css, "span[class='d2edcug0 hpfvmrgz qv66sw1b c1et5uql oi732d6d ik7dh3pa fgxwclzu a8c37x1j keod5gw0 nxhoafnm aigsh9s9 d9wwppkn fe6kdd0r mau55g9w c8b282yb iv3no6db a5q79mjw g1cxx5fr lrazzd5p oo9gr5id hzawbc8m']").first.text
            csv << [full_name, phone_number, applicant_position]
          elsif citizenship_answer.downcase == "no"
            csv << ["No citizenship"]
          end

      end
      
    end# end of csv
  
  end


  def get_more_applicants

  end
  

  # wait = Selenium::WebDriver::Wait.new(:timeout => 15)
 
  # # Add text to a text box
  # input = wait.until {
  #     element = browser.find_element(:name, "searchbox")
  #     element if element.displayed?
  # }
  # input.send_keys("Information")



  # https://www.rubydoc.info/gems/selenium-webdriver/Selenium/WebDriver/Chrome/Options