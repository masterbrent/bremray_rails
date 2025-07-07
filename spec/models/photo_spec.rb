# spec/models/photo_spec.rb
require 'rails_helper'

RSpec.describe Photo, type: :model do
  describe 'associations' do
    it { should belong_to(:job) }
  end

  describe 'validations' do
    it { should validate_presence_of(:url) }
    it { should validate_presence_of(:key) }
    it { should validate_presence_of(:size) }
    it { should validate_presence_of(:content_type) }
    it { should validate_presence_of(:uploaded_by) }
  end

  describe 'content type validation' do
    let(:job) { create(:job) }
    let(:valid_photo) { build(:photo, job: job) }

    it 'accepts valid image content types' do
      %w[image/jpeg image/png image/gif image/webp].each do |content_type|
        photo = build(:photo, job: job, content_type: content_type)
        expect(photo).to be_valid
      end
    end

    it 'rejects invalid content types' do
      photo = build(:photo, job: job, content_type: 'application/pdf')
      expect(photo).not_to be_valid
      expect(photo.errors[:content_type]).to include('must be an image (jpeg, png, gif, or webp)')
    end
  end

  describe 'scopes' do
    it 'orders by created_at descending by default' do
      job = create(:job)
      old_photo = create(:photo, job: job, created_at: 2.days.ago)
      new_photo = create(:photo, job: job, created_at: 1.day.ago)
      newest_photo = create(:photo, job: job)

      expect(Photo.all).to eq([newest_photo, new_photo, old_photo])
    end
  end

  describe 'methods' do
    let(:photo) { build(:photo, key: 'jobs/123/20240106_150230_abc123.jpg', size: 1024576) }

    describe '#filename' do
      it 'extracts filename from key' do
        expect(photo.filename).to eq('20240106_150230_abc123.jpg')
      end
    end

    describe '#size_in_mb' do
      it 'returns size in megabytes' do
        expect(photo.size_in_mb).to eq(1.0)
      end
    end

    describe '#image?' do
      it 'returns true for image content types' do
        photo.content_type = 'image/jpeg'
        expect(photo.image?).to be true
      end

      it 'returns false for non-image content types' do
        photo.content_type = 'application/pdf'
        expect(photo.image?).to be false
      end
    end
  end
end
