describe PersonalRole, type: :model do
  it 'has a valid factory' do
    expect(create(:personal_role)).to be_valid
  end

  describe '#name' do
    context 'a subject with role of "duck"' do
      let (:roger) { build :person, name: 'Roger'}
      let (:is_a_duck) { build :role, name: 'duck', role_type: 'animal'}
      let (:personal_role) { build :personal_role, person: roger, role: is_a_duck }
      it 'is a duck' do
        expect(personal_role.name).to eq('duck')
      end
    end
    context 'a husband' do
      let (:roger) { build :person, name: 'Roger'}
      let (:is_a_husband) { build :role, name: 'husband'}
      let (:of_sarah) { build :person, name: 'Sarah'}
      let (:personal_role) { build :personal_role, person: roger, role: is_a_husband, related_person: of_sarah }
      it 'is a husband of' do
        expect(personal_role.name).to eq('husband of Sarah')
      end
    end
    context 'a place that was founded' do
      let (:the_royal_marsden) { create :person, name: 'Royal Marsden'}
      let (:is_a_hospital) { create :role, name: 'hospital', role_type: 'place'}
      let (:is_a_foundation) { create :role, name: 'foundation', role_type: 'group'}
      it 'is just a place' do
        the_royal_marsden.roles << is_a_hospital
        the_royal_marsden.roles << is_a_foundation
        expect(the_royal_marsden.type).to eql 'place'
      end
    end
  end
  describe '#current?' do
    context 'a role that has not ended' do
      let (:roger) { build :person, name: 'Roger', died_on: '2001-01-21'}
      let (:was_a_duck) { build :role, name: 'duck'}
      let (:personal_role) { build :personal_role, person: roger, role: was_a_duck }
      it 'is currently a duck' do
        expect(personal_role.current?).to be_truthy
      end
    end
    context 'a role that ended before the subject died' do
      let (:roger) { build :person, name: 'Roger', died_on: '2001-01-21'}
      let (:was_a_duck) { build :role, name: 'duck'}
      let (:personal_role) { build :personal_role, person: roger, role: was_a_duck, ended_at: '2001-01-19' }
      it 'is not currently a duck' do
        expect(personal_role.current?).to be_falsey
      end
    end
    context 'a sticky role that ended before the subject died' do
      let (:roger) { build :person, name: 'Roger', died_on: '2001-01-21'}
      let (:was_a_prs) { build :role, name: 'President of the Royal Society'}
      let (:personal_role) { build :personal_role, person: roger, role: was_a_prs, ended_at: '2001-01-19' }
      it 'is currently a PRS' do
        expect(personal_role.current?).to be_truthy
      end
    end
  end
end
