require 'rails_helper'

RSpec.describe Job, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:address) }
    it { should validate_presence_of(:workspace_id) }

    context 'customer_name validation' do
      let(:skyview) { FactoryBot.create(:workspace, :skyview) }
      let(:contractors) { FactoryBot.create(:workspace, :contractors) }

      it 'requires customer_name for Skyview workspace' do
        job = Job.new(workspace: skyview, name: 'Test', address: '123 Main St')
        expect(job).not_to be_valid
        expect(job.errors[:customer_name]).to include("can't be blank")
      end

      it 'does not require customer_name for Contractors workspace' do
        job = Job.new(workspace: contractors, name: 'Test', address: '123 Main St')
        expect(job).to be_valid
      end
    end
  end

  describe 'associations' do
    it { should belong_to(:workspace) }
    it { should belong_to(:template).optional }
    it { should belong_to(:contractor).optional }
    it { should have_one(:job_card).dependent(:destroy) }
    it { should have_many(:floors).dependent(:destroy) }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(open: 0, closed: 1, invoiced: 2) }
  end

  describe 'attributes' do
    it 'has permitted defaulting to false' do
      job = Job.new
      expect(job.permitted).to eq(false)
    end

    it 'has permit_fee defaulting to 250.00' do
      job = Job.new
      expect(job.permit_fee).to eq(250.00)
    end

    it 'has status defaulting to open' do
      job = Job.new
      expect(job.status).to eq('open')
    end
  end

  describe 'callbacks' do
    context 'job card creation' do
      let(:skyview) { FactoryBot.create(:workspace, :skyview) }
      let(:contractors) { FactoryBot.create(:workspace, :contractors) }
      let(:rayno) { FactoryBot.create(:workspace, :rayno) }
      let(:template) { FactoryBot.create(:template, workspace: skyview) }

      it 'creates job card for Skyview jobs' do
        job = FactoryBot.create(:job, workspace: skyview)
        expect(job.job_card).to be_present
      end

      it 'creates job card for Rayno jobs with template' do
        job = FactoryBot.create(:job, workspace: rayno, template: template)
        expect(job.job_card).to be_present
      end

      it 'does not create job card for Rayno jobs without template' do
        job = FactoryBot.create(:job, workspace: rayno, template: nil)
        expect(job.job_card).to be_nil
      end

      it 'does not create job card for Contractors jobs' do
        job = FactoryBot.create(:job, workspace: contractors)
        expect(job.job_card).to be_nil
      end
    end
  end

  describe 'scopes' do
    let!(:open_job) { FactoryBot.create(:job, status: 'open') }
    let!(:closed_job) { FactoryBot.create(:job, status: 'closed') }
    let!(:invoiced_job) { FactoryBot.create(:job, status: 'invoiced') }

    it 'has open scope' do
      expect(Job.open).to include(open_job)
      expect(Job.open).not_to include(closed_job, invoiced_job)
    end

    it 'has closed scope' do
      expect(Job.closed).to include(closed_job)
      expect(Job.closed).not_to include(open_job, invoiced_job)
    end

    it 'has invoiced scope' do
      expect(Job.invoiced).to include(invoiced_job)
      expect(Job.invoiced).not_to include(open_job, closed_job)
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      job = FactoryBot.build(:job)
      expect(job).to be_valid
    end

    it 'has skyview trait' do
      job = FactoryBot.build(:job, :skyview)
      expect(job.workspace.slug).to eq('skyview')
      expect(job.customer_name).to be_present
    end

    it 'has contractors trait' do
      job = FactoryBot.build(:job, :contractors)
      expect(job.workspace.slug).to eq('contractors')
    end
  end
end
