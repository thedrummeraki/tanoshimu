class ShowsController < AuthenticatedController

  include ShowsHelper

  def index
    set_title(before: t('anime.shows.view-all'))
    @shows = Show.published
    @additional_main_class = 'no-margin no-padding' if @shows.blank?
    @shows_parts = @shows.each_slice(3).to_a
  end

  def show
    @show = Show.find_by(id: params[:id].to_i)
    p @show.published
    if @show.nil? || !@show.published?
      flash[:warning] = "This show is not available yet. Please try again later."
      redirect_to shows_path
    else
      set_title(:before => @show.get_title)
      @episodes_parts = @show.episodes.each_slice(3).to_a
      @additional_main_class = 'no-margin no-padding'
    end
  end

  def view_all
    @anime_current = "current"
    @shows = Show.all
  end

  def history
    @anime_current = "current"
    episodes = current_user.get_episodes_watched
    if episodes.empty?
      flash[:warning] = "Sorry, we don't know which epsiodes you've watched yet."
      redirect_to '/'
      return
    end
    @episodes = episodes.map{|e| Episode.find(e)}
    @episodes.select!{|e| e.is_published?}
    @episodes.reverse!
    set_title before: t('header.history') #, after: "What have you watched so far?"
  end

  def search
    @search = true
  end

  def tags
    set_title before: t('tags.title')
  end

  def render_img
    id = params[:id]
    if id.blank?
      render text: "No show id was provided."
      return
    end
    show = Show.find_by(id: id)
    if show.nil?
      render text: "Show number #{id} does not exist."
      return
    end

    path = show.get_new_image_path

    url = URI.parse(path)
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }

    send_data res.body, filename: "#{show.get_title}"
  end

end
