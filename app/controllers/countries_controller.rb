class CountriesController < ApplicationController

  before_filter :authenticate_admin!, :only => :destroy
  before_filter :authenticate_user!, :except => [:index, :show]
  before_filter :find, :only => [:edit, :update]

  def index
    @countries = Country.all.to_a
    @countries.delete_if {|x| x.plaques_count == 0 } 
    @countries.sort! { |a,b| b.plaques_count <=> a.plaques_count }
    respond_to do |format|
      format.html
      format.json { render :json => @countries }
      format.geojson { render :geojson => @countries }
    end
  end

  def new
    @country = Country.new
  end

  def create
    @country = Country.new(country_params)
    if @country.save
      redirect_to country_path(@country)
    else
      render :new
    end
  end

  def show
    begin
      @country = Country.find_by_alpha2!(params[:id])
    rescue
      @country = Country.find(params[:id])
      redirect_to(country_url(@country), :status => :moved_permanently) and return
    end
    respond_to do |format|
      format.html
      format.json { render :json => @country }
      format.geojson { render :geojson => @country }
    end
  end

  def update
    if @country.update_attributes(country_params)
      redirect_to country_path(@country)
    else
      render :edit
    end
  end

  protected

    def find
      @country = Country.find_by_alpha2!(params[:id])
    end

  private

    def country_params
      params.require(:country).permit(
        :alpha2,
        :name,
        :dbpedia_uri)
    end
end
