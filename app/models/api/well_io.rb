class Api::WellIO < Api::Base
  renders_model(::Well)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id, 'internal_id')
  map_attribute_to_json_attribute(:name)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)
  

  extra_json_attributes do |object, json_attributes|
    json_attributes["genotyping_status"]  = object.genotyping_status if object.sample
    json_attributes["genotyping_snp_plate_id"]  = object.sample.genotyping_snp_plate_id if object.sample
    
    if object.respond_to?(:well_attribute)
      well_attributes = object.well_attribute
      json_attributes["gel_pass"]         = well_attributes.gel_pass
      json_attributes["concentration"]    = well_attributes.concentration
      json_attributes["current_volume"]   = well_attributes.current_volume
      json_attributes["buffer_volume"]    = well_attributes.buffer_volume
      json_attributes["requested_volume"] = well_attributes.requested_volume
      json_attributes["picked_volume"]    = well_attributes.picked_volume
      json_attributes["pico_pass"]        = well_attributes.pico_pass
      json_attributes["measured_volume"]  = well_attributes.measured_volume
      json_attributes["sequenom_count"]   = well_attributes.sequenom_count
      json_attributes["gender_markers"]   = well_attributes.gender_markers.try(:to_s)
    end
  end

  with_association(:map) do
    map_attribute_to_json_attribute(:description, 'map')
  end

  with_association(:plate) do
    map_attribute_to_json_attribute(:barcode, 'plate_barcode')
    map_attribute_to_json_attribute(:uuid, 'plate_uuid')
    
    extra_json_attributes do |object, json_attributes|
      json_attributes["plate_barcode_prefix"] = object.prefix unless object.nil?
    end
  end

  with_association(:sample) do
    map_attribute_to_json_attribute(:uuid, 'sample_uuid')
    map_attribute_to_json_attribute(:id  , 'sample_internal_id')
    map_attribute_to_json_attribute(:name, 'sample_name')
  end

  self.related_resources = [ :lanes, :requests ]
end
