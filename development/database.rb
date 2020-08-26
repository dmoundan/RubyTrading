#!/usr/bin/env ruby

require 'sqlite3'

class DataBase

    def initialize(location, name)  
        @location=location
        @name=name
        @db = SQLite3::Database.open(@location+"/"+name)

    end

    def execute(sql)
        @db.execute(sql.gsub("CHARACTER SET=UTF8;", ""))
    end

    def close()
        @db.close if @db
    end

end
