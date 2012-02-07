$hide_sql = false
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

def create_audit_table
  con = Plate.connection
  database = "#{con.current_database}_audit"
  con.execute %Q{
    CREATE DATABASE IF NOT EXISTS #{database};
  }
  con.execute %Q{
    DROP TABLE IF EXISTS #{database}.assets;
  }
  con.execute %Q{
    CREATE TABLE #{database}.assets
    (update_at DATE, type VARCHAR(10), a VARCHAR(20))
-- (user VARCHAR(50), updated_at DATE, type VARCHAR(10))
      SELECT assets.*
      FROM assets
      WHERE false;
  }
  #con.execute %Q{
  #  CREATE VIEW assets_audit AS
  #  SELECT * FROM #{database}.assets;
  #}

end
def drop_audit_tables
  con = Plate.connection
  database = "#{con.current_database}_audit"
  con.execute %Q{
    DROP TABLE IF EXISTS #{database}.assets;
  }
  con.execute %Q{
    DROP TRIGGER IF EXISTS assets_ari;
  }
end
def create_audit_trigger
  con = Plate.connection
  database = "#{con.current_database}_audit"

  con.execute %Q{
    CREATE TRIGGER assets_ari
    AFTER INSERT ON assets
    FOR EACH ROW
    BEGIN
    INSERT into #{database}.assets
      SELECT now(), 'INSERT', 'ti', assets.* FROM assets
      WHERE id = NEW.id;
    END;
  }



end

def bench
  Rails.logger.warn("******* Creating Plate *******")
  p = create_plate
  Rails.logger.warn("******* Updating Plate ******")
  update_plate(p)
end
Rails.logger.warn("******* Normal sequence escape *****")
drop_audit_tables
bench

Rails.logger.warn("******* Create audit table ******")
create_audit_table
create_audit_trigger

bench


