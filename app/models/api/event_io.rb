class Api::EventIO < Api::Base
  renders_model(::Event)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id, 'internal_id')
  map_attribute_to_json_attribute(:message)
  map_attribute_to_json_attribute(:family)
  map_attribute_to_json_attribute(:identifier)
  map_attribute_to_json_attribute(:location)
  map_attribute_to_json_attribute(:actioned)
  map_attribute_to_json_attribute(:content)
  map_attribute_to_json_attribute(:created_by)
  map_attribute_to_json_attribute(:of_interest_to)
  map_attribute_to_json_attribute(:descriptor_key)
  map_attribute_to_json_attribute(:updated_at)
  map_attribute_to_json_attribute(:created_at)

  with_association(:eventful) do
    map_attribute_to_json_attribute(:uuid, 'eventful_uuid')
    map_attribute_to_json_attribute(:id,   'eventful_internal_id')

    extra_json_attributes do |object, json_attributes|
      json_attributes['eventful_type'] = object.class.name.tableize 
    end
  end
end
