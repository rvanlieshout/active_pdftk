require 'tempfile'
module PdftkForms
  # Wraps calls to PdfTk
  class Wrapper
    
    attr_reader :pdftk, :options
    
    # PdftkWrapper.new('/usr/bin/pdftk', :encrypt => true, :encrypt_options => 'allow Printing')
    # Or
    # PdftkWrapper.new  #assumes 'pdftk' is in the users path
    def initialize(pdftk_path = nil, options = {})
      @pdftk = pdftk_path || "pdftk"
      @options = options
    end
    
    # pdftk.fill_form('/path/to/form.pdf', '/path/to/destination.pdf', :field1 => 'value 1')
    # if your version of pdftk does not support xfdf then call
    # pdftk.fill_form('/path/to/form.pdf', '/path/to/destination.pdf', {:field1 => 'value 1'}, false)
    def fill_form(template, destination, data = {}, xfdf_input = true)
      input = xfdf_input ? Xfdf.new(data) : Fdf.new(data)
      tmp = Tempfile.new('pdf_forms_input')
      tmp.close
      input.save_to tmp.path
      call_pdftk template, 'fill_form', tmp.path, 'output', destination, 'flatten', encrypt_options(tmp.path)
      tmp.unlink
    end
    
    def fields(template_path)
      unless @all_fields
        field_output = call_pdftk(template_path, 'dump_data_fields')
        raw_fields = field_output.split(/^---\n/).reject {|text| text.empty? }
        @all_fields = raw_fields.map do |field_text|
          attributes = {}
          field_text.scan(/^(\w+): (.*)$/) do |key, value|
            if key == "FieldStateOption"
              attributes[key] ||= []
              attributes[key] << value
            else
              attributes[key] = value
            end
          end
          Field.new(attributes)
        end
      end
      @all_fields
    end
    
    protected
    
    def encrypt_options(pwd)
      if options[:encrypt]
        ['encrypt_128bit', 'owner_pw', pwd, options[:encrypt_options]]
      end
    end
    
    def call_pdftk(*args)
      %x{#{pdftk} #{args.flatten.compact.join ' '}}
    end
    
  end
end