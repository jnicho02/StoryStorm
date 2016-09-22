class OrganisationsController < ApplicationController

  before_filter :authenticate_admin!, only: :destroy
  before_filter :authenticate_user!, except: [:autocomplete, :index, :show]
  before_filter :find, only: [:edit, :update]

  def index
    @organisations = Organisation.all.select(:name,:slug,:sponsorships_count).order("name ASC")
    @top_10 = Organisation.all.select(:name,:slug,:sponsorships_count).order("sponsorships_count DESC").limit(10)
    respond_to do |format|
      format.html
      format.json { render json: @organisations }
      format.geojson { render geojson: @organisations }
    end
  end

  def autocomplete
    limit = params[:limit] ? params[:limit] : 5
    if params[:contains]
      @organisations = Organisation.select(:id,:name).name_contains(params[:contains]).limit(limit)
    elsif params[:starts_with]
      @organisations = Organisation.select(:id,:name).name_starts_with(params[:starts_with]).limit(limit)
    else
      @organisations = "{}"
    end
    render json: @organisations.as_json(only: [:id,:name])
  end

  def show
    begin
      if (params[:id]=="oxfordshire_blue_plaques_scheme")
        params[:id] = "oxfordshire_blue_plaques_board"
        redirect_to(organisation_path(params[:id])) and return
      end
      @organisation = Organisation.find_by_slug!(params[:id])
    rescue
      @organisation = Organisation.find(params[:id])
      redirect_to(organisation_path(@organisation.slug), status: :moved_permanently) and return
    end
    @sponsorships = @organisation.sponsorships.paginate(page: params[:page], per_page: 50)
    @mean = @organisation
    @zoom = @organisation.zoom
    respond_to do |format|
      format.html
      format.json { render json: @organisation }
      format.geojson { render geojson: @organisation }
    end
  end

  def new
    @organisation = Organisation.new
  end

  def create
    @organisation = Organisation.new(organisation_params)
    if @organisation.save
      redirect_to organisation_path(@organisation.slug)
    else
      render :new
    end
  end

  def update
    old_slug = @organisation.slug
    if (params[:streetview_url] && params[:streetview_url]!='')
      point = help.geolocation_from params[:streetview_url]
      if !point.latitude.blank? && !point.longitude.blank?
        params[:organisation][:latitude] = point.latitude
        params[:organisation][:longitude] = point.longitude
      end
    end
    if @organisation.update_attributes(organisation_params)
      flash[:notice] = 'Updates to organisation saved.'
      redirect_to organisation_path(@organisation.slug)
    else
      @organisation.slug = old_slug
      render :edit
    end
  end

  protected

    def find
      @organisation = Organisation.find_by_slug!(params[:id])
      if (!@organisation.geolocated? && @organisation.plaques.geolocated.size > 3)
        @organisation.save
      end
    end

  private

    def help
      Helper.instance
    end

    class Helper
      include Singleton
      include PlaquesHelper
    end

    def organisation_params
      params.require(:organisation).permit(
        :name,
        :slug,
        :latitude,
        :longitude,
        :streetview_url,
        :website,
        :description,
        :notes)
    end
end
