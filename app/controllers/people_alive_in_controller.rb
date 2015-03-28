class PeopleAliveInController < ApplicationController

  def index
    @counts = Person.count(:born_on)
  end

  def show
    year = params[:id].to_i
    raise ActiveRecord::RecordNotFound if year.blank?
    raise ActiveRecord::RecordNotFound if year < 1000
    raise ActiveRecord::RecordNotFound if year > 2030

    @year = Date.parse(year.to_s + "-01-01")
    @subjects = Person
		.where(['born_on between ? and ? and died_on between ? and ?', @year - 120.years, @year, @year, @year + 120.years])
		.includes(:roles)
    .order([:born_on, :surname_starts_with, :name])
    @people = @subjects.to_a
    @people.reject! {|subject| !subject.person? }
    respond_to do |format|
      format.html
      format.json { render :json => @people }
    end
  end

end
