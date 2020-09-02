#!/usr/bin/env ruby

require 'progress_bar'
require 'httparty'
require 'nokogiri'
require 'daru'
require "wisepdf"

class Finviz

    Base_url="https://finviz.com/"

    def weeklyEarnings(intersect_list, period="next_week")
        earnings_labels=[:date, :ticker, :time, :sfloat, :atr, :beta]
        earningsNextWeek = Set.new
        scraper_EarnnigsNextWeek(earningsNextWeek, period)
        puts(earningsNextWeek.count)
        myTarget=Set.new
        myTarget=earningsNextWeek & intersect_list
        puts("Looking for earnings of #{myTarget.count} companies")
        arr=Array.new
        (0..9).each do |i|
            arr[i]=Array.new
        end
        bar=ProgressBar.new(myTarget.count)
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
            bar.increment!
        end   
        final_hash=Hash.new
        earnings_labels.each do |s|
            final_hash[s]=Array.new
        end
        
        arr.each do |a|
            a.each do |h|
                h.each do |k,v|
                    final_hash[k] << v
                end
            end
        end
        df=Daru::DataFrame.new(final_hash, order: earnings_labels)
        #puts(df.inspect(spacing=20, threshold=25))
        pdf = Wisepdf::Writer.new.to_pdf(df.to_html)
        File.open("earnings.pdf", 'wb') do |file|
            file << pdf
        end
    end

    private

    def scraper_EarnnigsNextWeek(enw, period)
        period1=period.gsub("_","")
        url = Base_url+"screener.ashx?v=111&f=earningsdate_#{period1},sh_opt_option"
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
                url = Base_url+"screener.ashx?v=111&f=earningsdate_#{period1},sh_opt_option"
            else
                url = Base_url+"screener.ashx?v=111&f=earningsdate_#{period1},sh_opt_option"+"&r=#{i.to_s}"    
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
        url=Base_url+"quote.ashx?t=#{ticker}"
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

end