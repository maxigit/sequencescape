class Accessionable::Submission < Accessionable::Base


  attr_reader :broker, :alias, :date, :accessionables, :contact
  def initialize(service, user, *accessionables)
    @service = service
    @contact = Contact.new(user)
    @broker = service.broker
    @accessionables = accessionables

    super(accession_number)
  end

  def alias
    @accessionables.map(&:alias).join(" - ")
  end

  def <<(accessionable)
    @accessionables << accesionable
  end

  def xml
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.SUBMISSION(
      'xmlns:xsi'      => 'http://www.w3.org/2001/XMLSchema-instance',
      :center_name     => self.center_name, 
      :broker_name     => self.broker, 
      :alias           => self.alias,
      :submission_date => self.date
    ) {
      xml.CONTACTS { self.contact.build(xml) }
      xml.ACTIONS {
        accessionables.each do |accessionable|
          xml.ACTION {
            if accessionable.accession_number.blank?
              xml.ADD(:source => accessionable.file_name,  :schema => accessionable.schema_type)
            else
              xml.MODIFY(:source => accessionable.file_name, :target => accessionable.accession_number)
            end
          }
          xml.ACTION {
            if accessionable.protect?(@service)
              xml.PROTECT
            else
              xml.HOLD
            end
          }
        end
      }
    }
    return xml.target!
  end

  def name
    if @accessionables.size >= 1
      @accessionables.first.name
    else
      "empty"
    end
  end

  def all_accessionables
    @accessionables + [self]
  end

  def update_accession_number!(accession_number)
    @accession_number = accession_number
  end

private

  class Contact
    attr_reader :inform_on_error, :inform_on_status, :name
    def initialize(user)
      @inform_on_error = "#{user.login}@#{configatron.default_email_domain}"
      @inform_on_status =  inform_on_error
      @name = user.first_name+" "+user.last_name
    end

    def build(markup)
      markup.CONTACT(
        :inform_on_error  => inform_on_error, 
        :inform_on_status => inform_on_status,
        :name             => name
      )
    end
  end
end
