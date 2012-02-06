$hide_sql = true
def create_plate

  attributes = {}
  attributes[:size] = size = 96
  barcode = PlateBarcode.create.barcode
  wells = Map.where_plate_size(size).in_reverse_row_major_order.all.map { |map| Well.new(:map => map) }
  plate = nil
  Plate::benchmark "Create Plate", Logger::WARN, $hide_sql do
    plate = Plate.create_with_barcode!(barcode, attributes)
    plate.wells.import(wells)
  end
    plate
end


def update_plate(plate)

  wells = plate.wells
  wells.map { |w| w.barcode = "B1" }

  Plate::benchmark "Update Plate", Logger::WARN, $hide_sql do
    #Well.import(wells)
    wells.each(&:save)
  end

end



Rails.logger.warn("******* Normal sequence escape *****")
Rails.logger.warn("******* Creating Plate *******")
p = create_plate
Rails.logger.warn("******* Updating Plate ******")
update_plate(p)





