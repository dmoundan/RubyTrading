#!/usr/bin/env ruby

$VERBOSE=nil

=begin
require 'warning'
Gem.path.each do |path|
    Warning.ignore(//, path)
end
=end

require 'optparse'
require 'set'
require 'zlib'
require 'progress_bar'
require 'httparty'
require 'nokogiri'
require 'byebug'
require 'builder'
require "wisepdf"



def scraper_SP500list
    url = "https://en.wikipedia.org/wiki/List_of_S%26P_500_companies"
    unparsed_page=HTTParty.get(url)
    parsed_page=Nokogiri::HTML(unparsed_page)
    companies=Array.new
    table=parsed_page.at('#constituents')   # the hashmark needs to be added before the is name, potentially a . before class name
    table.search('tr').each do |tr|
        cells = tr.search('th, td')
=begin        
        cells.each do |cell|
            text = cell.text.strip
            puts(text)
        end
=end
        company={
                    symbol:  cells[0].text.strip,
                    name: cells[1].text.strip,
                    sector:  cells[3].text.strip,
                    industry: cells[4].text.strip
                }
        companies << company
    end
    puts(companies)    
end


def parse_weekly_option_tables(table, arr)
    table.search('tr').each do |tr|
        cells = tr.search('th, td')
        if cells.count >=2 
=begin            
            cells.each do |cell|
                text = cell.text.strip
                puts(text)
            end
=end
            str1=cells[0].text.strip
            str1.delete! '*'
            next if str1 == "Ticker"
            company={
                        symbol: str1,
                        name: cells[1].text.strip
                    }
            arr << company
        end    
    end

end 

def scraper_AllWeeklyOptionable
    weeklyOptionsEquities=Array.new
    weeklyOptionsETFs=Array.new
    url = "http://www.cboe.com/products/weeklys-options/available-weeklys"
    unparsed_page=HTTParty.get(url)
    parsed_page=Nokogiri::HTML(unparsed_page)
    list_of_tables=parsed_page.search('table')

    parse_weekly_option_tables(list_of_tables[4], weeklyOptionsEquities)

    puts(weeklyOptionsEquities)
    puts(weeklyOptionsEquities.count)

    parse_weekly_option_tables(list_of_tables[3], weeklyOptionsETFs)

    puts(weeklyOptionsETFs)
    puts(weeklyOptionsETFs.count)

end

def report msg
    puts msg
    t=Time.now
    yield
    puts "  -> #{Time.now-t}s"
end

def scraper_AllOptionables
    url = "https://www.finviz.com/screener.ashx?v=111&f=sh_opt_option"
    unparsed_page=HTTParty.get(url)
    parsed_page=Nokogiri::HTML(unparsed_page)
    page_array=Array.new
    parsed_page.css("#pageSelect option").each do |d|
        page_array <<  d.attr("value").to_i
    end
    bar=ProgressBar.new(page_array.count)
    allOptionables=Array.new
    marshal_dump=nil
    page_array.each do |i|
        #puts(i)
        if i == 1
            url = "https://www.finviz.com/screener.ashx?v=111&f=sh_opt_option"
        else
            url = "https://www.finviz.com/screener.ashx?v=111&f=sh_opt_option"+"&r=#{i.to_s}"    
        end
        unparsed_page=HTTParty.get(url)
        parsed_page=Nokogiri::HTML(unparsed_page)
        list_of_tables=parsed_page.search('table')  
        index=list_of_tables.count-2
        table=list_of_tables[index]
        table.search('tr').each do |tr|
            cells = tr.search('th, td') 
            next if cells[1].text.strip == "Ticker"
            company ={
                        ticker: cells[1].text.strip,
                        name: cells[2].text.strip,
                        sector: cells[3].text.strip,
                        industry: cells[4].text.strip,
                        country: cells[5].text.strip
                     }
            allOptionables << company
        end
        bar.increment!
    end
    #puts (allOptionables)
    report "Store the hash" do
        marshal_dump = Marshal.dump(allOptionables)
    end
=begin
    report "Write the marshal dump to file" do
        file_out = File.new("allOptionables.marshal",'w')
        file_out.write(marshal_dump)
        file_out.close
    end
=end

    report "Gzip the marshaled dump" do
        file = File.new('allOptionables.marshal.gz','w')
        gz = Zlib::GzipWriter.new(file)
        gz.write marshal_dump
        gz.close
   end
end

def readback_allOptionables
    report "Gunzip the marshaled dump and load it" do
        gz = Zlib::GzipReader.open('allOptionables.marshal.gz')
        loaded_hash = Marshal.load gz.read
        gz.close
        puts(loaded_hash)
    end
end

def read_text_file(fname, ms)
    File.foreach(fname) do |line|
        ms << line.chomp
    end
end


def scraper_EarnnigsNextWeek(enw)
    url = "https://finviz.com/screener.ashx?v=111&f=earningsdate_nextweek,sh_opt_option"
    unparsed_page=HTTParty.get(url)
    parsed_page=Nokogiri::HTML(unparsed_page)
    page_array=Set.new
    parsed_page.css("#pageSelect option").each do |d|
        page_array <<  d.attr("value").to_i
    end
    bar=ProgressBar.new(page_array.count)
    page_array.each do |i|
        #puts(i)
        if i == 1
            url = "https://finviz.com/screener.ashx?v=111&f=earningsdate_nextweek,sh_opt_option"
        else
            url = "https://finviz.com/screener.ashx?v=111&f=earningsdate_nextweek,sh_opt_option"+"&r=#{i.to_s}"    
        end
        unparsed_page=HTTParty.get(url)
        parsed_page=Nokogiri::HTML(unparsed_page)
        list_of_tables=parsed_page.search('table')  
        index=list_of_tables.count-2
        table=list_of_tables[index]
        table.search('tr').each do |tr|
            cells = tr.search('th, td') 
            next if cells[1].text.strip == "Ticker"
            ticker = cells[1].text.strip
            enw <<  ticker
        end
        bar.increment!
    end    
end

def scraper_CompanyData(ticker)
    url="https://finviz.com/quote.ashx?t=#{ticker}"
    unparsed_page=HTTParty.get(url)
    parsed_page=Nokogiri::HTML(unparsed_page)
    h1=Hash.new
    date=""
    time=""
    atr=""
    beta=""
    sfloat=""
    parsed_page.css(".snapshot-table2").search('tr').each do |tr|
        cells = tr.search('th, td') 
        count=0
        
        cells.each do |cell|
            text = cell.text.strip
            if text == "Earnings"
                earnings_date=cells[count+1].text.strip
                arr1=earnings_date.split(" ")
                time=arr1[2]
                dt=Date.new(Time.now.year,(Date::ABBR_MONTHNAMES.index(arr1[0])),arr1[1].to_i)
                date=dt.strftime('%a')+" "+Time.now.year.to_s+"-"+(Date::ABBR_MONTHNAMES.index(arr1[0])).to_s+"-"+arr1[1]
            elsif text == "Short Float"
                sfloat=cells[count+1].text.strip
            elsif text == "ATR"
                atr=cells[count+1].text.strip
            elsif text == "Beta"
                beta=cells[count+1].text.strip
            end
            count+=1
        end
    end
    h1={
            date: date,
            time: time,
            sfloat: sfloat,
            atr: atr,
            beta: beta,
            ticker: ticker
        }
    return h1    
end

def weeklyEarnings
    earningsNextWeek = Set.new
    scraper_EarnnigsNextWeek(earningsNextWeek)
    puts(earningsNextWeek.count)
    #We are going to intersect with
    # 1. My stock list
    myStocks=Set.new
    read_text_file("my_stock_list.txt", myStocks)
    puts(myStocks.count)
    myTarget=Set.new
    myTarget=earningsNextWeek & myStocks
    puts("Looking for earnings of #{myTarget.count} companies")
    arr=Array.new
    (0..9).each do |i|
        arr[i]=Array.new
    end
    myTarget.each do |ticker|
        h1= scraper_CompanyData(ticker)
        if h1[:date][0..2] == "Mon"
            if h1[:time] == "BMO"
                arr[0] << h1
            else
                arr[1] << h1
            end
        elsif h1[:date][0..2] == "Tue"
            if h1[:time] == "BMO"
                arr[2] << h1
            else
                arr[3] << h1
            end
        elsif h1[:date][0..2] == "Wed"
            if h1[:time] == "BMO"
                arr[4] << h1
            else
                arr[5] << h1
            end
        elsif h1[:date][0..2] == "Thu"
            if h1[:time] == "BMO"
                arr[6] << h1
            else
                arr[7] << h1
            end
        elsif h1[:date][0..2] == "Fri"
            if h1[:time] == "BMO"
                arr[8] << h1
            else
                arr[9] << h1
            end
        end
    end    
    #puts(arr[0])
    create_html(arr)
end

def create_html(arr)
    xm = Builder::XmlMarkup.new(:indent => 2)
    xm.table{
        xm.tr {arr[0][0].keys.each { |key| xm.th(key)}} 
        arr.each do |i|
            i.each do |j|
                xm.tr {j.values.each{|value| xm.td(value)}}
            end
        end
    }
    puts "#{xm}"
    pdf = Wisepdf::Writer.new.to_pdf("#{xm}")
    File.open("earnings.pdf", 'wb') do |file|
        file << pdf
    end
end

def getDaysOfWeek(start)
    arr1=start.split("-")
    year=arr1[0]
    month=arr1[1]
    day=arr1[2]
    arr1=Array.new
    dt = Date.new(year.to_i, month.to_i, day.to_i)
    (dt..dt+4).each do |d|
        arr1 << d.strftime('%a')+" "+d.year.to_s+"-"+d.month.to_s+"-"+d.day.to_s
    end    
    return arr1
end

#scraper_SP%00List()
#scraper_AllWeeklyOptionable()
#scraper_AllOptionables()
#readback_allOptionables()
#read_text_file("my_stock_list.txt")

#weeklyEarnings()
#scraper_CompanyData("AAPL")
#getDaysOfWeek("2020-8-3")

def main()
    options = {}
    optparse = OptionParser.new do |opts|
    # Set a banner, displayed at the top of the help screen.
        opts.banner = "Usage: test.rb [options]  ..."
        options[:all_weekly_optionables] = false
        opts.on('-w', '--all_weekly_optionables', 'Discover all instruments with weekly options') do
            options[:all_weekly_optionables] = true
        end    
    end
end