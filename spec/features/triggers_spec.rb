require 'spec_helper'

describe 'Triggers' do
  let(:user) { create(:user) }
  before { login_as(user) }

  before do
    @project = FactoryGirl.create :empty_project
    @project.team << [user, :master]
    visit namespace_project_settings_ci_cd_path(@project.namespace, @project)
  end

  context 'create a trigger' do
    before do
      click_on 'Add trigger'
      expect(@project.triggers.count).to eq(1)
    end

    it 'contains trigger token' do
      expect(page).to have_content(@project.triggers.first.token)
    end

    it 'revokes the trigger' do
      click_on 'Revoke'
      expect(@project.triggers.count).to eq(0)
    end
  end
end
