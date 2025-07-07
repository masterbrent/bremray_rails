# Database seeds for Bremray Electrical Business Management System
puts "🌱 Seeding database..."

# Clear existing data in development
if Rails.env.development?
  puts "Clearing existing data..."
  TemplateItem.destroy_all
  Template.destroy_all
  MasterItem.destroy_all
  User.destroy_all
  Workspace.destroy_all
end

# Create Workspaces
puts "Creating workspaces..."
skyview = Workspace.create!(
  name: 'Skyview',
  slug: 'skyview',
  settings: { 
    invoice_prefix: 'SKY',
    default_permit_fee: 250.00
  }
)

contractors = Workspace.create!(
  name: 'Contractors', 
  slug: 'contractors',
  settings: {
    enable_floors: true,
    enable_rooms: true,
    enable_change_orders: true
  }
)

rayno = Workspace.create!(
  name: 'Rayno',
  slug: 'rayno', 
  settings: {
    flexible_mode: true
  }
)

# Create Users
puts "Creating users..."
admin = User.create!(
  name: 'Brent Hall',
  email: 'brent@bremray.com',
  phone: '555-0001',
  password: 'password123',
  role: 'admin'
)

tech1 = User.create!(
  name: 'John Tech',
  email: 'john@bremray.com',
  phone: '555-0002',
  password: 'password123',
  role: 'tech'
)

tech2 = User.create!(
  name: 'Mike Fieldman',
  phone: '555-0003',
  password: 'password123',
  role: 'tech'
)

# Create Master Items
puts "Creating master items..."

# Electrical Items
electrical_items = [
  { code: 'GFCI-001', description: 'GFCI Outlet', base_price: 165.00 },
  { code: 'SW-001', description: 'Light Switch', base_price: 25.00 },
  { code: 'SW-DIM', description: 'Dimmer Switch', base_price: 45.00 },
  { code: 'REC-001', description: 'Standard Outlet', base_price: 35.00 },
  { code: 'REC-USB', description: 'USB Outlet', base_price: 75.00 },
  { code: 'FAN-001', description: 'Ceiling Fan', base_price: 250.00 },
  { code: 'LIGHT-REC', description: 'Recessed Light', base_price: 85.00 },
  { code: 'LIGHT-PEND', description: 'Pendant Light', base_price: 150.00 },
  { code: 'PANEL-200', description: '200 Amp Panel', base_price: 1200.00 },
  { code: 'CIRCUIT-20', description: '20 Amp Circuit', base_price: 125.00 }
]

electrical_items.each do |item|
  MasterItem.create!(
    code: item[:code],
    description: item[:description],
    base_price: item[:base_price],
    category: 'Electrical',
    unit: 'each'
  )
end

# HVAC Items
hvac_items = [
  { code: 'PTAC-001', description: 'PTAC Unit', base_price: 850.00 },
  { code: 'HEAT-BASE', description: 'Baseboard Heater', base_price: 275.00 },
  { code: 'HEAT-BROMIC', description: 'Bromic Heater', base_price: 650.00 },
  { code: 'THERM-WIFI', description: 'WiFi Thermostat', base_price: 225.00 }
]

hvac_items.each do |item|
  MasterItem.create!(
    code: item[:code],
    description: item[:description],
    base_price: item[:base_price],
    category: 'HVAC',
    unit: 'each'
  )
end

# Plumbing Items
plumbing_items = [
  { code: 'FAUCET-KIT', description: 'Kitchen Faucet', base_price: 275.00 },
  { code: 'FAUCET-BATH', description: 'Bathroom Faucet', base_price: 195.00 },
  { code: 'TOILET-STD', description: 'Standard Toilet', base_price: 325.00 },
  { code: 'SHUT-OFF', description: 'Shut-off Valve', base_price: 45.00 }
]

plumbing_items.each do |item|
  MasterItem.create!(
    code: item[:code],
    description: item[:description],
    base_price: item[:base_price],
    category: 'Plumbing',
    unit: 'each'
  )
end

# General Items
general_items = [
  { code: 'PERMIT-ELEC', description: 'Electrical Permit', base_price: 250.00 },
  { code: 'TRAVEL-TIME', description: 'Travel Time', base_price: 85.00, unit: 'per hour' },
  { code: 'LABOR-STD', description: 'Standard Labor', base_price: 125.00, unit: 'per hour' }
]

general_items.each do |item|
  MasterItem.create!(
    code: item[:code],
    description: item[:description],
    base_price: item[:base_price],
    category: 'General',
    unit: item[:unit] || 'each'
  )
end

# Create Templates for Skyview
puts "Creating templates..."

# Sunroom Template
sunroom = Template.create!(
  workspace: skyview,
  name: 'Sunroom',
  active: true
)

# Add items to Sunroom
sunroom.add_item(MasterItem.find_by(code: 'GFCI-001'))
sunroom.add_item(MasterItem.find_by(code: 'REC-USB'))
sunroom.add_item(MasterItem.find_by(code: 'LIGHT-REC'))
sunroom.add_item(MasterItem.find_by(code: 'SW-DIM'))
sunroom.add_item(MasterItem.find_by(code: 'HEAT-BASE'))
sunroom.add_item(MasterItem.find_by(code: 'PTAC-001'))

# Pergola Template
pergola = Template.create!(
  workspace: skyview,
  name: 'Pergola',
  minimum_price: 850.00,
  active: true
)

# Add items to Pergola
pergola.add_item(MasterItem.find_by(code: 'GFCI-001'))
pergola.add_item(MasterItem.find_by(code: 'SW-001'))
pergola.add_item(MasterItem.find_by(code: 'HEAT-BROMIC'))
pergola.add_item(MasterItem.find_by(code: 'FAN-001'))
pergola.add_item(MasterItem.find_by(code: 'LIGHT-PEND'))

# Bathroom Remodel Template for Rayno
bathroom = Template.create!(
  workspace: rayno,
  name: 'Bathroom Remodel',
  active: true
)

bathroom.add_item(MasterItem.find_by(code: 'GFCI-001'))
bathroom.add_item(MasterItem.find_by(code: 'SW-001'))
bathroom.add_item(MasterItem.find_by(code: 'LIGHT-REC'))
bathroom.add_item(MasterItem.find_by(code: 'FAN-001'))

puts "✅ Seeding complete!"
puts "📊 Created:"
puts "   - #{Workspace.count} workspaces"
puts "   - #{User.count} users"
puts "   - #{MasterItem.count} master items"
puts "   - #{Template.count} templates"
puts "   - #{TemplateItem.count} template items"
