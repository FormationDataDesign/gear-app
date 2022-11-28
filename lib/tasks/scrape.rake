require 'tasks/backcountry'

desc "Fetch all skis from backcountry.com an import into database"
task :scrape => :environment do

  ############################### DATA SCRAPE ####################################
  Backcountry.scrape

  ############################### DATA IMPORT ####################################
  # Backcountry.import

  ############################### DATAFEED ####################################
  # Backcountry.datafeed

end
