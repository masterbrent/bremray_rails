require 'rails_helper'

RSpec.describe 'Database seeds' do
  before do
    # Clear database before seeding
    TemplateItem.destroy_all
    Template.destroy_all
    MasterItem.destroy_all
    User.destroy_all
    Workspace.destroy_all
  end

  it 'creates workspaces' do
    expect { load Rails.root.join('db/seeds.rb') }.to change { Workspace.count }.by_at_least(3)
    
    expect(Workspace.skyview).to be_present
    expect(Workspace.contractors).to be_present
    expect(Workspace.rayno).to be_present
  end

  it 'creates admin and tech users' do
    load Rails.root.join('db/seeds.rb')
    
    expect(User.where(role: 'admin').count).to be >= 1
    expect(User.where(role: 'tech').count).to be >= 1
  end

  it 'creates master items in various categories' do
    load Rails.root.join('db/seeds.rb')
    
    expect(MasterItem.count).to be >= 20
    expect(MasterItem.by_category('Electrical').count).to be >= 5
    expect(MasterItem.by_category('HVAC').count).to be >= 3
    expect(MasterItem.by_category('Plumbing').count).to be >= 3
  end

  it 'creates templates for Skyview workspace' do
    load Rails.root.join('db/seeds.rb')
    
    skyview = Workspace.skyview
    expect(skyview.templates.count).to be >= 2
    expect(skyview.templates.pluck(:name)).to include('Sunroom', 'Pergola')
  end

  it 'creates template with minimum price for pergola' do
    load Rails.root.join('db/seeds.rb')
    
    pergola = Template.find_by(name: 'Pergola')
    expect(pergola.minimum_price).to eq(850.00)
  end

  it 'populates templates with items' do
    load Rails.root.join('db/seeds.rb')
    
    Template.all.each do |template|
      expect(template.template_items.count).to be >= 3
    end
  end

  it 'creates all data without errors' do
    expect { load Rails.root.join('db/seeds.rb') }.not_to raise_error
  end
end
