require 'rails_helper'

RSpec.describe JobCard, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:job_id) }
  end

  describe 'associations' do
    it { should belong_to(:job) }
    it { should have_many(:job_items).dependent(:destroy) }
    it { should have_many(:custom_entries).dependent(:destroy) }
    it { should have_many(:photos).dependent(:destroy) }
  end

  describe 'callbacks' do
    context 'populate from template' do
      let(:template) { FactoryBot.create(:template) }
      let!(:template_item1) { FactoryBot.create(:template_item, template: template, default_quantity: 5) }
      let!(:template_item2) { FactoryBot.create(:template_item, template: template, default_quantity: 0) }
      let(:job) { FactoryBot.create(:job, :skyview, template: template) }

      it 'creates job items from template items' do
        job_card = job.job_card
        expect(job_card.job_items.count).to eq(2)
        
        item1 = job_card.job_items.find_by(master_item: template_item1.master_item)
        expect(item1.quantity).to eq(0) # Always starts at 0
        
        item2 = job_card.job_items.find_by(master_item: template_item2.master_item)
        expect(item2.quantity).to eq(0)
      end

      it 'does not create items if no template' do
        job_without_template = FactoryBot.create(:job, :skyview, template: nil)
        expect(job_without_template.job_card.job_items).to be_empty
      end
    end
  end

  describe '#total_items' do
    let(:job_card) { FactoryBot.create(:job_card) }

    it 'returns sum of all item quantities' do
      FactoryBot.create(:job_item, job_card: job_card, quantity: 5)
      FactoryBot.create(:job_item, job_card: job_card, quantity: 3)
      FactoryBot.create(:job_item, job_card: job_card, quantity: 0)
      
      expect(job_card.total_items).to eq(8)
    end

    it 'returns 0 when no items' do
      expect(job_card.total_items).to eq(0)
    end
  end

  describe '#close!' do
    let(:job_card) { FactoryBot.create(:job_card) }

    it 'sets closed_at timestamp' do
      expect(job_card.closed_at).to be_nil
      job_card.close!
      expect(job_card.closed_at).to be_present
      expect(job_card.closed_at).to be_within(1.second).of(Time.current)
    end

    it 'updates job status to closed' do
      expect(job_card.job.status).to eq('open')
      job_card.close!
      expect(job_card.job.reload.status).to eq('closed')
    end
  end

  describe '#reopen!' do
    let(:job_card) { FactoryBot.create(:job_card, closed_at: 1.day.ago) }

    it 'clears closed_at timestamp' do
      job_card.reopen!
      expect(job_card.closed_at).to be_nil
    end

    it 'updates job status to open' do
      job_card.job.update!(status: 'closed')
      job_card.reopen!
      expect(job_card.job.reload.status).to eq('open')
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      job_card = FactoryBot.build(:job_card)
      expect(job_card).to be_valid
    end
  end
end
