require 'date'

module ActivePdftk

  class MetaData < Hash

    def number_of_pages
      self["NumberOfPages"]
    end

    def author
      self["Author"]
    end

    def creator
      self["Creator"]
    end

    def producer
      self["Producer"]
    end

    def title
      self["Title"]
    end

    def mod_date
      parse_date self["ModDate"]
    end

    def creation_date
      parse_date self["CreationDate"]
    end

    private 

      def parse_date raw
        key, raw_date = raw.split(":")
        date = raw_date[0..-4] # strip of '00'
        DateTime.parse(date)
      end

  end

  class MetaDataParser

    def initialize
      @pdftk = Wrapper.new
    end

    def parse(input)
      raw_data = @pdftk.dump_data(input)
      lines = raw_data.read.split("\n")
      puts lines
      meta_data = MetaData.new
      new_key = nil
      lines.each do |line|
        key, value = line.split(": ")
        case key
          when "InfoBegin"
          when "InfoKey"
            new_key = value
          when "InfoValue"
            meta_data[new_key] = value
          else 
            meta_data[key] = value unless value.nil?
        end 
      end
      puts meta_data
      meta_data
    end

  end

end