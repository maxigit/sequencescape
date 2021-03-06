class Accessionable::Base
  InvalidData = Class.new(AccessionService::AccessionServiceError)
  attr_reader :accession_number, :name, :date, :date_short
  def initialize(accession_number)
    @accession_number = accession_number

    time_now = Time.now
    @date       = time_now.strftime("%Y-%m-%dT%H:%M:%SZ")
    @date_short = time_now.strftime("%Y-%m-%d")

  end

  def errors
    []
  end

  def xml
    raise NotImplementedError, "abstract method"
  end

  def center_name
    AccessionService::CenterName
  end

  def schema_type
    #raise NotImplementedError, "abstract method"
    self.class.name.split("::").last.downcase
  end

  def alias
    #TODO move date from alias to filename
    "#{name.gsub(/[^a-z\d]/i, '_')}-sc-#{date}-#{object_id}"
  end

  def file_name
    "#{self.alias}.#{schema_type}.xml"
  end

  def extract_accession_number(xmldoc)
          element = xmldoc.root.elements["/RECEIPT/#{schema_type.upcase}"]
          accession_number       = element &&  element.attributes['accession']
  end

  def extract_array_express_accession_number(xmldoc)
          element = xmldoc.root.elements["/RECEIPT/#{schema_type.upcase}/EXT_ID[@type='array express']"]
          accession_number       = element &&  element.attributes['accession']
  end

  def update_accession_number!(accession_number)
    raise NotImplementedError, "abstract method"
  end

  def update_array_express_accession_number!(accession_number)
  end

  def object_id
    raise NotImplementError, "abstract method"
  end

  def label_scope
      @label_scope ||= "metadata.#{self.class.name.split("::").last.downcase}.metadata"
  end

  class Tag
    attr_reader :value
    def initialize(label_scope, name, value)
      @name = name
      @value = value
      @scope = label_scope
    end

    def label
      I18n.t("#{@scope}.#{ @name }.label")
    end

    def build(xml)
      xml.TAG   label
      xml.VALUE value
    end
  end
end
